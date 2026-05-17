--[[
  SekretovOS — Event System
  Unified mouse, keyboard, touch, scroll handling
]]

local event = require("event")

local events = {
  listeners = {},
  queue = {},
  drag = { active = false, button = 0, startX = 0, startY = 0, x = 0, y = 0 },
  lastMouse = { x = 1, y = 1 },
}

local function normalize(name, ...)
  local args = { ... }
  if name == "interrupted" then
    return { type = "interrupt" }
  elseif name == "touch" then
    return {
      type = "mouse_down",
      x = args[2], y = args[3],
      button = 1,
      source = "touch",
    }
  elseif name == "drag" or name == "drop" then
    return {
      type = name == "drag" and "mouse_drag" or "mouse_up",
      x = args[2], y = args[3],
      button = 1,
      source = "touch",
    }
  elseif name == "scroll" then
    return {
      type = "scroll",
      x = args[2], y = args[3],
      direction = args[4],
      delta = (args[4] or 0) > 0 and 1 or -1,
    }
  elseif name == "key_down" then
    return {
      type = "key_down",
      char = args[2],
      code = args[4],
    }
  elseif name == "key_up" then
    return {
      type = "key_up",
      char = args[2],
      code = args[4],
    }
  elseif name == "clipboard" then
    return { type = "clipboard", text = args[2] }
  end
  return { type = name, raw = args }
end

function events.listen(id, handler, filter)
  events.listeners[id] = { handler = handler, filter = filter }
end

function events.unlisten(id)
  events.listeners[id] = nil
end

function events.emit(evt)
  for id, entry in pairs(events.listeners) do
    if entry.handler then
      if not entry.filter or entry.filter(evt) then
        local ok, err = pcall(entry.handler, evt)
        if not ok then
          return false, id, err
        end
      end
    end
  end
  return true
end

function events.updateDrag(evt)
  if evt.type == "mouse_down" or evt.type == "touch" then
    events.drag.active = true
    events.drag.button = evt.button or 1
    events.drag.startX = evt.x
    events.drag.startY = evt.y
    events.drag.x = evt.x
    events.drag.y = evt.y
    evt.isDragStart = true
  elseif evt.type == "mouse_drag" or evt.type == "drag" then
    events.drag.x = evt.x
    events.drag.y = evt.y
    evt.dragDeltaX = evt.x - events.lastMouse.x
    evt.dragDeltaY = evt.y - events.lastMouse.y
    evt.dragStartX = events.drag.startX
    evt.dragStartY = events.drag.startY
  elseif evt.type == "mouse_up" or evt.type == "drop" then
    events.drag.active = false
    evt.isDragEnd = true
  end
  if evt.x and evt.y then
    events.lastMouse.x = evt.x
    events.lastMouse.y = evt.y
  end
end

function events.pull(timeout)
  local name, a, b, c, d, e = event.pull(timeout)
  if not name then return nil end
  local evt = normalize(name, a, b, c, d, e)
  events.updateDrag(evt)
  return evt
end

function events.pump()
  while true do
    local name, a, b, c, d, e = event.pull(0)
    if not name then break end
    local evt = normalize(name, a, b, c, d, e)
    events.updateDrag(evt)
    events.emit(evt)
  end
end

function events.mousePosition()
  return events.lastMouse.x, events.lastMouse.y
end

return events
