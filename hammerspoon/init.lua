----------------------------------------------------------
--  SuperWhisper ingest-watcher  •  v0.5 (2025-05-19)   --
--  • два исходных каталога (Huawei / OnePlus)           --
--  • FIFO-очередь, одновременность = 1                  --
--  • дубликаты отсекаются                               --
--  • OK  → mv →  _transcribed/YYYY/MM/DD/...            --
--  • FAIL→ mv →  _transcribed/_failed/                  --
--  • критерий OK : meta.json.rawResult ≠ ""            --
----------------------------------------------------------
local hs   = hs
local json = require("hs.json")

----------------------- CONFIG ---------------------------
local WATCH_HUAWEI   = "/Users/user/Recordings_ASR_Huawei/"
local WATCH_ONEPLUS  = "/Users/user/Recordings_ASR_OnePlus/"
local ARCHIVE_ROOT   = "/Users/user/NextCloud2/__Vaults_Databases_nxtcld/__Recordings_nxtcld/_transcribed"
local FAILED_DIR     = ARCHIVE_ROOT .. "/_failed"
local RECORDS_DIR    = os.getenv("HOME") .. "/Documents/superwhisper/recordings"
local APP_NAME       = "Superwhisper"

-- параметры контроля
local MAX_RUN       = 1800      -- 30 мин на файл
local MAX_RETRIES   = 3
local POLL_INTERVAL = 12        -- опрос meta.json

-------------------- UTILS/LIBS --------------------------
local exts = {wav=true, flac=true, mp3=true, m4a=true}
local function ts() return os.date("%H:%M:%S") end
------------------------------------------------------------------
-- helper: write each log line to daily file inside watch roots --
------------------------------------------------------------------
local function writeMsgToDailyLogs(message)
    local date = os.date("%Y-%m-%d")
    for _, root in ipairs { WATCH_HUAWEI, WATCH_ONEPLUS } do
        local logDir = root .. "logs"
        hs.fs.mkdir(logDir)                         -- idempotent
        local f = io.open(string.format("%s/%s.log", logDir, date), "a")
        if f then
            f:write(message .. "\n")
            f:close()
        end
    end
end

-- console + file logger (uses writeMsgToDailyLogs)
local function log(fmt, ...)
    local msg = string.format("[%s SW-HS] " .. fmt, ts(), ...)
    hs.printf("%s", msg)            -- console
    writeMsgToDailyLogs(msg)        -- daily file
end
local function isAudio(p) local e=p:match("%.([^%.]+)$"); return e and exts[e:lower()] end
local function base(p)   return p:match("[^/]+$") end
local function dirname(p)return p:match("(.+)/[^/]+$") end

-- рекурсивный поиск имени файла в каталоге
local function fileExistsRecursive(dir, name)
  for e in hs.fs.dir(dir) do
    if e~="." and e~=".." then
      local full = dir.."/"..e
      local st = hs.fs.attributes(full)
      if st then
         if st.mode=="file" and e==name then return true end
         if st.mode=="directory" and fileExistsRecursive(full,name) then return true end
      end
    end
  end; return false
end

-- извлекаем meta.json и проверяем готовность
local function metaReady(metaPath)
  local data = json.read(metaPath)
  if not data then return false end
  if data.rawResult and #data.rawResult>0 then return true end
  return false
end

-- находится ли meta для baseName и она успешная?
local function hasGoodMeta(baseName)
  for rec in hs.fs.dir(RECORDS_DIR) do
    if rec~="." and rec~=".." then
       local meta = RECORDS_DIR.."/"..rec.."/meta.json"
       if hs.fs.attributes(meta) then
          local ok, tbl = pcall(json.read, meta)
          if ok and tbl and tbl.audioFile==baseName and metaReady(meta) then
              return meta, tbl
          end
       end
    end
  end
end

-------------------- STATE/QUEUE -------------------------
local queue        = {}          -- FIFO путей
local processing   = {}          -- base → "busy"/"done"/"fail"
local retries      = {}          -- base → int
local busy         = false

