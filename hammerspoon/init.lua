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

-- allowed extensions
local exts = {wav=true, flac=true, mp3=true, m4a=true}

-- ########## UTILITIES #################################
local function ts() return os.date("%H:%M:%S") end
local function log(fmt, ...) hs.printf("[%s SW‑HS] " .. fmt, ts(), ...) end
local function isAudio(p)  local e=p:match("^.+%.([^.]+)$%c*$"); return e and exts[e:lower()] end -- added %c*$ to handle potential trailing nulls from some fs events
local function basename(p) return p:match("[^/]+$") end

-- Function to find the most recently modified subdirectory in RECORDS
-- This is used to find where SuperWhisper is *currently* working or just finished.
local function getMostRecentSuperwhisperDir(newer_than_timestamp)
    local mostRecentDir = nil
    local latestModTime = newer_than_timestamp or 0 -- Only look for dirs modified after a certain point
    for entry in hs.fs.dir(RECORDS) do
        if entry ~= "." and entry ~= ".." then
            local fullPath = RECORDS .. "/" .. entry
            local attr = hs.fs.attributes(fullPath)
            if attr and attr.mode == "directory" and attr.modification then
                if attr.modification > latestModTime then
                    latestModTime = attr.modification
                    mostRecentDir = fullPath
                end
            end
        end
    end
    -- Log only if a directory is found or if a timestamp was provided for context
    if mostRecentDir or newer_than_timestamp then 
        log("getMostRecentSuperwhisperDir (newer_than: %s): Found %s (modtime: %s)", newer_than_timestamp or "any", mostRecentDir or "None", latestModTime)
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
local MAX_RUN    = 3600       -- 60 min timeout per file

-- enqueue new file
local function enqueue(path)
  local base = basename(path)
  if processing[base] == "done" then 
    log("Enqueue: %s already marked 'done'. Skipping.", base)
    return 
  end
  if processing[base] then 
    log("Enqueue: %s already in processing. Skipping.", base)
    return 
  end

  -- Best-effort pre-check if meta.json might already exist from a previous interrupted run
  -- This is not foolproof as audioFile field might not match `base` directly in all meta.json files
  -- The main `tryNext` polling logic is more robust using directory modification times.
  -- if doesMetaJsonExistForBase(base) then
  --   log("Enqueue: Pre-check found existing meta.json for %s. Marking as done to avoid re-processing.", base)
  --   processing[base] = "done" -- Mark as done to avoid queueing if SW already processed it.
  --   return
  -- end

  log("Enqueue: Adding %s to queue.", base)
  processing[base] = true
  table.insert(queue, path)
end

