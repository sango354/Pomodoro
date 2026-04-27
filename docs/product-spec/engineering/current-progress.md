# Current Development Progress

Last updated: 2026-04-27

This document records the current implementation state so work can continue
from another machine without relying on chat history.

## Repository State

- Active Godot project: `game/`
- Main scene: `res://scenes/main.tscn`
- Spine probe scene kept for validation: `res://scenes/spine_background_probe.tscn`
- Latest localization/options spec:
  `docs/product-spec/systems/07-localization-and-options.md`
- Spine-enabled Godot editor expected locally:

```powershell
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe
```

Open project:

```powershell
E:\ProjectPomodoro\scripts\open-godot-spine.ps1
```

Headless validation:

```powershell
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\ProjectPomodoro\game --quit
```

## Implemented Prototype Scope

The current prototype targets the M1 core loop from the roadmap.

Headless validation passed locally with the Spine-enabled Godot
`4.1.3.stable.custom_build` editor:

```powershell
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\ProjectPomodoro\game --quit
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\ProjectPomodoro\game res://scenes/spine_background_probe.tscn --quit
```

Implemented:

- Spine background loading through the Spine-enabled Godot 4.1.3 editor.
- Main Pomodoro scene with edge HUD layout.
- Focus timer with `Start` / `Pause` / `Resume` sharing one primary button.
- Timer rail uses icon-only Settings and Reset buttons beside the primary
  `Start` / `Pause` / `Resume` button.
- Reset restores the focus timer to the current Settings focus duration and
  returns the timer to idle.
- Timer settings panel for focus duration, break duration, auto restart, and
  alarm.
- Focus and break duration controls step by one minute.
- Auto restart and alarm use switch-style controls with `on` / `off` tooltips.
- Focus completion always starts the break countdown. Auto restart only controls
  whether the next focus session starts automatically after break completion.
- Alarm playback is implemented behind an `Alarm` switch with a silent
  placeholder file at `game/assets/sfx/alarm_placeholder.wav`.
- Settings panel is positioned immediately left of the timer rail with a small
  gap.
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
- Bottom music controls use icon-only buttons for list, previous, play/pause,
  next, loop, and ambience.
- Loop off is shown with a gray overlay on the loop icon.
- Music playback auto-starts the last played track, or the first scanned track
  when there is no saved track.
- `main_game.gd` has started being split into focused scripts:
  - `save_data_service.gd`
  - `task_service.gd`
  - `progression_service.gd`
  - `spine_background_controller.gd`
  - `companion_dialogue_service.gd`
  - `music_player_controller.gd`
  - `companion_panel_controller.gd`
  - `timer_rail_controller.gd`
  - `timer_session_service.gd`
  - `timer_settings_controller.gd`
  - `localization_service.gd`
  - `option_panel_controller.gd`
- Localization table created at `game/data/localization.csv`.
  - Columns are open for English, Traditional Chinese, Simplified Chinese,
    Japanese, Korean, French, German, Italian, Russian, Spanish-Spain, and
    Portuguese-Brazil.
  - English and Traditional Chinese values are filled for current game UI text.
  - Other language columns are currently placeholders.
- Top-right Option button opens an option panel with language switching.
- Current language is saved under `app_settings.language` in `user://save.json`.
- To edit UI text, update `game/data/localization.csv` and restart the game.
- Break dialogue entries in `game/data/dialogue_defs.json` now include
  `text_key` values that resolve through the localization table.
- M2 companion interaction has a first break-panel prototype:
  - Break countdown shows a companion dialogue panel.
  - Dialogue content is loaded from `game/data/dialogue_defs.json`.
  - Break panel supports cycling to the next line and skipping the panel.
- Music folder scanning from `res://assets/music`.
- MP3 fallback loading via `AudioStreamMP3` when imported resources are unavailable.

## Current UI Layout

- Top-right: compact icon HUD.
  - `FP`: Focus Points tooltip.
  - `LV`: Focus Level / XP tooltip.
  - `BD`: Bond tooltip.
  - `UL`: Unlocks placeholder.
  - `ST`: Stats toggle.
  - `OP`: opens Options.
- Options panel:
  - Currently contains language switching with previous/next arrow buttons.
  - Language switching updates the main UI labels/tooltips immediately.
- Top-left: Tasks.
  - Title and `+` button are aligned.
  - No global task input field.
  - Each task has its own checkbox, editable text field, and delete/archive button.
- Right side: narrow Pomodoro timer rail.
  - Focus state.
- Focus time display. White means running; gray means inactive or paused.
- Break time display. White means running; gray means inactive or paused.
  - No progress bar.
  - Icon Settings button on the left of the primary action.
  - Primary Start/Pause/Resume button in the center.
  - Icon Reset button on the right of the primary action.
- Timer Settings popup:
  - Positioned left of the timer rail.
  - Focus duration and break duration use `-` / `+` controls in one-minute
    steps.
  - Auto restart and Alarm switches align with the duration controls.
- Break companion panel:
  - Appears when break countdown starts.
  - Displays data-driven break dialogue.
  - Can be skipped without stopping the break timer.
- Bottom: music player bar.
  - Left: music list button and current track title.
  - Middle-left: previous, play/pause, next, loop, and volume slider.
  - Right: ambience button.
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

Music UI icon assets are stored in:

```text
game/assets/icons/
```

