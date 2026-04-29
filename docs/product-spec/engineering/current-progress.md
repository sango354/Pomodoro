# Current Development Progress

Last updated: 2026-04-28

This document records the current implementation state so work can continue
from another machine without relying on chat history.

## Repository State

- Active Godot project: `game/`
- Main scene: `res://scenes/main.tscn`
- Spine probe scene kept for validation: `res://scenes/spine_background_probe.tscn`
- Latest localization/options spec:
  `docs/product-spec/systems/07-localization-and-options.md`
- Spine-enabled Godot editor expected locally:

Project root paths differ between development machines. Existing examples may
use `E:\ProjectPomodoro`; the current checkout may instead be `E:\Pomodoro`.
Use the same relative paths under the repository root when moving between
machines.

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
- Default focus duration is 5 minutes. Timer Settings and the right-side timer
  rail both read from the same `duration_minutes` value after save data loads.
- Existing local save data can still override the default focus duration through
  `timer_settings.focus_minutes`.
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
  - `task_panel_controller.gd`
  - `result_panel_controller.gd`
  - `session_reward_coordinator.gd`
  - `break_media_controller.gd`
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
- Break dialogue runtime control fields that should later be pulled into table
  control are `dialogue_id`, `interaction_type`, `text_key`,
  `bond_requirement`, `context_requirement`, `cooldown_minutes`, `weight`, and
  `is_active`.
- Break media runtime control fields that should later remain data-driven are
  `media_id`, `path`, `enabled`, `bond_requirement`, `context_requirement`,
  playback mode, and fallback behavior.
- M2 companion interaction has a first break-panel prototype:
  - Break countdown shows a companion dialogue panel.
  - Dialogue content is loaded from `game/data/dialogue_defs.json`.
  - Dialogue selection now filters by Bond and current context.
  - Dialogue entries support `bond_requirement`, `context_requirement`,
    `cooldown_minutes`, `weight`, and `is_active`.
  - Dialogue cooldowns are enforced from local `interaction_history`; if every
    matching line is still cooling down, Break falls back to the matching pool
    instead of showing no dialogue.
  - Break panel supports cycling to the next line and skipping the panel.
  - Break panel emits viewed, skipped, and advanced events. Advanced selection
    avoids choosing the same dialogue again when another valid line exists.
  - Interaction events are saved locally in `interaction_history`.
  - Bond level-up is recorded as an interaction event and shown in the session
    result summary.
  - Ambient companion prompts now appear at low frequency during idle/focus.
    They reuse the same Bond/context/cooldown/weight dialogue selection path as
    Break dialogue.
  - Ambient prompt events are saved as `ambient_prompt_shown` and
    `ambient_prompt_dismissed`.
  - Options can toggle Break media playback during Break countdown.
  - Break media uses `app_settings.break_media_enabled` and
    `app_settings.break_media_path`.
  - If the configured video is missing or unsupported, Break falls back to the
    text companion panel without interrupting the timer.
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
  - Contains a Break Video switch for Break media playback.
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
  - Dialogue is filtered by Bond and context.
  - Can be skipped without stopping the break timer.
- Break media:
  - If enabled and the configured path loads, a `VideoStreamPlayer` appears
    during Break countdown.
  - The video plays once, then closes automatically.
  - Runtime accepts `.ogv` and `.mp4` paths; `.ogv` is validated in the current
    Godot Spine build, while `.mp4` depends on runtime/importer support.
  - If disabled or loading fails, the text Break companion panel is shown.
  - A default prototype video asset exists at
    `res://assets/videos/break/video.mp4`.
- Bottom: music player bar.
  - Left: music list button and current track title.
  - Middle-left: previous, play/pause, next, loop, and volume slider.
  - Right: ambience button.
- Center: reserved for Spine background and character.
- Ambient companion prompt:
  - Appears as a small, dismissible companion text panel during idle/focus.
  - First idle prompt appears after about 20 seconds so the feature is visible
    during QA.
  - After the first idle prompt, cadence is every 3 minutes while idle and every
    8 minutes during focus.
  - Prompt auto-hides after 8 seconds.
  - It does not appear during Break countdown.

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
- Options currently contain language previous/next switching and Break Video
  on/off.
- Break media playback during Break countdown is implemented behind the Break
  Video switch. The default path is `res://assets/videos/break/video.mp4`.
- Changing the Break Video switch during an active Break countdown only updates
  the saved setting. It does not start or stop the currently active Break media
  or text Break panel.

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
  session flow coordination, progress HUD, save/load, and high-level controller
  wiring.
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
- Break media playback has a simple prototype `.ogv` video asset. A final
  production video can replace `game/assets/videos/break/video.mp4` or use a
  supported `.mp4` path if the target Godot build supports it.
- Break media path selection is not exposed in Options yet.
- No export presets are configured.
- Music playback should still be manually tested with real local audio files
  after pulling on another machine.
