extends Node
## Wave intro, spawn warnings, barrier styling, and room-clear feedback.

@export var show_wave_intro_text: bool = true
@export var show_wave_counter: bool = true
@export_range(0.1, 3.0, 0.05) var wave_intro_duration: float = 0.9
@export var room_lock_barrier_type: String = "energy"
@export var barrier_color: Color = Color(1.0, 0.35, 0.28, 0.75)
@export_range(0.05, 2.0, 0.05) var spawn_warning_duration: float = 0.55
@export_range(0.0, 3.0, 0.05) var room_clear_reward_delay: float = 0.65
@export var camera_shake_on_wave_start: bool = true
@export var camera_shake_on_room_clear: bool = true

var _world: Node = null
var _wave_label: Label = null


func bind_world(world: Node) -> void:
	_world = world
	_build_wave_ui()


func _build_wave_ui() -> void:
	if _world == null:
		return
	var ui: CanvasLayer = _world.get_node_or_null("HudLayer") as CanvasLayer
	if ui == null:
		ui = _world.get_node_or_null("HUDLayer") as CanvasLayer
	if ui == null:
		return
	_wave_label = ui.get_node_or_null("WaveCounterLabel") as Label
	if _wave_label == null:
		_wave_label = Label.new()
		_wave_label.name = "WaveCounterLabel"
		_wave_label.add_theme_font_size_override("font_size", 22)
		_wave_label.modulate = Color(1.0, 0.88, 0.45, 0.95)
		_wave_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_wave_label.offset_top = 48.0
		_wave_label.visible = false
		ui.add_child(_wave_label)


func on_room_locked(room_center: Vector2i) -> void:
	if _world == null:
		return
	if camera_shake_on_wave_start and _world.has_method("start_screen_shake"):
		_world.call("start_screen_shake", 2.8, 0.14)
	_style_block_markers(barrier_color)


func on_wave_start(wave_index: int, room_center: Vector2i) -> void:
	if not show_wave_counter or _wave_label == null:
		return
	_wave_label.text = "Wave %d" % (wave_index + 1)
	_wave_label.visible = true
	_wave_label.modulate.a = 0.0
	var tw: Tween = _wave_label.create_tween()
	tw.tween_property(_wave_label, "modulate:a", 1.0, 0.2)
	if show_wave_intro_text and _world != null and _world.has_method("show_floating_text"):
		_world.call("show_floating_text", _world.call("tile_to_world", room_center), "WAVE %d" % (wave_index + 1), Color(1.0, 0.9, 0.5, 1.0))


func on_spawn_warning(spawn_positions: Array[Vector2]) -> void:
	if _world == null:
		return
	for pos in spawn_positions:
		var ring: ColorRect = ColorRect.new()
		ring.size = Vector2(18.0, 18.0)
		ring.position = pos - ring.size * 0.5
		ring.color = Color(1.0, 0.45, 0.25, 0.55)
		ring.z_index = 80
		_world.add_child(ring)
		var tw: Tween = ring.create_tween()
		tw.tween_property(ring, "scale", Vector2(2.2, 2.2), spawn_warning_duration)
		tw.parallel().tween_property(ring, "modulate:a", 0.0, spawn_warning_duration)
		tw.finished.connect(func() -> void:
			if is_instance_valid(ring):
				ring.queue_free()
		)


func on_wave_complete(wave_index: int) -> void:
	if _wave_label != null:
		_wave_label.text = "Wave %d Complete" % (wave_index + 1)


func on_room_cleared(room_center: Vector2i) -> void:
	if _wave_label != null:
		var tw: Tween = _wave_label.create_tween()
		tw.tween_property(_wave_label, "modulate:a", 0.0, 0.35)
		tw.finished.connect(func() -> void:
			if is_instance_valid(_wave_label):
				_wave_label.visible = false
		)
	if _world == null:
		return
	if camera_shake_on_room_clear and _world.has_method("start_screen_shake"):
		_world.call("start_screen_shake", 1.6, 0.1)
	var timer: SceneTreeTimer = _world.get_tree().create_timer(room_clear_reward_delay)
	timer.timeout.connect(func() -> void:
		if _world != null and _world.has_method("spawn_room_clear_rewards"):
			_world.call("spawn_room_clear_rewards", room_center)
	)


func _style_block_markers(color: Color) -> void:
	if _world == null:
		return
	var markers: Dictionary = _world.get("active_main_block_markers")
	if markers == null:
		return
	for marker in markers.values():
		if marker is CanvasItem:
			(marker as CanvasItem).modulate = color
