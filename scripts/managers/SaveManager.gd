extends Node
## Persists campaign progress, currency, tutorial flags, and shop purchases.

const SAVE_PATH: String = "user://ruins_save.json"

signal coins_changed(new_total: int)
signal save_loaded

var coins: int = 0
var completed_levels: Dictionary = {}
var unlocked_worlds: Dictionary = {"world_1": true, "world_2": false}
var haven_unlocked: bool = false
var tutorial_completed: bool = false
var tutorial_steps_done: Dictionary = {}
var purchased_shop_items: Dictionary = {}
var player_upgrades: Dictionary = {}
## Class/item ids the player currently owns this run (1 random at new-game start, more via Haven shop).
var owned_classes: Array = []

var _dirty: bool = false


func _ready() -> void:
	load_progress()


func mark_dirty() -> void:
	_dirty = true


func save_progress() -> void:
	var data: Dictionary = {
		"coins": coins,
		"completed_levels": completed_levels,
		"unlocked_worlds": unlocked_worlds,
		"haven_unlocked": haven_unlocked,
		"tutorial_completed": tutorial_completed,
		"tutorial_steps_done": tutorial_steps_done,
		"purchased_shop_items": purchased_shop_items,
		"player_upgrades": player_upgrades,
		"owned_classes": owned_classes,
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: could not write %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_dirty = false


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_loaded.emit()
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		save_loaded.emit()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_apply_save_dict(parsed as Dictionary)
	save_loaded.emit()


func _apply_save_dict(data: Dictionary) -> void:
	coins = int(data.get("coins", 0))
	completed_levels = data.get("completed_levels", {}).duplicate(true)
	unlocked_worlds = data.get("unlocked_worlds", {"world_1": true, "world_2": false}).duplicate(true)
	haven_unlocked = bool(data.get("haven_unlocked", false))
	tutorial_completed = bool(data.get("tutorial_completed", false))
	tutorial_steps_done = data.get("tutorial_steps_done", {}).duplicate(true)
	purchased_shop_items = data.get("purchased_shop_items", {}).duplicate(true)
	player_upgrades = data.get("player_upgrades", {}).duplicate(true)
	owned_classes = (data.get("owned_classes", []) as Array).duplicate()


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	coins_changed.emit(coins)
	mark_dirty()


func spend_coins(amount: int) -> bool:
	if amount <= 0 or coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	mark_dirty()
	return true


func is_level_completed(level_id: String) -> bool:
	return bool(completed_levels.get(level_id, false))


func complete_level(level_id: String) -> void:
	completed_levels[level_id] = true
	mark_dirty()


func is_tutorial_step_done(step_id: String) -> bool:
	return bool(tutorial_steps_done.get(step_id, false))


func complete_tutorial_step(step_id: String) -> void:
	tutorial_steps_done[step_id] = true
	mark_dirty()


func set_tutorial_completed(value: bool = true) -> void:
	tutorial_completed = value
	mark_dirty()


func unlock_haven() -> void:
	haven_unlocked = true
	mark_dirty()


func unlock_world(world_id: String) -> void:
	unlocked_worlds[world_id] = true
	mark_dirty()


func get_owned_classes() -> Array:
	return owned_classes.duplicate()


func is_class_owned(class_id: String) -> bool:
	return owned_classes.has(class_id)


func add_owned_class(class_id: String) -> void:
	if class_id == "" or owned_classes.has(class_id):
		return
	owned_classes.append(class_id)
	mark_dirty()
	save_progress()


func set_owned_classes(ids: Array) -> void:
	owned_classes = ids.duplicate()
	mark_dirty()
	save_progress()


func reset_owned_classes_to(class_id: String) -> void:
	owned_classes = [class_id] if class_id != "" else []
	mark_dirty()
	save_progress()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _dirty:
		save_progress()
