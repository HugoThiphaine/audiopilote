# AudioPilote

Read this in: English | [Français](README.fr.md)

A small macOS menu-bar utility that manages the priority order of your audio
devices (input and output) and automatically switches to the most preferred
device that is available.

You rank your devices by drag and drop. AudioPilote forces the first available
device in the list as the system default, and falls back to the next one when
the active device disconnects.

## Features

- Input and Output tabs
- Drag-to-reorder list: that is your priority order
- Automatic switching to the highest-priority available device
- Auto-switch can be enabled independently for input and output
- Cascading fallback: when the active device disconnects, the next available one takes over
- Manual switch on click (with auto-switch on, clicking promotes the device to the top)
- Volume slider (output volume, input gain)
- Real-time input level meter, triggered per input by a button
- Offline devices are remembered and shown greyed out
- Launch at login (optional)
- 100% local: no telemetry, no account, free

## Installation

**[Download the latest version (AudioPilote.zip)](https://github.com/HugoThiphaine/audiopilote/releases/latest/download/AudioPilote.zip)**

Do not use the green "Code > Download ZIP" button at the top of the page. That
downloads the source code (Package.swift, build.sh...), not the app. For the
ready-to-use app, use the link above or the [Releases](../../releases) tab.

Then:

1. Unzip `AudioPilote.zip` (double-click).
2. Drag `AudioPilote.app` into your `Applications` folder.
3. **First launch**: right-click `AudioPilote.app` then `Open`, and confirm (the
   app is not notarized by Apple, this is expected). macOS will not ask again.

The icon appears in the menu bar (top right). No Dock icon, by design.

## Build from source

You only need Apple's Command Line Tools (`xcode-select --install`), not the
full Xcode.

```sh
git clone https://github.com/HugoThiphaine/audiopilote.git
cd audiopilote
./build.sh
open ./AudioPilote.app
```

`build.sh` compiles in release mode, assembles the `.app` and ad-hoc signs it
for local use.

## How it works

AudioPilote reads and writes the default device through CoreAudio (HAL) and
listens for connections and disconnections. The priority order is stored by UID
(a stable key), so it survives reconnections. With auto-switch enabled for a
mode, AudioPilote continuously enforces the highest available device in that
mode's list.

Target: macOS 13 or later.

## Credits

Inspired by [SoundAnchor](https://apps.kopiro.me/soundanchor) by Flavio De
Stefano. AudioPilote is an independent reimplementation, built only on Apple's
public APIs (CoreAudio, SwiftUI, ServiceManagement). No code or asset from
SoundAnchor was reused.

## Author

Hugo Thiphaine, web designer and SEO consultant. Help and contact:
[hugo-thiphaine.fr](https://hugo-thiphaine.fr).

## License

[MIT](LICENSE)
