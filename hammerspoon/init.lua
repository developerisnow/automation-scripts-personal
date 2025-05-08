----------------------------------------------------------
--  Superwhisper auto-ingest via Hammerspoon pathwatcher --
----------------------------------------------------------
-- cache of files already scheduled, to prevent duplicate launches
local processing = {}

local WATCH   = "/Users/user/NextCloud2/__Vaults_Databases_nxtcld/__Recordings_nxtcld/__cloud-recordings/_huawei_recordings/_recordings__by_EasyPro"
local ARCHIVE = WATCH .. "/_transcribed"
local INBOX  = os.getenv("HOME") .. "/Library/Application Support/Superwhisper/Inbox"
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
      -- ignore subsequent FSEvents for the same file
      if processing[f] then
        goto continue
      end
      log("skip, not audio: %s", f)
      goto continue 
    end                 -- skip non-audio
    -- mark as in‑process so we launch only once
    processing[f] = true
    -- дождёмся, когда Nextcloud закроет дескриптор + стабилизируется размер
    hs.timer.doAfter(2, function()
      if not hs.fs.attributes(f) then return end             -- файл уже исчез?
      -----------------------------------------------
      -- 1. открыть в Superwhisper (импорт & ASR)
      -----------------------------------------------
      -- copy original file into Superwhisper's watched Inbox first (no race‑condition)
      local infile = f
      local base   = infile:match(".+/([^/]+)$")
      local inboxTarget = INBOX .. "/" .. base
      hs.execute(string.format('/bin/cp "%s" "%s"', infile, inboxTarget), true)
      log("copied %s → INBOX", base)
      hs.task.new("/usr/bin/open", nil, {"-a", APP, f}):start()
      log("launched: open -a %s %s", APP, f)
      -- archive original after 90 s (enough for import)
      hs.timer.doAfter(90, function()
          local target = ARCHIVE .. "/" .. base
          if hs.fs.attributes(infile) and not hs.fs.attributes(target) then
              hs.fs.mkdir(ARCHIVE)
              os.rename(infile, target)
              log("archived %s → %s", infile, target)
              processing[infile] = nil            -- allow future reprocessing if needed
          end
      end)
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