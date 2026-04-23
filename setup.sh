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
# Usage:
#   bash setup.sh               — full install
#   bash setup.sh --change-font — change terminal font only
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

# --- Handle --change-font flag ---
if [[ "${1:-}" == "--change-font" ]]; then
    select_and_apply_font() {
        echo ""
        echo -e "${CYAN}Select a Nerd Font:${NC}"
        echo "  1) JetBrainsMono  — compact, sharp (default)"
        echo "  2) CascadiaCode   — open, airy, easy on the eyes"
        echo "  3) FiraCode       — clean with ligatures"
        echo "  4) Hack           — simple, high contrast"
        echo "  5) Iosevka        — tall, spacious, very readable"
        echo ""
        read -rp "Enter choice [1-5] (default: 1): " FONT_CHOICE
        FONT_CHOICE="${FONT_CHOICE:-1}"

        case "$FONT_CHOICE" in
            1) FONT_ARCHIVE="JetBrainsMono"; FONT_FC_PATTERN="JetBrainsMono.*Nerd"; FONT_GSETTINGS="JetBrainsMono Nerd Font Mono 13" ;;
            2) FONT_ARCHIVE="CascadiaCode";  FONT_FC_PATTERN="CaskaydiaCove.*Nerd";  FONT_GSETTINGS="CaskaydiaCove Nerd Font Mono 13" ;;
            3) FONT_ARCHIVE="FiraCode";      FONT_FC_PATTERN="FiraCode.*Nerd";       FONT_GSETTINGS="FiraCode Nerd Font Mono 13" ;;
            4) FONT_ARCHIVE="Hack";          FONT_FC_PATTERN="Hack.*Nerd";           FONT_GSETTINGS="Hack Nerd Font Mono 13" ;;
            5) FONT_ARCHIVE="Iosevka";       FONT_FC_PATTERN="Iosevka.*Nerd";        FONT_GSETTINGS="Iosevka Nerd Font Mono 13" ;;
            *) warn "Invalid choice, defaulting to JetBrainsMono."
               FONT_ARCHIVE="JetBrainsMono"; FONT_FC_PATTERN="JetBrainsMono.*Nerd"; FONT_GSETTINGS="JetBrainsMono Nerd Font Mono 13" ;;
        esac

        FONT_DIR="$HOME/.local/share/fonts"
        if fc-list | grep -qi "$FONT_FC_PATTERN"; then
            info "${FONT_ARCHIVE} Nerd Font already installed."
        else
            info "Installing ${FONT_ARCHIVE} Nerd Font..."
            mkdir -p "$FONT_DIR"
            TMP_DIR=$(mktemp -d)
            curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_ARCHIVE}.tar.xz" -o "$TMP_DIR/${FONT_ARCHIVE}.tar.xz"
            tar -xf "$TMP_DIR/${FONT_ARCHIVE}.tar.xz" -C "$FONT_DIR"
            rm -rf "$TMP_DIR"
            fc-cache -f "$FONT_DIR"
            info "${FONT_ARCHIVE} Nerd Font installed."
        fi

        if command -v gsettings &>/dev/null; then
            CURRENT_FONT=$(gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null || echo "")
            gsettings set org.gnome.desktop.interface monospace-font-name "$FONT_GSETTINGS"
            info "Font changed to: ${FONT_GSETTINGS}"
            info "Previous font was: $CURRENT_FONT"
            warn "To revert: gsettings set org.gnome.desktop.interface monospace-font-name $CURRENT_FONT"
        else
            warn "gsettings not found. Set your terminal font to '${FONT_GSETTINGS}' manually."
        fi
    }
    select_and_apply_font
    exit 0
fi

# --- 1. Check prerequisites ---
info "Checking prerequisites..."

if command -v bun &>/dev/null; then
    PKG_MGR="bun"
    INSTALL_CMD="bun install -g ccstatusline@latest"
elif command -v npm &>/dev/null; then
    PKG_MGR="npm"
    INSTALL_CMD="npm install -g ccstatusline@latest"
else
    error "Neither bun nor npm found. Install one first."
fi

info "Using package manager: ${CYAN}${PKG_MGR}${NC}"

# --- 2. Install ccstatusline globally ---
info "Installing ccstatusline globally..."
$INSTALL_CMD 2>&1 | tail -3
info "ccstatusline installed."

# Verify installation
if ! command -v ccstatusline &>/dev/null; then
    error "ccstatusline not found in PATH after install. Check your PATH."
fi

# --- Install cc-config command ---
info "Installing cc-config command..."
CC_BIN_DIR="$HOME/.local/bin"
mkdir -p "$CC_BIN_DIR"
REPO_RAW="https://raw.githubusercontent.com/dip497/claude-code-statusline/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/cc-config.js" ]; then
    cp "$SCRIPT_DIR/cc-config.js" "$CC_BIN_DIR/cc-config"
