----------------------------------------------------------
--  SuperWhisper ingest watcher  •  v0.4  (2025‑05‑08)   --
--  • single import per file                             --
--  • initial scan after reboot                          --
--  • FIFO queue, concurrency‑1                          --
--  • done‑criterion = meta.json                         --
----------------------------------------------------------
local hs               = hs      -- shorten
local json = require("hs.json")   -- наверх файла, рядом с `hs`

-- ########## CONFIG (edit if paths change) #############
local WATCH_ONEPLUS   = "/Users/user/Recordings_ASR_OnePlus/"
local WATCH_HUAWEI    = "/Users/user/Recordings_ASR_Huawei/"
local ARCHIVE_BASE_PATH = "/Users/user/NextCloud2/__Vaults_Databases_nxtcld/__Recordings_nxtcld/_transcribed"
local RECORDS = os.getenv("HOME") .. "/Documents/superwhisper/recordings"
local APP     = "Superwhisper"

-- global log directory
local LOG_ROOT = os.getenv("HOME") .. "/.hammerspoon/logs"
hs.fs.mkdir(LOG_ROOT)

-- allowed extensions
local exts = {wav=true, flac=true, mp3=true, m4a=true}

-- ########## UTILITIES #################################
local function ts() return os.date("%H:%M:%S") end

------------------------------------------------------------------
-- write each log line to ~/.hammerspoon/logs/YYYY-MM-DD.log     --
------------------------------------------------------------------
local function writeMsgToDailyLogs(message)
    local date = os.date("%Y-%m-%d")
    local f = io.open(string.format("%s/%s.log", LOG_ROOT, date), "a")
    if f then
        f:write(message .. "\n")
        f:close()
    end
end

-- console + file logger (uses writeMsgToDailyLogs)
local function log(fmt, ...)
    local msg = string.format("[%s SW-HS] " .. fmt, ts(), ...)
    hs.printf("%s", msg)            -- console
    writeMsgToDailyLogs(msg)        -- daily file
end

-- Helper to make timestamps human-readable in logs
local function formatTimestampForLog(ts_val)
    if not ts_val or ts_val == 0 then return "0 (Epoch or nil)" end
    return os.date("%Y-%m-%d %H:%M:%S", ts_val) .. " (" .. ts_val .. ")"
end

-- returns true when the supplied path (full or basename) has an allowed extension
local function isAudio(p)
  if not p then return false end
  -- grab what comes after the last dot
  local ext = p:match("^.+%.([^.]+)$")
  if not ext then return false end
  return exts[ext:lower()] ~= nil       -- wav / flac / mp3 / m4a
end

local function basename(p) return p:match("[^/]+$") end

-- Function to find the most recently modified subdirectory in RECORDS
-- This is used to find where SuperWhisper is *currently* working or just finished.
local function getMostRecentSuperwhisperDir(newer_than_timestamp)
    local mostRecentDir = nil
    local latestModTime = newer_than_timestamp or 0 
    log("getMostRecentSuperwhisperDir: Searching for dirs in %s newer than timestamp %s", RECORDS, formatTimestampForLog(latestModTime))
    for entry in hs.fs.dir(RECORDS) do
        if entry ~= "." and entry ~= ".." then
            local fullPath = RECORDS .. "/" .. entry
            local attr = hs.fs.attributes(fullPath)
            if attr and attr.mode == "directory" and attr.modification then
                log("getMostRecentSuperwhisperDir: Checking entry '%s', modtime %s (target: > %s)", fullPath, formatTimestampForLog(attr.modification), formatTimestampForLog(latestModTime))
                if attr.modification > latestModTime then
                    log("getMostRecentSuperwhisperDir: Candidate found: %s (new latestModTime: %s)", fullPath, formatTimestampForLog(attr.modification))
                    latestModTime = attr.modification
                    mostRecentDir = fullPath
                end
            end
        end
    end
    if mostRecentDir then 
        log("getMostRecentSuperwhisperDir: Finally selected %s (modtime: %s)", mostRecentDir, formatTimestampForLog(latestModTime))
    elseif newer_than_timestamp then
        log("getMostRecentSuperwhisperDir: No directory found newer than %s.", formatTimestampForLog(newer_than_timestamp))
    else
        log("getMostRecentSuperwhisperDir: No directory found without a newer_than condition.")
    end
    return mostRecentDir
