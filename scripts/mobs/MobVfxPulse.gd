extends Node2D
## Thin flickering red/gold beam warnings (rings replaced by tile click markers).

@export var duration: float = 2.0
@export var radius: float = 60.0
@export var mode: String = "beam"
@export var beam_end: Vector2 = Vector2.ZERO
@export var line_width: float = 6.0
@export var ring_count: int = 2
@export var fade_at_end: bool = true

var _lines: Array[Line2D] = []
var _elapsed: float = 0.0
var _beam_origin: Vector2 = Vector2.ZERO


func setup_beam(from_pos: Vector2, to_pos: Vector2, life: float, width: float = 6.0) -> void:
	mode = "beam"
	duration = life
	line_width = width
	_beam_origin = from_pos
	beam_end = to_pos
	global_position = Vector2.ZERO
	_build_beam()


func _ready() -> void:
	z_index = 18
	set_process(true)


func _build_beam() -> void:
	_clear_lines()
	var host: Node = get_parent()
	if host == null:
		host = self
	for layer in range(2):
		var line: Line2D = Line2D.new()
		line.width = line_width + float(1 - layer) * 3.0
		line.default_color = Color(1.0, 0.15, 0.05, 0.78 - float(layer) * 0.15)
		line.z_index = 20 + layer
		line.add_point(_beam_origin)
		line.add_point(beam_end)
		host.add_child(line)
		_lines.append(line)


func _clear_lines() -> void:
	for line in _lines:
		if is_instance_valid(line):
			line.queue_free()
	_lines.clear()


func _process(delta: float) -> void:
	_elapsed += delta
	var flicker: float = 0.5 + 0.5 * sin(_elapsed * 16.0)
	var warning_color: Color = Color(1.0, 0.08, 0.05, 0.88).lerp(Color(1.0, 0.88, 0.15, 0.92), flicker)
	for line in _lines:
		if not is_instance_valid(line):
			continue
		line.default_color = warning_color
	if _elapsed >= duration:
		if fade_at_end:
			var tween: Tween = create_tween()
			for line in _lines:
				if is_instance_valid(line):
					tween.parallel().tween_property(line, "modulate:a", 0.0, 0.2)
			tween.chain().tween_callback(queue_free)
		else:
			queue_free()


func _exit_tree() -> void:
	_clear_lines()
