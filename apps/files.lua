--[[ File Manager — filesystem browser ]]

local _OS = _OS
local gui, services, render, theme = _OS.gui, _OS.services, _OS.render, _OS.theme
local filesystem = require("filesystem")

local function createWindow()
  local win = gui.window({
    title = "FILE MANAGER",
    x = 5, y = 4,
    w = math.min(50, render.width - 4),
    h = math.min(18, render.height - 4),
    closable = true,
    draggable = true,
  })

  win.cwd = _OS.basePath or "/"
  win.entries = {}
  win.sel = 1
  win.scroll = 0

  local function refresh()
    win.entries = { ".." }
    local list = filesystem.list(win.cwd) or {}
    table.sort(list)
    for _, e in ipairs(list) do
      win.entries[#win.entries + 1] = e
    end
  end

  refresh()

  win.onDraw = function(ax, ay, ww, wh)
    local th = theme.current
    render.drawText(ax + 2, ay, win.cwd:sub(1, ww - 4), th.accent, th.panel)
    local visible = wh - 3
    local start = win.scroll + 1
    local y = ay + 2
    for i = start, math.min(#win.entries, start + visible - 1) do
      local e = win.entries[i]
      local prefix = filesystem.isDirectory(filesystem.concat(win.cwd, e)) and "/" or " "
      local mark = (i == win.sel) and ">" or " "
      local fg = (i == win.sel) and th.textBright or th.text
      render.drawText(ax + 2, y, (mark .. prefix .. " " .. e):sub(1, ww - 4), fg, th.panel)
      y = y + 1
    end
    render.drawText(ax + 2, ay + wh - 1, "[Enter] open  [Bksp] up", th.textDim, th.panel)
  end

  win.onEvent = function(evt)
    if evt.type == "key_down" then
      if evt.char == "w" or evt.code == 200 then
        win.sel = math.max(1, win.sel - 1)
        if win.sel < win.scroll + 1 then win.scroll = win.sel - 1 end
        return true
      elseif evt.char == "s" or evt.code == 208 then
        win.sel = math.min(#win.entries, win.sel + 1)
        local visible = win.h - 3
        if win.sel > win.scroll + visible then
          win.scroll = win.sel - visible
        end
        return true
      elseif evt.char == "\r" or evt.char == "\n" then
        local e = win.entries[win.sel]
        if e == ".." then
          win.cwd = filesystem.path(win.cwd) or "/"
        else
          local path = filesystem.concat(win.cwd, e)
          if filesystem.isDirectory(path) then
            win.cwd = path
          end
        end
        win.sel = 1
        win.scroll = 0
        refresh()
        return true
      end
    elseif evt.type == "scroll" then
      win.scroll = math.max(0, win.scroll - evt.delta)
      return true
    end
    return false
  end

  return win
end

return {
  id = "files",
  name = "File Manager",
  icon = "FS",
  createWindow = createWindow,
}
