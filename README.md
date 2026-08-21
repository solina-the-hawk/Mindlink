# Mindlink
**A streamlined, zero-dependency telepathic communication ledger for Achaea and Mudlet.**

Mindlink is a modern, lightweight tell catcher, inspired by predecessors like YATCO, but simplified, streamlined, and without dependencies on other systems or packages. It captures your game's chat channels, tells, and emotes, organizing them into a clean, tabbed Geyser interface so you never lose a message to combat or travel spam again.

Unlike older systems, Mindlink has zero external dependencies, relies purely on Mudlet's native Geyser layout manager, and includes automated roleplay logging.

---
## Screenshots
<img width="1030" height="702" alt="Screenshot_20260821_153253" src="https://github.com/user-attachments/assets/a98cb7b3-6ef4-4ae7-b5f1-1ecc41a99923" />

<img width="641" height="64" alt="image" src="https://github.com/user-attachments/assets/333f3c9b-6b46-4f42-a81c-be5b3116ce5c" />

<img width="907" height="816" alt="Screenshot_20260821_153539" src="https://github.com/user-attachments/assets/7d08423d-7137-4d9a-a5b0-85ffcf501308" />


## Features

* **Zero Bloat:** A single-script architecture with no external dependencies and no lag-inducing timers.
* **Interactive Dashboard:** A clickable in-game dashboard (`mindlink config`) to manage all your settings on the fly.
* **Persistent Settings:** All configuration changes made in-game are automatically saved to your profile and reloaded on startup.
* **Advanced Filtering:** Granular control to `filter` channels from the main window, `mute` them everywhere, or `gag` specific repetitive NPC lines from your chat tabs.
* **Native GMCP Routing:** Instantly captures `say`, `tell`, `party`, `city`, and other channels directly from the game's data stream.
* **Mathematical Highlighting:** Highlights custom words and names in your main window without destroying your prompt or overwriting Achaea's native ANSI colors. 
* **Automated Emote Capture:** Captures custom-colored emotes directly from the main window, preserving their original colors perfectly.
* **Automated RP Logging:** Silently saves clean, timestamped plain-text logs of any tabs you choose.

---

## Installation

1. Download the `Mindlink.mpackage` or import the `Mindlink-Core.lua` script directly into your Mudlet Script Editor.
2. Save the script. The UI will instantly generate.
3. Type `mindlink help` in the game for a list of helpful commands.
4. Use `mindlink config` to open the interactive dashboard and customize your settings.

You can put the geyser window anywhere. However, I recommend going into **Preferences > Main Display** in Mudlet and adding a **Display Border** to the left or right in which to contain this (and possibly other packages!). I use a right border width of 650px, with my mapper above it, but this will vary based on your display size and preferences!

---

## Catching Emotes (Zero Setup!)

Emotes in Achaea are freeform and tricky to catch with standard text triggers. Mindlink solves this by using Achaea's native color configuration—and it does all the heavy lifting for you.

When you install Mindlink, the script automatically talks to Achaea to set your emote color to a default (dark grey, XTerm 242) and silently builds the Mudlet trigger to catch it. **You do not need to make any manual triggers.** 

If you want to change the color used to catch emotes, simply type `mindlink emote <number>` (e.g., `mindlink emote 245`). The script will handle everything else automatically.

*(Note: If a specific room description also uses this color, you can add that text to the `ignorePatterns` table in the script configuration to prevent it from being copied).*

---

## Accessing Your Logs & Profiles

If you have logging enabled for a tab, Mindlink will organize them by date in a custom folder. 

To find your logs and your exported JSON profiles, look in your Mudlet Profile folder. If you're not sure where that is, open Mudlet's main input line and type:
`lua getMudletHomeDir()` 

Navigate to that folder on your computer, and you will find a directory named **Mindlink**. Inside, you will see your `Mindlink_Profile.json` configuration file, as well as a **Logs** folder containing your chat history.
