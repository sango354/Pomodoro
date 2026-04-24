# Pomodoro Godot Project

This is the working Godot project for the Pomodoro game. The original Spine
probe scene is kept at `res://scenes/spine_background_probe.tscn`.

Use this editor:

```powershell
E:\Pomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --path E:\Pomodoro\game
```

Or run:

```powershell
E:\Pomodoro\scripts\open-godot-spine.ps1
```

The main scene is:

```text
res://scenes/main.tscn
```

The project stores prepared copies of the source Spine exports under:

```text
res://assets/spine/backgrounds/<variant>/<variant>.skel
res://assets/spine/backgrounds/<variant>/<variant>.atlas
res://assets/spine/backgrounds/<variant>/<variant>.png
```

The source files in `docs/product-spec/ArtResource/Spine` are left untouched.
The `.skel.bytes` and `.atlas.txt` files are copied into this project with the
`.skel` and `.atlas` extensions expected by spine-godot.

Important: the current atlas files contain `pma:true`. Official spine-godot
documentation says premultiplied alpha atlases are not currently supported.
These assets should be re-exported from Spine 4.1.x with premultiplied alpha
disabled for production use in Godot.

Verification performed:

```powershell
E:\Pomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\Pomodoro\game --quit
```

Expected output includes:

```text
SpineSprite: true
SpineSkeletonFileResource: true
SpineAtlasResource: true
SpineSkeletonDataResource: true
Skeleton resource loaded: true
Atlas resource loaded: true
SpineSprite instantiated: true
```

The MVP game scene currently covers the M1 loop from the product spec:

- Start a focus session.
- Pause, resume, or end early.
- Bind one local task to the current session.
- Classify results as completed, partial, or abandoned.
- Grant Focus Points, XP, and Bond when rewardable.
- Save local tasks, sessions, progress, and stats to `user://save.json`.
