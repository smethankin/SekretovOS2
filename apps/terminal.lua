--[[ Terminal — shell-like interface ]]

local _OS = _OS
local gui, services, render, theme = _OS.gui, _OS.services, _OS.render, _OS.theme
local computer = require("computer")

local function createWindow()
  local win = gui.window({
    title = "TERMINAL",
    x = 7, y = 5,
    w = math.min(54, render.width - 6),
    h = math.min(14, render.height - 6),
    closable = true,
    draggable = true,
  })

  win.lines = { "SekretovOS Terminal v1.0", "Type 'help' for commands." }
  win.input = ""
  win.scroll = 0
  win.maxLines = 100

  local commands = {
    help = function()
      return "Commands: help, clear, echo, uptime, ver, date"
    end,
    clear = function()
      win.lines = {}
      return nil
    end,
    echo = function(args)
      return table.concat(args, " ")
    end,
    uptime = function()
      return ("Uptime: %.1fs"):format(computer.uptime())
    end,
    ver = function()
      return "SekretovOS 1.0.0 Industrial Edition"
    end,
    date = function()
      return os.date("%Y-%m-%d %H:%M:%S")
    end,
  }

  local function exec(line)
    local parts = {}
    for word in line:gmatch("%S+") do parts[#parts + 1] = word end
    if #parts == 0 then return end
    local cmd = parts[1]:lower()
    table.remove(parts, 1)
    local fn = commands[cmd]
    if fn then
      local result = fn(parts)
      if result then win.lines[#win.lines + 1] = result end
    else
      win.lines[#win.lines + 1] = "Unknown command: " .. cmd
    end
  end

  win.onDraw = function(ax, ay, ww, wh)
    local th = theme.current
    local visible = wh - 3
    local start = math.max(1, #win.lines - visible - win.scroll + 1)
    local y = ay
    for i = start, #win.lines do
      if y >= ay + wh - 3 then break end
      render.drawText(ax + 2, y, win.lines[i]:sub(1, ww - 4), th.text, th.panel)
      y = y + 1
    end
    local prompt = "> " .. win.input
    render.drawText(ax + 2, ay + wh - 2, prompt:sub(1, ww - 4), th.accent, th.panel)
  end

  win.onEvent = function(evt)
    if evt.type ~= "key_down" then return false end
    local c = evt.char
    if c == "\r" or c == "\n" then
      win.lines[#win.lines + 1] = "> " .. win.input
      exec(win.input)
      win.input = ""
      if #win.lines > win.maxLines then
        table.remove(win.lines, 1)
      end
      return true
    elseif c == "\b" then
      win.input = win.input:sub(1, -2)
      return true
    elseif c and #c == 1 and c >= " " then
      if #win.input < 60 then
        win.input = win.input .. c
      end
      return true
    end
    return false
  end

  return win
end

return {
  id = "terminal",
  name = "Terminal",
  icon = "TERM",
  createWindow = createWindow,
}
