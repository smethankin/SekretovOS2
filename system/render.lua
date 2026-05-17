--[[
  SekretovOS — Render System
  Double-buffered, dirty-region optimized GPU rendering
]]

local component = require("component")
local computer = require("computer")

local render = {
  width = 80,
  height = 25,
  buffer = nil,
  backBuffer = nil,
  dirty = {},
  gpu = nil,
  screen = nil,
  enabled = true,
  stats = { flushes = 0, cellsDrawn = 0, fullRedraws = 0 },
}

local function idx(x, y)
  return y * render.width + x + 1
end

local function packCell(bg, fg, ch)
  return string.char(
    bit32.band(bg, 0xFF), bit32.rshift(bg, 8),
    bit32.band(fg, 0xFF), bit32.rshift(fg, 8),
    ch and string.byte(ch) or 32
  )
end

local function unpackCell(packed)
  local b1, b2, f1, f2, ch = string.byte(packed, 1, 5)
  return bit32.bor(b1, bit32.lshift(b2, 8)),
         bit32.bor(f1, bit32.lshift(f2, 8)),
         string.char(ch)
end

function render.init()
  render.gpu = component.gpu
  render.screen = component.screen
  if render.gpu and render.screen then
    local ok, w, h = pcall(function()
      render.gpu.bind(render.screen.address)
      return render.gpu.getResolution()
    end)
    if ok and w then
      render.width, render.height = w, h
    end
  end
  local size = render.width * render.height
  render.buffer = {}
  render.backBuffer = {}
  for i = 1, size do
    render.buffer[i] = packCell(0x000000, 0xFFFFFF, " ")
    render.backBuffer[i] = render.buffer[i]
  end
  render.dirty = {}
  return render.width, render.height
end

function render.resize(w, h)
  if w and h then
    render.width, render.height = w, h
    render.init()
  end
end

function render.markDirty(x, y, w, h)
  w = w or 1
  h = h or 1
  render.dirty[#render.dirty + 1] = {
    x = math.max(1, x),
    y = math.max(1, y),
    w = math.min(w, render.width - x + 1),
    h = math.min(h, render.height - y + 1),
  }
end

function render.markAllDirty()
  render.markDirty(1, 1, render.width, render.height)
  render.stats.fullRedraws = render.stats.fullRedraws + 1
end

function render.set(x, y, ch, fg, bg)
  if x < 1 or y < 1 or x > render.width or y > render.height then
    return false
  end
  local i = idx(x, y)
  local packed = packCell(bg or 0x000000, fg or 0xFFFFFF, ch or " ")
  if render.buffer[i] ~= packed then
    render.buffer[i] = packed
    render.markDirty(x, y, 1, 1)
  end
  return true
end

function render.get(x, y)
  if x < 1 or y < 1 or x > render.width or y > render.height then
    return " ", 0xFFFFFF, 0x000000
  end
  return unpackCell(render.buffer[idx(x, y)])
end

function render.fill(x, y, w, h, ch, fg, bg)
  ch = ch or " "
  for dy = 0, h - 1 do
    for dx = 0, w - 1 do
      render.set(x + dx, y + dy, ch, fg, bg)
    end
  end
end

function render.drawText(x, y, text, fg, bg)
  for i = 1, #text do
    render.set(x + i - 1, y, text:sub(i, i), fg, bg)
  end
end

function render.drawBox(x, y, w, h, fg, bg, ch)
  ch = ch or " "
  render.fill(x, y, w, h, ch, fg, bg)
end

function render.drawBorder(x, y, w, h, fg, bg)
  if w < 2 or h < 2 then return end
  local hCh, vCh = string.char(0xCD), string.char(0xBA)
  for dx = 0, w - 1 do
    render.set(x + dx, y, hCh, fg, bg)
    render.set(x + dx, y + h - 1, hCh, fg, bg)
  end
  for dy = 1, h - 2 do
    render.set(x, y + dy, vCh, fg, bg)
    render.set(x + w - 1, y + dy, vCh, fg, bg)
  end
end

function render.beginFrame()
  -- Merge overlapping dirty rects (simple: keep list, flush merges at draw)
end

function render.flush()
  if not render.enabled or not render.gpu then
    return 0
  end

  local drawn = 0
  render.stats.flushes = render.stats.flushes + 1

  if #render.dirty == 0 then
    return 0
  end

  -- Batch by row for fewer gpu.setBackground/Foreground switches
  for _, rect in ipairs(render.dirty) do
    for dy = 0, rect.h - 1 do
      local row = rect.y + dy
      local lastBg, lastFg
      for dx = 0, rect.w - 1 do
        local col = rect.x + dx
        local i = idx(col, row)
        local packed = render.buffer[i]
        if render.backBuffer[i] ~= packed then
          local bg, fg, ch = unpackCell(packed)
          if bg ~= lastBg then
            render.gpu.setBackground(bg)
            lastBg = bg
          end
          if fg ~= lastFg then
            render.gpu.setForeground(fg)
            lastFg = fg
          end
          render.gpu.set(col, row, ch)
          render.backBuffer[i] = packed
          drawn = drawn + 1
        end
      end
    end
  end

  render.dirty = {}
  render.stats.cellsDrawn = render.stats.cellsDrawn + drawn
  return drawn
end

function render.present()
  render.beginFrame()
  return render.flush()
end

function render.clear(bg, fg)
  bg = bg or 0x000000
  fg = fg or 0xFFFFFF
  local packed = packCell(bg, fg, " ")
  local size = render.width * render.height
  for i = 1, size do
    render.buffer[i] = packed
  end
  render.markAllDirty()
end

function render.copyToGpu()
  render.markAllDirty()
  return render.flush()
end

return render