else
    curl -fsSL "$REPO_RAW/cc-config.js" -o "$CC_BIN_DIR/cc-config" \
        || error "Failed to download cc-config.js from $REPO_RAW"
fi
chmod +x "$CC_BIN_DIR/cc-config"
if ! echo "$PATH" | grep -q "$CC_BIN_DIR"; then
    warn "Add ~/.local/bin to your PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
info "cc-config installed."

# --- 3. Font selection ---
echo ""
echo -e "${CYAN}Select a Nerd Font to install (required for status line icons):${NC}"
echo "  1) JetBrainsMono  — compact, sharp (default)"
echo "  2) CascadiaCode   — open, airy, easy on the eyes"
echo "  3) FiraCode       — clean with ligatures"
echo "  4) Hack           — simple, high contrast"
echo "  5) Iosevka        — tall, spacious, very readable"
echo ""
read -rp "Enter choice [1-5] (default: 1): " FONT_CHOICE
FONT_CHOICE="${FONT_CHOICE:-1}"

case "$FONT_CHOICE" in
    1) FONT_ARCHIVE="JetBrainsMono"
       FONT_FC_PATTERN="JetBrainsMono.*Nerd"
       FONT_GSETTINGS="JetBrainsMono Nerd Font Mono 13" ;;
    2) FONT_ARCHIVE="CascadiaCode"
       FONT_FC_PATTERN="CaskaydiaCove.*Nerd"
       FONT_GSETTINGS="CaskaydiaCove Nerd Font Mono 13" ;;
    3) FONT_ARCHIVE="FiraCode"
       FONT_FC_PATTERN="FiraCode.*Nerd"
       FONT_GSETTINGS="FiraCode Nerd Font Mono 13" ;;
    4) FONT_ARCHIVE="Hack"
       FONT_FC_PATTERN="Hack.*Nerd"
       FONT_GSETTINGS="Hack Nerd Font Mono 13" ;;
    5) FONT_ARCHIVE="Iosevka"
       FONT_FC_PATTERN="Iosevka.*Nerd"
       FONT_GSETTINGS="Iosevka Nerd Font Mono 13" ;;
    *) warn "Invalid choice, defaulting to JetBrainsMono."
       FONT_ARCHIVE="JetBrainsMono"
       FONT_FC_PATTERN="JetBrainsMono.*Nerd"
       FONT_GSETTINGS="JetBrainsMono Nerd Font Mono 13" ;;
esac

FONT_DIR="$HOME/.local/share/fonts"
if fc-list | grep -qi "$FONT_FC_PATTERN"; then
    info "${FONT_ARCHIVE} Nerd Font already installed."
else
    info "Installing ${FONT_ARCHIVE} Nerd Font..."
    mkdir -p "$FONT_DIR"
    NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_ARCHIVE}.tar.xz"
    TMP_DIR=$(mktemp -d)
    curl -fsSL "$NERD_FONT_URL" -o "$TMP_DIR/${FONT_ARCHIVE}.tar.xz"
    tar -xf "$TMP_DIR/${FONT_ARCHIVE}.tar.xz" -C "$FONT_DIR"
    rm -rf "$TMP_DIR"
    fc-cache -f "$FONT_DIR"
    info "${FONT_ARCHIVE} Nerd Font installed."
fi

# --- 4. Set terminal font (GNOME Terminal) ---
if command -v gsettings &>/dev/null; then
    CURRENT_FONT=$(gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null || echo "")
    info "Setting terminal monospace font to ${FONT_GSETTINGS}..."
    gsettings set org.gnome.desktop.interface monospace-font-name "$FONT_GSETTINGS"
    info "Font set. Previous font was: $CURRENT_FONT"
    warn "To revert: gsettings set org.gnome.desktop.interface monospace-font-name $CURRENT_FONT"
else
    warn "gsettings not found. Set your terminal font to '${FONT_GSETTINGS}' manually."
fi

# --- 5. Write ccstatusline config ---
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

# --- 6. Update Claude Code settings.json ---
info "Updating Claude Code settings..."
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

if [ -f "$CLAUDE_SETTINGS" ]; then
    # Use python3 to safely merge statusLine into existing settings
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
    info "Updated existing $CLAUDE_SETTINGS"
else
    mkdir -p "$HOME/.claude"
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
echo -e "  ${YELLOW}To customize: run 'ccstatusline' interactively.${NC}"
echo -e "  ${YELLOW}To configure:    cc-config${NC}"
echo -e "  ${YELLOW}Config: ~/.config/ccstatusline/settings.json${NC}"
echo ""
