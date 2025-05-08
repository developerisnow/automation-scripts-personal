----------------------------------------------------------
--  Superwhisper auto-ingest via Hammerspoon pathwatcher --
----------------------------------------------------------
local WATCH   = "/Users/user/NextCloud2/__Vaults_Databases_nxtcld/__Recordings_nxtcld/__cloud-recordings/_huawei_recordings/_recordings__by_EasyPro"
local ARCHIVE = WATCH .. "/_transcribed"
local exts    = {wav=true, flac=true, mp3=true, m4a=true}

-- logging helper & app bundle
local APP = "Superwhisper"       -- bundle name as shown by `ls /Applications`
local function log(fmt, ...)
  hs.printf("[SW‑HS] " .. string.format(fmt, ...))
end

-- helper: is this a fresh audio file?
local function isAudio(f)
  local ext = f:match("^.+%.([^.]+)$")
  return ext and exts[ext:lower()]
end

-- main handler
local function handler(files)
  for _,f in ipairs(files) do
    log("fs event → %s", f)
    if f:find("/_transcribed/") then goto continue end       -- skip already processed
    if not isAudio(f) then 
      log("skip, not audio: %s", f)
      goto continue 
    end                 -- skip non-audio
    -- дождёмся, когда Nextcloud закроет дескриптор + стабилизируется размер
    hs.timer.doAfter(2, function()
      if not hs.fs.attributes(f) then return end             -- файл уже исчез?
      -----------------------------------------------
      -- 1. открыть в Superwhisper (импорт & ASR)
      -----------------------------------------------
      hs.task.new("/usr/bin/open", nil, {"-a", APP, f}):start()
      log("launched: open -a %s %s", APP, f)
      -----------------------------------------------
      -- 2. переместить исходник в _transcribed
      -----------------------------------------------
      hs.fs.mkdir(ARCHIVE)                                   -- idempotent
      local base = f:match(".+/([^/]+)$")
      local target = ARCHIVE .. "/" .. base
      os.rename(f, target)                                   -- atomic move
      log("moved %s → %s", f, target)
      -----------------------------------------------
      -- 3. уведомление (не обязательно)
      -----------------------------------------------
      hs.notify.new({
        title = "Superwhisper ingest",
        informativeText = base .. " → transcribed"
      }):send()
    end)
    ::continue::
  end
end

hs.pathwatcher.new(WATCH, handler):start()
log("watcher active on: %s", WATCH)