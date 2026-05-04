extends SceneTree

const MissionAchievementService = preload("res://scripts/mission_achievement_service.gd")


func _init() -> void:
	var mission_defs := MissionAchievementService.load_mission_defs()
	var achievement_defs := MissionAchievementService.load_achievement_defs()
	var daily_missions := []
	var user_achievements := []
	var currencies := {"focus_points": 0, "bond_points_total": 0}
	var level_progress := {"focus_level": 1, "focus_xp": 0, "focus_xp_lifetime": 0}
	var bond_progress := {"character_id": "companion_01", "bond_level": 1, "bond_points_current": 0, "bond_points_lifetime": 0}
	var stats := {
		"completed_sessions": 1,
		"partial_sessions": 0,
		"focus_minutes_total": 25,
		"tasks_completed": 2,
		"unlocked_count": 0,
		"focus_level": 1,
		"bond_level": 1
	}

	MissionAchievementService.refresh_daily_missions(mission_defs, daily_missions, stats, "2026-05-04")
	_assert(_count_status(daily_missions, "claimable") == 3, "Expected three claimable daily missions.")

	var claim := MissionAchievementService.claim_mission("daily_complete_session", mission_defs, daily_missions, currencies, level_progress, bond_progress)
	_assert(bool(claim.get("changed", false)), "Expected mission claim to change state.")
	_assert(int(currencies.get("focus_points", 0)) == int(claim.get("focus_points", 0)), "Mission reward was not granted.")
	var claim_again := MissionAchievementService.claim_mission("daily_complete_session", mission_defs, daily_missions, currencies, level_progress, bond_progress)
	_assert(not bool(claim_again.get("changed", false)), "Claimed mission should not be claimable again.")

	var unlocked := MissionAchievementService.refresh_achievements(achievement_defs, user_achievements, stats, currencies, level_progress, bond_progress)
	_assert(unlocked.has("ach_first_session"), "First session achievement should unlock.")
	var focus_points_after := int(currencies.get("focus_points", 0))
	var unlocked_again := MissionAchievementService.refresh_achievements(achievement_defs, user_achievements, stats, currencies, level_progress, bond_progress)
	_assert(unlocked_again.is_empty(), "Unlocked achievements should not unlock twice.")
	_assert(int(currencies.get("focus_points", 0)) == focus_points_after, "Achievement reward should not be granted twice.")

	print("Mission and achievement probe passed.")
	quit(0)


func _count_status(items: Array, status: String) -> int:
	var count := 0
	for item in items:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("status", "")) == status:
			count += 1
	return count


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	print("Mission and achievement probe failed: %s" % message)
	quit(1)
