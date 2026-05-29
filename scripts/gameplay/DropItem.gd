class_name DropItem
extends Node2D
## Pickup with spawn burst, idle bob, lift-then-curve magnet, and collection pop.

enum State { SPAWN_BURST, IDLE, LIFT, MAGNET, COLLECTED }

signal collected(item: DropItem)

@export var item_id: String = "silver_coin"
@export var item_name: String = "Silver Coin"
@export var item_type: String = "coin"
@export var value: int = 1
@export var rarity: String = "common"

@export_group("Magnet")
@export var magnet_enabled: bool = true
@export var magnet_radius: float = 96.0
@export var pickup_radius: float = 16.0
@export var lift_before_magnet: bool = true
@export var lift_height: float = 10.0
@export var lift_duration: float = 0.12
@export var magnet_start_delay: float = 0.05
@export var magnet_min_speed: float = 140.0
@export var magnet_max_speed: float = 900.0
@export var magnet_acceleration: float = 8.0
@export var magnet_curve_strength: float = 0.35

@export_group("Idle")
@export var bob_enabled: bool = true
@export var bob_height: float = 3.0
@export var bob_speed: float = 3.0
@export var bounce_enabled: bool = true
@export var lifetime: float = 45.0

@export_group("Juice")
@export var glow_enabled: bool = true
@export var sparkle_enabled: bool = true
@export var pickup_pop_enabled: bool = true
@export var pickup_text_enabled: bool = true

var _state: State = State.SPAWN_BURST
var _sprite: Sprite2D = null
var _glow: PointLight2D = null
var _player: Node2D = null
var _world: Node = null
var _velocity: Vector2 = Vector2.ZERO
var _spawn_timer: float = 0.0
var _idle_time: float = 0.0
var _lift_timer: float = 0.0
var _magnet_delay_timer: float = 0.0
var _magnet_speed: float = 0.0
var _land_y: float = 0.0
var _base_position: Vector2 = Vector2.ZERO
var _life_timer: float = 0.0
var _curve_offset: Vector2 = Vector2.ZERO


func setup(texture: Texture2D, world_ref: Node, player_ref: Node2D, config: Dictionary = {}) -> void:
	_world = world_ref
	_player = player_ref
	item_id = String(config.get("item_id", item_id))
	item_name = String(config.get("item_name", item_name))
	item_type = String(config.get("item_type", item_type))
	value = int(config.get("value", value))
	rarity = String(config.get("rarity", rarity))
	magnet_radius = float(config.get("magnet_radius", magnet_radius))
	pickup_radius = float(config.get("pickup_radius", pickup_radius))
	lifetime = float(config.get("lifetime", lifetime))

	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(config.get("scale", 1.0), config.get("scale", 1.0))
	add_child(_sprite)

	if glow_enabled:
		_glow = PointLight2D.new()
		_glow.energy = float(config.get("glow_energy", 0.35))
		_glow.texture_scale = float(config.get("glow_scale", 0.45))
		_glow.color = config.get("glow_color", Color(1.0, 0.92, 0.45, 1.0))
		add_child(_glow)

	z_index = 35
	_land_y = global_position.y
	_base_position = global_position
	_begin_spawn_burst(config)


func _begin_spawn_burst(config: Dictionary) -> void:
	_state = State.SPAWN_BURST
	var burst_dir: Vector2 = config.get("burst_dir", Vector2(randf_range(-1.0, 1.0), randf_range(-0.8, -0.2))).normalized()
	var burst_speed: float = float(config.get("burst_speed", randf_range(80.0, 140.0)))
	_velocity = burst_dir * burst_speed
	_spawn_timer = float(config.get("burst_duration", 0.22))


func _physics_process(delta: float) -> void:
	_life_timer += delta
	if _life_timer >= lifetime:
		queue_free()
		return
	if _player == null or not is_instance_valid(_player):
		_player = _world.get_node_or_null("Player") as Node2D if _world != null else null
	match _state:
		State.SPAWN_BURST:
			_process_spawn_burst(delta)
		State.IDLE:
			_process_idle(delta)
		State.LIFT:
			_process_lift(delta)
		State.MAGNET:
			_process_magnet(delta)


