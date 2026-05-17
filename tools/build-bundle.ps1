$Root = "c:\Users\Job\Desktop\SekretovOS"
$Out = Join-Path $Root "sekretov-install.lua"

$Files = @(
    "main.lua",
    "system\kernel.lua", "system\render.lua", "system\gui.lua",
    "system\window.lua", "system\desktop.lua", "system\events.lua",
    "system\theme.lua", "system\services.lua",
    "apps\energy.lua", "apps\ae2.lua", "apps\reactor.lua",
    "apps\logs.lua", "apps\settings.lua", "apps\files.lua", "apps\terminal.lua",
    "config\settings.cfg"
)

function Get-SafeDelimiter($allContent) {
    for ($n = 2; $n -le 10; $n++) {
        $eq = "=" * $n
        $close = "]" + $eq + "]"
        $safe = $true
        foreach ($c in $allContent) {
            if ($c.Contains($close)) { $safe = $false; break }
        }
        if ($safe) { return "[" + $eq + "[", $close }
    }
    throw "No safe delimiter"
}

$all = [ordered]@{}
foreach ($rel in $Files) {
    $unix = $rel -replace '\\', '/'
    $all[$unix] = [IO.File]::ReadAllText((Join-Path $Root $rel))
}

$open, $close = Get-SafeDelimiter @($all.Values)
$enc = New-Object System.Text.UTF8Encoding $false
$sw = New-Object System.IO.StreamWriter($Out, $false, $enc)

$sw.WriteLine("-- SekretovOS single-paste installer")
$sw.WriteLine("local INSTALL_DIR = '/SekretovOS'")
$sw.WriteLine("local RUN_AFTER = true")
$sw.WriteLine("local filesystem = require('filesystem')")
$sw.WriteLine("local shell = require('shell')")
$sw.WriteLine("local FILES = {")

foreach ($key in $all.Keys) {
    $sw.Write('  ["' + $key + '"] = ')
    $sw.Write($open)
    $sw.Write($all[$key])
    $sw.Write($close)
    $sw.WriteLine(",")
}

$sw.WriteLine("}")
$sw.WriteLine(@"
local function log(m) print('[SekretovOS] ' .. tostring(m)) end
local function ensureDir(p)
  if not filesystem.exists(p) then filesystem.makeDirectory(p) end
end
local function install()
  log('Installing to ' .. INSTALL_DIR .. ' ...')
  ensureDir(INSTALL_DIR)
  ensureDir(INSTALL_DIR .. '/system')
  ensureDir(INSTALL_DIR .. '/apps')
  ensureDir(INSTALL_DIR .. '/config')
  ensureDir(INSTALL_DIR .. '/logs')
  ensureDir(INSTALL_DIR .. '/temp')
  local n = 0
  for path, content in pairs(FILES) do
    n = n + 1
    local dest = filesystem.concat(INSTALL_DIR, path)
    local dir = filesystem.path(dest)
    if dir and dir ~= '' then ensureDir(dir) end
    local f = filesystem.open(dest, 'w')
    if not f then log('FAIL: ' .. path) return false end
    f:write(content)
    f:close()
    log(('  [%d] %s'):format(n, path))
  end
  log('Done. Starting SekretovOS...')
  if RUN_AFTER then shell.execute(INSTALL_DIR .. '/main') end
end
install()
"@)
$sw.Close()

Write-Host "Built $Out ($([math]::Round((Get-Item $Out).Length/1KB,1)) KB) $open ... $close"
