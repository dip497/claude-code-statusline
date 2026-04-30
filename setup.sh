#!/usr/bin/env bash
#
# Claude Code Status Line - Complete Setup Script
# Uses: ccstatusline (https://github.com/sirmalloc/ccstatusline)
#
# 3-Line Layout:
#   Line 1: Model | Version | Style | Vim Mode | Cost | Session Usage | Weekly Usage
#   Line 2: Git Branch | Changes | Insertions | Deletions | Worktree | CWD | Git Root
#   Line 3: Tokens In | Tokens Out | Cached | Context Length | Context % | Session Clock | Block Timer | Memory
#
# Supports: Linux, macOS, WSL, Git Bash on Windows.
# Native Windows PowerShell users: run setup.ps1 instead.
#
# Usage:
#   bash setup.sh
#   curl -fsSL <raw-url>/setup.sh | bash
#

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- OS detection ---
# OS_KIND ∈ { linux, macos, wsl, gitbash }
detect_os() {
    local uname_s
    uname_s="$(uname -s 2>/dev/null || echo "")"
    case "$uname_s" in
        Darwin) OS_KIND="macos" ;;
        Linux)
            if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
                OS_KIND="wsl"
            else
                OS_KIND="linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*) OS_KIND="gitbash" ;;
        *) OS_KIND="linux" ;;
    esac
    info "Detected OS: ${CYAN}${OS_KIND}${NC}"
}
detect_os

# Refuse to run as root on Unix: configs would land under /root, not the real user's $HOME.
# Skip on Git Bash where `id -u` semantics differ.
if [ "$OS_KIND" != "gitbash" ] && [ "$(id -u)" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ]; then
        error "Don't run with sudo. Re-run as ${SUDO_USER}: 'curl -fsSL <url> | bash' (no sudo). The script handles permissions itself."
    else
        error "Don't run as root. Re-run as your normal user."
    fi
fi

# --- 1. Check prerequisites ---
info "Checking prerequisites..."

if command -v bun &>/dev/null; then
    PKG_MGR="bun"
    INSTALL_CMD="bun install -g ccstatusline@latest"
    BUN_BIN="${BUN_INSTALL:-$HOME/.bun}/bin"
    if [ -d "$BUN_BIN" ] && ! echo ":$PATH:" | grep -q ":$BUN_BIN:"; then
        export PATH="$BUN_BIN:$PATH"
        if ! grep -qs 'BUN_INSTALL_PATH' "$HOME/.bashrc" 2>/dev/null; then
            printf '\n# BUN_INSTALL_PATH (added by ccstatusline setup)\nexport PATH="%s:$PATH"\n' "$BUN_BIN" >> "$HOME/.bashrc"
        fi
    fi
elif command -v npm &>/dev/null; then
    PKG_MGR="npm"
    INSTALL_CMD="npm install -g ccstatusline@latest"
else
    error "Neither bun nor npm found. Install one first."
fi

info "Using package manager: ${CYAN}${PKG_MGR}${NC}"

# --- 2. Install ccstatusline globally ---
# If running as non-root and npm prefix is unwritable, configure a user-local prefix
# so we don't need sudo (avoids landing configs under /root).
if [ "$PKG_MGR" = "npm" ] && [ "$OS_KIND" != "gitbash" ] && [ "$(id -u)" -ne 0 ]; then
    NPM_PREFIX="$(npm config get prefix 2>/dev/null || echo "")"
    if [ -z "$NPM_PREFIX" ] || [ ! -w "$NPM_PREFIX/lib/node_modules" ] 2>/dev/null; then
        if [ ! -w "${NPM_PREFIX:-/usr/local}" ] 2>/dev/null; then
            USER_PREFIX="$HOME/.npm-global"
            info "npm prefix not writable; switching to ${USER_PREFIX} (no sudo)."
            mkdir -p "$USER_PREFIX"
            npm config set prefix "$USER_PREFIX"
            export PATH="$USER_PREFIX/bin:$PATH"
            if ! grep -qs 'NPM_GLOBAL_PREFIX' "$HOME/.bashrc" 2>/dev/null; then
                printf '\n# NPM_GLOBAL_PREFIX (added by ccstatusline setup)\nexport PATH="%s/bin:$PATH"\n' "$USER_PREFIX" >> "$HOME/.bashrc"
            fi
            # Also patch ~/.zshrc on macOS where zsh is default.
            if [ "$OS_KIND" = "macos" ] && ! grep -qs 'NPM_GLOBAL_PREFIX' "$HOME/.zshrc" 2>/dev/null; then
                printf '\n# NPM_GLOBAL_PREFIX (added by ccstatusline setup)\nexport PATH="%s/bin:$PATH"\n' "$USER_PREFIX" >> "$HOME/.zshrc"
            fi
            warn "Added ${USER_PREFIX}/bin to your shell rc — open a new shell after install."
        fi
    fi