local function enqueue(path)
  local b = base(path)
  if not isAudio(b) then return end
  if processing[b]=="done" or processing[b]=="fail" then return end
  if retries[b] and retries[b]>=MAX_RETRIES then return end
  retries[b]=(retries[b] or 0)+1
  table.insert(queue,path)
  log("enqueue %s (try %d/%d)", b, retries[b], MAX_RETRIES)
end

-------------------- MAIN WORKER -------------------------
local function closeAnyRecordWindow()
    local app = hs.appfinder.appFromName(APP_NAME)
    if not app then return end
    -- Send Cmd‑W using character "w" (API expects a string)
    hs.eventtap.keyStroke({"cmd"}, "w", 0, app)
end

local function archive(src, ok)
  local b = base(src)
  local target
  if ok then
     -- YYYY/MM/DD из имени katalog или берём текущую дату
     local y,m,d = b:match("^(%d%d%d%d)_(%d%d)_(%d%d)")
     if not y then local t=os.date("*t"); y,m,d=t.year,t.month,t.day end
     target = string.format("%s/%04d/%02d/%02d", ARCHIVE_ROOT,y,m,d)
  else
     target = FAILED_DIR
  end
  hs.fs.mkdir(target)
  local dst=target.."/"..b
  os.rename(src,dst)
  log("mv %s → %s", b, ok and dst or "_failed")
end

local function tryNext()
  if busy or #queue==0 then return end
  busy=true
  local src=table.remove(queue,1)
  local b = base(src)
  processing[b]="busy"
  log("▶ %s",b)

  -- закрываем старое окно через 3 с
  hs.timer.doAfter(3, closeAnyRecordWindow)
  hs.task.new("/usr/bin/open",nil,{"-a",APP_NAME,src}):start()

  local t0=os.time()
  local poll
  poll=hs.timer.doEvery(POLL_INTERVAL,function()
      local metaPath,metaTbl = hasGoodMeta(b)
      local elapsed=os.time()-t0
      if metaPath then
         log("✓ meta ok %s (%.0fs)",b,elapsed)
         archive(src,true)
         processing[b]="done"
         poll:stop(); busy=false; tryNext()
      elseif elapsed>MAX_RUN then
         log("✗ timeout %s",b)
         archive(src,false)
         processing[b]="fail"
         poll:stop(); busy=false; tryNext()
      end
  end)
end

-------------------- INITIAL SCAN ------------------------
local function scan(dir)
  for e in hs.fs.dir(dir) do
    if e~="." and e~=".." and e:sub(1,1)~="." then
      local p=dir..e
      local st=hs.fs.attributes(p)
      if st then
        if st.mode=="file" then enqueue(p)
        elseif st.mode=="directory" then
           scan(p.."/")
        end
      end
    end
  end
end
scan(WATCH_HUAWEI); scan(WATCH_ONEPLUS)
hs.timer.doAfter(1,tryNext)

-------------------- WATCHERS ----------------------------
local function onEvent(paths)
  for _,p in ipairs(paths) do
    local abs=hs.fs.pathToAbsolute(p); if not abs then goto skip end
    if abs:find("/_transcribed/",1,true) then goto skip end
    if abs:find("/_failed/",1,true)       then goto skip end
    if not isAudio(abs)                  then goto skip end
    if abs:sub(1,#WATCH_HUAWEI)==WATCH_HUAWEI or abs:sub(1,#WATCH_ONEPLUS)==WATCH_ONEPLUS then
        enqueue(abs); tryNext()
    end
    ::skip::
  end
end
hs.pathwatcher.new(WATCH_HUAWEI,  onEvent):start()
hs.pathwatcher.new(WATCH_ONEPLUS, onEvent):start()
log("WATCHING:\n  %s\n  %s",WATCH_HUAWEI,WATCH_ONEPLUS)