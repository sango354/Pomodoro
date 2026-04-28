# 系統規格 04：角色陪伴互動系統

## 1. 目的

角色系統負責建立情感陪伴與產品差異化。它應該讓使用者感到被陪伴，但不能打斷工作。

## 2. 設計目標

- 角色應降低孤單感，而非增加負擔
- 互動主軸應以休息時段為主，而非工作中打擾
- 角色成長應綁定穩定使用，而非刷行為漏洞

## 3. 範圍

### 3.1 納入範圍

- 單一陪伴角色
- 專注時的待機存在
- 低頻環境反應
- 休息互動片段
- Break 期間播放指定本機路徑影片
- Bond 成長
- 對時間 / 天氣的情境反應

### 3.2 不納入範圍

- 分支式劇情路線
- 完整戀愛模擬
- 必要配音需求
- 多角色同時陪伴

## 4. 互動類型

| 類型 | 說明 |
| --- | --- |
| ambient idle | 專注時的存在感與待機表現 |
| light prompt | 長時間 session 中低頻文字或動作反應 |
| break interaction | session 結束後的互動片段 |
| break media | 休息期間播放指定本機路徑的短影片，可由 Options 開關 |
| bond event | 關係里程碑解鎖的特殊互動 |
| context reaction | 對白天 / 夜晚 / 天氣的不同反應 |

## 5. 功能需求

| ID | 需求 | 優先級 |
| --- | --- | --- |
| CI-001 | 主畫面與 session 畫面需顯示角色 | P0 |
| CI-002 | 角色需支援專注時的 ambient 狀態 | P0 |
| CI-003 | 結算畫面可觸發休息互動片段 | P0 |
| CI-004 | 完成 session 會累積 Bond | P0 |
| CI-005 | Bond 里程碑可解鎖對話與事件 | P1 |
| CI-006 | 角色支援依時間 / 天氣切換反應 | P1 |
| CI-007 | 提示頻率需受限制，避免打擾 | P0 |
| CI-008 | Break 期間可播放指定本機路徑影片作為休息陪伴媒體 | P1 |
| CI-009 | 使用者可在 Options 中開關 Break 影片播放 | P1 |

### 5.1 目前 Godot 原型狀態

- Break countdown 開始時會顯示一個 companion break panel。
- Panel 目前顯示純文字休息互動台詞。
- 台詞資料來源為 `game/data/dialogue_defs.json` 的 `break_interaction` 陣列。
- Panel 支援 `Next` 切換下一句與 `Skip` 隱藏面板。
- Skip 只隱藏互動面板，不會停止 break 倒數。
- Break dialogue 會依 Bond 與目前 context 篩選，支援
  `bond_requirement`、`context_requirement`、`weight` 與 `is_active`。
- Break panel 會發出 viewed、skipped 與 advanced 事件，原型目前記錄到本地
  `interaction_history`。
- Break media 已有原型：Break countdown 期間會在 Options 開啟時嘗試播放指定路徑影片；
  影片播放完一次後會自動關閉；影片不存在或載入失敗時會回退到純文字 Break interaction。
- 目前預設影片資產為 `res://assets/videos/break/video.mp4`。

## 6. 規則

- 專注中的提示最多每 8 到 12 分鐘一次
- 提示不可遮擋計時器控制
- 休息互動是主要情感回饋入口
- Break 影片僅在 short break / long break 期間播放，不應在 focus 期間自動播放
- Break 影片播放完一次後應停止並隱藏，不循環播放
- Break 結束、使用者跳過休息互動、或使用者關閉 Break 影片選項時，影片應停止或隱藏
- 指定影片路徑不存在、格式不支援、或載入失敗時，系統需回退到純文字休息互動，不中斷倒數
- Break media 路徑目前接受 `.ogv` 與 `.mp4`；實際能否播放仍取決於 Godot runtime / importer 支援
- Bond 進度應鼓勵穩定使用，而不是短期刷值

## 7. 狀態模型

- idle
- focus_companion
- break_interaction
- special_event
- night_variant

## 8. 內容需求

### 8.1 MVP 台詞量

- ambient 台詞：20 到 30 條
- 休息台詞：20 到 30 條
- 里程碑事件台詞：10 條
- 主要情境類型至少各有 1 組差異反應

### 8.2 內容資料欄位

- dialogue_id
- interaction_type
- bond_requirement
- context_requirement
- cooldown_rule
- weight

## 9. UI 需求

- 角色需可見但不干擾
- 休息互動需可略過
- Break 影片需可由 Options 關閉；關閉後不應佔用主要 UI 空間
- Bond 升級需有清楚提示
- 互動紀錄檔可留到 MVP 後再做

## 10. 分析事件

- `break_interaction_viewed`
- `break_interaction_skipped`
- `bond_progressed`
- `ambient_prompt_shown`
- `ambient_prompt_dismissed`

## 11. 依賴

- 成長與回饋系統
- 情境 / 內容系統
- Session 結算畫面

## 12. Current Prototype Rules

- Break dialogue is loaded from `game/data/dialogue_defs.json`.
- Break dialogue selection filters by Bond level, context, active state, and
  cooldown.
- Ambient dialogue is loaded from the same file under the `ambient` section and
  uses the same Bond level, context, active state, cooldown, and weight rules.
- Ambient prompts appear during idle/focus at low frequency, can be dismissed,
  and auto-hide after a short duration. They do not appear during Break.
- Cooldown is evaluated from local `interaction_history` viewed events. If every
  matching dialogue is cooling down, the system falls back to the matching pool
  so the Break panel still has content.
- Break Next records `break_interaction_advanced` with the previous and next
  dialogue IDs and avoids repeating the same dialogue when another valid line
  exists.
- Bond level-up records `bond_level_up` in `interaction_history` and appends a
  line to the session result summary.
- Break video is controlled by Options, plays once, closes automatically, and
  falls back to Break dialogue if playback fails.
- Runtime accepts `.ogv` and `.mp4` paths. In the current Godot Spine build,
  `.mp4` uses a same-name `.ogv` sidecar fallback for playback.

Future table-control fields:

- Dialogue: `dialogue_id`, `interaction_type`, `text_key`,
  `bond_requirement`, `context_requirement`, `cooldown_minutes`, `weight`,
  `is_active`.
- Break media: `media_id`, `path`, `enabled`, `bond_requirement`,
  `context_requirement`, `play_once`, `fallback_behavior`.

Remote handoff note:

- Minimal ambient prompt is implemented. When resuming work on another machine,
  first run the project in Godot windowed mode and verify ambient prompt timing
  and placement. Confirm the prompt does not cover Tasks, the timer rail, the
  music bar, Break dialogue, or Break video UI before tuning cadence or adding
  more content.