fi

info "Installing ccstatusline globally..."
$INSTALL_CMD 2>&1 | tail -3
info "ccstatusline installed."

# Verify installation
if ! command -v ccstatusline &>/dev/null; then
    error "ccstatusline not found in PATH after install. Check your PATH."
fi

# --- 3. Install cc-config command ---
info "Installing cc-config command..."
CC_BIN_DIR="$HOME/.local/bin"
mkdir -p "$CC_BIN_DIR"
REPO_RAW="https://raw.githubusercontent.com/dip497/claude-code-statusline/main"
SCRIPT_SRC="${BASH_SOURCE[0]:-${0:-}}"
if [ -n "$SCRIPT_SRC" ] && [ -f "$SCRIPT_SRC" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SRC")" 2>/dev/null && pwd || echo "")"
else
    SCRIPT_DIR=""
fi
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/cc-config.js" ]; then
    cp "$SCRIPT_DIR/cc-config.js" "$CC_BIN_DIR/cc-config"
else
    curl -fsSL "$REPO_RAW/cc-config.js" -o "$CC_BIN_DIR/cc-config" \
        || error "Failed to download cc-config.js from $REPO_RAW"
fi
chmod +x "$CC_BIN_DIR/cc-config"
if ! echo ":$PATH:" | grep -q ":$CC_BIN_DIR:"; then
    warn "Add ~/.local/bin to your PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
info "cc-config installed."

# --- 4. Write ccstatusline config ---
info "Writing ccstatusline configuration..."
CCSTATUS_DIR="$HOME/.config/ccstatusline"
mkdir -p "$CCSTATUS_DIR"

cat > "$CCSTATUS_DIR/settings.json" << 'CCEOF'
{
  "version": 3,
  "lines": [
    [
      {
        "id": "1",
        "type": "model",
        "color": "cyan"
      },
      {
        "id": "2",
        "type": "separator"
      },
      {
        "id": "3",
        "type": "version",
        "color": "brightBlack"
      },
      {
        "id": "4",
        "type": "separator"
      },
      {
        "id": "5",
        "type": "output-style",
        "color": "green"
      },
      {
        "id": "6",
        "type": "separator"
      },
      {
        "id": "7",
        "type": "vim-mode",
        "color": "yellow"
      },
      {
        "id": "9",
        "type": "session-cost",
        "color": "red"
      },
      {
        "id": "10",
        "type": "separator"
      },
      {
        "id": "11",
        "type": "session-usage",
        "color": "yellow"
      },
      {
        "id": "12",
        "type": "separator"
      },
      {
        "id": "13",
        "type": "weekly-usage",
        "color": "brightBlack"
      }
    ],
    [
      {
        "id": "14",
        "type": "git-branch",
        "color": "magenta"
      },
      {
        "id": "15",
        "type": "separator"
      },
      {
        "id": "16",
        "type": "git-changes",
        "color": "yellow"
      },
      {
        "id": "17",
        "type": "separator"
      },
      {
        "id": "18",
        "type": "git-insertions",
        "color": "green"
      },
      {
        "id": "19",
        "type": "separator"
      },
      {
        "id": "20",
        "type": "git-deletions",
        "color": "red"
      },
      {
        "id": "21",
        "type": "separator"
      },
      {
        "id": "22",
        "type": "git-worktree",
        "color": "blue"
      },
      {
        "id": "24",
        "type": "cwd",
        "color": "blue"
      },
      {
        "id": "25",
        "type": "separator"
      },
      {
        "id": "26",
        "type": "git-root-dir",
        "color": "brightBlack"
      }
    ],
    [
      {
        "id": "27",
        "type": "tokens-input",
        "color": "green"
      },
      {
        "id": "28",
        "type": "separator"
      },
      {
        "id": "29",
        "type": "tokens-output",
        "color": "cyan"
      },
      {
        "id": "30",
        "type": "separator"
      },
      {
        "id": "31",
        "type": "tokens-cached",
        "color": "yellow"
      },
      {
        "id": "32",
        "type": "separator"
      },
      {
        "id": "33",
        "type": "context-length",
        "color": "brightBlack"
      },
      {
        "id": "50",
        "type": "separator"
      },
      {
        "id": "51",
        "type": "context-percentage",
        "color": "white"
      },
      {
        "id": "34",
        "type": "separator"
      },
      {
        "id": "37",
        "type": "session-clock",
        "color": "blue"
      },
      {
        "id": "38",
        "type": "separator"
      },
      {
        "id": "39",
        "type": "block-timer",
        "color": "magenta"
      },
      {
        "id": "40",
        "type": "separator"
      },
      {
        "id": "41",
        "type": "memory-usage",
        "color": "brightBlack"
      }
    ]
  ],
  "flexMode": "full-minus-40",
  "compactThreshold": 60,
  "colorLevel": 3,
  "inheritSeparatorColors": false,
  "globalBold": false,
  "powerline": {
    "enabled": false,
    "separators": [
      "|"
    ],
    "separatorInvertBackground": [
      false
    ],
    "startCaps": [],
    "endCaps": [],
    "autoAlign": false
  }
}
CCEOF

