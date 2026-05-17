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
local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function dec(data)
  data = data:gsub("[^" .. b64 .. "=]", "")
  return (data:gsub(".", function(x)
    if x == "=" then return "" end
    local r, f = "", (b64:find(x, 1, true) - 1)
    for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and "1" or "0") end
    return r
  end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
    if #x ~= 8 then return "" end
    local c = 0
    for i = 1, 8 do c = c + (x:sub(i,i) == "1" and 2^(8-i) or 0) end
    return string.char(c)
  end))
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
    "local FILES = {}",
    "for k, v in pairs(FILES_B64) do FILES[k] = dec(v) end",
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
    "  local n = 0",
    "  for path, content in pairs(FILES) do",
    "    n = n + 1",
    "    local dest = filesystem.concat(INSTALL_DIR, path)",
    "    local dir = filesystem.path(dest)",
    "    if dir and dir ~= '' then ensureDir(dir) end",
    "    local h = filesystem.open(dest, 'w')",
    "    if not h then log('FAIL: ' .. path) return false end",
    "    h:write(content)",
    "    h:close()",
    "    log(('  [%d] %s'):format(n, path))",
    "  end",
    "  log('Done. Starting SekretovOS...')",
    "  if RUN_AFTER then shell.execute(INSTALL_DIR .. '/main') end",
    "end",
    "install()",
])

with open(OUT, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(lines) + "\n")

print(f"Built {OUT} ({os.path.getsize(OUT) // 1024} KB)")
