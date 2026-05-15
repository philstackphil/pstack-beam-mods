# pstack-beam-mods

A collection of fun and silly mods for BeamNG.drive — sound effects, custom game modes, and car skins.

## Project Layout

```
mods/
  silly_sounds/   — custom sound effects (honks, crashes, silly noises)
  wacky_modes/    — custom game modes and scenarios written in Lua
  funky_skins/    — car paint skins (DDS textures + material overrides)
scripts/
  pack.sh         — packages any mod folder into a deployable .zip
dist/             — output zips (gitignored)
```

## BeamNG Mod Basics

BeamNG mods are **zip files** whose internal directory structure mirrors the game's content tree. The game loads them from:

- **Windows**: `%USERPROFILE%\Documents\BeamNG.drive\mods\`
- **Linux (Steam/Proton)**: `~/.local/share/Steam/steamapps/compatdata/<appid>/pfx/drive_c/users/steamuser/Documents/BeamNG.drive/mods/`

Each mod has an `info.json` at its root (inside the zip):

```json
{
  "title": "Mod Name",
  "version": "1.0.0",
  "description": "What this mod does.",
  "author": "pstack"
}
```

### Sound Mods (`art/sounds/`)

- Audio files must be **Ogg Vorbis** (`.ogg`), mono or stereo, 44100 Hz.
- Sound events are defined in `.json` files alongside the audio files.
- Override existing sounds by matching the game's internal path exactly.
- New sounds need to be referenced from a Lua script or vehicle `.jbeam`.

### Game Mode Mods (`lua/ge/extensions/gameplay/`)

- BeamNG uses **Lua 5.1** for all game-side scripting.
- Extensions are loaded with `extensions.load("gameplay/myMod")`.
- Each extension should expose `M.onExtensionLoaded`, `M.onExtensionUnloaded`, `M.onUpdate(dt)`, etc. as needed.
- Use `Scenario` API for structured game modes; use `extensions.hook` to fire events.
- Keyboard input in GE extensions: `im.IsKeyPressed(keyCode)` inside `onUpdate`. Key codes for letter keys match their ASCII value (`string.byte('H')` = 72).
- Debug with the in-game Lua console (`F11` → Lua tab).
- Expose a `M.drop()` / `M.trigger()` alias on public modes so you can test from the console without pressing the hotkey.

#### Drop the Hammer

- Extension: `gameplay/dropTheHammer`
- Hotkey: `H` (configurable via `HOTKEY` at top of file)
- Proxy vehicle: `drop_hammer_crate` (8-node rigid box, 600 kg, indestructible beams)
- Spawns 14 AI traffic cars on load via `extensions.traffic.activate()`
- Wreckage is persistent — crates stay in world until session ends or player clears them
- Console test: `extensions.gameplay_dropTheHammer.drop()`
- Known limitation: crate is invisible in v1 (no flexbody mesh); add a `.dae` + flexbody entry to the JBeam for a visible model

### Skin Mods (`art/vehicles/<vehicle_name>/`)

- Skins are **DDS** textures (BC1/BC3 compression) referenced by `.skin.json` files.
- A `.skin.json` maps a skin name to a set of material overrides.
- Vehicle folder names must exactly match the game's internal vehicle folder (e.g., `etk800`, `pickup`, `vivace`).

## Packaging a Mod

```bash
./scripts/pack.sh mods/silly_sounds
# → dist/silly_sounds.zip
```

Install by copying the zip into the BeamNG mods folder. No extraction needed.

## Adding a New Mod

1. Create a folder under `mods/<mod_name>/`.
2. Add `info.json` with title, version, description, author.
3. Add mod content following the directory conventions above.
4. Run `./scripts/pack.sh mods/<mod_name>` to build it.
5. Test in-game, then commit.

## Conventions

- Mod folder names: `snake_case`.
- Lua files: `camelCase` functions, local-first (`local M = {}`), return `M` at the bottom.
- Sound files: descriptive names, prefix with mod short-code (e.g., `ss_honk_clown.ogg`).
- Skin texture files: `<vehicle>_<skin_name>_<channel>.dds` (e.g., `pickup_hotdog_diffuse.dds`).
- Keep `dist/` out of git — it's build output.
