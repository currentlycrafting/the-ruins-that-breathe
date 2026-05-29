extends Node
## Subtle petal/firefly particles drifting toward the current objective.

@export var objective_trail_enabled: bool = true
@export var trail_type: String = "petals"
@export_range(0.05, 2.0, 0.05) var trail_spawn_rate: float = 0.22
@export_range(0.2, 3.0, 0.05) var trail_lifetime: float = 1.1
@export_range(16.0, 200.0, 1.0) var trail_distance_from_player: float = 42.0
@export var trail_color: Color = Color(1.0, 0.82, 0.55, 0.55)
@export_range(0.05, 1.0, 0.05) var trail_opacity: float = 0.5
@export_range(20.0, 320.0, 5.0) var trail_speed: float = 95.0
@export_range(0.0, 1.5, 0.05) var trail_curve_strength: float = 0.45

var _world: Node = null
var _particles: CPUParticles2D = null
var _spawn_timer: float = 0.0
var _pool: Array[Sprite2D] = []


func bind_world(world: Node) -> void:
	_world = world
	if _particles == null and world != null:
		_particles = CPUParticles2D.new()
		_particles.name = "ObjectiveTrailParticles"
		_particles.emitting = false
		_particles.amount = 24
		_particles.lifetime = trail_lifetime
		_particles.one_shot = false
		_particles.direction = Vector2.RIGHT
		_particles.spread = 18.0
		_particles.gravity = Vector2.ZERO
		_particles.initial_velocity_min = trail_speed * 0.4
		_particles.initial_velocity_max = trail_speed
		_particles.scale_amount_min = 0.35
		_particles.scale_amount_max = 0.7
		_particles.color = trail_color
		world.add_child(_particles)


func _process(delta: float) -> void:
	if not objective_trail_enabled or _world == null:
		if _particles != null:
			_particles.emitting = false
		return
	if not _world.get("game_started"):
		return
	var player: Node2D = _world.get_node_or_null("Player") as Node2D
	if player == null:
		return
	if not _world.has_method("get_current_objective_tile"):
		return
	var objective_tile: Vector2i = _world.call("get_current_objective_tile")
	if objective_tile == Vector2i.ZERO:
		_clear_trail()
		return
	var objective_world: Vector2 = _world.call("tile_to_world", objective_tile)
	var direction: Vector2 = objective_world - player.global_position
	if direction.length() < 64.0:
		_clear_trail()
		return
	var dir: Vector2 = direction.normalized()
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = trail_spawn_rate
		_spawn_trail_mote(player, dir)
	if _particles != null:
		_particles.global_position = player.global_position + dir * trail_distance_from_player
		_particles.direction = dir
		_particles.emitting = true


func _spawn_trail_mote(player: Node2D, dir: Vector2) -> void:
	var mote: Sprite2D = Sprite2D.new()
	mote.texture = _make_mote_texture()
	mote.centered = true
	mote.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mote.scale = Vector2(0.8, 0.8)
	mote.modulate = Color(trail_color.r, trail_color.g, trail_color.b, trail_opacity)
	var perp: Vector2 = dir.rotated(PI * 0.5) * randf_range(-trail_curve_strength, trail_curve_strength) * 30.0
	mote.global_position = player.global_position + dir * trail_distance_from_player + perp
	_world.add_child(mote)
	var target: Vector2 = mote.global_position + dir * randf_range(36.0, 72.0)
	var tw: Tween = mote.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mote, "global_position", target, trail_lifetime * 0.85)
	tw.tween_property(mote, "modulate:a", 0.0, trail_lifetime)
	tw.finished.connect(func() -> void:
		if is_instance_valid(mote):
			mote.queue_free()
	)


func _clear_trail() -> void:
	if _particles != null:
		_particles.emitting = false


func _make_mote_texture() -> Texture2D:
	var image: Image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
	var c: Color = trail_color
	c.a = 1.0
	image.fill(c)
	return ImageTexture.create_from_image(image)
