# claude-code-statusline

One-command setup for a beautiful 3-line status line in [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code), powered by [ccstatusline](https://github.com/sirmalloc/ccstatusline).

<img width="1847" height="94" alt="image" src="https://github.com/user-attachments/assets/e29ebfd5-734f-4d53-8d8b-3a30f37dc15c" />

## Quick Install

**Linux / macOS / WSL / Git Bash:**
```bash
curl -fsSL https://raw.githubusercontent.com/dip497/claude-code-statusline/main/setup.sh | bash
```

**Windows (PowerShell 5.1+ / 7+):**
```powershell
irm https://raw.githubusercontent.com/dip497/claude-code-statusline/main/setup.ps1 | iex
```

The bash script auto-detects Linux, macOS, WSL, and Git Bash and routes accordingly. No `sudo` needed — it auto-switches to a user-local npm prefix if `/usr/local` isn't writable.

## What You Get

A fully configured 3-line status line with 15+ widgets:

| Line       | Widgets                                                                                      |
| ---------- | -------------------------------------------------------------------------------------------- |
| **Line 1** | Model, Version, Output Style, Vim Mode, Session Cost, Session Usage, Weekly Usage            |
| **Line 2** | Git Branch, Changes, Insertions, Deletions, Worktree, CWD, Git Root Dir                      |
| **Line 3** | Tokens In, Tokens Out, Cached, Context Length, Context %, Session Clock, Block Timer, Memory |

## What the Script Does

1. Detects your OS (Linux / macOS / WSL / Git Bash, or native Windows for `setup.ps1`)
2. Installs `ccstatusline` (via `bun` or `npm`; on Windows uses `npx`/`bunx` directly — no global needed)
3. Installs `cc-config` — runtime config tool (bash platforms only)
4. Writes the full 3-line config to `~/.config/ccstatusline/settings.json`
5. Updates Claude Code `~/.claude/settings.json` (or `$CLAUDE_CONFIG_DIR/settings.json`) with the status line command

> **Nerd Font**: not auto-installed. For the icon glyphs in the status line, install one yourself from <https://www.nerdfonts.com/> and set your terminal to use it.

## Requirements

- **Claude Code CLI** installed
- **bun** or **npm** (Linux/macOS/WSL); **Node.js** or **Bun** (Windows)
- **python3** or **jq** (optional — for safely merging settings.json; otherwise the script backs up and overwrites)

## Runtime Configuration

After install, use `cc-config` (Linux/macOS/WSL/Git Bash) or `ccstatusline` directly to tweak the status line:

```bash
cc-config         # menu wrapper
ccstatusline      # interactive TUI
```

On Windows native:

```powershell
npx -y ccstatusline@latest    # or: bunx -y ccstatusline@latest
```

## Uninstall

**Linux / macOS / WSL / Git Bash:**
```bash
npm uninstall -g ccstatusline   # or: bun remove -g ccstatusline
rm ~/.local/bin/cc-config
rm -rf ~/.config/ccstatusline
# Then delete the "statusLine" block from ~/.claude/settings.json
```

**Windows:**
```powershell
Remove-Item -Recurse -Force "$HOME\.config\ccstatusline"
# Then delete the "statusLine" block from $HOME\.claude\settings.json
```

## Credits

- [ccstatusline](https://github.com/sirmalloc/ccstatusline) by [@sirmalloc](https://github.com/sirmalloc)
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)

## License

MIT
