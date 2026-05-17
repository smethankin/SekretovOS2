--[[
  SekretovOS — Theme System
  Industrial / Cyberpunk / Retro palettes
]]

local theme = {
  name = "industrial",
  current = nil,
}

local palettes = {
  industrial = {
    background   = 0x0A0E14,
    panel        = 0x121820,
    panelBorder  = 0x1E2A38,
    accent       = 0x00D4AA,
    accentDim    = 0x008866,
    accentBlue   = 0x00A8E8,
    text         = 0xC8D4E0,
    textDim      = 0x607080,
    textBright   = 0xE8F4FF,
    warning      = 0xFFB020,
    success      = 0x20E080,
    error        = 0xFF4060,
    titleBar     = 0x0E1620,
    titleActive  = 0x142030,
    graphLine    = 0x00D4AA,
    graphFill    = 0x004433,
    graphGrid    = 0x1A2430,
    shadow       = 0x060810,
    button       = 0x1A2838,
    buttonHover  = 0x243848,
    buttonPress  = 0x0E1824,
    scrollbar    = 0x2A3848,
    notification = 0x142028,
  },
  cyberpunk = {
    background   = 0x0C0014,
    panel        = 0x180028,
    panelBorder  = 0x400060,
    accent       = 0xFF00FF,
    accentDim    = 0x880088,
    accentBlue   = 0x00FFFF,
    text         = 0xE0C0FF,
    textDim      = 0x8060A0,
    textBright   = 0xFFFFFF,
    warning      = 0xFFFF00,
    success      = 0x00FF88,
    error        = 0xFF0044,
    titleBar     = 0x140020,
    titleActive  = 0x280040,
    graphLine    = 0xFF00FF,
    graphFill    = 0x440044,
    graphGrid    = 0x200030,
    shadow       = 0x080010,
    button       = 0x280040,
    buttonHover  = 0x380060,
    buttonPress  = 0x180028,
    scrollbar    = 0x400060,
    notification = 0x200030,
  },
  retro = {
    background   = 0x001100,
    panel        = 0x002200,
    panelBorder  = 0x004400,
    accent       = 0x00FF00,
    accentDim    = 0x008800,
    accentBlue   = 0x88FF88,
    text         = 0x00CC00,
    textDim      = 0x006600,
    textBright   = 0x00FF44,
    warning      = 0xCCCC00,
    success      = 0x00FF00,
    error        = 0xFF0000,
    titleBar     = 0x001800,
    titleActive  = 0x002800,
    graphLine    = 0x00FF00,
    graphFill    = 0x003300,
    graphGrid    = 0x002200,
    shadow       = 0x000800,
    button       = 0x003300,
    buttonHover  = 0x004400,
    buttonPress  = 0x002200,
    scrollbar    = 0x006600,
    notification = 0x001800,
  },
}

function theme.get(name)
  return palettes[name or theme.name] or palettes.industrial
end

function theme.apply(name)
  theme.name = name or "industrial"
  theme.current = theme.get(theme.name)
  return theme.current
end

function theme.list()
  local names = {}
  for k in pairs(palettes) do
    names[#names + 1] = k
  end
  table.sort(names)
  return names
end

-- Initialize default
theme.apply("industrial")

return theme
