# XCord

> Xcode activity → Discord Rich Presence, automatically.

XCord is a lightweight macOS menu bar utility that bridges your Xcode workflow with Discord Rich Presence — so your friends always know what you're shipping.

---

## What it does

XCord runs silently in your menu bar and pushes a Discord status update every **5 seconds**, reflecting your current activity across the Apple developer toolchain.

---

## What shows up in Discord

| Field | Details |
|---|---|
| 📁 Project | Active Xcode workspace or project name |
| 📄 Open file | Current file with a language icon |
| 📱 Simulator | Device model + iOS version |
| 🔬 Instruments | Active profiling tool |

**40+ supported file extensions** — Swift, Objective-C, C++, Storyboard, plist, Metal, Markdown, and more.

---

## Supported tools

- 🔨 Xcode
- 📱 iOS / macOS Simulator
- 📊 Instruments
- ♿ Accessibility Inspector
- 🔀 FileMerge
- 🧠 Create ML
- 🌐 Reality Composer

---

## Installation

1. Clone the repo and open `XCord.xcodeproj` in Xcode.
2. Build and run — the XCord icon appears in your menu bar.
3. Grant **Automation (Apple Events)** permission when prompted.
4. Ensure Discord is running with **Activity Status** enabled (User Settings → Activity Privacy).
5. Optionally enable **Launch at Login** from the menu bar icon.

> ⚠️ **Apple Events permission** is required for XCord to query Xcode via AppleScript.  
> Grant access in: *System Settings → Privacy & Security → Automation*

---

## How it works

Every 5 seconds, XCord:
1. Queries Xcode via **AppleScript** → retrieves the open workspace and active file
2. Runs `xcrun simctl list` → detects running simulators
3. Maps the file extension to a language icon (40+ supported)
4. Pushes a presence update to Discord via **SwordRPC**

**Tech stack:** Swift · SwiftUI · Combine · AppleScript · simctl · SwordRPC

---

## Requirements

- macOS 12 (Monterey) or later
- Xcode installed
- Discord running with Activity Status enabled
- Apple Events permission granted

---

*Made with ♥ for the Apple developer community.*
