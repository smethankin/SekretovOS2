--[[ Settings — theme & performance ]]

local _OS = _OS
local gui, services, render, theme = _OS.gui, _OS.services, _OS.render, _OS.theme

local function createWindow()
  local win = gui.window({
    title = "SETTINGS",
    x = 10, y = 6,
    w = 40, h = 14,
    closable = true,
    draggable = true,
  })

  win.selectedTheme = 1
  win.themes = theme.list()
  win.tickIdx = 2
  win.tickRates = { 0.2, 0.1, 0.05, 0.03 }

  for i, name in ipairs(win.themes) do
    if name == theme.name then win.selectedTheme = i end
  end

  win.onDraw = function(ax, ay, ww, wh)
    local th = theme.current
    render.drawText(ax + 2, ay, "THEME", th.accent, th.panel)
    for i, name in ipairs(win.themes) do
      local mark = (i == win.selectedTheme) and ">" or " "
      render.drawText(ax + 4, ay + i, mark .. " " .. name, th.textBright, th.panel)
    end

    render.drawText(ax + 2, ay + 6, "TICK RATE", th.accent, th.panel)
    local tr = win.tickRates[win.tickIdx] or 0.1
    render.drawText(ax + 4, ay + 7, (" %.2fs [+/-]"):format(tr), th.text, th.panel)

    render.drawText(ax + 2, ay + 9, "[T] cycle theme  [+/-] tick", th.textDim, th.panel)
    render.drawText(ax + 2, ay + 10, "[S] save config", th.textDim, th.panel)
  end

  win.onEvent = function(evt)
    if evt.type ~= "key_down" then return false end
    local c = evt.char
    if c == "t" or c == "T" then
      win.selectedTheme = (win.selectedTheme % #win.themes) + 1
      theme.apply(win.themes[win.selectedTheme])
      gui.notify("Settings", "Theme: " .. win.themes[win.selectedTheme], "info")
      return true
    elseif c == "+" or c == "=" then
      win.tickIdx = math.min(#win.tickRates, win.tickIdx + 1)
      _OS.kernel.tickRate = win.tickRates[win.tickIdx]
      return true
    elseif c == "-" then
      win.tickIdx = math.max(1, win.tickIdx - 1)
      _OS.kernel.tickRate = win.tickRates[win.tickIdx]
      return true
    elseif c == "s" or c == "S" then
      services.saveConfig("theme", win.themes[win.selectedTheme])
      gui.notify("Settings", "Configuration saved", "success")
      return true
    end
    return false
  end

  return win
end

return {
  id = "settings",
  name = "Settings",
  icon = "CFG",
  createWindow = createWindow,
}
