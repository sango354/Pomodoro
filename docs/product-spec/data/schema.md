# 邏輯資料結構

## 1. 概述

本文件定義支援 MVP 與首版內容所需的邏輯資料結構，不綁定特定資料庫廠商。

## 2. 實體總覽

| 實體 | 用途 |
| --- | --- |
| `users` | 玩家檔案與進度狀態 |
| `sessions` | 專注與休息 session 歷史 |
| `tasks` | 輕量任務管理 |
| `task_session_links` | session 與任務的關聯 |
| `app_configs` | 通用系統參數設定 |
| `currencies` | 當前可消耗與成長資源 |
| `level_progress` | XP 與等級狀態 |
| `bond_progress` | 角色關係狀態 |
| `content_defs` | 資料驅動的可解鎖內容定義 |
| `user_unlocks` | 使用者已擁有內容 |
| `contexts` | 房間、天氣與環境音定義 |
| `dialogue_defs` | 角色台詞資料 |
| `event_defs` | 角色或內容事件定義 |
| `daily_missions` | 每日任務派發結果 |
| `achievement_defs` | 永久成就定義 |
| `user_achievements` | 使用者成就進度 |
| `daily_stats` | 每日彙總統計 |

## 3. 資料表

### 3.1 `users`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `user_id` | string PK | 使用者唯一 ID |
| `display_name` | string | 可為空，供訪客模式使用 |
| `created_at` | datetime | 建立時間 |
| `last_active_at` | datetime | 最後活動時間 |
| `timezone` | string | 用於任務刷新與統計 |
| `settings_json` | json | 使用者偏好設定 |

### 3.2 `sessions`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `session_id` | string PK | session 唯一 ID |
| `user_id` | string FK | 所屬使用者 |
| `mode` | enum | focus、short_break、long_break |
| `planned_duration_sec` | int | 預定秒數 |
| `actual_duration_sec` | int | 實際經過秒數 |
| `status` | enum | completed、partial、abandoned |
| `started_at` | datetime | 開始時間 |
| `ended_at` | datetime | 結束時間 |
| `linked_task_id` | string nullable FK | 綁定任務 |
| `context_id` | string nullable FK | 執行當下情境 |
| `reward_granted_at` | datetime nullable | 獎勵發放標記 |

### 3.3 `tasks`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `task_id` | string PK | 任務唯一 ID |
| `user_id` | string FK | 所屬使用者 |
| `title` | string | 必填標題 |
| `description` | text | 可選描述 |
| `status` | enum | todo、in_progress、done、archived |
| `sort_order` | int | 手動排序值 |
| `created_at` | datetime | 建立時間 |
| `updated_at` | datetime | 更新時間 |
| `completed_at` | datetime nullable | 完成時間 |

### 3.4 `task_session_links`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `task_session_link_id` | string PK | 關聯唯一 ID |
| `task_id` | string FK | 任務 ID |
| `session_id` | string FK | session ID |
| `linked_at` | datetime | 綁定時間 |

### 3.5 `app_configs`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `config_key` | string PK | 設定鍵，例如 `min_rewardable_session_sec` |
| `config_value` | string | 設定值，實際型別由應用層解析 |
| `value_type` | enum | string、int、float、bool、json |
| `description` | string | 設定用途說明 |
| `updated_at` | datetime | 最後更新時間 |

### 3.6 `currencies`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `user_id` | string PK/FK | 所屬使用者 |
| `focus_points` | int | 可消耗貨幣 |
| `bond_points_total` | int | 累積 Bond 點數 |
| `updated_at` | datetime | 最後更新時間 |

### 3.7 `level_progress`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `user_id` | string PK/FK | 所屬使用者 |
| `focus_level` | int | 當前等級 |
| `focus_xp` | int | 當前等級經驗值 |
| `focus_xp_lifetime` | int | 累積經驗值 |
| `updated_at` | datetime | 最後更新時間 |

### 3.8 `bond_progress`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `user_id` | string PK/FK | 所屬使用者 |
| `character_id` | string | 當前角色 |
| `bond_level` | int | 關係等級 |
| `bond_points_current` | int | 當前進度 |
| `bond_points_lifetime` | int | 累積 Bond 點數 |
| `last_interaction_at` | datetime nullable | 最近互動時間 |

### 3.9 `content_defs`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `content_id` | string PK | 內容唯一 ID |
| `content_type` | enum | decor、bg、collectible、pose、event |
| `name` | string | 顯示名稱 |
| `rarity` | enum nullable | 可選稀有度 |
| `unlock_type` | enum | currency、level、bond、condition、mission |
| `unlock_value` | string | 通用解鎖條件 payload |
| `price_focus_points` | int nullable | 貨幣型解鎖價格 |
| `context_tags_json` | json | 相容情境與主題標籤 |
| `is_active` | bool | 啟用開關 |