The current icon set includes list, previous, musicplay, musicpause, next,
loop, ambience, reset, and settings PNG assets.

The saved game payload includes `music_state` for current track, loop state,
and volume.

## Localization And Options

Runtime files:

```text
game/data/localization.csv
game/data/dialogue_defs.json
game/scripts/localization_service.gd
game/scripts/option_panel_controller.gd
docs/product-spec/systems/07-localization-and-options.md
```

Localization table columns:

```text
key,en,zh_TW,zh_CN,ja,ko,fr,de,it,ru,es_ES,pt_BR
```

Current state:

- English and Traditional Chinese are filled for active scripted UI text.
- Empty language cells fall back to English.
- The selected language is saved as `app_settings.language` in
  `user://save.json`.
- The top-right `OP` button opens the Options panel.
- Options currently contain language previous/next switching only.

When changing visible text:

- Edit `game/data/localization.csv`.
- Keep localization keys stable.
- Preserve placeholders such as `{time}`, `{focus_points}`, `{xp}`, and
  `{bond}`.
- Restart the game after editing the CSV.

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

- UI is still generated from scripts, but the timer rail, music player, break
  companion panel, Spine background, save data, task, and progression logic have
  been split out of `game/scripts/main_game.gd`.
- Remaining `main_game.gd` responsibilities are still broad: scene assembly,
  session completion/reward coordination, result popup, task list UI, and
  high-level controller wiring.
- Task editing uses a display truncation helper instead of a native LineEdit
  ellipsis mode because Godot 4.1 `LineEdit` does not expose
  `text_overrun_behavior`.
- Result rewards are prototype-level and not yet fully idempotent across all
  edge cases.
- Auto restart and alarm are prototype-level local settings saved in
  `user://save.json`; they are not yet backed by content/config data.
- Alarm currently uses a silent placeholder audio file until final SFX is
  supplied.
- `UL` unlocks is a placeholder.
- `ST` only toggles a compact stats text display.
- No real inventory, unlock, mission, achievement, or companion dialogue system
  is implemented yet.
- No export presets are configured.
- Music playback should still be manually tested with real local audio files
  after pulling on another machine.
- Localization currently covers the active scripted UI and break dialogue keys,
  but needs manual UI review for text length in every target language once those
  translations are filled.

## Next Recommended Work

1. Manually verify the refactored UI in the Godot editor, especially timer rail,
   bottom music controls, and the break companion panel.
2. Continue splitting `main_game.gd`:
   - task list controller
   - result panel controller
   - session result/reward coordinator
3. Expand M2 companion interaction:
   - add context/Bond filtering for dialogue entries
   - emit viewed/skipped events
   - add more break interaction content
4. Add lightweight content data files for unlocks and music metadata.
5. Fill remaining localization columns and review UI fit for each language.
6. Add manual QA checklist for:
   - session start/pause/resume/reset
   - completed/partial/abandoned rewards
   - task rename persistence
   - result popup dismissal
   - music list/playback/loop/volume
   - Spine background switching by mood/time
   - break panel show/next/skip behavior
   - auto restart after break completion

## Latest Validation

2026-04-27:

- Split timer rail UI into `game/scripts/timer_rail_controller.gd`.
- Split timer settings popup into `game/scripts/timer_settings_controller.gd`.
- Split timer/session state transitions into
  `game/scripts/timer_session_service.gd`.
- Split bottom music player UI/playback into
  `game/scripts/music_player_controller.gd`.
- Split M2 break companion panel into
  `game/scripts/companion_panel_controller.gd`.
- Added immediate music state saving through `MusicPlayerController.state_changed`.
- `game/scripts/main_game.gd` no longer directly references timer rail labels or
  timer rail buttons.
- `game/scripts/main_game.gd` no longer builds Timer Settings controls directly.
- Added `game/data/localization.csv` and `game/scripts/localization_service.gd`.
- Added `game/scripts/option_panel_controller.gd` with language previous/next
  controls.
- Added localization keys to break dialogue data.
- Headless validation passed:

```powershell
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\ProjectPomodoro\game --quit
```

## Git Notes

Latest pushed commit known from this work session:

```text
28cb1a5 Add Godot pomodoro prototype with Spine assets
```

There may be local changes after that commit, especially in:

- `game/scripts/main_game.gd`
- `game/scripts/localization_service.gd`
- `game/scripts/option_panel_controller.gd`
- `game/data/localization.csv`
- `game/data/dialogue_defs.json`
- `game/assets/music/`
- `docs/product-spec/engineering/current-progress.md`
- `docs/product-spec/systems/07-localization-and-options.md`

Files that are expected to exist locally for the current prototype:

- `game/scripts/save_data_service.gd`
- `game/scripts/task_service.gd`
- `game/scripts/progression_service.gd`
- `game/scripts/spine_background_controller.gd`
- `game/scripts/companion_dialogue_service.gd`
- `game/scripts/companion_panel_controller.gd`
- `game/scripts/music_player_controller.gd`
- `game/scripts/timer_rail_controller.gd`
- `game/scripts/timer_session_service.gd`
- `game/scripts/timer_settings_controller.gd`
- `game/scripts/localization_service.gd`
- `game/scripts/option_panel_controller.gd`
- `game/data/dialogue_defs.json`
- `game/data/localization.csv`

Before moving machines, run:

```powershell
git status --short
git diff --stat
```

Then commit and push only the intended changes.