end

-- Function to check if a meta.json exists for a given base filename
-- This is primarily for pre-checking in enqueue
local function doesMetaJsonExistForBase(base_filename)
    for dir_entry in hs.fs.dir(RECORDS) do
        if dir_entry ~= "." and dir_entry ~= ".." then
            local potential_meta_path = RECORDS .. "/" .. dir_entry .. "/meta.json"
            if hs.fs.attributes(potential_meta_path) then
                local f = io.open(potential_meta_path, "r")
                if f then
                    local content = f:read("*a")
                    f:close()
                    -- This is a simplified check. SuperWhisper might not store the original filename directly.
                    -- The main polling logic uses a more robust method (most recent dir).
                    -- This is a best-effort pre-check.
                    if content and content:find([["audioFile"%s*:%s*"]] .. hs.fnutils.escapePattern(base_filename) .. [["]], 1, false) then
                        log("doesMetaJsonExistForBase: Found existing meta.json for %s in %s", base_filename, potential_meta_path)
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ########## QUEUE / STATE #############################
local queue      = {}         -- FIFO of full paths
local busy       = false
local processing = {}         -- baseName → true while in queue/processing or "done"
local MAX_RUN    = 300       -- 5 min max per file
local MAX_RETRIES = 3           -- abandon file after 3 failed attempts
local FAILED_DIR  = ARCHIVE_BASE_PATH .. "/_failed"
local SW_DIR_TIMEOUT = 45      -- give up if SuperWhisper hasn't created its folder after N seconds (increased from 30)
local attempts    = {}          -- baseName → retry counter
local tryNext -- Forward declaration

-- Helper function to recursively check if a file exists in a directory
local function findFileRecursive(baseFilename, dirToSearch)
    for entry in hs.fs.dir(dirToSearch) do
        if entry ~= "." and entry ~= ".." then
            local fullEntryPath = dirToSearch .. "/" .. entry
            local attr = hs.fs.attributes(fullEntryPath)
            if attr then
                if attr.mode == "file" and entry == baseFilename then
                    return true -- Found the file
                elseif attr.mode == "directory" then
                    if findFileRecursive(baseFilename, fullEntryPath) then
                        return true -- Found in subdirectory
                    end
                end
            end
        end
    end
    return false -- Not found in this directory or its children
end

-- Check if a file with the same base name already exists in the archive (including _failed)
local function isAlreadyArchived(baseFilename)
    if findFileRecursive(baseFilename, ARCHIVE_BASE_PATH) then
        log("isAlreadyArchived: Found %s in ARCHIVE_BASE_PATH", baseFilename)
        return true
    end
    -- No need to check FAILED_DIR separately if ARCHIVE_BASE_PATH is its parent,
    -- but if they were parallel, you would:
    -- if findFileRecursive(baseFilename, FAILED_DIR) then
    --     log("isAlreadyArchived: Found %s in FAILED_DIR", baseFilename)
    --     return true
    -- end
    return false
end

-- helper: size (MiB), sha1 hash (первые 8 симв), дата создания --
local function fileInfo(p)
    local a = hs.fs.attributes(p)
    local mb = a and string.format("%.1f", (a.size or 0)/1024/1024) or "?"
    local ct = a and os.date("%Y-%m-%d %H:%M", a.creation) or "?"
    local h8 = "????????"
    if a and a.size and a.size > 0 then
        local ok,out = pcall(function()
            return hs.execute(string.format("/usr/bin/shasum -a 1 '%s'", p), true)
        end)
        if ok and out then h8 = out:match("^(%w%w%w%w%w%w%w%w)") or h8 end
    end
    return mb,h8,ct
end

