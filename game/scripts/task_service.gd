extends RefCounted


static func create_task(tasks: Array, title: String) -> Dictionary:
	title = title.strip_edges()
	if title == "":
		return {}
	return {
		"task_id": "task_%s" % Time.get_unix_time_from_system(),
		"user_id": "local_user",
		"title": title,
		"description": "",
		"status": "todo",
		"sort_order": tasks.size(),
		"created_at": Time.get_datetime_string_from_system(false, true),
		"updated_at": Time.get_datetime_string_from_system(false, true),
		"completed_at": ""
	}


static func set_task_status(tasks: Array, task_id: String, status: String) -> bool:
	for task in tasks:
		if task.task_id == task_id:
			task.status = status
			task.updated_at = Time.get_datetime_string_from_system(false, true)
			if status == "done":
				task.completed_at = Time.get_datetime_string_from_system(false, true)
			return true
	return false


static func selected_task_id(tasks: Array) -> String:
	for task in tasks:
		if task.status == "todo" or task.status == "in_progress":
			return str(task.task_id)
	return ""


static func task_title(tasks: Array, task_id: String) -> String:
	for task in tasks:
		if task.task_id == task_id:
			return task.title
	return ""


static func task_status(tasks: Array, task_id: String) -> String:
	for task in tasks:
		if task.task_id == task_id:
			return task.status
	return ""


static func rename_task(tasks: Array, new_title: String, task_id: String, fallback_title: String = "Type Here") -> String:
	new_title = new_title.strip_edges()
	if new_title == "":
		new_title = fallback_title
	for task in tasks:
		if task.task_id == task_id:
			task.title = new_title
			task.updated_at = Time.get_datetime_string_from_system(false, true)
			return new_title
	return new_title
