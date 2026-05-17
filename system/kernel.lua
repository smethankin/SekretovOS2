--[[
  SekretovOS — Kernel
  Boot, module registry, main loop orchestration
]]

local computer = require("computer")
local component = require("component")
local filesystem = require("filesystem")

local kernel = {
  version = "1.0.0",
  name = "SekretovOS",
  running = false,
  basePath = "",
  modules = {},
  desktop = nil,
  tickRate = 0.1,
  lastTick = 0,
}

function kernel.register(name, mod)
  kernel.modules[name] = mod
end

function kernel.require(name)
  if kernel.modules[name] then
    return kernel.modules[name]
  end
  local path = name:gsub("%.", "/")
  if not path:find("/") then
    path = "system/" .. path
  end
  local full = filesystem.concat(kernel.basePath, path .. ".lua")
  if filesystem.exists(full) then
    local fn, err = loadfile(full, "bt", _G)
    if not fn then
      error("kernel: failed to load " .. name .. ": " .. tostring(err))
    end
    local mod = fn()
    kernel.modules[name] = mod
    return mod
  end
  return require(name)
end

function kernel.boot(basePath)
  kernel.basePath = basePath or filesystem.canonical(".")
  kernel.running = true

  local services = kernel.require("services")
  services.init(kernel.basePath)
  services.info("kernel", kernel.name .. " v" .. kernel.version .. " booting")

  local theme = kernel.require("theme")
  local savedTheme = services.loadConfig("theme", "industrial")
  theme.apply(savedTheme)

  local render = kernel.require("render")
  render.init()
  services.info("kernel", ("Display %dx%d"):format(render.width, render.height))

  kernel.register("theme", theme)
  kernel.register("render", render)
  kernel.register("services", services)

  local events = kernel.require("events")
  kernel.register("events", events)

  local gui = kernel.require("gui")
  kernel.register("gui", gui)

  local wm = kernel.require("window")
  kernel.register("wm", wm)

  services.info("kernel", "Subsystems online")
  return kernel
end

function kernel.setDesktop(desktop)
  kernel.desktop = desktop
end

function kernel.frame(dt)
  local render = kernel.modules.render
  local wm = kernel.modules.wm
  local gui = kernel.modules.gui
  local services = kernel.modules.services

  if kernel.desktop and kernel.desktop.draw then
    kernel.desktop.draw()
  end

  if wm then wm.draw() end
  if gui then gui.drawNotifications(render.width) end

  render.present()
end

function kernel.run()
  local events = kernel.modules.events
  local services = kernel.modules.services
  local wm = kernel.modules.wm
  local render = kernel.modules.render

  kernel.lastTick = computer.uptime()
  services.info("kernel", "Entering main loop")

  while kernel.running do
    local timeout = kernel.tickRate
    if kernel.desktop and kernel.desktop.getTickRate then
      timeout = kernel.desktop.getTickRate()
    end

    local evt = events.pull(timeout)

    if evt then
      if evt.type == "interrupt" then
        kernel.running = false
        break
      end

      local handled = false
      if wm then handled = wm.handleEvent(evt) end
      if not handled and kernel.desktop and kernel.desktop.handleEvent then
        handled = kernel.desktop.handleEvent(evt)
      end
      if not handled and kernel.desktop and kernel.desktop.onEvent then
        handled = kernel.desktop.onEvent(evt)
      end
    end

    local now = computer.uptime()
    if now - kernel.lastTick >= 1.0 then
      services.tickTelemetry()
      kernel.lastTick = now
      if kernel.desktop and kernel.desktop.tick then
        kernel.desktop.tick(1.0)
      end
    end

    if kernel.desktop and kernel.desktop.update then
      kernel.desktop.update(timeout)
    end

    kernel.frame(timeout)
  end

  services.info("kernel", "Shutdown complete")
  render.copyToGpu()
end

function kernel.shutdown()
  kernel.running = false
end

return kernel