func _process_spawn_burst(delta: float) -> void:
	global_position += _velocity * delta
	_velocity.y += 420.0 * delta
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 or global_position.y >= _land_y:
		global_position.y = _land_y
		_velocity = Vector2.ZERO
		_state = State.IDLE
		_land_y = global_position.y
		_base_position = global_position


func _process_idle(delta: float) -> void:
	_idle_time += delta
	if bob_enabled and _sprite != null:
		_sprite.position.y = sin(_idle_time * bob_speed) * bob_height
	if sparkle_enabled and int(_idle_time * 10.0) % 7 == 0:
		_spawn_sparkle()
	if not magnet_enabled or _player == null:
		return
	if global_position.distance_to(_player.global_position) <= magnet_radius:
		_magnet_delay_timer = magnet_start_delay
		_state = State.LIFT if lift_before_magnet else State.MAGNET
		_lift_timer = 0.0
		_magnet_speed = magnet_min_speed
		_curve_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5)).normalized() * 24.0


func _process_lift(delta: float) -> void:
	_lift_timer += delta
	var t: float = clampf(_lift_timer / maxf(0.01, lift_duration), 0.0, 1.0)
	if _sprite != null:
		_sprite.position.y = lerpf(sin(_idle_time * bob_speed) * bob_height, -lift_height, t)
	_magnet_delay_timer -= delta
	if t >= 1.0 and _magnet_delay_timer <= 0.0:
		_state = State.MAGNET


func _process_magnet(delta: float) -> void:
	if _player == null:
		_state = State.IDLE
		return
	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()
	if dist <= pickup_radius:
		_collect()
		return
	var dir: Vector2 = to_player.normalized()
	var curve_dir: Vector2 = dir.rotated(PI * 0.5) * magnet_curve_strength
	var blended: Vector2 = (dir + curve_dir * (_curve_offset.x * 0.02)).normalized()
	_magnet_speed = clampf(_magnet_speed + magnet_acceleration * 60.0 * delta, magnet_min_speed, magnet_max_speed)
	var speed_scale: float = lerpf(0.65, 1.35, 1.0 - clampf(dist / magnet_radius, 0.0, 1.0))
	global_position += blended * _magnet_speed * speed_scale * delta
	if _sprite != null:
		_sprite.position.y = lerpf(_sprite.position.y, 0.0, delta * 8.0)
	if sparkle_enabled and randf() < 0.25:
		_spawn_sparkle()


func _collect() -> void:
	if _state == State.COLLECTED:
		return
	_state = State.COLLECTED
	if pickup_pop_enabled:
		_spawn_collect_pop()
	if _world != null and _world.has_method("on_drop_collected"):
		_world.call("on_drop_collected", self)
	collected.emit(self)
	queue_free()


func _spawn_sparkle() -> void:
	var spark: ColorRect = ColorRect.new()
	spark.size = Vector2(3.0, 3.0)
	spark.position = Vector2(randf_range(-6.0, 6.0), randf_range(-10.0, 2.0))
	spark.color = Color(1.0, 0.95, 0.7, 0.85)
	add_child(spark)
	var tw: Tween = spark.create_tween()
	tw.tween_property(spark, "modulate:a", 0.0, 0.18)
	tw.finished.connect(func() -> void:
		if is_instance_valid(spark):
			spark.queue_free()
	)


func _spawn_collect_pop() -> void:
	var pop: ColorRect = ColorRect.new()
	pop.size = Vector2(10.0, 10.0)
	pop.position = Vector2(-5.0, -5.0)
	pop.color = Color(1.0, 0.92, 0.45, 0.9)
	add_child(pop)
	var tw: Tween = pop.create_tween()
	tw.set_parallel(true)
	tw.tween_property(pop, "scale", Vector2(2.0, 2.0), 0.14)
	tw.tween_property(pop, "modulate:a", 0.0, 0.14)
