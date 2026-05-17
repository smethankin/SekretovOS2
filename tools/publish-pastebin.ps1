# Upload SekretovOS files to Pastebin and print manifest codes.
# Requires: $env:PASTEBIN_API_KEY from https://pastebin.com/doc_api

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

$ApiKey = $env:PASTEBIN_API_KEY
if (-not $ApiKey) {
    Write-Host "Set API key: `$env:PASTEBIN_API_KEY = 'your_key'" -ForegroundColor Yellow
    Write-Host "Get key: https://pastebin.com/doc_api"
    exit 1
}

$Files = @(
    "main.lua",
    "system\kernel.lua", "system\render.lua", "system\gui.lua",
    "system\window.lua", "system\desktop.lua", "system\events.lua",
    "system\theme.lua", "system\services.lua",
    "apps\energy.lua", "apps\ae2.lua", "apps\reactor.lua",
    "apps\logs.lua", "apps\settings.lua", "apps\files.lua", "apps\terminal.lua",
    "config\settings.cfg"
)

function Send-Pastebin {
    param([string]$Title, [string]$Content)
    $body = @{
        api_dev_key  = $ApiKey
        api_option   = "paste"
        api_paste_code = $Content
        api_paste_name = $Title
        api_paste_format = "lua"
        api_paste_private = "0"
        api_paste_expire_date = "N"
    }
    $response = Invoke-RestMethod -Uri "https://pastebin.com/api/api_post.php" -Method Post -Body $body
  if ($response -match "Bad API request") { throw $response }
    return $response.Trim()
}

$codes = @{}
Write-Host "Uploading from $Root ..." -ForegroundColor Cyan

foreach ($rel in $Files) {
    $full = Join-Path $Root $rel
    if (-not (Test-Path $full)) {
        Write-Host "  SKIP missing: $rel" -ForegroundColor DarkYellow
        continue
    }
    $content = Get-Content -Path $full -Raw -Encoding UTF8
    $title = "SekretovOS-" + ($rel -replace '[\\/]', '-')
    Write-Host "  $rel ..."
    $code = Send-Pastebin -Title $title -Content $content
    $unixPath = $rel -replace '\\', '/'
    $codes[$unixPath] = $code
    Write-Host "    -> $code" -ForegroundColor Green
    Start-Sleep -Seconds 3
}

Write-Host "`n--- MANIFEST (paste into install.lua) ---`n"
foreach ($rel in $Files) {
    $unixPath = $rel -replace '\\', '/'
    if ($codes.ContainsKey($unixPath)) {
        Write-Host "  { path = `"$unixPath`", code = `"$($codes[$unixPath])`" },"
    }
}

Write-Host "`n--- Next ---"
Write-Host "1. Copy lines above into install.lua MANIFEST"
Write-Host "2. Upload install.lua manually or run this script again on install.lua only"
Write-Host "3. In game: pastebin get <INSTALL_CODE> install && install"
