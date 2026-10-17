# openglm bootstrap installer - Windows, self-contained.
# Usage (after publishing to GitHub):
#   powershell -c "irm https://raw.githubusercontent.com/dmitryrublev04-cpu/openglm/main/install.ps1 | iex"
# The script fetches the mod files, and even the OpenCode engine itself, if missing.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue } catch { }

# zip extraction without Expand-Archive: works even when the Archive module
# cannot load (sandbox / Restricted policy machines)
function Expand-Zip([string]$zip, [string]$dest) {
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $dest)
}

$GitHubRepo   = 'dmitryrublev04-cpu/openglm'
$ReleaseTag   = 'v1.1.0'
$TgUrl        = 'https://t.me/+oLvLfkydwG8xMWFi'
$OcRepo       = 'anomalyco/opencode'
$OcAsset      = 'opencode-windows-x64.zip'
$Home_        = $env:USERPROFILE
$Dest         = Join-Path $Home_ '.config\opencode'
$OcExe        = Join-Path $Home_ '.opencode\bin\opencode.exe'
$ModRoot      = $PSScriptRoot                # works for "run from folder" case

Write-Host ''
Write-Host '== openglm installer ==' -ForegroundColor Green

# --- 1. locate mod files: next to script, or download from GitHub ------------
# NOTE: when piped through "irm | iex", $PSScriptRoot is empty - handle it.
$modSrc = $null
if ($ModRoot) { $modSrc = Join-Path $ModRoot 'opencode\themes\openglm.json' }
if (-not $modSrc -or -not (Test-Path $modSrc)) {
    Write-Host '[i] mod files not found locally, downloading from GitHub...' -ForegroundColor Cyan
    $tmpZip  = Join-Path $env:TEMP 'openglm-repo.zip'
    $tmpDir  = Join-Path $env:TEMP ('openglm-' + [guid]::NewGuid().ToString('N').Substring(0,8))
    Invoke-WebRequest "https://github.com/$GitHubRepo/archive/refs/heads/main.zip" -OutFile $tmpZip -UseBasicParsing
    Expand-Zip $tmpZip $tmpDir
    $ModRoot = Join-Path $tmpDir 'openglm-main'
    $modSrc  = Join-Path $ModRoot 'opencode\themes\openglm.json'
    if (-not (Test-Path $modSrc)) { throw 'mod files missing even after download - check $GitHubRepo in install.ps1' }
    Write-Host '[+] mod files downloaded' -ForegroundColor Green
}

# --- 2. ensure OpenCode engine (portable single exe, no app install) ---------
$haveCli = Get-Command opencode -ErrorAction SilentlyContinue
if ($haveCli -or (Test-Path $OcExe)) {
    Write-Host '[i] OpenCode engine already present' -ForegroundColor Cyan
} else {
    Write-Host '[i] downloading OpenCode engine (portable, one exe)...' -ForegroundColor Cyan
    # pinned release first (supply-chain safety); falls back to latest
    $rel = $null
    try {
        $rel = Invoke-RestMethod "https://api.github.com/repos/$OcRepo/releases/tags/v2.0.31" -Headers @{ 'User-Agent' = 'openglm' }
    } catch {
        Write-Host '[i] pinned version unavailable, falling back to latest' -ForegroundColor Yellow
        $rel = Invoke-RestMethod "https://api.github.com/repos/$OcRepo/releases/latest" -Headers @{ 'User-Agent' = 'openglm' }
    }
    $asset  = $rel.assets | Where-Object { $_.name -eq $OcAsset } | Select-Object -First 1
    if (-not $asset) { throw 'could not find engine release asset' }
    $zip = Join-Path $env:TEMP 'opencode-engine.zip'
    Invoke-WebRequest $asset.browser_download_url -OutFile $zip -UseBasicParsing
    New-Item -ItemType Directory -Force -Path (Split-Path $OcExe) | Out-Null
    Expand-Zip $zip (Join-Path $env:TEMP 'opencode-engine')
    Get-ChildItem (Join-Path $env:TEMP 'opencode-engine') -Recurse -Filter 'opencode.exe' |
        Select-Object -First 1 |
        ForEach-Object { Copy-Item $_.FullName $OcExe -Force }
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path $OcExe)) { throw 'engine download failed' }
    Write-Host '[+] OpenCode engine installed (portable)' -ForegroundColor Green
}

