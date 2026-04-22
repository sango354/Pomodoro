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

## 6. 規則

- 專注中的提示最多每 8 到 12 分鐘一次
- 提示不可遮擋計時器控制
- 休息互動是主要情感回饋入口
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
