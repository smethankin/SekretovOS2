--[[
  SekretovOS — One-command installer (OpenComputers)

  On computer with Internet Card:
    pastebin get <INSTALL_CODE> install
    install

  Or in one line:
    pastebin get <INSTALL_CODE> install && install
]]

local filesystem = require("filesystem")
local shell = require("shell")
local computer = require("computer")

-- ============================================================
-- Pastebin codes — replace after you upload files to pastebin.com
-- Format: path relative to /SekretovOS/
-- ============================================================
local MANIFEST = {
  { path = "main.lua",              code = "PASTE_MAIN" },
  { path = "system/kernel.lua",     code = "PASTE_KERNEL" },
  { path = "system/render.lua",     code = "PASTE_RENDER" },
  { path = "system/gui.lua",        code = "PASTE_GUI" },
  { path = "system/window.lua",     code = "PASTE_WINDOW" },
  { path = "system/desktop.lua",    code = "PASTE_DESKTOP" },
  { path = "system/events.lua",     code = "PASTE_EVENTS" },
  { path = "system/theme.lua",      code = "PASTE_THEME" },
  { path = "system/services.lua",   code = "PASTE_SERVICES" },
  { path = "apps/energy.lua",       code = "PASTE_ENERGY" },
  { path = "apps/ae2.lua",          code = "PASTE_AE2" },
  { path = "apps/reactor.lua",      code = "PASTE_REACTOR" },
  { path = "apps/logs.lua",         code = "PASTE_LOGS" },
  { path = "apps/settings.lua",    code = "PASTE_SETTINGS" },
  { path = "apps/files.lua",        code = "PASTE_FILES" },
  { path = "apps/terminal.lua",     code = "PASTE_TERMINAL" },
  { path = "config/settings.cfg",   code = "PASTE_CONFIG" },
}

local INSTALL_DIR = "/SekretovOS"
local RUN_AFTER = true

local function log(msg)
  print("[SekretovOS] " .. tostring(msg))
end

local function ensureDir(path)
  if not filesystem.exists(path) then
    filesystem.makeDirectory(path)
  end
end

local function download(code, dest)
  local dir = filesystem.path(dest)
  if dir and dir ~= "" then
    ensureDir(dir)
  end
  local ok, err = shell.execute("pastebin", "get", code, dest)
  if not ok then
    return false, err or "pastebin get failed"
  end
  if not filesystem.exists(dest) then
    return false, "file not created: " .. dest
  end
  return true
end

local function install()
  log("Installing to " .. INSTALL_DIR .. " ...")
  ensureDir(INSTALL_DIR)
  ensureDir(INSTALL_DIR .. "/system")
  ensureDir(INSTALL_DIR .. "/apps")
  ensureDir(INSTALL_DIR .. "/config")
  ensureDir(INSTALL_DIR .. "/logs")
  ensureDir(INSTALL_DIR .. "/temp")

  local failed = 0
  for i, entry in ipairs(MANIFEST) do
    local dest = filesystem.concat(INSTALL_DIR, entry.path)
    if entry.code:match("^PASTE_") then
      log("SKIP (not configured): " .. entry.path)
      failed = failed + 1
    else
      io.write(string.format("  [%d/%d] %s ... ", i, #MANIFEST, entry.path))
      local ok, err = download(entry.code, dest)
      if ok then
        print("OK")
      else
        print("FAIL")
        log("  Error: " .. tostring(err))
        failed = failed + 1
      end
    end
  end

  if failed > 0 then
    log("Done with " .. failed .. " error(s). Edit install.lua MANIFEST codes.")
    return false
  end

  log("Install complete.")
  if RUN_AFTER then
    log("Starting SekretovOS...")
    shell.execute(INSTALL_DIR .. "/main")
  else
    log("Run: " .. INSTALL_DIR .. "/main")
  end
  return true
end

install()
