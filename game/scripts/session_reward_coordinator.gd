extends RefCounted

const ProgressionService = preload("res://scripts/progression_service.gd")
const TaskService = preload("res://scripts/task_service.gd")


static func grant_session_rewards(
	session_mode: String,
	status: String,
	actual_sec: int,
	planned_duration_sec: int,
	currencies: Dictionary,
	level_progress: Dictionary,
	bond_progress: Dictionary,
	min_rewardable_session_sec: int,
	base_focus_points: int,
	base_bond: int,
	base_xp: int
) -> Dictionary:
	return ProgressionService.grant_session_rewards(
		session_mode,
		status,
		actual_sec,
		planned_duration_sec,
		currencies,
		level_progress,
		bond_progress,
		min_rewardable_session_sec,
		base_focus_points,
		base_bond,
		base_xp
	)


static func apply_task_completion_bonus(
	tasks: Array,
	task_id: String,
	currencies: Dictionary,
	level_progress: Dictionary,
	daily_stats: Dictionary,
	focus_points_bonus: int,
	xp_bonus: int,
	localizer
) -> Dictionary:
	if task_id == "":
		return {"changed": false, "summary": ""}
	if not TaskService.set_task_status(tasks, task_id, "done"):
		return {"changed": false, "summary": ""}
	currencies.focus_points += focus_points_bonus
	ProgressionService.add_xp(level_progress, xp_bonus)
	daily_stats.tasks_completed += 1
	return {
		"changed": true,
		"summary": localizer.trf("result.task_bonus", {
			"focus_points": focus_points_bonus,
			"xp": xp_bonus
		}) if localizer != null else "+%d Focus Points  +%d XP" % [focus_points_bonus, xp_bonus]
	}


static func update_focus_stats(daily_stats: Dictionary, session_mode: String, status: String, actual_sec: int) -> void:
	if session_mode != "focus":
		return
	var minutes := int(round(actual_sec / 60.0))
	if status == "completed":
		daily_stats.completed_sessions += 1
		daily_stats.focus_minutes_completed += minutes
	elif status == "partial":
		daily_stats.partial_sessions += 1
		daily_stats.focus_minutes_partial += minutes


static func reward_summary(localizer, rewards: Dictionary) -> String:
	if not bool(rewards.get("rewardable", false)):
		return localizer.translate("result.no_reward") if localizer != null else "No reward."
	if localizer != null:
		return localizer.trf("result.reward_summary", {
			"focus_points": int(rewards.get("focus_points", 0)),
			"xp": int(rewards.get("xp", 0)),
			"bond": int(rewards.get("bond", 0))
		})
	return "+%d Focus Points  +%d XP  +%d Bond" % [
		int(rewards.get("focus_points", 0)),
		int(rewards.get("xp", 0)),
		int(rewards.get("bond", 0))
	]
