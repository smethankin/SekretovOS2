--[[
  SekretovOS — Desktop Environment
  Top panel, launcher, wallpaper, status
]]

local render = require("system.render")
local theme = require("system.theme")
local gui = require("system.gui")
local wm = require("system.window")
local services = require("system.services")

local desktop = {
  apps = {},
  launcherOpen = false,
  launcherIndex = 1,
  statusText = "ONLINE",
  wallpaperPattern = 0,
}

function desktop.registerApp(app)
  desktop.apps[#desktop.apps + 1] = app
  table.sort(desktop.apps, function(a, b) return (a.name or "") < (b.name or "") end)
end

function desktop.launch(appId)
  for _, app in ipairs(desktop.apps) do
    if app.id == appId or app.name == appId then
      local win = app.createWindow()
      if win then
        wm.add(win)
        services.info("desktop", "Launched " .. (app.name or appId))
        gui.notify(app.name or appId, "Application started", "success")
      end
      return
    end
  end
end

function desktop.drawWallpaper()
  local th = theme.current
  local w, h = render.width, render.height
  render.fill(1, 2, w, h - 1, " ", th.textDim, th.background)

  -- Subtle grid pattern (industrial SCADA aesthetic)
  for y = 3, h - 1, 3 do
    for x = 1, w, 4 do
      render.set(x, y, string.char(0xFA), th.graphGrid, th.background)
    end
  end

  -- Corner branding
  local brand = " SEKRETOV INDUSTRIAL OS "
  render.drawText(2, h - 1, brand:sub(1, w - 2), th.accentDim, th.background)
end

function desktop.drawTopPanel()
  local th = theme.current
  local w = render.width
  render.fill(1, 1, w, 1, " ", th.accent, th.titleBar)

  local timeStr = os.date("%H:%M:%S")
  local dateStr = os.date("%Y-%m-%d")
  local left = (" %s v%s "):format(services and "SekretovOS" or "SOS", "1.0")
  render.drawText(1, 1, left:sub(1, 18), th.accent, th.titleBar)

  local center = (" %s | SYS:%s | WIN:%d "):format(
    dateStr, desktop.statusText, wm.count())
  local cx = math.floor((w - #center) / 2)
  render.drawText(cx, 1, center:sub(1, w - cx), th.text, th.titleBar)

  local right = (" %s [F1] "):format(timeStr)
  render.drawText(w - #right, 1, right, th.textBright, th.titleBar)
end

function desktop.drawLauncher()
  if not desktop.launcherOpen then return end
  local th = theme.current
  local w, h = render.width, render.height
  local lw, lh = 28, math.min(#desktop.apps + 2, h - 4)
  local lx = math.floor((w - lw) / 2)
  local ly = math.floor((h - lh) / 2)

  render.fill(lx, ly, lw, lh, " ", th.panelBorder, th.panel)
  render.drawBorder(lx, ly, lw, lh, th.accent, th.panel)
  render.drawText(lx + 2, ly, " APPLICATION LAUNCHER ", th.accent, th.panel)

  for i, app in ipairs(desktop.apps) do
    local y = ly + i
    local prefix = (i == desktop.launcherIndex) and ">" or " "
    local line = ("%s [%s] %s"):format(prefix, app.id or "?", app.name or "App")
    local fg = (i == desktop.launcherIndex) and th.textBright or th.text
    local bg = (i == desktop.launcherIndex) and th.titleActive or th.panel
    render.drawText(lx + 2, y, line:sub(1, lw - 4), fg, bg)
  end
end

function desktop.draw()
  desktop.drawWallpaper()
  desktop.drawTopPanel()
  desktop.drawLauncher()
end

function desktop.handleEvent(evt)
  if evt.type == "key_down" then
    if evt.char == "l" or evt.char == "L" then
      desktop.launcherOpen = not desktop.launcherOpen
      return true
    end
    if desktop.launcherOpen then
      if evt.char == "w" or evt.code == 200 then
        desktop.launcherIndex = math.max(1, desktop.launcherIndex - 1)
        return true
      elseif evt.char == "s" or evt.code == 208 then
        desktop.launcherIndex = math.min(#desktop.apps, desktop.launcherIndex + 1)
        return true
      elseif evt.char == "\r" or evt.char == "\n" then
        local app = desktop.apps[desktop.launcherIndex]
        if app then
          desktop.launch(app.id)
          desktop.launcherOpen = false
        end
        return true
      elseif evt.char == "q" or evt.char == "\27" then
        desktop.launcherOpen = false
        return true
      end
    end
  end

  if evt.type == "mouse_down" and evt.y == 1 then
  local w = render.width
    local mx = evt.x
    if mx >= w - 20 then
      desktop.launcherOpen = not desktop.launcherOpen
      return true
    end
  end
  return false
end

function desktop.tick(dt)
  local e = services.getEnergy()
  if e.load > 90 then
    desktop.statusText = "HIGH LOAD"
  elseif not services.getReactor().safe then
    desktop.statusText = "ALERT"
  else
    desktop.statusText = "ONLINE"
  end
end

function desktop.getTickRate()
  return 0.05
end

function desktop.update(dt)
  for _, win in ipairs(wm.windows) do
    if win.onUpdate then win.onUpdate(dt) end
  end
end

return desktop