# --- 3. mod files into place --------------------------------------------------
New-Item -ItemType Directory -Force -Path (Join-Path $Dest 'themes') | Out-Null
Copy-Item (Join-Path $ModRoot 'opencode\themes\openglm.json') (Join-Path $Dest 'themes\openglm.json') -Force
New-Item -ItemType Directory -Force -Path (Join-Path $Dest 'agent') | Out-Null
Copy-Item (Join-Path $ModRoot 'opencode\agent\glm.md') (Join-Path $Dest 'agent\glm.md') -Force
New-Item -ItemType Directory -Force -Path (Join-Path $Dest 'commands') | Out-Null
Copy-Item (Join-Path $ModRoot 'opencode\commands\*.md') (Join-Path $Dest 'commands\') -Force
Write-Host '[+] theme / agent / commands installed' -ForegroundColor Green

# --- 3b. brand plugin (baked splash animation, /gif) --------------------------
$plugSrc = Join-Path $ModRoot 'opencode\plugins\openglm-brand'
$plugDst = Join-Path $Dest 'plugins\openglm-brand'
$brandOk = (Test-Path $plugSrc)
if ($brandOk) {
    if ($plugSrc -ne $plugDst) {
        New-Item -ItemType Directory -Force -Path (Split-Path $plugDst) | Out-Null
        Copy-Item -Recurse -Force $plugSrc $plugDst
    }
    # plugin needs its JS dependencies once; they ship as a release asset zip
    $nmDir = Join-Path $plugDst 'node_modules'
    if (-not (Test-Path $nmDir)) {
        try {
            Write-Host '[i] downloading brand plugin dependencies (one time)...' -ForegroundColor Cyan
            $depsZip = Join-Path $env:TEMP 'openglm-brand-deps.zip'
            Invoke-WebRequest "https://github.com/$GitHubRepo/releases/download/$ReleaseTag/openglm-brand-deps.zip" -OutFile $depsZip -UseBasicParsing
            Expand-Zip $depsZip $plugDst
            Remove-Item $depsZip -Force -ErrorAction SilentlyContinue
        } catch { }
        # degrade gracefully: without deps the plugin must not be registered
        if (-not (Test-Path $nmDir)) {
            Remove-Item $plugDst -Recurse -Force -ErrorAction SilentlyContinue
            $brandOk = $false
        }
    }
}
if ($brandOk) {
    Write-Host '[+] brand plugin (splash animation, /gif)' -ForegroundColor Green
} else {
    Write-Host '[!] brand plugin skipped: release asset missing - add Release v1.1.0 with openglm-brand-deps.zip to the repo' -ForegroundColor Yellow
}

# --- 4. cli.json: theme + comfort ---------------------------------------------
$cli = Join-Path $Dest 'cli.json'
$out = [ordered]@{}
if (Test-Path $cli) {
    try {
        $existing = Get-Content $cli -Raw | ConvertFrom-Json
        foreach ($p in $existing.PSObject.Properties) { $out[$p.Name] = $p.Value }
    } catch { }
}
$out['$schema']  = 'https://opencode.ai/v2/cli.json'
$out['theme']    = [ordered]@{ name = 'openglm'; mode = 'dark' }
$out['mouse']    = $true
$out['cursor']   = [ordered]@{ style = 'block'; blinking = $true }
$out['session']  = [ordered]@{
    thinking = 'hide'; tps = $true; markdown = 'rendered'
    permissions = 'autoaccept'; sidebar = 'auto'
}
$out['terminal'] = [ordered]@{ title = $true; copy = 'select' }

# register the brand plugin (do not duplicate the entry)
if (Test-Path $plugDst) {
    $plugs = @()
    if ($out.Contains('plugins') -and $out['plugins'] -is [array]) { $plugs = @($out['plugins']) }
    $hasBrand = $false
    foreach ($p in $plugs) {
        $val = if ($p -is [string]) { $p } elseif ($p.package) { $p.package } else { '' }
        if ("$val" -like '*openglm-brand*') { $hasBrand = $true }
    }
    if (-not $hasBrand) {
        $plugs = $plugs + ('file:///' + ($plugDst -replace '\\', '/'))
        $out['plugins'] = $plugs
    }
}
$cliJson = $out | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($cli, $cliJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host '[+] cli.json: theme + comfort settings' -ForegroundColor Green

# --- 5. opencode.json: free fast model + automation permissions ---------------
$cfgFile = Join-Path $Dest 'opencode.json'
$oc = [ordered]@{}
if (Test-Path $cfgFile) {
    try {
        $existing = Get-Content $cfgFile -Raw | ConvertFrom-Json
        foreach ($p in $existing.PSObject.Properties) { $oc[$p.Name] = $p.Value }
    } catch { }
}
$oc['$schema'] = 'https://opencode.ai/config.json'
$oc['model']   = 'opencode/glm-5.3-flash-free#low'
$oc['permissions'] = @(
    [ordered]@{ action = '*';       resource = '*';        effect = 'allow' },
    [ordered]@{ action = 'read';    resource = '*.env';   effect = 'ask' },
    [ordered]@{ action = 'read';    resource = '*.env.*'; effect = 'ask' },
    [ordered]@{ action = 'shell';   resource = 'format *';   effect = 'deny' },
    [ordered]@{ action = 'shell';   resource = 'shutdown *'; effect = 'deny' },
    [ordered]@{ action = 'shell';   resource = 'rmdir /s *'; effect = 'ask' }
)
$ocJson = $oc | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($cfgFile, $ocJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host '[+] opencode.json: GLM-5.3 Flash Free #low + auto permissions' -ForegroundColor Green

# --- 5b. claudecode world: separate config dir with Claude-look theme ---------
$CcRoot = Join-Path $Home_ '.config\claudecode\opencode'
$themeSrc = Join-Path $ModRoot 'opencode\themes\claude.json'
if (Test-Path $themeSrc) {
    New-Item -ItemType Directory -Force -Path (Join-Path $CcRoot 'themes') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $CcRoot 'agent') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $CcRoot 'commands') | Out-Null
    Copy-Item $themeSrc (Join-Path $CcRoot 'themes\claude.json') -Force
    $agentClaude = Join-Path $ModRoot 'opencode\agent\claude.md'
    if (Test-Path $agentClaude) { Copy-Item $agentClaude (Join-Path $CcRoot 'agent\claude.md') -Force }
    foreach ($c in @('opus', 'sonnet', 'haiku', 'fable', 'deep', 'skills', 'tg')) {
        $cmdSrc = Join-Path $ModRoot ('opencode\commands\' + $c + '.md')
        if (Test-Path $cmdSrc) { Copy-Item $cmdSrc (Join-Path $CcRoot ('commands\' + $c + '.md')) -Force }
    }
    # claude-world opencode.json: Claude model names, same guards
    $cc = [ordered]@{}
    $cc['$schema'] = 'https://opencode.ai/config.json'
    $cc['model']   = 'opencode/glm-5.3-flash-free#low'
    $cc['permissions'] = $oc['permissions']
    $cc['providers'] = [ordered]@{
        opencode = [ordered]@{
            models = [ordered]@{
                'glm-5.3-flash-free'        = [ordered]@{ name = 'Claude Opus 5.5' }
                'deepseek-v4.1-flash-free'  = [ordered]@{ name = 'Claude Sonnet 5.5' }
                'mimo-v2.6-flash-free'      = [ordered]@{ name = 'Claude Haiku 4.5' }
                'space-bunny-free'          = [ordered]@{ name = 'Claude Fable 5.1' }
                'longcat-2.5-preview-free'  = [ordered]@{ name = 'Claude Forge (preview)' }
            }
        }
    }
    $ccJson = $cc | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText((Join-Path $CcRoot 'opencode.json'), $ccJson, (New-Object System.Text.UTF8Encoding($false)))
    # claude-world cli.json: warm theme, no matrix plugin
    $ccCli = [ordered]@{}
    try {
        $ccCliPath = Join-Path $CcRoot 'cli.json'
        if (Test-Path $ccCliPath) {
            $existingCc = Get-Content $ccCliPath -Raw | ConvertFrom-Json
            foreach ($p in $existingCc.PSObject.Properties) { $ccCli[$p.Name] = $p.Value }
        }
    } catch { }
    $ccCli['$schema'] = 'https://opencode.ai/v2/cli.json'
    $ccCli['theme']   = [ordered]@{ name = 'claude'; mode = 'dark' }
    $ccCli['mouse']   = $true
    $ccCli['cursor']  = [ordered]@{ style = 'block'; blinking = $true }
    $ccCli['session'] = [ordered]@{
        thinking = 'hide'; tps = $true; markdown = 'rendered'
        permissions = 'autoaccept'; sidebar = 'auto'
    }
    $ccCli['terminal'] = [ordered]@{ title = $true; copy = 'select' }
    $ccCliJson = $ccCli | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText((Join-Path $CcRoot 'cli.json'), $ccCliJson, (New-Object System.Text.UTF8Encoding($false)))
    # share skills with the matrix world through a junction
    if (-not (Test-Path (Join-Path $CcRoot 'skills'))) {
        $skillsDst = Join-Path $Dest 'skills'
        if (Test-Path $skillsDst) {
            cmd /c mklink /J (Join-Path $CcRoot 'skills') $skillsDst | Out-Null
        }
    }
    Write-Host '[+] claudecode world: warm theme, Claude model names, shared skills' -ForegroundColor Green
}

# --- 6. launcher: openglm + claudecode commands -------------------------------
New-Item -ItemType Directory -Force -Path (Join-Path $Home_ 'openglm\bin') | Out-Null
$launchers = @('openglm.cmd', 'claudecode.cmd')
foreach ($l in $launchers) {
    $launchSrc = Join-Path $ModRoot ('bin\' + $l)
    $launchDst = Join-Path (Join-Path $Home_ 'openglm\bin') $l
    if ((Test-Path $launchSrc) -and ($launchSrc -ne $launchDst)) {
        Copy-Item $launchSrc $launchDst -Force
    }
    if (Test-Path $launchDst) {
        Write-Host ('[+] launcher: ' + $l.Split('.')[0] + ' command') -ForegroundColor Green
    }
}
$binDir = Join-Path $Home_ 'openglm\bin'
try {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$binDir*") {
        [Environment]::SetEnvironmentVariable('Path', $userPath.TrimEnd(';') + ";$binDir", 'User')
        Write-Host '[+] PATH: openglm command added' -ForegroundColor Green
    }
} catch {
    Write-Host "[!] could not update PATH ($($_.Exception.Message))" -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Done. Open a NEW terminal window and run:' -ForegroundColor Green
Write-Host '  openglm      (matrix console, GLM default)' -ForegroundColor Cyan
Write-Host '  claudecode   (Claude Code style: /opus /sonnet /haiku /fable)' -ForegroundColor Cyan
Write-Host 'First run: /login (free OpenCode account) - then GLM works for free.' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Community Telegram: ' -NoNewline
Write-Host $TgUrl -ForegroundColor Cyan

# --- 7. community: open Telegram after install --------------------------------
try {
    Start-Process $TgUrl
    Write-Host '[+] Telegram community opened in browser' -ForegroundColor Green
} catch {
    Write-Host "[!] could not open browser ($($_.Exception.Message))" -ForegroundColor Yellow
}
