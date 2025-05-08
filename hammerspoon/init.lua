----------------------------------------------------------
--  SuperWhisper ingest watcher (one‑shot, with polling) --
--  v0.3  2025‑05‑08                                      --
----------------------------------------------------------
-- helper: hh:mm:ss timestamp
local function ts() return os.date("%H:%M:%S") end

----------------------------------------------------------
--  CONFIG — ADAPT THESE PATHS                           --
----------------------------------------------------------
local WATCH = "/Users/user/NextCloud2/__Vaults_Databases_nxtcld/__Recordings_nxtcld/__cloud-recordings/_huawei_recordings/_recordings__by_EasyPro"
local INBOX = os.getenv("HOME") .. "/Library/Application Support/Superwhisper/Inbox"
local ARCHIVE = WATCH .. "/_transcribed"
local APP = "Superwhisper"          -- bundle name

----------------------------------------------------------
--  INTERNAL STATE                                       --
----------------------------------------------------------
local exts       = {wav=true, flac=true, mp3=true, m4a=true}
local processing = {}               -- map sourceFile → { inbox = “…/Inbox/foo.m4a”, timer = timerObj }

----------------------------------------------------------
--  UTILS                                                --
----------------------------------------------------------
local function isAudio(p)
  local ext = p:match("^.+%.([^.]+)$")
  return ext and exts[ext:lower()]
end

local function log(fmt, ...)
  hs.printf("[%s SW‑HS] " .. fmt, ts(), ...)
end

----------------------------------------------------------
--  PER‑FILE POLLER                                      --
--  Waits until the copy disappears from Inbox           --
--  (SuperWhisper removes it when takes control)         --
----------------------------------------------------------
local function startPoll(src, inboxCopy)
  local t0 = os.time()
  local pollTimer
  pollTimer = hs.timer.doEvery(10, function()
      if not hs.fs.attributes(inboxCopy) then
         local secs = os.time() - t0
         log("✓ processed <%s> by SuperWhisper in %ds", src:match("[^/]+$"), secs)

         -- move original to archive
         hs.fs.mkdir(ARCHIVE)
         local dst = ARCHIVE .. "/" .. src:match("[^/]+$")
         if hs.fs.attributes(src) then
             os.rename(src, dst)
             log("archived → %s", dst)
         end

         processing[src] = nil      -- release
         pollTimer:stop()
      end
  end)
  return pollTimer
end

----------------------------------------------------------
--  MAIN HANDLER                                         --
----------------------------------------------------------
local function handler(files)
  for _, f in ipairs(files) do
      if not isAudio(f) or f:find("/_transcribed/") then goto continue end
      if processing[f] then goto continue end            -- already in flight

      processing[f] = true                               -- lock
      log("event: %s", f)

      -- copy to Inbox (skip if already exists)
      local base = f:match("[^/]+$")
      local inCopy = INBOX .. "/" .. base
      if not hs.fs.attributes(inCopy) then
          hs.execute(string.format('/bin/cp "%s" "%s"', f, inCopy), true)
          log("copied → Inbox")
      else
          log("Inbox already has copy, skip cp")
      end

      -- launch import (one single call)
      hs.task.new("/usr/bin/open", nil, {"-a", APP, f}):start()
      log("open ‑a %s \"%s\"", APP, f)

      -- start poller for this file
      processing[f] = { inbox = inCopy,
                        timer = startPoll(f, inCopy) }

      ::continue::
  end
end

----------------------------------------------------------
--  START WATCHER                                        --
----------------------------------------------------------
hs.pathwatcher.new(WATCH, handler):start()
log("watching: %s", WATCH)