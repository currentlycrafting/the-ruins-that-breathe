extends CanvasLayer
## Full-screen fade transitions between campaign worlds and Haven.

signal transition_finished(destination: String)

@export_range(0.1, 2.0, 0.05) var fade_duration: float = 0.55
@export var block_input: bool = true

var _fade_rect: ColorRect = null
var _title_label: Label = null
var _subtitle_label: Label = null
var _busy: bool = false


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_fade_rect.modulate.a = 0.0
	visible = true


func _build_ui() -> void:
	_fade_rect = ColorRect.new()
	_fade_rect.name = "Fade"
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0.03, 0.05, 0.08, 1.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.set_anchors_preset(Control.PRESET_CENTER)
	_title_label.position = Vector2(-260.0, -18.0)
	_title_label.size = Vector2(520.0, 40.0)
	_title_label.modulate = Color(1.0, 0.92, 0.62, 1.0)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "Subtitle"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 16)
	_subtitle_label.set_anchors_preset(Control.PRESET_CENTER)
	_subtitle_label.position = Vector2(-260.0, 20.0)
	_subtitle_label.size = Vector2(520.0, 28.0)
	_subtitle_label.modulate = Color(0.78, 0.86, 0.92, 0.9)
	_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_subtitle_label)


func is_busy() -> bool:
	return _busy


func transition_to(destination: String, title: String, subtitle: String = "", scene_path: String = "") -> void:
	if _busy:
		return
	_busy = true
	if block_input:
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_title_label.text = title
	_subtitle_label.text = subtitle
	_title_label.visible = true
	_subtitle_label.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, fade_duration * 0.45)
	await tween.finished
	await get_tree().create_timer(0.12).timeout
	if scene_path != "":
		get_tree().change_scene_to_file(scene_path)
		await get_tree().process_frame
	var out: Tween = create_tween()
	out.tween_property(_fade_rect, "modulate:a", 0.0, fade_duration * 0.55)
	await out.finished
	_title_label.visible = false
	_subtitle_label.visible = false
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	transition_finished.emit(destination)
