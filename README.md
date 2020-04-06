# tts_pathfinder

Scripted characters for Tabletop Simulator Pathfinder sessions

## Features

### Commands

- `fort` - Make a fortitude save - Key: Numpad1
- `reflex` - Make a reflex save - Key: Numpad2
- `will` - Make a will save  - Key: Numpad3
- `attack` - Make an attack roll - Key: Numpad4
- `perception` - Make a perception roll  - Key: Numpad5
- `test` - Run script tests  - Key: not bound

### Command Keybinds

TTS uses the numpad as scripting keybinds.  The commands above are bound in order, 1-X.

Change keybinds to your liking by adjusting the order in the `keybinds` variable in `onLoad`.

### Notecard as Data Source

- Create a Notecard object (Objects -> Components -> Tools -> Notecard)
- Set the Notecard title to match the internal `character_name` variable
- Set the Notecard description to any of the following values (case/whitespace not important for keys)
  - Level: `number`
  - Attack: `<x>d<y>+<z>`
  - To Hit: `number`
  - Fort Save: `number`
  - Will Save: `number`
  - Reflex Save: `number`
- Drop your scripted character token onto the notecard
- That's it!

## Usage (TTS)

### Setup
- Create a character object, doesn't matter what it is
- Paste the script into the object
- Save the object to your Saved Objects
- Load in your GM's game

### Commands

Run commands from the chat box by prefixing with `#` - e.g. `#attack`

## Usage (Command line)

All the same TTS chat commands are available from the command line.

Internal data only - no Notecard data is available.

### Setup

- Install `lua` according to your platform
  - Mac: `brew install lua`
  - Windows: Install MacOS instead, then follow Mac instructions

### Commands

`lua ./benedict_flameblade.lua attack`