### 3.10 `user_unlocks`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `user_unlock_id` | string PK | 唯一 ID |
| `user_id` | string FK | 所屬使用者 |
| `content_id` | string FK | 內容 ID |
| `unlocked_at` | datetime | 解鎖時間 |
| `equipped` | bool | 是否已裝備 |

### 3.11 `contexts`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `context_id` | string PK | 唯一 ID |
| `room_id` | string | 房間 ID |
| `time_of_day` | enum | day、night |
| `weather` | enum | clear、rain |
| `ambience_id` | string | 環境音 ID |
| `display_name` | string | 顯示名稱 |
| `is_default` | bool | 是否預設 |

### 3.12 `dialogue_defs`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `dialogue_id` | string PK | 台詞唯一 ID |
| `character_id` | string | 所屬角色 |
| `interaction_type` | enum | ambient、break、event |
| `text` | text | 文案或在地化參照 |
| `bond_requirement` | int | 最低 Bond 要求 |
| `context_requirement_json` | json | 房間 / 時段 / 天氣條件 |
| `cooldown_minutes` | int | 最短重複間隔 |
| `weight` | int | 權重 |
| `is_active` | bool | 是否可用 |

### 3.13 `event_defs`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `event_id` | string PK | 事件唯一 ID |
| `event_type` | enum | break、milestone、context |
| `character_id` | string nullable | 對應角色，可為空 |
| `trigger_condition_json` | json | 觸發條件 |
| `reward_payload_json` | json | 可選獎勵內容 |
| `is_repeatable` | bool | 是否可重複 |
| `is_active` | bool | 是否啟用 |

### 3.14 `daily_missions`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `daily_mission_id` | string PK | 任務唯一 ID |
| `user_id` | string FK | 所屬使用者 |
| `mission_def_id` | string | 任務模板 ID |
| `local_date` | date | 使用者時區日期 |
| `progress` | int | 當前進度 |
| `target` | int | 目標值 |
| `status` | enum | active、claimable、claimed、expired |
| `reward_payload_json` | json | 任務獎勵 |

### 3.15 `achievement_defs`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `achievement_def_id` | string PK | 成就定義 ID |
| `category` | enum | sessions、tasks、streak、bond、content |
| `target_value` | int | 達成門檻 |
| `reward_payload_json` | json | 成就獎勵 |
| `is_active` | bool | 是否啟用 |

### 3.16 `user_achievements`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `user_achievement_id` | string PK | 唯一 ID |
| `user_id` | string FK | 所屬使用者 |
| `achievement_def_id` | string FK | 成就定義 |
| `progress` | int | 當前進度 |
| `status` | enum | active、unlocked、claimed |
| `updated_at` | datetime | 最後更新時間 |

### 3.17 `daily_stats`

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `user_id` | string PK part | 所屬使用者 |
| `local_date` | date PK part | 日期 bucket |
| `focus_minutes_completed` | int | completed session 分鐘數 |
| `focus_minutes_partial` | int | partial session 分鐘數 |
| `completed_sessions` | int | 完成數 |
| `partial_sessions` | int | partial 數 |
| `tasks_completed` | int | 任務完成數 |
| `favorite_context_id` | string nullable | 最常使用情境 |

## 4. 關聯

- `users` 1:N `sessions`
- `users` 1:N `tasks`
- `tasks` 預設為純本地資料，不納入跨裝置同步關聯設計
- `users` 1:1 `currencies`
- `users` 1:1 `level_progress`
- `users` 1:1 `bond_progress`
- `users` 1:N `user_unlocks`
- `users` 1:N `daily_missions`
- `users` 1:N `user_achievements`
- `sessions` N:1 `tasks`，透過 `linked_task_id` 與關聯歷史表紀錄
- `content_defs` 1:N `user_unlocks`

## 5. 實作備註

- 獎勵發放應與 `reward_granted_at` 一起處理，避免重複給獎
- 最小可得獎 session 長度等通用參數應由 `app_configs` 管理，不應散落在商業邏輯常數中
- 每日任務刷新需依使用者時區計算
- 台詞與事件應採內容資料驅動，而非硬編碼
- 任務資料於 MVP 階段以本地端持久化為主，後續若要同步，應另外定義同步邊界與衝突處理
- 統計彙總可由 sessions 與 tasks 非同步整理產生