info "ccstatusline config written to $CCSTATUS_DIR/settings.json"

# --- 5. Update Claude Code settings.json ---
info "Updating Claude Code settings..."
CLAUDE_SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
mkdir -p "$(dirname "$CLAUDE_SETTINGS")"

if [ -f "$CLAUDE_SETTINGS" ]; then
    if command -v python3 &>/dev/null; then
        python3 -c "
import json
with open('$CLAUDE_SETTINGS') as f:
    settings = json.load(f)
settings['statusLine'] = {
    'type': 'command',
    'command': 'ccstatusline',
    'padding': 0
}
with open('$CLAUDE_SETTINGS', 'w') as f:
    json.dump(settings, f, indent=2)
"
    elif command -v jq &>/dev/null; then
        TMP_SETTINGS="$(mktemp)"
        jq '.statusLine = {type:"command", command:"ccstatusline", padding:0}' "$CLAUDE_SETTINGS" > "$TMP_SETTINGS" \
            && mv "$TMP_SETTINGS" "$CLAUDE_SETTINGS"
    else
        warn "Neither python3 nor jq found; backing up existing settings.json and overwriting."
        cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.bak.$(date +%s)"
        cat > "$CLAUDE_SETTINGS" << 'CLEOF'
{
  "statusLine": {
    "type": "command",
    "command": "ccstatusline",
    "padding": 0
  }
}
CLEOF
    fi
    info "Updated existing $CLAUDE_SETTINGS"
else
    cat > "$CLAUDE_SETTINGS" << 'CLEOF'
{
  "statusLine": {
    "type": "command",
    "command": "ccstatusline",
    "padding": 0
  }
}
CLEOF
    info "Created $CLAUDE_SETTINGS"
fi

# --- Done ---
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ccstatusline setup complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "  ${CYAN}Line 1:${NC} Model | Version | Style | Vim | Cost | Session% | Weekly%"
echo -e "  ${CYAN}Line 2:${NC} Branch | Changes | +Lines | -Lines | Worktree | CWD | Root"
echo -e "  ${CYAN}Line 3:${NC} In Tokens | Out | Cached | Context | Context% | Clock | Block | Mem"
echo ""
echo -e "  ${YELLOW}Restart Claude Code to see the new status line.${NC}"
echo -e "  ${YELLOW}For icons, install a Nerd Font and set your terminal to it: https://www.nerdfonts.com/${NC}"
echo -e "  ${YELLOW}To customize: run 'ccstatusline' interactively.${NC}"
echo -e "  ${YELLOW}To configure: cc-config${NC}"
echo -e "  ${YELLOW}Config: ~/.config/ccstatusline/settings.json${NC}"
echo ""
