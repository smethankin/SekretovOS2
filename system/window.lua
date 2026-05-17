--[[
  SekretovOS — Window Manager
  Focus, z-index, drag, minimize, close
]]

local gui = require("system.gui")
local render = require("system.render")
local events = require("system.events")

local wm = {
  windows = {},
  active = nil,
  dragging = nil,
  dragOffsetX = 0,
  dragOffsetY = 0,
  nextZ = 10,
}

function wm.add(win)
  win.zIndex = wm.nextZ
  wm.nextZ = wm.nextZ + 1
  win.focused = true
  wm.windows[#wm.windows + 1] = win
  wm.focus(win)
  return win
end

function wm.remove(win)
  for i, w in ipairs(wm.windows) do
    if w.id == win.id then
      table.remove(wm.windows, i)
      break
    end
  end
  if wm.active == win then
    wm.active = wm.windows[#wm.windows]
    if wm.active then wm.active.focused = true end
  end
end

function wm.focus(win)
  for _, w in ipairs(wm.windows) do
    w.focused = (w.id == win.id)
  end
  win.zIndex = wm.nextZ
  wm.nextZ = wm.nextZ + 1
  wm.active = win
  -- Re-sort by zIndex
  table.sort(wm.windows, function(a, b) return a.zIndex < b.zIndex end)
end

function wm.getAt(mx, my)
  for i = #wm.windows, 1, -1 do
    local w = wm.windows[i]
    if w.visible ~= false then
      local hit, ax, ay = gui.hitTest(w, mx, my, w.x, w.y)
      if hit then
        return w, hit, ax, ay
      end
      if mx >= w.x and mx < w.x + w.w and my >= w.y and my < w.y + (w.minimized and 1 or w.h) then
        return w, w, w.x, w.y
      end
    end
  end
  return nil
end

function wm.titleBarHit(win, mx, my)
  return my == win.y and mx >= win.x and mx < win.x + win.w
end

function wm.closeButtonHit(win, mx, my)
  if not win.closable then return false end
  return my == win.y and mx >= win.x + win.w - 4 and mx < win.x + win.w
end

function wm.handleEvent(evt)
  if not evt.x then return false end
  local mx, my = evt.x, evt.y

  if evt.type == "mouse_down" or evt.type == "touch" then
    local win, hit, ax, ay = wm.getAt(mx, my)
    if win then
      wm.focus(win)
      if wm.closeButtonHit(win, mx, my) then
        if win.onClose then win.onClose(win) end
        wm.remove(win)
        return true
      end
      if wm.titleBarHit(win, mx, my) and win.draggable then
        wm.dragging = win
        wm.dragOffsetX = mx - win.x
        wm.dragOffsetY = my - win.y
        return true
      end
      if hit and hit.type == "button" then
        hit.pressed = true
        return true
      end
      if hit then
        return gui.handleClick(hit, mx, my, ax, ay)
      end
    end
    return false

  elseif evt.type == "mouse_drag" or evt.type == "drag" then
    if wm.dragging then
      wm.dragging.x = math.max(1, mx - wm.dragOffsetX)
      wm.dragging.y = math.max(2, my - wm.dragOffsetY)
      return true
    end

  elseif evt.type == "mouse_up" or evt.type == "drop" then
    if wm.dragging then
      wm.dragging = nil
      return true
    end
    local win, hit = wm.getAt(mx, my)
    if hit and hit.type == "button" and hit.pressed then
      hit.pressed = false
      if hit.onClick then hit.onClick(hit) end
      return true
    end
    for _, w in ipairs(wm.windows) do
      for _, ch in ipairs(w.children or {}) do
        if ch.type == "button" then ch.pressed = false end
      end
    end

  elseif evt.type == "scroll" then
    local win = wm.getAt(mx, my)
    if win and win.onScroll then
      win.onScroll(evt.delta, mx, my)
      return true
    end

  elseif evt.type == "key_down" or evt.type == "key_up" then
    if wm.active and wm.active.onEvent then
      return wm.active.onEvent(evt) == true
    end
  end
  return false
end

function wm.draw()
  for _, w in ipairs(wm.windows) do
    if w.visible ~= false then
      gui.drawWidget(w, 0, 0)
    end
  end
end

function wm.minimize(win)
  win.minimized = true
end

function wm.restore(win)
  win.minimized = false
end

function wm.count()
  return #wm.windows
end

return wm
