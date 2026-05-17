#!/usr/bin/env python3
"""Build single-file SekretovOS installer with base64-encoded sources."""
import base64
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "sekretov-install.lua")

FILES = [
    "main.lua",
    "system/kernel.lua", "system/render.lua", "system/gui.lua",
    "system/window.lua", "system/desktop.lua", "system/events.lua",
    "system/theme.lua", "system/services.lua",
    "apps/energy.lua", "apps/ae2.lua", "apps/reactor.lua",
    "apps/logs.lua", "apps/settings.lua", "apps/files.lua", "apps/terminal.lua",
    "config/settings.cfg",
]

DECODER = r'''
local computer = require("computer")
local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local yieldEvery = 128
local yieldTick = 0

local function yieldStep()
  yieldTick = yieldTick + 1
  if yieldTick >= yieldEvery then
    yieldTick = 0
    os.sleep(0)
  end
end

local function dec(data)
  data = data:gsub("[^" .. b64 .. "=]", "")
  local out, batch = {}, {}
  local len, pos = #data, 1
  while pos <= len do
    yieldStep()
    local c1, c2, c3, c4 = data:byte(pos, pos + 3)
    pos = pos + 4
    if not c1 then break end
    c2, c3, c4 = c2 or 0, c3 or 0, c4 or 0
    local n1 = (b64:find(string.char(c1), 1, true) or 1) - 1
    local n2 = c2 > 0 and ((b64:find(string.char(c2), 1, true) or 1) - 1) or 0
    local n3 = c3 > 0 and ((b64:find(string.char(c3), 1, true) or 1) - 1) or 0
    local n4 = c4 > 0 and ((b64:find(string.char(c4), 1, true) or 1) - 1) or 0
    local n = n1 * 262144 + n2 * 4096 + n3 * 64 + n4
    batch[#batch + 1] = string.char(math.floor(n / 65536) % 256)
    if c3 > 0 or (c4 == 0 and c2 > 0) then
      batch[#batch + 1] = string.char(math.floor(n / 256) % 256)
    end
    if c4 > 0 then
      batch[#batch + 1] = string.char(n % 256)
    end
    if #batch >= 512 then
      out[#out + 1] = table.concat(batch)
      batch = {}
      os.sleep(0)
    end
  end
  if #batch > 0 then out[#out + 1] = table.concat(batch) end
  return table.concat(out)
end
'''

lines = [
    "-- SekretovOS single-paste installer (base64)",
    "local INSTALL_DIR = '/SekretovOS'",
    "local RUN_AFTER = true",
    "local filesystem = require('filesystem')",
    "local shell = require('shell')",
    DECODER.strip(),
    "local FILES_B64 = {",
]

for rel in FILES:
    path = os.path.join(ROOT, rel.replace("/", os.sep))
    with open(path, "rb") as f:
        enc = base64.b64encode(f.read()).decode("ascii")
    lines.append(f'  ["{rel}"] = "{enc}",')

lines.extend([
    "}",
    "local ORDER = {",
])
for rel in FILES:
    lines.append(f'  "{rel}",')
lines.extend([
    "}",
    "local function log(m) print('[SekretovOS] ' .. tostring(m)) end",
    "local function ensureDir(p)",
    "  if not filesystem.exists(p) then filesystem.makeDirectory(p) end",
    "end",
    "local function install()",
    "  log('Installing to ' .. INSTALL_DIR .. ' ...')",
    "  ensureDir(INSTALL_DIR)",
    "  ensureDir(INSTALL_DIR .. '/system')",
    "  ensureDir(INSTALL_DIR .. '/apps')",
    "  ensureDir(INSTALL_DIR .. '/config')",
    "  ensureDir(INSTALL_DIR .. '/logs')",
    "  ensureDir(INSTALL_DIR .. '/temp')",
    "  local n = #ORDER",
    "  for i, path in ipairs(ORDER) do",
    "    local b64data = FILES_B64[path]",
    "    if not b64data then log('Missing: ' .. path) return false end",
    "  log(('  [%d/%d] %s'):format(i, n, path))",
    "    os.sleep(0)",
    "    local content = dec(b64data)",
    "    os.sleep(0)",
    "    local dest = filesystem.concat(INSTALL_DIR, path)",
    "    local dir = filesystem.path(dest)",
    "    if dir and dir ~= '' then ensureDir(dir) end",
    "    local h = filesystem.open(dest, 'w')",
    "    if not h then log('FAIL write: ' .. path) return false end",
    "    h:write(content)",
    "    h:close()",
    "    content = nil",
    "    b64data = nil",
    "    os.sleep(0)",
    "    collectgarbage('collect')",
    "  end",
    "  log('Install complete.')",
    "  if RUN_AFTER then",
    "    log('Run: ' .. INSTALL_DIR .. '/main')",
    "    os.sleep(0.2)",
    "  end",
    "end",
    "install()",
])

with open(OUT, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(lines) + "\n")

print(f"Built {OUT} ({os.path.getsize(OUT) // 1024} KB)")
