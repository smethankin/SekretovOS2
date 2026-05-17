--[[
  SekretovOS — GUI Framework
  Widgets: window, panel, button, label, graph, progressBar, tabs, scroll
]]

local render = require("system.render")
local theme = require("system.theme")

local gui = {
  widgets = {},
  nextId = 1,
  notifications = {},
  focused = nil,
}

local function id()
  local i = gui.nextId
  gui.nextId = gui.nextId + 1
  return i
end

local function t()
  return theme.current
end

-- Base widget
local function widgetBase(typeName, opts)
  opts = opts or {}
  local w = {
    id = id(),
    type = typeName,
    x = opts.x or 1,
    y = opts.y or 1,
    w = opts.w or 10,
    h = opts.h or 3,
    visible = opts.visible ~= false,
    enabled = opts.enabled ~= false,
    parent = opts.parent,
    children = {},
    onClick = opts.onClick,
    onDraw = opts.onDraw,
    data = opts.data or {},
  }
  gui.widgets[w.id] = w
  if opts.parent and opts.parent.children then
    opts.parent.children[#opts.parent.children + 1] = w
  end
  return w
end

function gui.register(w)
  gui.widgets[w.id] = w
  return w
end

function gui.panel(opts)
  return widgetBase("panel", opts)
end

function gui.label(opts)
  local w = widgetBase("label", opts)
  w.text = opts.text or ""
  w.align = opts.align or "left"
  w.color = opts.color
  return w
end

function gui.button(opts)
  local w = widgetBase("button", opts)
  w.text = opts.text or "OK"
  w.pressed = false
  w.hovered = false
  return w
end

function gui.progressBar(opts)
  local w = widgetBase("progressBar", opts)
  w.value = opts.value or 0
  w.max = opts.max or 100
  w.label = opts.label
  return w
end

function gui.graph(opts)
  local w = widgetBase("graph", opts)
  w.data = opts.data or {}
  w.maxPoints = opts.maxPoints or 40
  w.minVal = opts.minVal or 0
  w.maxVal = opts.maxVal
  return w
end

function gui.tabs(opts)
  local w = widgetBase("tabs", opts)
  w.tabs = opts.tabs or {}
  w.active = opts.active or 1
  w.onTab = opts.onTab
  return w
end

function gui.scrollArea(opts)
  local w = widgetBase("scrollArea", opts)
  w.scrollY = 0
  w.contentH = opts.contentH or 10
  w.children = opts.children or {}
  return w
end

function gui.window(opts)
  local w = widgetBase("window", opts)
  w.title = opts.title or "Window"
  w.minimized = false
  w.maximized = false
  w.resizable = opts.resizable
  w.closable = opts.closable ~= false
  w.draggable = opts.draggable ~= false
  w.content = opts.content
  w.children = {}
  w.zIndex = opts.zIndex or 1
  return w
end

function gui.popup(opts)
  local w = gui.window(opts)
  w.modal = true
  w.type = "popup"
  return w
end

-- Drawing helpers
function gui.drawPanel(w, absX, absY)
  local th = t()
  render.fill(absX, absY, w.w, w.h, " ", th.panelBorder, th.panel)
  render.drawBorder(absX, absY, w.w, w.h, th.accentDim, th.panel)
end

function gui.drawLabel(w, absX, absY)
  local th = t()
  local fg = w.color or th.text
  local text = w.text:sub(1, w.w)
  local x = absX
  if w.align == "center" then
    x = absX + math.floor((w.w - #text) / 2)
  elseif w.align == "right" then
    x = absX + w.w - #text
  end
  render.drawText(x, absY, text, fg, th.panel)
end

function gui.drawButton(w, absX, absY)
  local th = t()
  local bg = w.pressed and th.buttonPress or (w.hovered and th.buttonHover or th.button)
  render.fill(absX, absY, w.w, w.h, " ", th.accent, bg)
  local text = (" %s "):format(w.text):sub(1, w.w)
  local tx = absX + math.floor((w.w - #text) / 2)
  render.drawText(tx, absY + math.floor(w.h / 2) - 1, text, th.textBright, bg)
end

function gui.drawProgressBar(w, absX, absY)
  local th = t()
  render.fill(absX, absY, w.w, w.h, " ", th.textDim, th.panelBorder)
  local pct = math.min(1, w.value / math.max(w.max, 1))
  local fillW = math.max(0, math.floor((w.w - 2) * pct))
  if fillW > 0 then
    render.fill(absX + 1, absY + 1, fillW, w.h - 2, " ", th.graphFill, th.success)
  end
  if w.label then
    local txt = ("%s %d%%"):format(w.label, math.floor(pct * 100))
    render.drawText(absX + 2, absY, txt:sub(1, w.w - 2), th.text, th.panelBorder)
  end
end

function gui.renderGraph(absX, absY, gw, gh, data, opts)
  opts = opts or {}
  local w = {
    type = "graph",
    w = gw, h = gh,
    data = data or {},
    minVal = opts.minVal or 0,
    maxVal = opts.maxVal,
  }
  gui.drawGraph(w, absX, absY)
end

function gui.drawGraph(w, absX, absY)
  local th = t()
  render.fill(absX, absY, w.w, w.h, " ", th.graphGrid, th.panel)
  local data = w.data
  if #data < 2 then return end

  local maxV = w.maxVal
  if not maxV then
    maxV = data[1]
    for i = 2, #data do
      if data[i] > maxV then maxV = data[i] end
    end
  end
  maxV = math.max(maxV, w.minVal + 1)
  local minV = w.minVal
  local range = maxV - minV
  local innerW = w.w - 2
  local innerH = w.h - 2

  for row = 1, innerH do
    local gridY = absY + row
    render.drawText(absX + 1, gridY, string.rep(string.char(0xFA), innerW), th.graphGrid, th.panel)
  end

  local step = innerW / math.max(#data - 1, 1)
  local prevX, prevY
  for i, val in ipairs(data) do
    local px = absX + 1 + math.floor((i - 1) * step)
    local norm = (val - minV) / range
    local py = absY + w.h - 1 - math.floor(norm * (innerH - 1))
    py = math.max(absY + 1, math.min(absY + w.h - 1, py))
    if prevX then
      local x0, y0 = prevX, prevY
      local x1, y1 = px, py
      local dx = math.abs(x1 - x0)
      local dy = math.abs(y1 - y0)
      local sx = x0 < x1 and 1 or -1
      local sy = y0 < y1 and 1 or -1
      local err = dx - dy
      while true do
        render.set(x0, y0, string.char(0xDB), th.graphLine, th.panel)
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then err = err - dy; x0 = x0 + sx end
        if e2 < dx then err = err + dx; y0 = y0 + sy end
      end
    end
    prevX, prevY = px, py
  end
end

function gui.drawTabs(w, absX, absY)
  local th = t()
  local tabW = math.floor(w.w / math.max(#w.tabs, 1))
  for i, tab in ipairs(w.tabs) do
    local tx = absX + (i - 1) * tabW
    local bg = (i == w.active) and th.titleActive or th.titleBar
    local fg = (i == w.active) and th.accent or th.textDim
    local label = (" %s "):format(tab):sub(1, tabW)
    render.fill(tx, absY, tabW, 1, " ", fg, bg)
    render.drawText(tx + 1, absY, label, fg, bg)
  end
  render.fill(absX, absY + 1, w.w, w.h - 1, " ", th.textDim, th.panel)
end

function gui.drawWindow(w, absX, absY)
  local th = t()
  if w.minimized then
    render.fill(absX, absY, w.w, 1, " ", th.text, th.titleBar)
    render.drawText(absX + 1, absY, (" _ %s"):format(w.title):sub(1, w.w - 2), th.accent, th.titleBar)
    return
  end

  -- Shadow
  render.fill(absX + 1, absY + 1, w.w, w.h, " ", th.shadow, th.shadow)

  render.fill(absX, absY, w.w, w.h, " ", th.panelBorder, th.panel)
  local titleBg = w.focused and th.titleActive or th.titleBar
  render.fill(absX, absY, w.w, 1, " ", th.accent, titleBg)
  local controls = w.closable and " [X]" or ""
  local title = (" %s%s"):format(w.title, controls):sub(1, w.w)
  render.drawText(absX + 1, absY, title, th.textBright, titleBg)

  local contentY = absY + 1
  local contentH = w.h - 1
  if w.onDraw then
    w.onDraw(absX, contentY, w.w, contentH)
  end
  for _, child in ipairs(w.children or {}) do
    gui.drawWidget(child, absX, contentY)
  end
end

function gui.drawWidget(w, parentX, parentY)
  if not w or not w.visible then return end
  local absX = (parentX or 0) + w.x
  local absY = (parentY or 0) + w.y

  if w.type == "panel" then gui.drawPanel(w, absX, absY)
  elseif w.type == "label" then gui.drawLabel(w, absX, absY)
  elseif w.type == "button" then gui.drawButton(w, absX, absY)
  elseif w.type == "progressBar" then gui.drawProgressBar(w, absX, absY)
  elseif w.type == "graph" then gui.drawGraph(w, absX, absY)
  elseif w.type == "tabs" then gui.drawTabs(w, absX, absY)
  elseif w.type == "window" then gui.drawWindow(w, absX, absY)
  elseif w.type == "scrollArea" then
    gui.drawPanel(w, absX, absY)
    for _, ch in ipairs(w.children) do
      gui.drawWidget(ch, absX, absY + 1 - w.scrollY)
    end
  end

  if w.onDraw and w.type ~= "window" then
    w.onDraw(absX, absY, w.w, w.h)
  end
end

function gui.notify(title, message, level)
  local th = t()
  level = level or "info"
  local fg = th.accent
  if level == "warn" then fg = th.warning
  elseif level == "error" then fg = th.error
  elseif level == "success" then fg = th.success end

  table.insert(gui.notifications, 1, {
    title = title,
    message = message,
    fg = fg,
    ttl = 5,
    time = os.clock(),
  })
  if #gui.notifications > 5 then
    table.remove(gui.notifications)
  end
end

function gui.drawNotifications(screenW)
  local th = t()
  local y = 2
  for i, n in ipairs(gui.notifications) do
    if os.clock() - n.time < n.ttl then
      local line = (" %s: %s "):format(n.title, n.message)
      local w = math.min(#line + 2, screenW - 2)
      render.fill(screenW - w, y, w, 1, " ", n.fg, th.notification)
      render.drawText(screenW - w + 1, y, line:sub(1, w - 2), n.fg, th.notification)
      y = y + 1
    else
      table.remove(gui.notifications, i)
    end
  end
end

function gui.hitTest(w, mx, my, parentX, parentY)
  if not w or not w.visible then return nil end
  local absX = (parentX or 0) + w.x
  local absY = (parentY or 0) + w.y
  local h = w.minimized and 1 or w.h

  if mx >= absX and mx < absX + w.w and my >= absY and my < absY + h then
    for i = #((w.children) or {}), 1, -1 do
      local hit = gui.hitTest(w.children[i], mx, my, absX, absY + (w.type == "window" and 1 or 0))
      if hit then return hit end
    end
    return w, absX, absY
  end
  return nil
end

function gui.handleClick(w, mx, my, absX, absY)
  if w.type == "button" and w.enabled and w.onClick then
    w.onClick(w)
    return true
  elseif w.type == "tabs" then
    local tabW = math.floor(w.w / math.max(#w.tabs, 1))
    local idx = math.floor((mx - absX) / tabW) + 1
    if idx >= 1 and idx <= #w.tabs then
      w.active = idx
      if w.onTab then w.onTab(idx, w.tabs[idx]) end
      return true
    end
  end
  return false
end

return gui
