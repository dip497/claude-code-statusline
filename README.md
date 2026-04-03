# claude-code-statusline

One-command setup for a beautiful 3-line status line in [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code), powered by [ccstatusline](https://github.com/sirmalloc/ccstatusline).

<img width="1847" height="94" alt="image" src="https://github.com/user-attachments/assets/e29ebfd5-734f-4d53-8d8b-3a30f37dc15c" />


## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/dip497/claude-code-statusline/main/setup.sh | bash
```

## What You Get

A fully configured 3-line status line with 15+ widgets:

| Line | Widgets |
|------|---------|
| **Line 1** | Model, Version, Output Style, Vim Mode, Session Cost, Session Usage, Weekly Usage |
| **Line 2** | Git Branch, Changes, Insertions, Deletions, Worktree, CWD, Git Root Dir |
| **Line 3** | Tokens In, Tokens Out, Cached, Context Length, Context %, Session Clock, Block Timer, Memory |

## What the Script Does

1. Installs `ccstatusline` globally (via `bun` or `npm`)
2. Downloads & installs **JetBrainsMono Nerd Font** (if missing)
3. Sets GNOME Terminal font to the Nerd Font
4. Writes the full 3-line config to `~/.config/ccstatusline/settings.json`
5. Updates Claude Code `~/.claude/settings.json` with the status line command

## Requirements

- **Claude Code CLI** installed
- **bun** or **npm** (for installing ccstatusline)
- **python3** (for safely updating settings.json)
- **GNOME Terminal** (for auto font setup; other terminals need manual font change)

## Customization

After install, run the interactive TUI to tweak widgets, colors, and layout:

```bash
ccstatusline
```

Config file: `~/.config/ccstatusline/settings.json`

## Revert Terminal Font

```bash
gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Sans Mono 13'
```

## Uninstall

```bash
# Remove ccstatusline
npm uninstall -g ccstatusline  # or: bun remove -g ccstatusline

# Remove config
rm -rf ~/.config/ccstatusline

# Remove statusLine from Claude Code settings (edit manually)
# ~/.claude/settings.json -> delete the "statusLine" block
```

## Credits

- [ccstatusline](https://github.com/sirmalloc/ccstatusline) by [@sirmalloc](https://github.com/sirmalloc)
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)

## License

MIT
