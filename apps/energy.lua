--[[ Energy Monitor — realtime power SCADA panel ]]

local _OS = _OS
local gui, services, render, theme = _OS.gui, _OS.services, _OS.render, _OS.theme

local function createWindow()
  local w, h = render.width, render.height
  local win = gui.window({
    title = "ENERGY MONITOR",
    x = 4, y = 4,
    w = math.min(52, w - 6),
    h = math.min(18, h - 6),
    closable = true,
    draggable = true,
  })

  win.widgets = {}
  win.onUpdate = function()
    local e = services.getEnergy()
    win._energy = e
  end

  win.onDraw = function(ax, ay, ww, wh)
    local th = theme.current
    local e = win._energy or services.getEnergy()

    render.drawText(ax + 2, ay, "POWER CONTROL CENTER", th.accent, th.panel)
    render.drawText(ax + 2, ay + 1, string.rep("─", ww - 4), th.accentDim, th.panel)

    local lines = {
      (" IN:  %6d RF/t"):format(e.input or 0),
      (" OUT: %6d RF/t"):format(e.output or 0),
      (" STO: %6d RF  "):format(e.stored or 0),
      (" LOAD:%3d%%      "):format(e.load or 0),
    }
    for i, line in ipairs(lines) do
      render.drawText(ax + 2, ay + 2 + i, line, th.textBright, th.panel)
    end

    local gx, gy, gw, gh = ax + 2, ay + 8, ww - 4, wh - 10
    gui.renderGraph(gx, gy, gw, gh, e.history or {}, { minVal = 0 })

    if (e.load or 0) > 85 then
      render.drawText(ax + 2, ay + wh - 2, "!! HIGH LOAD ALERT !!", th.warning, th.panel)
    end
  end

  win.onUpdate()
  return win
end

return {
  id = "energy",
  name = "Energy Monitor",
  icon = "PWR",
  createWindow = createWindow,
}