- Localization currently covers the active scripted UI and break dialogue keys,
  but needs manual UI review for text length in every target language once those
  translations are filled.

## Next Recommended Work

If work resumes on another machine and the next step is unclear, start from the
ambient prompt QA pass. The minimal ambient prompt implementation is already in
place: it appears during idle/focus, uses the shared Bond/context/cooldown/weight
dialogue selector, records `ambient_prompt_shown` /
`ambient_prompt_dismissed`, can be dismissed, auto-hides after 8 seconds, and
does not appear during Break. The recommended next action is to run the project
in the Godot windowed editor/player and manually verify ambient prompt position
and cadence, confirming it does not cover Tasks, the timer rail, the music bar,
Break dialogue, or Break video UI.

1. Manually verify the refactored UI in the Godot editor, especially timer rail,
   bottom music controls, and the break companion panel.
2. Continue M2 companion interaction:
  - manually verify ambient prompt timing and placement in the Godot editor
   - confirm the first idle prompt appears around 20 seconds after startup, then
     returns to low-frequency idle cadence
   - decide whether ambient prompt cadence should become an Options setting
   - replace the prototype Break video with production art if needed
   - manually verify Break Video playback with a supported Godot video format
   - add optional Break media path selection later if needed
3. Add lightweight content data files for unlocks and music metadata.
4. Fill remaining localization columns and review UI fit for each language.
5. Add manual QA checklist for:
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
- Split task list UI into `game/scripts/task_panel_controller.gd`.
- Split result popup UI into `game/scripts/result_panel_controller.gd`.
- Split session reward/stat summary coordination into
  `game/scripts/session_reward_coordinator.gd`.
- Added Break media playback requirement to the system specs. This is not yet
  implemented in runtime.
- Headless validation passed:

```powershell
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\ProjectPomodoro\game --quit
```

2026-04-28:

- Added Bond/context filtering for Break dialogue.
- Expanded Break dialogue content to 20 entries with English and Traditional
  Chinese localization keys.
- Added Break interaction viewed/skipped/advanced signals.
- Added local `interaction_history` persistence for Break interaction events.
- Enforced Break dialogue cooldowns from `interaction_history`.
- Updated Break Next behavior so it avoids repeating the same dialogue when a
  different eligible line exists.
- Added Bond level-up result text and `bond_level_up` interaction event.
- Added low-frequency ambient companion prompts for idle/focus.
- Added ambient dialogue content, localization keys, and
  `ambient_prompt_shown` / `ambient_prompt_dismissed` events.
- Added `game/scripts/break_media_controller.gd`.
- Added Break Video switch to Options.
- Added `app_settings.break_media_enabled` and
  `app_settings.break_media_path` persistence.
- Added prototype Break video asset at `game/assets/videos/break/video.mp4`.
- Added `game/scripts/break_media_probe.gd` for video resource validation.
- Break media attempts playback during Break countdown, closes after one play,
  and falls back to text interaction when the configured video is missing or
  unsupported.
- Updated Break Video option behavior: toggling it during an active Break no
  longer starts or stops Break media immediately. The setting applies from the
  next Break.
- Headless validation passed on the current `E:\Pomodoro` checkout:

```powershell
E:\Pomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\Pomodoro\game --quit
E:\Pomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\Pomodoro\game --script res://scripts/break_media_probe.gd
```

## Git Notes

Latest pushed commit known from this work session:

```text
94add43 新增功能並拆分code
```

There may be local changes after that commit, especially in:

- `game/scripts/main_game.gd`
- `game/scripts/localization_service.gd`
- `game/scripts/option_panel_controller.gd`
- `game/scripts/break_media_controller.gd`
- `game/scripts/break_media_probe.gd`
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
- `game/scripts/task_panel_controller.gd`
- `game/scripts/result_panel_controller.gd`
- `game/scripts/session_reward_coordinator.gd`
- `game/scripts/break_media_controller.gd`
- `game/scripts/break_media_probe.gd`
- `game/data/dialogue_defs.json`
- `game/data/localization.csv`
- `game/assets/videos/break/video.mp4`
- `game/assets/videos/break/video.ogv`

2026-04-29 remote-work check on `E:\ProjectPomodoro`:

- Confirmed the current checkout contains the 2026-04-28 M2 companion and Break
  media work.
- Confirmed `game/assets/videos/break/video.mp4` and
  `game/assets/videos/break/video.ogv` both exist locally.
- Headless validation passed:

```powershell
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\ProjectPomodoro\game --quit
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\ProjectPomodoro\game res://scenes/spine_background_probe.tscn --quit
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\ProjectPomodoro\game --script res://scripts/break_media_probe.gd
```

Before moving machines, run:

```powershell
git status --short
git diff --stat
```

Then commit and push only the intended changes.
