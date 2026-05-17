--[[
  Pastebin 403 workaround for OpenComputers.
  Usage (in OC terminal):
    edit oc-download.lua   -- paste this file, save
    oc-download yVh06yQL sekretov
    sekretov
]]

local args = {...}
local code = args[1] or "yVh06yQL"
local out = args[2] or "sekretov"

local internet = require("internet")
local urls = {
  "https://pastebin.com/dl/" .. code,
  "https://pastebin.com/raw/" .. code,
}

local headers = {
  ["User-Agent"] = "Mozilla/5.0 (compatible; OpenComputers/1.0)",
  ["Accept"] = "text/plain,*/*",
}

local function download(url)
  local data = {}
  local ok, err = pcall(function()
    for chunk in internet.request(url, 8, headers) do
      data[#data + 1] = chunk
    end
  end)
  if not ok then return nil, err end
  local body = table.concat(data)
  if #body < 100 then
    return nil, "response too small (" .. #body .. " bytes)"
  end
  if body:find("<!DOCTYPE") or body:find("<html") then
    return nil, "got HTML instead of paste (private or blocked)"
  end
  return body
end

print("SekretovOS downloader")
for _, url in ipairs(urls) do
  print("Trying: " .. url)
  local body, err = download(url)
  if body then
    local f = io.open(out, "w")
    if not f then
      print("Cannot write: " .. out)
      return
    end
    f:write(body)
    f:close()
    print("Saved " .. out .. " (" .. #body .. " bytes)")
    print("Run: " .. out)
    return
  end
  print("  failed: " .. tostring(err))
end

print("")
print("Pastebin blocked (403). Options:")
print("  1) Re-upload paste as PUBLIC (not Unlisted)")
print("  2) Copy sekretov-install.lua via floppy to /sekretov")
print("  3) Use wget + GitHub raw URL if available")
