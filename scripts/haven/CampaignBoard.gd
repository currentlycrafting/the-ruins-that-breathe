extends Node2D
## Level selection board with completed levels crossed out.

const LEVEL_BUTTONS: Array[Dictionary] = [
	{"id": "world_1_1", "label": "World 1-1", "offset": Vector2(-80.0, -60.0)},
	{"id": "world_1_2", "label": "World 1-2", "offset": Vector2(0.0, -60.0)},
	{"id": "world_1_3", "label": "World 1-3", "offset": Vector2(80.0, -60.0)},
	{"id": "world_2_1", "label": "World 2-1", "offset": Vector2(-80.0, 20.0)},
	{"id": "world_2_2", "label": "World 2-2", "offset": Vector2(0.0, 20.0)},
	{"id": "world_2_3", "label": "World 2-3", "offset": Vector2(80.0, 20.0)},
]

var _campaign: Node = null
var _save: Node = null


func _ready() -> void:
	_campaign = get_node_or_null("/root/CampaignManager")
	_save = get_node_or_null("/root/SaveManager")
	_build_board()


func _build_board() -> void:
	var panel: ColorRect = ColorRect.new()
	panel.size = Vector2(220.0, 120.0)
	panel.position = Vector2(-110.0, -70.0)
	panel.color = Color(0.12, 0.18, 0.14, 0.85)
	add_child(panel)
	for entry in LEVEL_BUTTONS:
		var btn: Button = Button.new()
		btn.text = String(entry.get("label", ""))
		btn.position = entry.get("offset", Vector2.ZERO) + Vector2(-40.0, 0.0)
		btn.custom_minimum_size = Vector2(78.0, 28.0)
		var level_id: String = String(entry.get("id", ""))
		btn.pressed.connect(_on_level_pressed.bind(level_id))
		add_child(btn)
		_refresh_button(btn, level_id)


func _refresh_button(btn: Button, level_id: String) -> void:
	var completed: bool = _save != null and _save.is_level_completed(level_id)
	var unlocked: bool = _campaign == null or _campaign.is_level_unlocked(level_id)
	btn.disabled = not unlocked
	if completed:
		btn.text = "[X] " + btn.text


func _on_level_pressed(level_id: String) -> void:
	if _campaign == null:
		return
	if not _campaign.is_level_unlocked(level_id):
		return
	var loading: Node = get_node_or_null("/root/LoadingScreen")
	if loading != null and loading.has_method("transition_to"):
		var stage: int = _campaign.stage_for_level(level_id)
		_campaign.start_campaign_level(level_id)
		_campaign.queue_start_from_haven(level_id, stage)
		loading.call("transition_to", level_id, _campaign.get_display_name(level_id), "Entering campaign...", "res://world.tscn")
	else:
		get_tree().change_scene_to_file("res://world.tscn")
