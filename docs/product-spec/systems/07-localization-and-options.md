# System 07: Localization and Options

Last updated: 2026-04-27

This document records the current localization and options-menu implementation
for handoff between machines.

## Scope

The game now supports a lightweight scripted localization layer for UI text and
break companion dialogue. The first Options panel is implemented in the
top-right HUD and currently exposes language switching.

## Localization Table

Runtime table:

```text
game/data/localization.csv
```

Current columns:

```text
key,en,zh_TW,zh_CN,ja,ko,fr,de,it,ru,es_ES,pt_BR
```

Language meaning:

- `en`: English
- `zh_TW`: Traditional Chinese
- `zh_CN`: Simplified Chinese
- `ja`: Japanese
- `ko`: Korean
- `fr`: French
- `de`: German
- `it`: Italian
- `ru`: Russian
- `es_ES`: Spanish - Spain
- `pt_BR`: Portuguese - Brazil

Current content status:

- English and Traditional Chinese are filled for active scripted UI text.
- Other language columns are intentionally open but mostly empty.
- Empty translations fall back to English at runtime.

## Editing Text

To change displayed text, edit `game/data/localization.csv`.

Example:

```csv
timer.start,Start,開始,,,,,,,,,
settings.title,Timer Settings,計時器設定,,,,,,,,,
```

Rules:

- Keep the `key` unchanged unless the code is also updated.
- Preserve placeholder names inside braces.
- Examples of placeholders:
  - `{time}`
  - `{focus_points}`
  - `{xp}`
  - `{bond}`
- The current implementation loads the CSV when the game starts, so restart the
  game after editing the CSV.

## Runtime Services

Scripts:

```text
game/scripts/localization_service.gd
game/scripts/option_panel_controller.gd
```

`LocalizationService` responsibilities:

- Load `game/data/localization.csv`.
- Track the active language.
- Provide `translate(key)` and `trf(key, values)`.
- Fall back to English when the active language value is empty.
- Cycle through supported language codes.

`OptionPanelController` responsibilities:

- Add the top-right `OP` option button.
- Display the Options panel.
- Display the current language name.
- Emit previous/next language requests.

## Saved State

The selected language is saved in:

```text
user://save.json
```

Payload path:

```json
{
  "app_settings": {
    "language": "en"
  }
}
```

Supported values currently match the CSV columns:

```text
en, zh_TW, zh_CN, ja, ko, fr, de, it, ru, es_ES, pt_BR
```

## Current UI Behavior

- The top-right HUD contains an `OP` button.
- Clicking `OP` opens the Options panel.
- The panel currently contains:
  - Language label
  - Previous language arrow
  - Current language display
  - Next language arrow
- Switching language updates visible labels/tooltips immediately.
- The selected language is saved immediately.

## Localized Areas

Currently wired:

- Top HUD tooltips
- Task panel title and add/archive tooltips
- Timer rail labels and primary button text
- Timer Settings panel labels and switch tooltips
- Result panel buttons and result status text
- Reward summary and task bonus text
- Bottom music player tooltips and list panel empty states
- Break companion panel title/buttons
- Break companion dialogue through `text_key`
- Compact stats overlay labels
- Option button and language panel

## Dialogue Integration

Break dialogue data:

```text
game/data/dialogue_defs.json
```

Dialogue entries now support `text_key`:

```json
{
  "dialogue_id": "break_001",
  "text_key": "dialogue.break_001",
  "text": "Nice work. Look away from the screen and let your eyes rest for a moment.",
  "bond_requirement": 0,
  "context_requirement": "any"
}
```

Runtime behavior:

- `text_key` is used for localized text when present.
- `text` remains as fallback/source content.

## Known Gaps

- No hot reload for `localization.csv`; restart the game after CSV edits.
- UI has only been headless-validated. Manual visual review is still required.
- Non-English/non-Traditional-Chinese columns still need translation.
- Long translated strings may need layout tuning.
- Options panel currently only supports language switching.

## Validation

Use the Spine-enabled Godot executable:

```powershell
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\ProjectPomodoro\game --quit
E:\ProjectPomodoro\tools\godot-spine-4.1.3\godot-4.1-4.1.3-stable.exe --headless --path E:\ProjectPomodoro\game res://scenes/spine_background_probe.tscn --quit
```
