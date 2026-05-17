--[[ AE2 Monitor — storage & crafting network ]]

local _OS = _OS
local gui, services, render, theme = _OS.gui, _OS.services, _OS.render, _OS.theme

local function createWindow()
  local w, h = render.width, render.height
  local win = gui.window({
    title = "AE2 NETWORK",
    x = 6, y = 3,
    w = math.min(48, w - 4),
    h = math.min(16, h - 4),
    closable = true,
    draggable = true,
  })

  win.onUpdate = function()
    win._ae = services.getAE2()
  end

  win.onDraw = function(ax, ay, ww, wh)
    local th = theme.current
    local a = win._ae or services.getAE2()
    local pct = math.floor((a.used / math.max(a.total, 1)) * 100)

    render.drawText(ax + 2, ay, "APPLIED ENERGISTICS 2", th.accentBlue, th.panel)
    render.drawText(ax + 2, ay + 2,
      (" Storage: %d / %d (%d%%)"):format(a.used, a.total, pct),
      th.textBright, th.panel)
    render.drawText(ax + 2, ay + 4,
      (" Channels: %d    CPUs: %d"):format(a.channels, a.cpus),
      th.text, th.panel)
    render.drawText(ax + 2, ay + 5,
      (" Crafting queue: %d jobs"):format(a.crafting),
      th.text, th.panel)

    local barW = ww - 6
    local fill = math.floor(barW * a.used / math.max(a.total, 1))
    render.fill(ax + 2, ay + 7, barW, 2, " ", th.textDim, th.panelBorder)
    if fill > 0 then
      render.fill(ax + 2, ay + 7, fill, 2, " ", th.graphFill, th.accentBlue)
    end

    local status = pct > 90 and "NETWORK STRESSED" or "NETWORK STABLE"
    local fg = pct > 90 and th.warning or th.success
    render.drawText(ax + 2, ay + 10, status, fg, th.panel)

    render.drawText(ax + 2, ay + wh - 3,
      "ME Controller: ONLINE", th.success, th.panel)
  end

  win.onUpdate()
  return win
end

return {
  id = "ae2",
  name = "AE2 Monitor",
  icon = "AE2",
  createWindow = createWindow,
}
