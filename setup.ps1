# Claude Code Status Line - Windows PowerShell Setup
#
# Runs natively on Windows PowerShell 5.1+ and PowerShell 7+.
# WSL / Git Bash users: run setup.sh instead.
#
# Usage:
#   irm https://raw.githubusercontent.com/dip497/claude-code-statusline/main/setup.ps1 | iex
#
# Requirements:
#   - Node.js (for npx) OR Bun
#   - Internet access

$ErrorActionPreference = 'Stop'

function Write-Info  { param($m) Write-Host "[INFO] $m"  -ForegroundColor Green }
function Write-Warn  { param($m) Write-Host "[WARN] $m"  -ForegroundColor Yellow }
function Write-Err   { param($m) Write-Host "[ERROR] $m" -ForegroundColor Red; exit 1 }

# --- 1. Detect package manager ---
$pkgMgr     = $null
$statusCmd  = $null

if (Get-Command bun -ErrorAction SilentlyContinue) {
    $pkgMgr    = 'bun'
    $statusCmd = 'bunx -y ccstatusline@latest'
} elseif (Get-Command npx -ErrorAction SilentlyContinue) {
    $pkgMgr    = 'npx'
    $statusCmd = 'npx -y ccstatusline@latest'
} elseif (Get-Command npm -ErrorAction SilentlyContinue) {
    # npm without npx is unusual but possible — fall back to npx via npm exec.
    $pkgMgr    = 'npm'
    $statusCmd = 'npx -y ccstatusline@latest'
} else {
    Write-Err "Need Node.js (npx) or Bun. Install one first:`n  Bun:  irm bun.sh/install.ps1 | iex`n  Node: winget install OpenJS.NodeJS.LTS"
}

Write-Info "Using package manager: $pkgMgr"
Write-Info "Status line command: $statusCmd"

# --- 2. Locate config dirs ---
# Claude Code reads %USERPROFILE%\.claude\settings.json (or $env:CLAUDE_CONFIG_DIR).
$claudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
$claudeSettings = Join-Path $claudeDir 'settings.json'

# ccstatusline config: ~/.config/ccstatusline/settings.json on all platforms.
$ccDir = Join-Path $HOME '.config\ccstatusline'
$ccSettings = Join-Path $ccDir 'settings.json'

New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
New-Item -ItemType Directory -Force -Path $ccDir     | Out-Null

# --- 3. Write ccstatusline config ---
Write-Info "Writing ccstatusline configuration..."
$ccConfig = @'
{
  "version": 3,
  "lines": [
    [
      { "id": "1",  "type": "model",          "color": "cyan" },
      { "id": "2",  "type": "separator" },
      { "id": "3",  "type": "version",        "color": "brightBlack" },
      { "id": "4",  "type": "separator" },
      { "id": "5",  "type": "output-style",   "color": "green" },
      { "id": "6",  "type": "separator" },
      { "id": "7",  "type": "vim-mode",       "color": "yellow" },
      { "id": "9",  "type": "session-cost",   "color": "red" },
      { "id": "10", "type": "separator" },
      { "id": "11", "type": "session-usage",  "color": "yellow" },
      { "id": "12", "type": "separator" },
      { "id": "13", "type": "weekly-usage",   "color": "brightBlack" }
    ],
    [
      { "id": "14", "type": "git-branch",     "color": "magenta" },
      { "id": "15", "type": "separator" },
      { "id": "16", "type": "git-changes",    "color": "yellow" },
      { "id": "17", "type": "separator" },
      { "id": "18", "type": "git-insertions", "color": "green" },
      { "id": "19", "type": "separator" },
      { "id": "20", "type": "git-deletions",  "color": "red" },
      { "id": "21", "type": "separator" },
      { "id": "22", "type": "git-worktree",   "color": "blue" },
      { "id": "24", "type": "cwd",            "color": "blue" },
      { "id": "25", "type": "separator" },
      { "id": "26", "type": "git-root-dir",   "color": "brightBlack" }
    ],
    [
      { "id": "27", "type": "tokens-input",       "color": "green" },
      { "id": "28", "type": "separator" },
      { "id": "29", "type": "tokens-output",      "color": "cyan" },
      { "id": "30", "type": "separator" },
      { "id": "31", "type": "tokens-cached",      "color": "yellow" },
      { "id": "32", "type": "separator" },
      { "id": "33", "type": "context-length",     "color": "brightBlack" },
      { "id": "50", "type": "separator" },
      { "id": "51", "type": "context-percentage", "color": "white" },
      { "id": "34", "type": "separator" },
      { "id": "37", "type": "session-clock",      "color": "blue" },
      { "id": "38", "type": "separator" },
      { "id": "39", "type": "block-timer",        "color": "magenta" },
      { "id": "40", "type": "separator" },
      { "id": "41", "type": "memory-usage",       "color": "brightBlack" }
    ]
  ],
  "flexMode": "full-minus-40",
  "compactThreshold": 60,
  "colorLevel": 3,
  "inheritSeparatorColors": false,
  "globalBold": false,
  "powerline": {
    "enabled": false,
    "separators": ["|"],
    "separatorInvertBackground": [false],
    "startCaps": [],
    "endCaps": [],
    "autoAlign": false
  }
}
'@
[System.IO.File]::WriteAllText($ccSettings, $ccConfig, (New-Object System.Text.UTF8Encoding($false)))
Write-Info "ccstatusline config written to $ccSettings"

# --- 4. Update Claude Code settings.json ---
Write-Info "Updating Claude Code settings at $claudeSettings"

$statusLine = [pscustomobject]@{
    type    = 'command'
    command = $statusCmd
    padding = 0
}

if (Test-Path $claudeSettings) {
    try {
        $existing = Get-Content $claudeSettings -Raw | ConvertFrom-Json
    } catch {
        Write-Warn "Existing settings.json is not valid JSON — backing up and overwriting."
        Copy-Item $claudeSettings "$claudeSettings.bak.$(Get-Date -Format yyyyMMddHHmmss)"
        $existing = [pscustomobject]@{}
    }
    if ($existing -isnot [pscustomobject]) { $existing = [pscustomobject]@{} }
    if ($existing.PSObject.Properties.Name -contains 'statusLine') {
        $existing.statusLine = $statusLine
    } else {
        $existing | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine -Force
    }
    $json = $existing | ConvertTo-Json -Depth 32
    [System.IO.File]::WriteAllText($claudeSettings, $json, (New-Object System.Text.UTF8Encoding($false)))
    Write-Info "Updated existing $claudeSettings"
} else {
    $json = @{ statusLine = $statusLine } | ConvertTo-Json -Depth 32
    [System.IO.File]::WriteAllText($claudeSettings, $json, (New-Object System.Text.UTF8Encoding($false)))
    Write-Info "Created $claudeSettings"
}

# --- Done ---
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  ccstatusline setup complete!"               -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Line 1: Model | Version | Style | Vim | Cost | Session% | Weekly%" -ForegroundColor Cyan
Write-Host "  Line 2: Branch | Changes | +Lines | -Lines | Worktree | CWD | Root" -ForegroundColor Cyan
Write-Host "  Line 3: In Tokens | Out | Cached | Context | Context% | Clock | Block | Mem" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Restart Claude Code to see the new status line." -ForegroundColor Yellow
Write-Host "  For icons, install a Nerd Font and set your terminal to it: https://www.nerdfonts.com/" -ForegroundColor Yellow
Write-Host "  To customize: run '$statusCmd' interactively." -ForegroundColor Yellow
Write-Host "  Config: $ccSettings" -ForegroundColor Yellow
Write-Host ""
