--[[
  SekretovOS — System Services
  Logging, clock, mock industrial data feeds
]]

local filesystem = require("filesystem")
local unicode = require("unicode")

local services = {
  logPath = "/logs",
  configPath = "/config",
  tempPath = "/temp",
  logs = {},
  maxMemoryLogs = 200,
  subscribers = {},
}

local LEVELS = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4, ALERT = 5 }
local LEVEL_NAMES = { "DEBUG", "INFO", "WARN", "ERROR", "ALERT" }

function services.init(basePath)
  basePath = basePath or ""
  services.logPath = filesystem.concat(basePath, "logs")
  services.configPath = filesystem.concat(basePath, "config")
  services.tempPath = filesystem.concat(basePath, "temp")
  for _, p in ipairs({ services.logPath, services.configPath, services.tempPath }) do
    if not filesystem.exists(p) then
      filesystem.makeDirectory(p)
    end
  end
end

function services.timestamp()
  return os.date("%Y-%m-%d %H:%M:%S")
end

function services.log(level, source, message)
  level = LEVELS[level] and level or "INFO"
  local entry = {
    time = services.timestamp(),
    level = level,
    source = source or "system",
    message = tostring(message),
  }
  services.logs[#services.logs + 1] = entry
  if #services.logs > services.maxMemoryLogs then
    table.remove(services.logs, 1)
  end

  local line = string.format("[%s] [%s] [%s] %s\n",
    entry.time, entry.level, entry.source, entry.message)

  local ok, f = pcall(filesystem.open,
    filesystem.concat(services.logPath, "system.log"), "a")
  if ok and f then
    f:write(line)
    f:close()
  end

  if level == "ERROR" or level == "ALERT" then
    local errFile = filesystem.open(filesystem.concat(services.logPath, "error.log"), "a")
    if errFile then
      errFile:write(line)
      errFile:close()
    end
  end

  for _, cb in ipairs(services.subscribers) do
    pcall(cb, entry)
  end
  return entry
end

function services.debug(src, msg) return services.log("DEBUG", src, msg) end
function services.info(src, msg) return services.log("INFO", src, msg) end
function services.warn(src, msg) return services.log("WARN", src, msg) end
function services.error(src, msg) return services.log("ERROR", src, msg) end
function services.alert(src, msg) return services.log("ALERT", src, msg) end

function services.getLogs(filter)
  if not filter or filter == "" then
    return services.logs
  end
  local result = {}
  local lower = string.lower(filter)
  for _, e in ipairs(services.logs) do
    if string.find(string.lower(e.message), lower, 1, true)
        or string.find(string.lower(e.level), lower, 1, true)
        or string.find(string.lower(e.source), lower, 1, true) then
      result[#result + 1] = e
    end
  end
  return result
end

function services.onLog(callback)
  services.subscribers[#services.subscribers + 1] = callback
end

-- Mock industrial telemetry (replace with real component probes)
local telemetry = {
  energy = { input = 0, output = 0, stored = 0, load = 0, history = {} },
  ae2 = { used = 0, total = 1, channels = 0, cpus = 0, crafting = 0 },
  reactor = { active = false, temp = 20, output = 0, rodLevel = 0, safe = true },
}

function services.tickTelemetry()
  local t = os.time()
  local e = telemetry.energy
  e.input = 800 + math.random(400)
  e.output = 600 + math.random(500)
  e.stored = math.min(100000, (e.stored or 50000) + e.input - e.output)
  e.load = math.floor(e.output / math.max(e.input, 1) * 100)
  e.history[#e.history + 1] = e.output
  if #e.history > 60 then table.remove(e.history, 1) end

  local a = telemetry.ae2
  a.used = 40000 + math.random(20000)
  a.total = 64000
  a.channels = math.random(8, 32)
  a.cpus = math.random(1, 4)
  a.crafting = math.random(0, 12)

  local r = telemetry.reactor
  if r.active then
    r.temp = math.min(1200, r.temp + math.random(5, 20))
    r.output = 200 + math.random(800)
    r.safe = r.temp < 1000
  else
    r.temp = math.max(20, r.temp - 5)
    r.output = 0
    r.safe = true
  end
end

function services.getEnergy() return telemetry.energy end
function services.getAE2() return telemetry.ae2 end
function services.getReactor() return telemetry.reactor end

function services.reactorShutdown()
  telemetry.reactor.active = false
  services.alert("reactor", "EMERGENCY SHUTDOWN INITIATED")
end

function services.reactorStart()
  telemetry.reactor.active = true
  telemetry.reactor.temp = 200
  services.info("reactor", "Reactor startup sequence")
end

function services.loadConfig(key, default)
  local path = filesystem.concat(services.configPath, "settings.cfg")
  if not filesystem.exists(path) then return default end
  local f = filesystem.open(path, "r")
  if not f then return default end
  local data = f:read("*a")
  f:close()
  for line in data:gmatch("[^\n]+") do
    local k, v = line:match("^([^=]+)=(.+)$")
    if k and k:match("^%s*" .. key .. "%s*$") then
      return v:match("^%s*(.-)%s*$")
    end
  end
  return default
end

function services.saveConfig(key, value)
  local path = filesystem.concat(services.configPath, "settings.cfg")
  local lines = {}
  local found = false
  if filesystem.exists(path) then
    local f = filesystem.open(path, "r")
    if f then
      for line in f:read("*a"):gmatch("[^\n]+") do
        local k = line:match("^([^=]+)=")
        if k and k:match("^%s*" .. key .. "%s*$") then
          lines[#lines + 1] = key .. "=" .. tostring(value)
          found = true
        else
          lines[#lines + 1] = line
        end
      end
      f:close()
    end
  end
  if not found then
    lines[#lines + 1] = key .. "=" .. tostring(value)
  end
  local f = filesystem.open(path, "w")
  if f then
    f:write(table.concat(lines, "\n"))
    f:close()
  end
end

return services
