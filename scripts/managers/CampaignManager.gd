extends Node
## Campaign level IDs, progression, and scene routing helpers.

signal level_completed(level_id: String)
signal haven_unlocked
signal campaign_changed(level_id: String)

const LEVEL_WORLD_1_1: String = "world_1_1"
const LEVEL_WORLD_1_2: String = "world_1_2"
const LEVEL_WORLD_1_3: String = "world_1_3"
const LEVEL_HAVEN: String = "haven"
const LEVEL_WORLD_2_1: String = "world_2_1"
const LEVEL_WORLD_2_2: String = "world_2_2"
const LEVEL_WORLD_2_3: String = "world_2_3"

var WORLD_1_ORDER: PackedStringArray = PackedStringArray([
	"world_1_1", "world_1_2", "world_1_3",
])
var WORLD_2_ORDER: PackedStringArray = PackedStringArray([
	"world_2_1", "world_2_2", "world_2_3",
])

var current_world: String = "world_1"
var current_level_id: String = LEVEL_WORLD_1_1
var use_campaign_flow: bool = true
var pending_scene_mode: String = ""
var pending_haven_level_id: String = ""
var pending_haven_start_stage: int = 0

var _save: Node = null


func _ready() -> void:
	_save = get_node_or_null("/root/SaveManager")


func get_display_name(level_id: String) -> String:
	match level_id:
		LEVEL_WORLD_1_1: return "World 1-1"
		LEVEL_WORLD_1_2: return "World 1-2"
		LEVEL_WORLD_1_3: return "World 1-3"
		LEVEL_HAVEN: return "Haven"
		LEVEL_WORLD_2_1: return "World 2-1"
		LEVEL_WORLD_2_2: return "World 2-2"
		LEVEL_WORLD_2_3: return "World 2-3"
		_: return level_id


func stage_for_level(level_id: String) -> int:
	match level_id:
		LEVEL_WORLD_1_1, LEVEL_WORLD_2_1: return 1
		LEVEL_WORLD_1_2, LEVEL_WORLD_2_2: return 2
		LEVEL_WORLD_1_3, LEVEL_WORLD_2_3: return 3
		_: return 1


func level_for_stage(stage: int, world: String = "world_1") -> String:
	if world == "world_2":
		return WORLD_2_ORDER[clampi(stage - 1, 0, WORLD_2_ORDER.size() - 1)]
	return WORLD_1_ORDER[clampi(stage - 1, 0, WORLD_1_ORDER.size() - 1)]


func is_level_unlocked(level_id: String) -> bool:
	if level_id == LEVEL_HAVEN:
		return _save != null and bool(_save.haven_unlocked)
	if level_id.begins_with("world_2"):
		if _save == null:
			return false
		if not bool(_save.unlocked_worlds.get("world_2", false)):
			return false
		var idx: int = WORLD_2_ORDER.find(level_id)
		if idx <= 0:
			return true
		return _save.is_level_completed(WORLD_2_ORDER[idx - 1])
	var idx_w1: int = WORLD_1_ORDER.find(level_id)
	if idx_w1 <= 0:
		return true
	if _save == null:
		return idx_w1 == 0
	return _save.is_level_completed(WORLD_1_ORDER[idx_w1 - 1])


func is_level_completed(level_id: String) -> bool:
	if _save == null:
		return false
	return _save.is_level_completed(level_id)


func queue_start_from_haven(level_id: String, stage_number: int) -> void:
	pending_haven_level_id = level_id
	pending_haven_start_stage = stage_number
	pending_scene_mode = ""


func queue_enter_haven(return_level_id: String = LEVEL_WORLD_1_1, return_stage: int = 1) -> void:
	pending_scene_mode = LEVEL_HAVEN
	pending_haven_level_id = return_level_id
	pending_haven_start_stage = maxi(1, return_stage)


func start_campaign_level(level_id: String) -> void:
	current_level_id = level_id
	if level_id.begins_with("world_2"):
		current_world = "world_2"
	elif level_id.begins_with("world_1"):
		current_world = "world_1"
	campaign_changed.emit(level_id)


func complete_level(level_id: String) -> void:
	if _save != null:
		_save.complete_level(level_id)
		_save.save_progress()
	level_completed.emit(level_id)
	if level_id == LEVEL_WORLD_1_3:
		unlock_haven()


func unlock_haven() -> void:
	if _save != null:
		_save.unlock_haven()
		_save.unlock_world("world_2")
		_save.save_progress()
	haven_unlocked.emit()


func get_next_level_after(level_id: String) -> String:
	if level_id == LEVEL_WORLD_1_1:
		return LEVEL_WORLD_1_2
	if level_id == LEVEL_WORLD_1_2:
		return LEVEL_WORLD_1_3
	if level_id == LEVEL_WORLD_1_3:
		return LEVEL_HAVEN
	if level_id == LEVEL_WORLD_2_1:
		return LEVEL_WORLD_2_2
	if level_id == LEVEL_WORLD_2_2:
		return LEVEL_WORLD_2_3
	return ""


func should_go_to_haven_after_win(stage: int) -> bool:
	return use_campaign_flow and level_for_stage(stage, "world_1") == LEVEL_WORLD_1_3
