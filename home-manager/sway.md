# Sway Window Manager Configuration

This document provides a complete reference for the Sway window manager configuration including all keyboard shortcuts, features, and usage tips.

## Overview

This Sway configuration uses **Alt** as the main modifier key (instead of the typical Super key) and features:
- Dracula color theme throughout
- Waybar status bar
- Wofi application launcher
- Alacritty terminal
- Auto-lock and power management
- Complete touchpad support

## Keyboard Shortcuts

### Application Shortcuts
| Shortcut | Action |
|----------|--------|
| `Alt + Enter` | Open terminal (Alacritty) |
| `Alt + R` | Launch application menu (Wofi) |
| `Alt + E` | Open file manager (Nautilus) |
| `Alt + Q` | Kill focused window |
| `Alt + Shift + E` | Exit Sway (with confirmation dialog) |

### Window Focus Navigation
| Shortcut | Action |
|----------|--------|
| `Alt + ←/↓/↑/→` | Move focus between windows (arrow keys) |
| `Alt + H/J/K/L` | Move focus between windows (vim-style) |
| `Alt + Space` | Toggle focus between floating and tiled windows |
| `Alt + A` | Focus parent container |

### Window Movement
| Shortcut | Action |
|----------|--------|
| `Alt + Shift + ←/↓/↑/→` | Move windows (arrow keys) |
| `Alt + Shift + H/J/K/L` | Move windows (vim-style) |

### Workspace Management
| Shortcut | Action |
|----------|--------|
| `Alt + 1-9,0` | Switch to workspace 1-10 |
| `Alt + Shift + 1-9,0` | Move window to workspace 1-10 |
| `Alt + Tab` | Switch to next workspace |
| `Alt + Shift + Tab` | Switch to previous workspace |

### Window Layout & Display
| Shortcut | Action |
|----------|--------|
| `Alt + B` | Split container horizontally |
| `Alt + V` | Split container vertically |
| `Alt + S` | Change to stacking layout |
| `Alt + W` | Change to tabbed layout |
| `Alt + Shift + S` | Toggle between split layouts |
| `Alt + F` | Toggle fullscreen mode |
| `Alt + Shift + Space` | Toggle floating mode |

### Resize Mode
| Shortcut | Action |
|----------|--------|
| `Alt + Shift + R` | Enter resize mode |

**In resize mode:**
| Shortcut | Action |
|----------|--------|
| `←/↓/↑/→` or `H/J/K/L` | Resize window |
| `Enter` or `Escape` | Exit resize mode |

### System Controls
| Shortcut | Action |
|----------|--------|
| `Alt + Ctrl + L` | Lock screen (Swaylock) |
| `F6` (XF86MonBrightnessDown) | Decrease brightness by 10% |
| `F7` (XF86MonBrightnessUp) | Increase brightness by 10% |
| `F1` (XF86AudioMute) | Toggle audio mute |
| `F2` (XF86AudioLowerVolume) | Decrease volume by 5% |
| `F3` (XF86AudioRaiseVolume) | Increase volume by 5% |

### Media Controls
| Shortcut | Action |
|----------|--------|
| `XF86AudioPlay` | Play/pause media |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |

### Screenshots
| Shortcut | Action |
|----------|--------|
| `Alt + Print` | Screenshot selected area (copied to clipboard) |
| `Print` | Full screenshot (copied to clipboard) |

## Important Features

### Auto-Lock & Power Management
- Screen locks automatically after 5 minutes of inactivity
- Display turns off after 10 minutes of inactivity
- Laptop lid closing triggers immediate screen lock
- Auto-lock before system sleep

### Touchpad Configuration
- Tap to click enabled
- Natural scrolling enabled
- Disable while typing (dwt)
- Adaptive acceleration profile
- Click finger method for right-click

### Window Rules
Certain applications automatically open in floating mode:
- PulseAudio Volume Control (pavucontrol)
- Bluetooth Manager (blueman-manager)
- Network Manager Connection Editor

### Status Bar (Waybar)
The top bar displays:
- **Left**: Workspaces and current mode
- **Center**: Current window title
- **Right**: Audio, network, CPU, memory, temperature, battery, clock, system tray

Click on audio icon to open PulseAudio control.

### Application Launcher (Wofi)
- Triggered with `Alt + R`
- Search applications by typing
- Navigate with arrow keys or mouse
- Enter to launch, Escape to cancel

### Auto-started Applications
The following applications start automatically:
- Dunst (notifications)
- NetworkManager applet
- Bluetooth applet
- Swayidle (auto-lock daemon)

## Configuration Files
- Main config: `home-manager/sway.nix`
- Waybar styling: Dracula theme with transparency
- Wofi styling: Dracula theme with rounded corners
- Alacritty: Dracula color scheme with Hack Nerd Font
- Dunst: Dracula themed notifications

## Tips & Tricks

### Window Management
- Use `Alt + A` to focus parent containers for managing window groups
- Combine floating toggle (`Alt + Shift + Space`) with resize mode for precise window positioning
- Use tabbed layout (`Alt + W`) for efficient space usage with many windows

### Productivity
- Set up workspaces for different tasks (coding, browsing, communication, etc.)
- Use `Alt + Tab`/`Alt + Shift + Tab` for quick workspace switching
- Screenshot tools copy directly to clipboard for easy sharing

### Troubleshooting
- If applications don't start, check if they're installed in your configuration
- For display issues, verify your output configuration in the sway config
- Audio issues can often be resolved through pavucontrol (`Alt + R` → type "pavucontrol")

## Package Dependencies
The configuration includes these essential packages:
- `grim` & `slurp` - Screenshot tools
- `wl-clipboard` - Clipboard utilities
- `brightnessctl` - Brightness control
- `swaylock` & `swayidle` - Screen locking
- `playerctl` - Media control
- `pavucontrol` - Audio control
- `nautilus` - File manager
- `firefox-wayland` - Web browser