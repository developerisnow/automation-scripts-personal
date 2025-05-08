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
local function isAudio(p)  local e=p:match("^.+%.([^.]+)$"); return e and exts[e:lower()] end
local function basename(p) return p:match("[^/]+$") end

-- find meta.json that references <baseName> and return its path
local function findMetaJsonPath(base)
  log("findMetaJsonPath: Entered for base '%s'", base)
  local dir_count = 0
  for dir in hs.fs.dir(RECORDS) do
      dir_count = dir_count + 1
      if dir:sub(1,1) ~= "." then
         local meta_path = RECORDS.."/"..dir.."/meta.json"
         if hs.fs.attributes(meta_path) then
            local ok, tbl = pcall(function()
                 return json.read(meta_path) -- Read the specific meta_path
            end)
            if ok and tbl and tbl.audioFile == base then
               log("findMetaJsonPath: Found matching audioFile '%s' in %s", base, meta_path)
               log("findMetaJsonPath: Exiting for base '%s', returning path. Total dirs checked: %d", base, dir_count)
               return meta_path -- Return the path
            end
         end
      end
  end
  log("findMetaJsonPath: Exiting for base '%s', meta.json not found. Total dirs checked: %d", base, dir_count)
  return nil -- Return nil if not found
end

-- ########## QUEUE / STATE #############################
local queue      = {}         -- FIFO of full paths
local busy       = false
local processing = {}         -- baseName → true while in queue/processing
local MAX_RUN    = 3600       -- 60 min timeout per file

-- enqueue new file
local function enqueue(path)
  local base = basename(path)
  if processing[base] == "done" then return end
  if processing[base] then return end
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
  -- через 3 с после старта нажимаем Cmd-W (закрыть окно записи)
  hs.timer.doAfter(3, function()
    local appwin = hs.window.filter.new(false):setAppFilter(APP,{allowTitles={".*"}}):getWindows()[1]
    if appwin then
        hs.eventtap.keyStroke({"cmd"}, nil, 13, 0, appwin:application())  -- keycode 13 = "w"
        log("sent Cmd-W")
    end
  end)

  -- open file (SuperWhisper creates its own copy)
  hs.task.new("/usr/bin/open", nil, {"-a", APP, src}):start()

  local t0 = os.time()
  -- poll every 15 s for meta.json
  local pollT
  pollT = hs.timer.doEvery(15, function()
      local elapsed = os.time()-t0
      -- log("POLL: Checking status for %s (elapsed: %.0fs)", base, elapsed) -- Keep this if you like, or remove
      
      local found_meta_json_path = findMetaJsonPath(base)

      if found_meta_json_path then
          log("✓ Transcription complete for %s. Meta.json: %s", base, found_meta_json_path)
          
          -- Archive original with new YYYY/MM/DD structure
          local yyyy, mm, dd = nil, nil, nil
          local meta_file_content = nil
          local f_meta = io.open(found_meta_json_path, "r")
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
              log("⚠ Could not extract YYYY/MM/DD from meta.json for archiving: %s. Using current date as fallback.", found_meta_json_path)
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
          local args = {python_script_path, found_meta_json_path}
          log("Calling Obsidian aggregation script for: %s", found_meta_json_path)
          hs.task.new(cmd, function(exitCode, stdOut, stdErr) 
              log("Obsidian script stdout: %s", stdOut)
              if stdErr and #stdErr > 0 then log("Obsidian script stderr: %s", stdErr) end
              if exitCode ~= 0 then log("⚠ Obsidian script failed for %s with exit code %d", found_meta_json_path, exitCode) end
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
      if entry ~= "." and entry ~= ".." and entry ~= "_transcribed" then -- Ensure _transcribed is not scanned if it's a subfolder of WATCH
         local p = dir_to_scan.."/"..entry
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
  for _,p in ipairs(paths) do
      -- Check if the path is within one of the main watch folders and not in an archive path itself
      local is_in_oneplus_watch = p:sub(1, #WATCH_ONEPLUS) == WATCH_ONEPLUS
      local is_in_huawei_watch = p:sub(1, #WATCH_HUAWEI) == WATCH_HUAWEI
      local is_in_archive = p:find(ARCHIVE_BASE_PATH, 1, true) -- Check if path contains archive base path

      if (is_in_oneplus_watch or is_in_huawei_watch) and not is_in_archive then
          if isAudio(p) then
             log("Watcher event: detected audio %s", p)
             enqueue(p);  tryNext()
          end
      end
  end
end

hs.pathwatcher.new(WATCH_ONEPLUS, fileEventHandler):start()
hs.pathwatcher.new(WATCH_HUAWEI, fileEventHandler):start()
log("Watching %s and %s  — initial %d in queue", WATCH_ONEPLUS, WATCH_HUAWEI, #queue)