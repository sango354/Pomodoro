# Pomodoro Godot Project

This is the working Godot project for the Pomodoro game. The original Spine
probe scene is kept at `res://scenes/spine_background_probe.tscn`.

Use this editor:

```powershell
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --path E:\ProjectPomodoro\game
```

Or run:

```powershell
E:\ProjectPomodoro\scripts\open-godot-spine.ps1
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
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\ProjectPomodoro\game --quit
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
- Reset the focus timer back to the configured focus duration.
- Bind one local task to the current session.
- Classify results as completed, partial, or abandoned.
- Grant Focus Points, XP, and Bond when rewardable.
- Automatically enter break countdown after each completed focus session.
- Start the next focus session after break only when Auto restart is enabled.
- Save local tasks, sessions, progress, stats, timer settings, and music state
  to `user://save.json`.
- Play music from `res://assets/music`, restoring the last played track when
  possible.

Current UI implementation notes:

- Timer controls use icon-only Settings and Reset buttons beside the primary
  Start/Pause/Resume button.
- Timer Settings supports one-minute focus/break adjustments plus Auto restart
  and Alarm switches.
- The Alarm switch currently plays a silent placeholder from
  `res://assets/sfx/alarm_placeholder.wav`.
- The bottom music bar uses icon-only controls from `res://assets/icons`.
- Loop off is represented by a gray overlay on the loop icon.

For handoff status and current implementation notes, see:

```text
E:\ProjectPomodoro\docs\product-spec\engineering\current-progress.md
```
