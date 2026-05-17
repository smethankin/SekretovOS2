["main.lua"]=[==[--[[
  SekretovOS — Main Entry Point
  Industrial SCADA-style OS for OpenComputers

  Install: copy folder to computer root, run: main
]]

local filesystem = require("filesystem")
local shell = require("shell")

-- Resolve install path
local mainPath = shell.getRunningProgram() or "main.lua"
local basePath = filesystem.path(filesystem.canonical(mainPath))

-- Prepend to package.path for module loading
package.path = basePath .. "/?.lua;" .. basePath .. "/?/init.lua;" .. package.path

local kernel = dofile(filesystem.concat(basePath, "system/kernel.lua"))
kernel.basePath = basePath

-- Boot kernel
kernel.boot(basePath)

local services = kernel.modules.services
local gui = kernel.modules.gui
local desktop = dofile(filesystem.concat(basePath, "system/desktop.lua"))
kernel.setDesktop(desktop)

-- Load applications
local appIds = {
  "energy", "ae2", "reactor", "logs", "settings", "files", "terminal",
}

for _, id in ipairs(appIds) do
  local path = filesystem.concat(basePath, "apps", id .. ".lua")
  if filesystem.exists(path) then
    local fn = loadfile(path, "bt", setmetatable({
      _OS = {
        kernel = kernel,
        gui = gui,
        render = kernel.modules.render,
        theme = kernel.modules.theme,
        services = services,
        wm = kernel.modules.wm,
        basePath = basePath,
      },
    }, { __index = _G }))
    if fn then
      local app = fn()
      if app then
        desktop.registerApp(app)
        services.debug("main", "Loaded app: " .. id)
      end
    end
  end
end

services.info("main", "SekretovOS ready — L launcher, clock click, Ctrl+C exit")
gui.notify("SekretovOS", "System online", "success")

-- Run main loop
kernel.run()
]==]