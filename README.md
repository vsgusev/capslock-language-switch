# CapsLock language switch

CapsLock switches the keyboard layout on Windows, like on a Mac.

Usually this is done with AutoHotkey, but some games with anti-cheat refuse to run while AutoHotkey is open.
This switcher doesn't use AutoHotkey, keyboard hooks or simulated key presses, so it can keep running while you play.
Tested with ARC Raiders.

## Requirements

- Windows 10 or 11
- Admin rights (for the install only)

## Install

1. Download the ZIP (green **Code** button, then **Download ZIP**) and extract it.
2. Double-click `install.cmd` and allow it to make changes.
3. Restart Windows.

If Windows warns that the file came from the internet, choose **Run** (or **More info**, then **Run anyway**).

After every sign-in, the switcher needs 10 to 30 seconds to start.

Its files go to `C:\Program Files\capslock-language-switch`, so the extracted folder can be deleted afterwards.

## Uninstall

Double-click `uninstall.cmd`, then restart Windows.

## Good to know

- **CapsLock no longer turns on capital letters.** Hold Shift instead.
- **It cycles through all your layouts**, like Alt+Shift does.
- **If you already use AutoHotkey for this, remove it from startup.** Otherwise it still starts with Windows
  and the anti-cheat still complains.
- **It won't install over another key remap.** If you've remapped keys with SharpKeys or a similar tool,
  the installer stops and changes nothing.

## Another key instead of CapsLock

Open `src\install.ps1` in Notepad, change the line `$Key = 0x3A` to the code from the table, save it and install.

| Key          | Code     |
|--------------|----------|
| CapsLock     | `0x3A`   |
| Right Alt    | `0xE038` |
| Right Ctrl   | `0xE01D` |
| Menu         | `0xE05D` |
| Scroll Lock  | `0x46`   |
| Insert       | `0xE052` |

The key stops doing its usual job.

If it's already installed, run `install.cmd` again after the change and restart Windows.

## How it works

1. The installer tells the Windows keyboard driver to send F24 when you press CapsLock (the `Scancode Map`
   registry setting). F24 is a real key that no keyboard has, so nothing else reacts to it.
2. A small background script registers F24 as a hotkey, the same way Discord or OBS register theirs. When you
   press it, the script asks the active window to switch to the next layout.

The script runs as admin, because otherwise it couldn't switch the layout in admin windows like Task Manager.