-- enqueue new file
local function enqueue(path)
    local base = basename(path)
    if processing[base] == true then
        log("Enqueue: %s already being processed, skipping duplicate watcher event.", base)
        return
    end
    -- Check if already archived BEFORE any attempt logic
    if isAlreadyArchived(base) then
        log("Enqueue: Skipping %s as it (or a file with the same name) was already found in the archive destination: %s", base, ARCHIVE_BASE_PATH)
        processing[base] = "done" -- Mark as done to prevent re-processing by watcher/scan
        return
    end
    attempts[base] = (attempts[base] or 0) + 1
    local sz,h8,ct = fileInfo(path)
    log("enqueue: %s  %s MB  sha1:%s  created:%s  (try %d/%d)",
        base, sz, h8, ct, attempts[base], MAX_RETRIES)
    -- Too many failures: quarantine the file and mark as failed
    if attempts[base] > MAX_RETRIES then
        log("✗ giving up on %s after %d unsuccessful attempts. Moving to FAILED_DIR.", base, MAX_RETRIES)
        hs.fs.mkdir(FAILED_DIR)
        -- Ensure the source file still exists before attempting to move
        if hs.fs.attributes(path) then
            local failed_dst = FAILED_DIR .. "/" .. base
            local ren_ok, ren_err = os.rename(path, failed_dst)
            if ren_ok then
                log("✓ Moved %s to %s", base, failed_dst)
                log("mv %s → %s", path, failed_dst)
            else
                log("⚠ Error moving %s to %s: %s", base, failed_dst, tostring(ren_err))
            end
        else
            log("⚠ Source file %s not found for moving to FAILED_DIR.", path)
        end
        processing[base] = "failed" -- Mark as terminally failed
        -- Remove from queue if it's there
        for i = #queue, 1, -1 do
            if queue[i] == path then
                table.remove(queue, i)
                log("Removed %s from queue after marking as failed.", base)
            end
        end
        busy = false -- Free up processor for next item
        -- Schedule tryNext to run slightly deferred to avoid potential recursion/scoping issues
        hs.timer.doAfter(0.1, function() tryNext() end) 
        return
    end
    -- Skip if we have already finished or permanently failed this file
    if processing[base] == "done" or processing[base] == "failed" then
        log("Enqueue: Skipping %s as it's already '%s'", base, processing[base])
        -- If it was 'failed' but somehow re-attempted below MAX_RETRIES, reset attempts to avoid instant fail
        if processing[base] == "failed" and (attempts[base] <= MAX_RETRIES) then
            attempts[base] = MAX_RETRIES +1 -- Ensure it won't be picked up again by scanDir/watcher
        end
        return
    end
    -- If already in process (e.g. duplicate watcher event while it's in pollT), ignore.
    -- processing[base] might be true if it's actively being processed by tryNext.
    if processing[base] == true and busy and #queue > 0 and queue[1] ~= path then -- Check if it's genuinely a new add vs. already processing
        log("Enqueue: %s already in active processing or queue. Skipping duplicate add.", base)
        return
    end
    log("Enqueue: Adding %s to queue.", base)
    processing[base] = true
    table.insert(queue, path)
end

-- main worker
local function tryNext_actual() -- Renamed to avoid conflict if forward declaration is tricky with scoping
  if busy or #queue==0 then
    if #queue == 0 and busy == false then
        log("Queue is empty and not busy. Waiting for new files.")
    end
    return
  end
  busy = true
  local src = table.remove(queue,1)
  local base = basename(src)
  local idx = TOTAL_INITIAL - #queue
  log("Processing file %d of %d — %s", idx, TOTAL_INITIAL, base)
  log("▶ importing %s (attempt %d/%d)", base, attempts[base] or 1, MAX_RETRIES)
  
  local t_before_open = os.time() -- Time before opening SuperWhisper

  hs.timer.doAfter(3, function()
    local appwin = hs.window.filter.new(false):setAppFilter(APP,{allowTitles={".*"}}):getWindows()[1]
    if appwin then
        hs.eventtap.keyStroke({"cmd"}, "w", 0, appwin:application())
        log("sent Cmd-W to %s", APP)
    else
        log("No window found for %s to send Cmd-W", APP)
    end
  end)

  hs.task.new("/usr/bin/open", nil, {"-a", APP, src}):start()

  local t0 = os.time()
  local pollT
  local expected_sw_dir_path = nil 
  local find_dir_attempts = 0

  local function findSuperWhisperDir()
    find_dir_attempts = find_dir_attempts + 1
    log("Attempt %d to find SuperWhisper dir for %s (t_before_open: %s)", find_dir_attempts, base, formatTimestampForLog(t_before_open))
    expected_sw_dir_path = getMostRecentSuperwhisperDir(t_before_open - 5) -- Loosen timing slightly (orig -2)
    if expected_sw_dir_path then
        log("Identified SuperWhisper directory for %s as %s", base, expected_sw_dir_path)
    else
        log("⚠ Could not identify SuperWhisper directory for %s on attempt %d.", base, find_dir_attempts)
        if find_dir_attempts < 3 and not pollT:running() then -- Try a couple more times if pollT hasn't started its main work
            hs.timer.doAfter(7, findSuperWhisperDir) -- Try again after 7 seconds
        else
            log("Giving up on finding SuperWhisper dir for %s after %d attempts. Polling will rely on meta.json appearance.", base, find_dir_attempts)
        end
    end
  end

  hs.timer.doAfter(7, findSuperWhisperDir) -- Initial attempt after 7s (was 10)

  pollT = hs.timer.doEvery(15, function()
      local elapsed = os.time()-t0

      -- Early abort: SuperWhisper never created its working folder, or we couldn't find it
      if (not expected_sw_dir_path) and elapsed > SW_DIR_TIMEOUT then
          log("✗ SW_DIR_TIMEOUT for %s: no SuperWhisper dir identified or meta.json found after %ds", base, elapsed)
          pollT:stop()
          busy = false
          -- This will increment attempts and potentially move to _failed if MAX_RETRIES is hit
          log("Re-enqueueing %s due to SW_DIR_TIMEOUT.", base) 
          enqueue(src) 
          tryNext()
          return
      end

      local meta_json_path_for_current_file = nil

      if expected_sw_dir_path then
          local potential_meta_path = expected_sw_dir_path .. "/meta.json"
          if hs.fs.attributes(potential_meta_path) then
              -- Basic check: ensure the meta.json isn't ancient (e.g., older than when we started processing this file)
              local meta_attr = hs.fs.attributes(potential_meta_path)
              if meta_attr and meta_attr.modification and meta_attr.modification >= t_before_open then
                  log("Found meta.json at %s for %s", potential_meta_path, base)
                  meta_json_path_for_current_file = potential_meta_path
              else
                  log("Found meta.json at %s but it seems too old (mod: %s, t_before_open: %s). Still waiting.", potential_meta_path, meta_attr and formatTimestampForLog(meta_attr.modification), formatTimestampForLog(t_before_open))
              end
          else
              -- log("Still waiting for meta.json in %s for %s", expected_sw_dir_path, base) -- Can be noisy
          end
      else
          -- Fallback to old scanning method if expected_sw_dir_path couldn't be identified (less ideal)
          -- This part would be removed if we are confident getMostRecentSuperwhisperDir always works after SW starts.
          -- For now, let's log a warning and it will likely timeout if this fallback is hit without finding anything.
          log("Polling fallback: expected_sw_dir_path not set for %s. This may lead to a timeout.", base)
      end

      if meta_json_path_for_current_file then
          log("✓ Transcription complete for %s. Meta.json: %s", base, meta_json_path_for_current_file)
          
          -- Archive original with new YYYY/MM/DD structure
          local yyyy, mm, dd = nil, nil, nil
          local meta_file_content = nil
          local f_meta = io.open(meta_json_path_for_current_file, "r")
          if f_meta then
              meta_file_content = f_meta:read("*a")
              f_meta:close()
              -- Extract YYYY-MM-DD from "datetime" : "YYYY-MM-DDTHH:MM:SS"
              local dt_str_match = meta_file_content:match([["datetime"%s*:%s*"([%d%-%dT%:%fZS%.]+)"]])
              if dt_str_match then
                  yyyy = dt_str_match:match("^(%d%d%d%d)")
                  mm   = dt_str_match:match("^%d%d%d%d%-(%d%d)")
                  dd   = dt_str_match:match("^%d%d%d%d%-%d%d%-(%d%d)")
              end
          end

          if not (yyyy and mm and dd) then
              log("⚠ Could not extract YYYY/MM/DD from meta.json for archiving: %s. Using current date as fallback.", meta_json_path_for_current_file)
              local now = os.date("*t")
              yyyy = string.format("%04d", now.year)
              mm = string.format("%02d", now.month)
              dd = string.format("%02d", now.day)
          end

          local original_filename = base -- Use base as it's already derived
          local original_src_dir_path = src:match("(.+)/[^/]+$") or ""
          local rel_path_from_watch_dir = ""

          if original_src_dir_path:sub(1, #WATCH_ONEPLUS) == WATCH_ONEPLUS then
              rel_path_from_watch_dir = original_src_dir_path:sub(#WATCH_ONEPLUS + 1)
          elseif original_src_dir_path:sub(1, #WATCH_HUAWEI) == WATCH_HUAWEI then
              rel_path_from_watch_dir = original_src_dir_path:sub(#WATCH_HUAWEI + 1)
          end
          
          -- Normalize rel_path_from_watch_dir: remove leading/trailing slashes
          if rel_path_from_watch_dir then
            rel_path_from_watch_dir = rel_path_from_watch_dir:gsub("^[/]*", ""):gsub("[/]*$", "")
          else
            rel_path_from_watch_dir = ""
          end

          -- Construct the archive path carefully
          local archive_date_part = yyyy .. "/" .. mm .. "/" .. dd
          local archive_target_dir

          -- If rel_path_from_watch_dir already contains the date structure (e.g., "2025/05" or "2025/05/09")
          -- or if it's empty, we don't want to prepend the date part again or add extra slashes.
          if rel_path_from_watch_dir == "" then
            archive_target_dir = ARCHIVE_BASE_PATH .. "/" .. archive_date_part
          elseif rel_path_from_watch_dir:match("^" .. yyyy .. "/") then -- covers YYYY/MM and YYYY/MM/DD
            -- This case implies the watch folder itself might have date-based subdirs that Syncthing preserves
            log("Archive path: rel_path_from_watch_dir '%s' seems to already include date structure. Using it directly under ARCHIVE_BASE_PATH.", rel_path_from_watch_dir)
            archive_target_dir = ARCHIVE_BASE_PATH .. "/" .. rel_path_from_watch_dir
          else
            -- Standard case: append non-date-structured relative path to the date part
            archive_target_dir = ARCHIVE_BASE_PATH .. "/" .. archive_date_part .. "/" .. rel_path_from_watch_dir
          end
          
          -- Final cleanup of slashes for archive_target_dir
          archive_target_dir = archive_target_dir:gsub("//+", "/")

          hs.fs.mkdir(archive_target_dir) 
          local dst_file_final = archive_target_dir .. "/" .. original_filename

          if hs.fs.attributes(src) then 
              local ren_ok, ren_err = os.rename(src, dst_file_final)
              if ren_ok then
                log("mv %s → %s", src, dst_file_final)
                log("✓ Archived %s to %s (%.0fs)", base, dst_file_final, elapsed)
                -- Verify move
                if hs.fs.attributes(src) then
                    log("⚠ CRITICAL: Source file %s STILL EXISTS after successful os.rename to %s!", src, dst_file_final)
                else
                    log("✓ Source file %s confirmed removed after archiving.", src)
                end
                if not hs.fs.attributes(dst_file_final) then
                    log("⚠ CRITICAL: Destination file %s DOES NOT EXIST after successful os.rename from %s!", dst_file_final, src)
                else
                    log("✓ Destination file %s confirmed created.", dst_file_final)
                end

                -- Call Python script to aggregate into Obsidian
                local python_script_path = os.getenv("HOME") .. "/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/transcription_aggregation_obsidian.py"
                local cmd = "/usr/bin/python3"
                local args = {python_script_path, meta_json_path_for_current_file} -- Add original_filename later for date extraction
                log("Calling Obsidian aggregation script for: %s", meta_json_path_for_current_file)
                hs.task.new(cmd, function(exitCode, stdOut, stdErr) 
                    log("Obsidian script stdout: %s", stdOut)
                    if stdErr and #stdErr > 0 then log("Obsidian script stderr: %s", stdErr) end
                    if exitCode ~= 0 then log("⚠ Obsidian script failed for %s with exit code %d", meta_json_path_for_current_file, exitCode) end
                end, args):start()

                pollT:stop()
                processing[base]="done"; busy=false; tryNext()
              else
                log("⚠ Error archiving %s to %s: %s. File remains in source. Will retry.", base, dst_file_final, tostring(ren_err))
                pollT:stop()
                busy=false;
                log("Re-enqueueing %s due to os.rename failure.", base)
                enqueue(src); -- This will use the attempt counter
                tryNext()
              end
          else
              log("⚠ Source file %s not found for archiving.", src)
          end
      elseif elapsed > MAX_RUN then
          log("⚠ MAX_RUN timeout for %s (%.0fs)", base, elapsed)
          pollT:stop()
          busy=false;
          log("Re-enqueueing %s due to MAX_RUN timeout.", base)
          enqueue(src); tryNext()
      end
  end)
end

-- Assign the actual function to the forward-declared variable
tryNext = tryNext_actual

-- ########## SCAN EXISTING FILES #######################
local function scanDir(dir_to_scan)
  log("Scanning directory: %s", dir_to_scan)
  for entry in hs.fs.dir(dir_to_scan) do
      if entry ~= "." and entry ~= ".." and entry:lower() ~= "_transcribed" and entry:lower() ~= ".stfolder" and entry:lower() ~= ".ds_store" then
         -- Ensure dir_to_scan ends with a slash before concatenating entry
         local correctly_formed_dir_path = dir_to_scan
         if correctly_formed_dir_path:sub(-1) ~= "/" then
             correctly_formed_dir_path = correctly_formed_dir_path .. "/"
         end
         local p = correctly_formed_dir_path .. entry
         local attr = hs.fs.attributes(p)
         if attr then
            if attr.mode == "file" then
                log("scanDir: found file %s", p)
                if isAudio(entry) then
                    log("Initial scan: found audio %s", p)
                    enqueue(p)
                end
            elseif attr.mode == "directory" then
                log("scanDir: recursing into subdirectory %s", p)
                scanDir(p)
            end
         else
            log("scanDir: could not stat %s", p)
         end
      end
  end
end
scanDir(WATCH_ONEPLUS)    -- initial load for OnePlus
scanDir(WATCH_HUAWEI)     -- initial load for Huawei

local TOTAL_INITIAL = #queue
log("Initial scan found %d audio files to process.", TOTAL_INITIAL)

if #queue > 0 then
    log("Sorting initial queue of %d files by filename.", #queue)
    table.sort(queue, function(a,b)
        return basename(a) < basename(b)
    end)
    if #queue > 0 then -- Check again in case queue became empty during sort (highly unlikely)
      log("Queue sorted. First item: %s, Last item: %s", basename(queue[1]), basename(queue[#queue]))
    else
      log("Queue became empty after attempting to sort.")
    end
end

hs.timer.doAfter(1, tryNext)

-- ########## WATCHER ###################################
local function fileEventHandler(paths)
  for _,p_event in ipairs(paths) do
      -- Normalize the path from the event, as it might be relative or malformed sometimes
      local p = hs.fs.pathToAbsolute(p_event)
      if not p then
        log("Watcher event: could not resolve path for event data '%s'. Skipping.", p_event)
        goto continue_loop
      end

      local file_name_lower = basename(p):lower()
      if file_name_lower == ".ds_store" or file_name_lower == ".stfolder" or p:find("/_transcribed/", 1, true) or p:find(ARCHIVE_BASE_PATH, 1, true) then
          -- Skip these files/folders immediately
          goto continue_loop
      end

      -- Check if the path is within one of the main watch folders
      local is_in_oneplus_watch = p:sub(1, #WATCH_ONEPLUS) == WATCH_ONEPLUS
      local is_in_huawei_watch = p:sub(1, #WATCH_HUAWEI) == WATCH_HUAWEI
      -- local is_in_archive = p:find(ARCHIVE_BASE_PATH, 1, true) -- Already checked above more broadly

      if (is_in_oneplus_watch or is_in_huawei_watch) then
          if isAudio(p) then
             log("Watcher event: detected audio %s", p)
             enqueue(p);  tryNext()
          end
      end
      ::continue_loop::
  end
end

hs.pathwatcher.new(WATCH_ONEPLUS, fileEventHandler):start()
hs.pathwatcher.new(WATCH_HUAWEI, fileEventHandler):start()
hs.alert.show("SW‑HS config reloaded", 1)
log("Watching %s and %s  — initial %d in queue", WATCH_ONEPLUS, WATCH_HUAWEI, #queue)