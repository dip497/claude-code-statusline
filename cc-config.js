#!/usr/bin/env node

const { execSync, spawn } = require("child_process");
const readline = require("readline");
const os = require("os");
const path = require("path");
const fs = require("fs");

const FONTS = [
  {
    name: "JetBrainsMono — compact, sharp (default)",
    archive: "JetBrainsMono",
    fc: "JetBrainsMono",
    gsettings: "JetBrainsMono Nerd Font Mono 13",
  },
  {
    name: "CascadiaCode  — open, airy, easy on the eyes",
    archive: "CascadiaCode",
    fc: "CaskaydiaCove",
    gsettings: "CaskaydiaCove Nerd Font Mono 13",
  },
  {
    name: "FiraCode      — clean with ligatures",
    archive: "FiraCode",
    fc: "FiraCode",
    gsettings: "FiraCode Nerd Font Mono 13",
  },
  {
    name: "Hack          — simple, high contrast",
    archive: "Hack",
    fc: "Hack",
    gsettings: "Hack Nerd Font Mono 13",
  },
  {
    name: "Iosevka       — tall, spacious, very readable",
    archive: "Iosevka",
    fc: "Iosevka",
    gsettings: "Iosevka Nerd Font Mono 13",
  },
];

function ask(rl, question) {
  return new Promise((resolve) => rl.question(question, resolve));
}

async function changeFont(rl) {
  console.log("\nSelect a Nerd Font:\n");
  FONTS.forEach((f, i) => console.log(`  ${i + 1}) ${f.name}`));
  console.log("");

  const answer = await ask(rl, "Enter choice [1-5] (default: 1): ");
  const idx = Math.max(0, Math.min(4, (parseInt(answer) || 1) - 1));
  const font = FONTS[idx];
  const fontDir = path.join(os.homedir(), ".local", "share", "fonts");

  console.log("");

  // Check if already installed
  let alreadyInstalled = false;
  try {
    const result = execSync("fc-list 2>/dev/null", { shell: true }).toString();
    alreadyInstalled = result.toLowerCase().includes(font.fc.toLowerCase());
  } catch {}

  if (alreadyInstalled) {
    console.log(`[INFO] ${font.archive} Nerd Font already installed.`);
  } else {
    console.log(`[INFO] Installing ${font.archive} Nerd Font...`);
    try {
      fs.mkdirSync(fontDir, { recursive: true });
      const tmp = execSync("mktemp -d", { shell: true }).toString().trim();
      const url = `https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font.archive}.tar.xz`;
      execSync(`curl -fsSL "${url}" -o "${tmp}/${font.archive}.tar.xz"`, {
        shell: true,
        stdio: "inherit",
      });
      execSync(`tar -xf "${tmp}/${font.archive}.tar.xz" -C "${fontDir}"`, {
        shell: true,
      });
      execSync(`rm -rf "${tmp}"`, { shell: true });
      execSync(`fc-cache -f "${fontDir}"`, { shell: true });
      console.log(`[INFO] ${font.archive} Nerd Font installed.`);
    } catch (err) {
      console.error(`[ERROR] Font installation failed: ${err.message}`);
      return;
    }
  }

  // Apply via gsettings
  try {
    execSync(
      `gsettings set org.gnome.desktop.interface monospace-font-name "${font.gsettings}"`,
      { shell: true },
    );

    // Update active GNOME Terminal profile for immediate effect
    try {
      const activeProfile = execSync(
        "gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null",
        { shell: true },
      )
        .toString()
        .trim()
        .replace(/'/g, "");

      if (activeProfile) {
        const profilePath = `org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${activeProfile}/`;
        execSync(`gsettings set "${profilePath}" use-system-font false`, {
          shell: true,
        });
        execSync(`gsettings set "${profilePath}" font "${font.gsettings}"`, {
          shell: true,
        });
      }
    } catch {}

    console.log(`[INFO] Font set to: ${font.gsettings}`);
    console.log("[INFO] Takes effect immediately — no restart needed.");
  } catch {
    console.log(
      `[WARN] gsettings not found. Set terminal font to '${font.gsettings}' manually.`,
    );
  }
}

function launchCcstatusline(rl) {
  return new Promise((resolve) => {
    rl.close();
    const child = spawn("ccstatusline", { stdio: "inherit" });
    child.on("close", resolve);
  });
}

async function main() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  console.log("\n  Claude Code Status Line — Config\n");
  console.log("  1) Change Font");
  console.log("  2) Edit Colors & Lines\n");

  const choice = await ask(rl, "Enter choice [1-2]: ");

  switch (choice.trim()) {
    case "1":
      await changeFont(rl);
      rl.close();
      break;
    case "2":
      await launchCcstatusline(rl);
      break;
    default:
      console.log("[WARN] Invalid choice.");
      rl.close();
  }
}

main();
