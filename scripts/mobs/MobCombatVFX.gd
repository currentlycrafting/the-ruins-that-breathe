class_name MobCombatVFX
extends RefCounted

const VFX_PULSE_SCRIPT: Script = preload("res://scripts/mobs/MobVfxPulse.gd")


static func world_root(from_node: Node) -> Node:
	if from_node == null:
		return null
	return from_node.get_tree().current_scene


static func spawn_tile_warning(
	world: Node,
	world_pos: Vector2,
	duration: float = 0.85,
	loop_pulse: bool = false
) -> Node:
	if world == null or not world.has_method("spawn_combat_tile_marker"):
		return null
	return world.spawn_combat_tile_marker(world_pos, duration, loop_pulse)


static func spawn_tile_box(
	world: Node,
	center_world_pos: Vector2,
	duration: float = 0.85,
	loop_pulse: bool = true,
	box_tiles: Vector2i = Vector2i(2, 2)
) -> Array:
	if world == null or not world.has_method("spawn_combat_tile_markers_box"):
		return []
	return world.spawn_combat_tile_markers_box(center_world_pos, box_tiles, duration, loop_pulse)


static func spawn_tile_beam_path(
	world: Node,
	from_pos: Vector2,
	to_pos: Vector2,
	duration: float = 0.85,
	loop_pulse: bool = true
) -> Array:
	if world == null or not world.has_method("spawn_combat_tile_markers_line"):
		return []
	return world.spawn_combat_tile_markers_line(from_pos, to_pos, duration, loop_pulse)


static func spawn_persistent_ring(
	world: Node,
	center: Vector2,
	_radius: float,
	duration: float,
	_line_width: float = 12.0,
	_layers: int = 4
) -> Array:
	return spawn_tile_box(world, center, duration, true)


static func spawn_flicker_beam_warning(
	world: Node,
	from_pos: Vector2,
	to_pos: Vector2,
	duration: float,
	width: float = 7.0
) -> Node2D:
	if world == null:
		return null
	var pulse: Node2D = Node2D.new()
	pulse.set_script(VFX_PULSE_SCRIPT)
	world.add_child(pulse)
	pulse.call("setup_beam", from_pos, to_pos, duration, width)
	return pulse


static func spawn_landing_zone(
	world: Node,
	center: Vector2,
	_radius: float,
	duration: float
) -> Node:
	return spawn_tile_warning(world, center, duration, true)


static func spawn_beam_flash(
	world: Node,
	from_pos: Vector2,
	to_pos: Vector2,
	width: float,
	_duration: float,
	_z_index: int = 22
) -> void:
	if world == null:
		return
	for layer in range(3):
		var line: Line2D = Line2D.new()
		line.width = width + float(2 - layer) * 3.0
		line.default_color = Color(1.0, 0.92, 0.45, 0.9 - float(layer) * 0.2)
		line.z_index = _z_index + layer
		line.add_point(from_pos)
		line.add_point(to_pos)
		world.add_child(line)
		var tween: Tween = line.create_tween()
		tween.tween_property(line, "modulate:a", 0.0, maxf(0.12, _duration))
		tween.chain().tween_callback(line.queue_free)


static func spawn_particle_burst(
	world: Node,
	center: Vector2,
	color: Color,
	amount: int = 16,
	lifetime: float = 0.32,
	spread: float = 1.0,
	z_index: int = 24
) -> void:
	if world == null:
		return
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.global_position = center
	particles.z_index = z_index
	particles.emitting = true
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = lifetime
	particles.explosiveness = 0.9
	particles.spread = 180.0 * spread
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 110.0
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.5
	particles.color = color
	world.add_child(particles)
	particles.finished.connect(particles.queue_free, CONNECT_ONE_SHOT)


static func spawn_shockwave_lines(
	world: Node,
	center: Vector2,
	_radius: float,
	_color: Color,
	duration: float = 0.35,
	_segments: int = 1
) -> Array:
	return spawn_tile_box(world, center, duration, true)


static func spawn_motion_streak(world: Node, from_pos: Vector2, to_pos: Vector2, color: Color, width: float = 3.0) -> void:
	if world == null:
		return
	var line: Line2D = Line2D.new()
	line.width = width
	line.default_color = color
	line.z_index = 12
	line.add_point(from_pos)
	line.add_point(to_pos)
	world.add_child(line)
	var tween: Tween = line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(line.queue_free)


static func spawn_ground_ring(world: Node, center: Vector2, radius: float, _color: Color, duration: float, _z: int = 4, _grow: float = 1.0) -> Array:
	return spawn_tile_box(world, center, duration, true)


static func spawn_line_telegraph(world: Node, from_pos: Vector2, to_pos: Vector2, width: float, _color: Color, duration: float, _z: int = 18, _glow: float = 2.4) -> Node2D:
	return spawn_flicker_beam_warning(world, from_pos, to_pos, duration, maxf(5.0, width * 0.45))


static func spawn_landing_marker(world: Node, center: Vector2, radius: float, _color: Color, duration: float) -> Node:
	return spawn_landing_zone(world, center, radius, duration)


static func spawn_rune_circle(world: Node, center: Vector2, radius: float, _color: Color, duration: float) -> Array:
	return spawn_tile_box(world, center, duration, true)


static func spawn_impact_burst(
	world: Node,
	center: Vector2,
	color: Color,
	_size: float = 18.0,
	duration: float = 0.28,
	_z: int = 24,
	particle_count: int = 14
) -> void:
	spawn_particle_burst(world, center, color, particle_count, duration, 1.0, _z)
	spawn_tile_warning(world, center, duration * 0.85, false)


static func spawn_trail_dot(world: Node, pos: Vector2, color: Color, _z_index: int = 8) -> void:
	spawn_motion_streak(world, pos, pos + Vector2(randf_range(-4.0, 4.0), randf_range(-3.0, 3.0)), color, 2.5)
