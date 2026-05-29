extends Node
## Data-driven tutorial cards triggered by player actions.

signal step_shown(step_id: String)
signal tutorial_finished

@export var tutorial_enabled: bool = true
@export var pause_on_show: bool = false

const STEPS: Array[Dictionary] = [
	{"id": "move", "text": "Move around to explore the ruins.", "trigger": "moved"},
	{"id": "aim", "text": "Aim with your cursor.", "trigger": "aimed"},
	{"id": "shoot", "text": "Shoot toward the cursor.", "trigger": "shot"},
	{"id": "charge", "text": "Hold charge to power up your weapon.", "trigger": "charged"},
	{"id": "trail", "text": "Follow the glowing trail to your next objective.", "trigger": "trail_seen"},
	{"id": "pickup", "text": "Pick up coins and hearts from defeated enemies.", "trigger": "pickup"},
	{"id": "room", "text": "Entering a main room starts a wave encounter.", "trigger": "room_enter"},
	{"id": "wave", "text": "Defeat all enemies to unlock the room.", "trigger": "wave_clear"},
	{"id": "keys", "text": "Find keys to open the path forward.", "trigger": "key"},
	{"id": "complete", "text": "Complete World 1 to unlock Haven.", "trigger": "level_win"},
]

var _panel: PanelContainer = null
var _label: Label = null
var _skip_btn: Button = null
var _save: Node = null
var _pending_triggers: Dictionary = {}
var _shown_ids: Dictionary = {}


func _ready() -> void:
	_save = get_node_or_null("/root/SaveManager")
	for step in STEPS:
		_pending_triggers[String(step.get("trigger", ""))] = step


func bind_ui(layer: CanvasLayer) -> void:
	if _panel != null:
		return
	_panel = PanelContainer.new()
	_panel.name = "TutorialPanel"
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.offset_bottom = -24.0
	_panel.custom_minimum_size = Vector2(520.0, 72.0)
	layer.add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	margin.add_child(row)

	_label = Label.new()
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 15)
	row.add_child(_label)

	_skip_btn = Button.new()
	_skip_btn.text = "Skip"
	_skip_btn.pressed.connect(_skip_all)
	row.add_child(_skip_btn)


func notify_trigger(trigger_name: String) -> void:
	if not tutorial_enabled:
		return
	if _save != null and bool(_save.tutorial_completed):
		return
	if not _pending_triggers.has(trigger_name):
		return
	var step: Dictionary = _pending_triggers[trigger_name]
	var step_id: String = String(step.get("id", ""))
	if _shown_ids.has(step_id):
		return
	_show_step(step)


func _show_step(step: Dictionary) -> void:
	var step_id: String = String(step.get("id", ""))
	_shown_ids[step_id] = true
	if _save != null:
		_save.complete_tutorial_step(step_id)
	if _panel == null or _label == null:
		return
	_label.text = String(step.get("text", ""))
	_panel.visible = true
	step_shown.emit(step_id)
	var timer: SceneTreeTimer = get_tree().create_timer(4.5)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(_panel):
			_panel.visible = false
	)
	if _shown_ids.size() >= STEPS.size():
		_finish_tutorial()


func _skip_all() -> void:
	_finish_tutorial()
	if _panel != null:
		_panel.visible = false


func _finish_tutorial() -> void:
	if _save != null:
		_save.set_tutorial_completed(true)
		_save.save_progress()
	tutorial_finished.emit()
