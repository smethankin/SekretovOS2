--[[ Logs Viewer — system & alert logs ]]

local _OS = _OS
local gui, services, render, theme = _OS.gui, _OS.services, _OS.render, _OS.theme

local function createWindow()
  local w, h = render.width, render.height
  local win = gui.window({
    title = "SYSTEM LOGS",
    x = 3, y = 3,
    w = math.min(60, w - 2),
    h = math.min(20, h - 3),
    closable = true,
    draggable = true,
  })

  win.filter = ""
  win.scroll = 0

  win.onDraw = function(ax, ay, ww, wh)
    local th = theme.current
    render.drawText(ax + 2, ay, (" Filter: %s [type to filter]"):format(
      win.filter == "" and "*" or win.filter), th.textDim, th.panel)

    local logs = services.getLogs(win.filter)
    local start = math.max(1, #logs - (wh - 4) - win.scroll + 1)
    local y = ay + 2
    for i = start, #logs do
      if y >= ay + wh - 1 then break end
      local e = logs[i]
      local fg = th.text
      if e.level == "WARN" then fg = th.warning
      elseif e.level == "ERROR" or e.level == "ALERT" then fg = th.error
      elseif e.level == "INFO" then fg = th.accent end
      local line = ("[%s] %s"):format(e.level:sub(1, 4), e.message):sub(1, ww - 4)
      render.drawText(ax + 2, y, line, fg, th.panel)
      y = y + 1
    end
  end

  win.onEvent = function(evt)
    if evt.type == "key_down" and evt.char and #evt.char == 1 then
      if evt.char == "\b" then
        win.filter = win.filter:sub(1, -2)
      elseif evt.char == "\27" then
        win.filter = ""
      elseif evt.char >= " " then
        win.filter = win.filter .. evt.char
      end
      return true
    elseif evt.type == "scroll" then
      win.scroll = math.max(0, win.scroll - evt.delta)
      return true
    end
  end

  return win
end

return {
  id = "logs",
  name = "Logs Viewer",
  icon = "LOG",
  createWindow = createWindow,
}
