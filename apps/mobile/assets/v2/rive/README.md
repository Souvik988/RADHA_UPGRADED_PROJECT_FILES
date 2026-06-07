# Rive Asset — mor.riv

## Status: PLACEHOLDER — needs rigging in the Rive editor

## What this file will be
A single Rive artboard "Mor" with one state machine "MorSM" that drives the RADHA peacock mascot.

## Source material
Use the parts from `assets/character/mor/parts/` (body, head, crest, eyelid, wing-l, wing-r, 
tail-base, tail-feather-1..5, feet) as the bones/mesh source in the Rive editor.

## State machine inputs (per CHARACTER_STORYTELLING_BIBLE.md §7.2)
- `mood` (number enum): 0=idle · 1=greet · 2=think · 3=work · 4=celebrate · 5=shelter · 6=concern · 7=guard · 8=sleep
- `progress` (number 0–1): drives think→done, loaders, gauge sync
- `intensity` (number 0–1): celebration size
- `trigTap`, `trigSuccess`, `trigError` (triggers): one-shot reactions
- `lookX`, `lookY` (numbers −1..1): optional eye/crest follow
- `reduceMotion` (bool): snaps to single expressive frame per mood

## Budget
- File size: < 150 KB
- Max concurrent instances: 2 (usually 1)

## Flutter integration
See `mascotControllerProvider` in `lib/features/mascot/mascot_controller.dart` (to be implemented).
Static PNG fallbacks at `assets/character/mor/static/<mood>.png` are used when reduceMotion=true.

## Build order
1. Lock parts sheet → import into Rive
2. Rig bones/meshes for each part
3. Create 9 animation clips (one per mood)
4. Wire state machine inputs
5. Export mor.riv (< 150 KB)
6. Place at assets/rive/mor.riv
