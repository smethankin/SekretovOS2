$ErrorActionPreference = "Continue"
$Root = "c:\Users\Job\Desktop\SekretovOS"
$ApiKey = $env:PASTEBIN_API_KEY

function Get-PasteCode($response) {
    if ($response -match 'pastebin\.com/([a-zA-Z0-9]+)$') { return $Matches[1] }
    return $response.Trim()
}

function Send-Pastebin {
    param([string]$Title, [string]$Content, [string]$Format = "lua")
    $body = @{
        api_dev_key           = $ApiKey
        api_option            = "paste"
        api_paste_code        = $Content
        api_paste_name        = $Title
        api_paste_format      = $Format
        api_paste_private     = "0"
        api_paste_expire_date = "N"
    }
    for ($try = 1; $try -le 5; $try++) {
        try {
            $r = Invoke-RestMethod -Uri "https://pastebin.com/api/api_post.php" -Method Post -Body $body
            if ($r -match "Bad API request") { throw $r }
            return Get-PasteCode $r
        } catch {
            Write-Host "    retry $try : $_" -ForegroundColor Yellow
            Start-Sleep -Seconds (5 * $try)
        }
    }
    return $null
}

# Already uploaded
$codes = @{
    "main.lua" = "Emqk3Uik"
    "system/kernel.lua" = "pguppBFP"
}

$Files = @(
    "system\render.lua", "system\gui.lua", "system\window.lua", "system\desktop.lua",
    "system\events.lua", "system\theme.lua", "system\services.lua",
    "apps\energy.lua", "apps\ae2.lua", "apps\reactor.lua", "apps\logs.lua",
    "apps\settings.lua", "apps\files.lua", "apps\terminal.lua", "config\settings.cfg"
)

foreach ($rel in $Files) {
    $unix = $rel -replace '\\', '/'
    if ($codes.ContainsKey($unix)) { continue }
    $full = Join-Path $Root $rel
    $fmt = if ($rel -like "*.cfg") { "text" } else { "lua" }
    Write-Host $unix ...
    $c = Send-Pastebin -Title "SekretovOS-$unix" -Content (Get-Content $full -Raw -Encoding UTF8) -Format $fmt
    if ($c) {
        $codes[$unix] = $c
        Write-Host "  OK $c" -ForegroundColor Green
    } else {
        Write-Host "  FAIL" -ForegroundColor Red
    }
    Start-Sleep -Seconds 8
}

$codes | ConvertTo-Json | Set-Content (Join-Path $Root "tools\pastebin-codes.json") -Encoding UTF8
Write-Host "`nSaved tools\pastebin-codes.json"
$codes.GetEnumerator() | Sort-Object Name | ForEach-Object { Write-Host "$($_.Key) = $($_.Value)" }
