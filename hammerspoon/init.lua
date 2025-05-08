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
local WATCH   = "/Users/user/NextCloud2/__Vaults_Databases_nxtcld/__Recordings_nxtcld/__cloud-recordings/_huawei_recordings/_recordings__by_EasyPro"
local ARCHIVE = WATCH .. "/_transcribed"
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
      
      local found_meta_json_path = findMetaJsonPath(base) -- Call the renamed function

      if found_meta_json_path then
          log("✓ Transcription complete for %s. Meta.json: %s", base, found_meta_json_path)
          -- Archive original preserving recorder sub‑folders
          local rel  = src:sub(#WATCH + 2)           -- path part after WATCH/
          local dst  = ARCHIVE .. "/" .. rel         -- e.g. _transcribed/2025/05/...
          local dstDir = dst:match("(.+)/[^/]+$")
          hs.fs.mkdir(dstDir)                        -- create nested dirs if absent
          if hs.fs.attributes(src) then os.rename(src, dst) end
          log("✓ Archived %s to %s (%.0fs)", base, dst, elapsed)

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
local function scanDir(dir)
  for entry in hs.fs.dir(dir) do
      if entry ~= "." and entry ~= ".." and entry ~= "_transcribed" then
         local p = dir.."/"..entry
         local attr = hs.fs.attributes(p)
         if attr and attr.mode == "file" and isAudio(entry) then
            enqueue(p)
         elseif attr and attr.mode == "directory" then
            scanDir(p)
         end
      end
  end
end
scanDir(WATCH)         -- initial load
hs.timer.doAfter(1, tryNext) -- Reverted to 1s, adjust if needed

-- ########## WATCHER ###################################
local function handler(paths)
  for _,p in ipairs(paths) do
      if isAudio(p) and not p:find("/_transcribed/") then
         enqueue(p);  tryNext()
      end
  end
end
hs.pathwatcher.new(WATCH, handler):start()
log("watching %s  — initial %d in queue", WATCH, #queue)