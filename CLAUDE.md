# Villain Bomber - Godot 4 Project

## Project Overview
2D side-scrolling bomber arcade game built with Godot 4.6. All graphics are procedural via `_draw()` — no external sprite/image assets.

## Architecture
- **Autoloads**: `GameState` (score/lives/difficulty), `Events` (signal bus), `SoundManager` (procedural audio)
- **Scenes**: Each entity (plane, bomb, villain, explosion, powerup) is its own scene
- **Visuals**: Separate `*_draw.gd` scripts handle all `_draw()` rendering
- **Environment**: `ParallaxBackground` with 4 layers (sky, clouds, buildings, ground)

## Key Conventions
- All variables accessing properties of untyped objects must use explicit type annotations: `var x: float = obj.prop` (NOT `var x := obj.prop`). Godot 4.6 requires this.
- Signals go through the `Events` autoload (global signal bus pattern)
- Entity cleanup: bombs/villains `queue_free()` themselves when off-screen
- Collision uses layers: 1=player, 2=bombs, 4=villains, 8=ground
- Sound effects are generated procedurally via `AudioStreamWAV` PCM data — no audio files

## Testing
Run headless to verify scripts compile:
```
Godot_v4.6.1-stable_win64_console.exe --headless --path "C:\Users\levar\Bomb-Iran" 2>&1 | grep "parse\|compile\|failed"
```
No output = success. NavMesh/RID warnings are normal Godot cleanup noise.

## Content Policy
- All characters are fictional cartoon villains (generic evil army)
- No real countries, ethnicities, or political figures
- Buildings are "cartoon villain hideouts" (industrial/evil lair style)
