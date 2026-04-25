# Current Development Progress

Last updated: 2026-04-25

This document records the current implementation state so work can continue
from another machine without relying on chat history.

## Repository State

- Active Godot project: `game/`
- Main scene: `res://scenes/main.tscn`
- Spine probe scene kept for validation: `res://scenes/spine_background_probe.tscn`
- Spine-enabled Godot editor expected locally:

```powershell
E:\Pomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe
```

Open project:

```powershell
E:\Pomodoro\scripts\open-godot-spine.ps1
```

Headless validation:

```powershell
E:\Pomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\Pomodoro\game --quit
```

## Implemented Prototype Scope

The current prototype targets the M1 core loop from the roadmap.

Implemented:

- Spine background loading through the Spine-enabled Godot 4.1.3 editor.
- Main Pomodoro scene with edge HUD layout.
- Focus timer with `Start` / `Pause` / `Resume` sharing one primary button.
- Separate `Reset` button.
- Timer settings panel for focus duration and break duration.
- Settings panel positioned on the left side below Tasks to avoid the timer rail.
- Session result popup for `completed`, `partial`, and `abandoned`.
- Result popup can be dismissed by clicking anywhere outside the popup.
- Basic reward calculation for Focus Points, XP, and Bond.
- Local task list with up to 5 visible tasks.
- Task add button next to the `Tasks` title.
- New tasks default to `Type Here`.
- Task title is directly editable in-place.
- Long task titles are truncated in display form and expose full text via tooltip.
- Local persistence to `user://save.json` for tasks, sessions, progress, and stats.
- Top-right icon HUD for Focus Points, Level, Bond, Unlocks, and Stats.
- Bottom music bar with list, previous, play/pause, next, loop toggle, and volume slider.
- Music folder scanning from `res://assets/music`.
- MP3 fallback loading via `AudioStreamMP3` when imported resources are unavailable.

## Current UI Layout

- Top-right: compact icon HUD.
  - `FP`: Focus Points tooltip.
  - `LV`: Focus Level / XP tooltip.
  - `BD`: Bond tooltip.
  - `UL`: Unlocks placeholder.
  - `ST`: Stats toggle.
- Top-left: Tasks.
  - Title and `+` button are aligned.
  - No global task input field.
  - Each task has its own checkbox, editable text field, and delete/archive button.
- Right side: narrow Pomodoro timer rail.
  - Focus state.
  - Remaining focus time.
  - Break duration.
  - Progress bar.
  - Primary Start/Pause/Resume button.
  - Reset button.
  - Settings button.
- Left side below Tasks: Timer Settings popup.
- Bottom: music player bar.
- Center: reserved for Spine background and character.

## Music Assets

Music files should be placed in:

```text
game/assets/music/
```

Supported extensions:

- `.ogg`
- `.mp3`
- `.wav`

Current implementation scans the folder at startup. If MP3 files are not
imported by Godot, the player falls back to reading file bytes into
`AudioStreamMP3`.

## Spine Notes

Source Spine assets are stored at:

```text
docs/product-spec/ArtResource/Spine/
```

Godot-ready copies are stored at:

```text
game/assets/spine/backgrounds/
```

The source atlas files declare `pma:true`. Official spine-godot documentation
states premultiplied alpha atlases are not currently supported. The current
prototype can load and display the assets, but production assets should be
re-exported from Spine 4.1.x with premultiplied alpha disabled.

## Known Gaps

- UI is still generated entirely from `game/scripts/main_game.gd`; it should
  eventually be split into smaller scenes/components.
- Task editing uses a display truncation helper instead of a native LineEdit
  ellipsis mode because Godot 4.1 `LineEdit` does not expose
  `text_overrun_behavior`.
- Result rewards are prototype-level and not yet fully idempotent across all
  edge cases.
- `UL` unlocks is a placeholder.
- `ST` only toggles a compact stats text display.
- No real inventory, unlock, mission, achievement, or companion dialogue system
  is implemented yet.
- No export presets are configured.
- Music playback should still be manually tested with real local audio files
  after pulling on another machine.

## Next Recommended Work

1. Commit/push the latest UI and music-player changes after manual verification.
2. Split `main_game.gd` into focused scripts:
   - session timer service
   - task service
   - reward/progression service
   - spine background controller
   - music player controller
3. Add lightweight content data files for dialogue, unlocks, and music metadata.
4. Implement break interaction panel using companion dialogue data.
5. Add manual QA checklist for:
   - session start/pause/resume/reset
   - completed/partial/abandoned rewards
   - task rename persistence
   - result popup dismissal
   - music list/playback/loop/volume
   - Spine background switching by mood/time

## Git Notes

Latest pushed commit known from this work session:

```text
28cb1a5 Add Godot pomodoro prototype with Spine assets
```

There may be local changes after that commit, especially in:

- `game/scripts/main_game.gd`
- `game/assets/music/`
- `docs/product-spec/engineering/current-progress.md`

Before moving machines, run:

```powershell
git status --short
git diff --stat
```

Then commit and push only the intended changes.
