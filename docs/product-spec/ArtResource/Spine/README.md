# Spine Animation Assets

This folder contains Spine background animation exports for the Pomodoro game.
Each animation variant is stored in its own folder with three files:

- `*.skel.bytes`: Spine binary skeleton data.
- `*.atlas.txt`: Spine texture atlas metadata.
- `*.png`: Texture page referenced by the atlas.

## Format Identification

All inspected skeleton files expose Spine version `4.1.23` in the binary header.
The atlas files use `pma:true`, so the Godot runtime/material path must support
premultiplied alpha.

Godot does not play these files through built-in `AnimatedSprite2D` or
`AnimationPlayer` alone. Use a Spine runtime/plugin compatible with Godot and
Spine `4.1.x`, or re-export the animations to a Godot-native format before
implementation.

## Asset Inventory

| Variant | Mood | Time | Files | Spine | Texture | Atlas regions | Loop use |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `LofiBG_01_Good_Day` | Good | Day | `.skel.bytes`, `.atlas.txt`, `.png` | 4.1.23 | 4096x4096 | 124 | Yes |
| `LofiBG_01_Good_Night` | Good | Night | `.skel.bytes`, `.atlas.txt`, `.png` | 4.1.23 | 4096x4096 | 117 | Yes |
| `LofiBG_01_Good_Sunfall` | Good | Sunfall | `.skel.bytes`, `.atlas.txt`, `.png` | 4.1.23 | 4096x4096 | 115 | Yes |
| `LofiBG_01_Nomal_Cloudy` | Nomal | Cloudy | `.skel.bytes`, `.atlas.txt`, `.png` | 4.1.23 | 4096x4096 | 116 | Yes |
| `LofiBG_01_Nomal_Day` | Nomal | Day | `.skel.bytes`, `.atlas.txt`, `.png` | 4.1.23 | 4096x4096 | 116 | Yes |
| `LofiBG_01_Nomal_Night` | Nomal | Night | `.skel.bytes`, `.atlas.txt`, `.png` | 4.1.23 | 4096x4096 | 116 | Yes |
| `LofiBG_01_Nomal_Sunfall` | Nomal | Sunfall | `.skel.bytes`, `.atlas.txt`, `.png` | 4.1.23 | 4096x4096 | 116 | Yes |
| `LofiBG_01_Troubled_Day` | Troubled | Day | `.skel.bytes`, `.atlas.txt`, `.png` | 4.1.23 | 4096x4096 | 100 | Yes |
| `LofiBG_01_Troubled_Night` | Troubled | Night | `.skel.bytes`, `.atlas.txt`, `.png` | 4.1.23 | 4096x4096 | 100 | Yes |
| `LofiBG_01_Troubled_Sunfall` | Troubled | Sunfall | `.skel.bytes`, `.atlas.txt`, `.png` | 4.1.23 | 4096x4096 | 100 | Yes |

`Nomal` is kept as-is because it is part of the source folder and file names.
If the game uses `Normal` in code, map it in data instead of renaming the
source files without artist confirmation.

## Godot Integration Notes

Installed local validation editor:

```text
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe
```

This is the official Spine-enabled Godot `4.1.3.stable.custom_build` editor
downloaded from Esoteric Software's spine-godot builds for the `4.1` runtime
series.

Recommended import target once a Godot project exists:

```text
res://assets/spine/backgrounds/<variant>/<variant>.skel.bytes
res://assets/spine/backgrounds/<variant>/<variant>.atlas.txt
res://assets/spine/backgrounds/<variant>/<variant>.png
```

Implementation requirements:

- Install or build a Godot Spine integration that supports Spine `4.1.x`.
- Keep each `.skel.bytes`, `.atlas.txt`, and `.png` file together in the same
  folder so atlas texture references stay valid.
- In the Godot project, use `.skel` and `.atlas` file extensions. The current
  probe project copies the source files and renames only the copied extensions.
- Configure the animation track to loop for background playback.
- Re-export the atlases with premultiplied alpha disabled before production
  use. Official spine-godot documentation states PMA atlases are not currently
  supported, while these source atlases declare `pma:true`.
- Treat each variant as a full-screen animated background selected by mood and
  time/weather state.

Suggested runtime selection keys:

- `mood`: `good`, `normal`, `troubled`
- `time`: `day`, `night`, `sunfall`, `cloudy`
- `loop`: always `true`

See `manifest.json` in this folder for machine-readable paths and selection
metadata.