-- main worker
local function tryNext()
  if busy or #queue==0 then return end
  busy = true
  local src = table.remove(queue,1)
  local base = basename(src)
  log("▶ importing %s", base)
  
  local t_before_open = os.time() -- Time before opening SuperWhisper

  hs.timer.doAfter(3, function()
    local appwin = hs.window.filter.new(false):setAppFilter(APP,{allowTitles={".*"}}):getWindows()[1]
    if appwin then
        hs.eventtap.keyStroke({"cmd"}, nil, 13, 0, appwin:application())  -- keycode 13 = "w"
        log("sent Cmd-W")
    end
  end)

  hs.task.new("/usr/bin/open", nil, {"-a", APP, src}):start()

  local t0 = os.time()
  local pollT
  local expected_sw_dir_path = nil -- Will store the path to the SuperWhisper dir for this recording

  -- Give SuperWhisper a moment to create its directory, then find it.
  hs.timer.doAfter(5, function() -- Wait 5 seconds for SW to create its directory
      -- We are looking for a directory newer than when we started processing this specific file.
      expected_sw_dir_path = getMostRecentSuperwhisperDir(t_before_open - 10) -- -10s to allow for slight clock differences or delays
      if expected_sw_dir_path then
          log("Identified SuperWhisper directory for %s as %s", base, expected_sw_dir_path)
      else
          log("⚠ Could not identify SuperWhisper directory for %s after 5s. Polling will be less targeted.", base)
      end
  end)

  pollT = hs.timer.doEvery(15, function() -- Or your preferred interval
      local elapsed = os.time()-t0
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
                  log("Found meta.json at %s but it seems too old (mod: %s, t_before_open: %s). Still waiting.", potential_meta_path, meta_attr and meta_attr.modification, t_before_open)
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

          local rel_path_from_watch_dir = ""
          local original_filename = basename(src)
          local original_src_dir_path = src:match("(.+)/[^/]+$") or ""

          if src:sub(1, #WATCH_ONEPLUS) == WATCH_ONEPLUS then
              rel_path_from_watch_dir = original_src_dir_path:sub(#WATCH_ONEPLUS + 1)
          elseif src:sub(1, #WATCH_HUAWEI) == WATCH_HUAWEI then
              rel_path_from_watch_dir = original_src_dir_path:sub(#WATCH_HUAWEI + 1)
          end
          if rel_path_from_watch_dir:sub(1,1) == "/" then rel_path_from_watch_dir = rel_path_from_watch_dir:sub(2) end
          if rel_path_from_watch_dir:sub(-1) == "/" then rel_path_from_watch_dir = rel_path_from_watch_dir:sub(1, -2) end

          local archive_target_dir = ARCHIVE_BASE_PATH .. "/" .. yyyy .. "/" .. mm .. "/" .. dd
          if rel_path_from_watch_dir and #rel_path_from_watch_dir > 0 then
              archive_target_dir = archive_target_dir .. "/" .. rel_path_from_watch_dir
          end
          
          hs.fs.mkdir(archive_target_dir)
          local dst_file_final = archive_target_dir .. "/" .. original_filename

          if hs.fs.attributes(src) then 
              os.rename(src, dst_file_final)
              log("✓ Archived %s to %s (%.0fs)", base, dst_file_final, elapsed)
          else
              log("⚠ Source file %s not found for archiving.", src)
          end

          -- Call Python script to aggregate into Obsidian
          local python_script_path = os.getenv("HOME") .. "/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/transcription_aggregation_obsidian.py"
          local cmd = "/usr/bin/python3"
          local args = {python_script_path, meta_json_path_for_current_file}
          log("Calling Obsidian aggregation script for: %s", meta_json_path_for_current_file)
          hs.task.new(cmd, function(exitCode, stdOut, stdErr) 
              log("Obsidian script stdout: %s", stdOut)
              if stdErr and #stdErr > 0 then log("Obsidian script stderr: %s", stdErr) end
              if exitCode ~= 0 then log("⚠ Obsidian script failed for %s with exit code %d", meta_json_path_for_current_file, exitCode) end
          end, args):start()

          pollT:stop()
          processing[base]="done"; busy=false; tryNext()
      elseif elapsed > MAX_RUN then
          log("⚠ timeout %s  (%.0fs) — will retry later", base, elapsed)
          pollT:stop()
          processing[base]=nil; busy=false; enqueue(src); tryNext()
      end
  end)
end

-- ########## SCAN EXISTING FILES #######################
local function scanDir(dir_to_scan)
  log("Scanning directory: %s", dir_to_scan)
  for entry in hs.fs.dir(dir_to_scan) do
      if entry ~= "." and entry ~= ".." and entry:lower() ~= "_transcribed" and entry:lower() ~= ".stfolder" and entry:lower() ~= ".ds_store" then
         local p = dir_to_scan .. entry -- Corrected path concatenation
         local attr = hs.fs.attributes(p)
         if attr and attr.mode == "file" and isAudio(entry) then
            log("Initial scan: found audio %s", p)
            enqueue(p)
         elseif attr and attr.mode == "directory" then
            scanDir(p)
         end
      end
  end
end
scanDir(WATCH_ONEPLUS)    -- initial load for OnePlus
scanDir(WATCH_HUAWEI)     -- initial load for Huawei
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
log("Watching %s and %s  — initial %d in queue", WATCH_ONEPLUS, WATCH_HUAWEI, #queue)