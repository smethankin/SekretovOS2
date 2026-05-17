--[[ Reactor Control — safety & emergency systems ]]

local _OS = _OS
local gui, services, render, theme = _OS.gui, _OS.services, _OS.render, _OS.theme

local function createWindow()
  local w, h = render.width, render.height
  local win = gui.window({
    title = "REACTOR CONTROL",
    x = 8, y = 5,
    w = math.min(44, w - 4),
    h = math.min(17, h - 4),
    closable = true,
    draggable = true,
  })

  win.buttons = {}

  win.onUpdate = function()
    win._r = services.getReactor()
  end

  win.onDraw = function(ax, ay, ww, wh)
    local th = theme.current
    local r = win._r or services.getReactor()

    local state = r.active and "ACTIVE" or "STANDBY"
    local stateFg = r.active and th.success or th.textDim
    render.drawText(ax + 2, ay, (" STATE: %s "):format(state), stateFg, th.panel)
    render.drawText(ax + 2, ay + 2,
      (" TEMP: %4d C   OUTPUT: %d RF/t"):format(r.temp, r.output),
      r.safe and th.textBright or th.error, th.panel)

    local tempPct = math.min(100, math.floor(r.temp / 12))
    render.fill(ax + 2, ay + 4, ww - 4, 1, " ", th.textDim, th.panelBorder)
    local fill = math.floor((ww - 4) * tempPct / 100)
    local tempCol = r.temp > 900 and th.error or (r.temp > 600 and th.warning or th.success)
    if fill > 0 then
      render.fill(ax + 2, ay + 4, fill, 1, " ", th.graphFill, tempCol)
    end

    local safety = r.safe and "SAFETY: OK" or "SAFETY: CRITICAL"
    render.drawText(ax + 2, ay + 6, safety, r.safe and th.success or th.error, th.panel)

    render.drawText(ax + 2, ay + 9, "[S] START  [X] EMERGENCY STOP", th.accent, th.panel)
  end

  win.onEvent = function(evt)
    if evt.type == "key_down" then
      if evt.char == "x" or evt.char == "X" then
        services.reactorShutdown()
        gui.notify("Reactor", "Emergency shutdown", "error")
        return true
      elseif evt.char == "s" or evt.char == "S" then
        services.reactorStart()
        gui.notify("Reactor", "Startup initiated", "success")
        return true
      end
    end
  end

  local oldUpdate = win.onUpdate
  win.onUpdate = function(dt)
    oldUpdate()
    -- forward key events via desktop; store handler on window
  end

  win.onUpdate()
  return win
end

return {
  id = "reactor",
  name = "Reactor Control",
  icon = "RCT",
  createWindow = createWindow,
}
