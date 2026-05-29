class_name BaseEnemy
extends Area2D

signal slime_died(slime: Node2D, room_center: Vector2i)

const STATE_IDLE: String = "IDLE"
const STATE_CHASE: String = "CHASE"
const STATE_WINDUP: String = "WINDUP"
const STATE_ATTACK: String = "ATTACK"
const STATE_RECOVER: String = "RECOVER"
const STATE_HURT: String = "HURT"
const STATE_DEAD: String = "DEAD"

@export var enemy_id: String = "slime"
@export var max_health: float = 50.0
@export var movement_speed: float = 45.0
@export var contact_damage: float = 8.0
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 3.0
@export var detection_range: float = 280.0
@export var attack_range: float = 160.0
@export var knockback_resistance: float = 0.5
@export var telegraph_duration: float = 0.45
@export var recover_duration: float = 0.35
@export var contact_damage_cooldown: float = 0.75
@export var loot_drop_chance: float = 0.65
@export var difficulty_value: float = 1.0
@export var can_fly: bool = false
@export var strategic_orbit_radius: float = 72.0
@export var strategic_orbit_weight: float = 0.60
@export var strategic_cutoff_weight: float = 0.40
@export var use_single_walk_animation: bool = true
@export var use_walk_for_idle: bool = true
@export var frames_resource: SpriteFrames = null
@export var base_tint: Color = Color.WHITE
@export var heart_points_per_heart: float = 20.0
@export var heart_scale: float = 1.7
@export var movement_acceleration: float = 11.0
@export var movement_deceleration: float = 16.0
@export var stop_distance: float = 38.0
@export var facing_deadzone: float = 8.0
@export var default_faces_left: bool = true
@export var separation_radius: float = 30.0
@export var separation_strength: float = 140.0
@export var attack_hit_delay: float = 0.14
@export var attack_duration: float = 0.38
@export var show_attack_debug: bool = false
@export var body_bob_amount: float = 2.0
@export var body_bob_speed: float = 5.0
@export var use_slime_hop_combat: bool = false
@export var hop_interval: float = 0.72
@export var hop_distance: float = 48.0
@export var hop_height: float = 20.0
@export var hop_duration: float = 0.34

var health: float = 50.0
var velocity: Vector2 = Vector2.ZERO
var facing_direction: String = "down"
var current_state: String = STATE_IDLE
var target_player: Node2D = null
var can_attack: bool = true
var room_center: Vector2i = Vector2i(-9999, -9999)
var world_ref: Node = null

var sprite: AnimatedSprite2D = null
var collision_shape: CollisionShape2D = null

var _attack_cd_left: float = 0.0
var _state_timer: float = 0.0
var _contact_cd_left: float = 0.0
var _flash_left: float = 0.0
var _flash_color: Color = Color(1.65, 0.26, 0.26, 1.0)
var _base_modulate: Color = Color.WHITE
var _is_dead: bool = false
var _player_last_pos: Vector2 = Vector2.ZERO
var _player_velocity: Vector2 = Vector2.ZERO
var _buff_move_mult: float = 1.0
var _buff_attack_haste: float = 1.0
var _buff_left: float = 0.0
var _death_frames_left: int = 0
var _death_tick_left: float = 0.0
var _heart_sprites: Array[Sprite2D] = []
var _heart_texture: Texture2D = null
var _attack_elapsed: float = 0.0
var _attack_damage_done: bool = false
var _bob_phase: float = 0.0
var _debug_shapes: Array[Node] = []
var _hop_timer: float = 0.0
var _hop_elapsed: float = 0.0
var _is_hopping: bool = false
var _hop_start: Vector2 = Vector2.ZERO
var _hop_target: Vector2 = Vector2.ZERO
var _telegraph_markers: Array = []
var _active_beam_vfx: Node2D = null


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = true
	monitorable = true
	add_to_group("hostile_mobs")
	_build_nodes()
	_build_animations()
	_heart_texture = _make_heart_texture(base_tint)
	health = max_health
	current_state = STATE_IDLE
	_update_heart_visual()
	if use_slime_hop_combat:
		_hop_timer = randf_range(0.05, 0.28)
	set_process(true)


func configure(player_ref: Node2D, config: Dictionary) -> void:
	target_player = player_ref
	world_ref = config.get("world_ref", get_tree().current_scene)
	room_center = config.get("room_center", room_center)
	max_health = float(config.get("max_health", max_health))
	health = max_health
	movement_speed = float(config.get("movement_speed", movement_speed))
	contact_damage = float(config.get("contact_damage", contact_damage))
	attack_damage = float(config.get("attack_damage", attack_damage))
	attack_cooldown = float(config.get("attack_cooldown", attack_cooldown))
	detection_range = float(config.get("detection_range", detection_range))
	attack_range = float(config.get("attack_range", attack_range))
	knockback_resistance = float(config.get("knockback_resistance", knockback_resistance))
	telegraph_duration = float(config.get("telegraph_duration", telegraph_duration))
	recover_duration = float(config.get("recover_duration", recover_duration))
	loot_drop_chance = float(config.get("loot_drop_chance", loot_drop_chance))
	difficulty_value = float(config.get("difficulty_value", difficulty_value))
	base_tint = config.get("base_tint", base_tint)
	if config.has("enemy_id"):
		enemy_id = String(config.get("enemy_id"))
	set_meta("drop_id", enemy_id)
	_base_modulate = base_tint
	if sprite != null:
		sprite.modulate = _base_modulate
	_heart_texture = _make_heart_texture(_base_modulate)
	_update_heart_visual()
	_play_anim(_idle_anim_name(), true)


func _process(delta: float) -> void:
	if _is_dead:
		_update_death_anim(delta)
		return
	if target_player == null or not is_instance_valid(target_player):
		target_player = get_tree().current_scene.get_node_or_null("Player") as Node2D
	if target_player != null and is_instance_valid(target_player):
		_update_player_velocity(delta)
	_attack_cd_left = maxf(0.0, _attack_cd_left - delta)
	_contact_cd_left = maxf(0.0, _contact_cd_left - delta)
	_state_timer = maxf(0.0, _state_timer - delta)
	_flash_left = maxf(0.0, _flash_left - delta)
	_update_flash_visual()
	_update_buffs(delta)

	match current_state:
		STATE_IDLE:
			_process_idle(delta)
		STATE_CHASE:
			_process_chase(delta)
		STATE_WINDUP:
			_process_windup(delta)
		STATE_ATTACK:
			_process_attack(delta)
		STATE_RECOVER:
			_process_recover(delta)
		STATE_HURT:
			_process_hurt(delta)
		STATE_DEAD:
			pass
	if not _is_contact_state_blocked():
		_update_contact_damage()
	_update_body_bob(delta)
	_update_attack_debug_shapes()
	_process_custom(delta)


func take_damage(amount: float) -> void:
	if _is_dead:
		return
	health = maxf(0.0, health - amount)
	flash_damage()
	_apply_hit_knockback()
	_update_heart_visual()
	if world_ref != null and world_ref.has_method("spawn_damage_tick"):
		world_ref.call("spawn_damage_tick", global_position, amount, Color(1.0, 0.62, 0.28, 1.0))
	if health <= 0.0:
		die()
		return
	current_state = STATE_HURT
	_state_timer = 0.12
	_play_anim(_hurt_anim_name(), false)


func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	current_state = STATE_DEAD
	can_attack = false
	_clear_telegraph_vfx()
	set_deferred("monitoring", false)
	drop_loot()
	_emit_death_particles()
	_play_anim(_death_anim_name(), false)
	_death_frames_left = max(5, _current_anim_frame_count())
	_death_tick_left = 0.05
	_end_all_abilities()


func flash_damage() -> void:
	_flash_left = 0.20
	_update_flash_visual()


func _apply_hit_knockback() -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	var away: Vector2 = global_position - target_player.global_position
	if away.length_squared() <= 0.001:
		return
	var push: float = 5.0 * (1.0 - clampf(knockback_resistance, 0.0, 1.0))
	global_position += away.normalized() * push


func drop_loot() -> void:
	if randf() > loot_drop_chance:
		set_meta("drop_id", "")
	else:
		set_meta("drop_id", enemy_id)


func apply_temporary_buffs(move_mult: float, attack_haste: float, duration: float) -> void:
	_buff_move_mult = maxf(_buff_move_mult, move_mult)
	_buff_attack_haste = maxf(_buff_attack_haste, attack_haste)
	_buff_left = maxf(_buff_left, duration)


func _process_custom(_delta: float) -> void:
	pass


func _should_apply_attack_on_hit_delay() -> bool:
	return true


func _get_attack_phase_duration() -> float:
	return attack_duration


func _process_attack_phase(_delta: float) -> bool:
	return false


func _perform_attack() -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	_deal_attack_damage(attack_damage)


func _on_windup_started() -> void:
	pass


func _on_attack_started() -> void:
	pass


func _end_all_abilities() -> void:
	_clear_telegraph_vfx()


func _idle_anim_name() -> String:
	return enemy_id + "_idle"


func _move_anim_name() -> String:
	return enemy_id + "_move"


func _windup_anim_name() -> String:
	return _move_anim_name()


func _attack_anim_name() -> String:
	return _move_anim_name()


func _hurt_anim_name() -> String:
	return _move_anim_name()


func _death_anim_name() -> String:
	return _move_anim_name()


func _animation_sheet_specs() -> Dictionary:
	return {}


func _process_idle(_delta: float) -> void:
	if not _can_detect_player():
		_play_anim(_move_anim_name() if use_walk_for_idle else _idle_anim_name(), true)
		return
	current_state = STATE_CHASE
	_play_anim(_move_anim_name(), true)


func _process_chase(delta: float) -> void:
	if not _can_detect_player():
		_decelerate(delta)
		current_state = STATE_IDLE
		_play_anim(_move_anim_name() if use_walk_for_idle else _idle_anim_name(), true)
		return
	if use_slime_hop_combat:
		_process_slime_hop_chase(delta)
		return
	var dist_to_player: float = global_position.distance_to(target_player.global_position)
	var target_pos: Vector2 = _compute_strategic_target()
	if dist_to_player < stop_distance:
		var away: Vector2 = (global_position - target_player.global_position).normalized()
		target_pos = global_position + away * stop_distance * 0.35
	_apply_chase_movement(target_pos, delta)
	_play_anim(_move_anim_name(), true)
	if can_attack and _attack_cd_left <= 0.0 and dist_to_player <= attack_range:
		_begin_windup()


func _process_windup(delta: float) -> void:
	_decelerate(delta)
	_face_towards(_get_player_position())
	if _state_timer > 0.0:
		return
	_begin_attack()


func _process_attack(delta: float) -> void:
	_attack_elapsed += delta
	if _should_apply_attack_on_hit_delay() and not _attack_damage_done and _attack_elapsed >= attack_hit_delay:
		_attack_damage_done = true
		_perform_attack()
	var phase_done: bool = _process_attack_phase(delta)
	if not phase_done and _attack_elapsed < _get_attack_phase_duration():
		return
	_begin_recover()


func _process_recover(delta: float) -> void:
	_decelerate(delta)
	if _state_timer > 0.0:
		return
	current_state = STATE_CHASE if _can_detect_player() else STATE_IDLE
	_play_anim(_move_anim_name() if current_state == STATE_CHASE or use_walk_for_idle else _idle_anim_name(), true)


func _process_hurt(delta: float) -> void:
	_decelerate(delta)
	if _state_timer > 0.0:
		return
	current_state = STATE_CHASE if _can_detect_player() else STATE_IDLE
	_play_anim(_move_anim_name() if current_state == STATE_CHASE or use_walk_for_idle else _idle_anim_name(), true)


func _can_detect_player() -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return false
	return global_position.distance_to(target_player.global_position) <= detection_range


func _apply_chase_movement(target_pos: Vector2, delta: float) -> void:
	var to_target: Vector2 = target_pos - global_position
	var desired: Vector2 = Vector2.ZERO
	if to_target.length_squared() > 4.0:
		desired = to_target.normalized()
	desired += _compute_separation_force()
	if desired.length_squared() > 0.001:
		desired = desired.normalized()
	var speed_mult: float = maxf(0.1, _buff_move_mult)
	var target_velocity: Vector2 = desired * movement_speed * speed_mult
	velocity = velocity.lerp(target_velocity, movement_acceleration * delta)
	_apply_velocity(delta)


func _decelerate(delta: float) -> void:
	velocity = velocity.lerp(Vector2.ZERO, movement_deceleration * delta)
	_apply_velocity(delta)


func _apply_velocity(delta: float) -> void:
	if velocity.length_squared() <= 0.01:
		velocity = Vector2.ZERO
		return
	_update_facing_from_velocity()
	var next_pos: Vector2 = global_position + velocity * delta
	if not can_fly and world_ref != null and world_ref.has_method("is_world_position_on_walkable_tile"):
		if not bool(world_ref.call("is_world_position_on_walkable_tile", next_pos)):
			if world_ref.has_method("snap_world_position_to_walkable"):
				next_pos = world_ref.call("snap_world_position_to_walkable", next_pos)
				velocity *= 0.35
			else:
				velocity = Vector2.ZERO
				return
	global_position = next_pos


func _compute_separation_force() -> Vector2:
	var force: Vector2 = Vector2.ZERO
	for node in get_tree().get_nodes_in_group("hostile_mobs"):
		var ally: BaseEnemy = node as BaseEnemy
		if ally == null or ally == self or ally._is_dead:
			continue
		var away: Vector2 = global_position - ally.global_position
		var dist: float = away.length()
		if dist <= 0.001 or dist >= separation_radius:
			continue
		var push: float = (separation_radius - dist) / separation_radius
		force += away.normalized() * push * separation_strength / maxf(1.0, movement_speed)
	return force


func _update_facing_from_velocity() -> void:
	if sprite == null:
		return
	if velocity.length() < facing_deadzone:
		return
	_apply_facing_from_direction(velocity)


func _face_towards(world_pos: Vector2) -> void:
	var dir: Vector2 = world_pos - global_position
	if dir.length_squared() <= 0.001:
		return
	_apply_facing_from_direction(dir)


func _apply_facing_from_direction(dir: Vector2) -> void:
	if sprite == null:
		return
	if abs(dir.x) > abs(dir.y):
		facing_direction = "right" if dir.x > 0.0 else "left"
	else:
		facing_direction = "down" if dir.y > 0.0 else "up"
	if default_faces_left:
		sprite.flip_h = facing_direction == "right"
	else:
		sprite.flip_h = facing_direction == "left"


func _get_player_position() -> Vector2:
	if target_player != null and is_instance_valid(target_player):
		return target_player.global_position
	return global_position


func _begin_windup() -> void:
	if _is_hopping:
		_is_hopping = false
		if sprite != null:
			sprite.position.y = 0.0
			sprite.scale = Vector2.ONE
	current_state = STATE_WINDUP
	_state_timer = maxf(0.35, telegraph_duration)
	velocity = Vector2.ZERO
	_face_towards(_get_player_position())
	_on_windup_started()
	_play_anim(_state_action_anim(_windup_anim_name()), false)


func _begin_attack() -> void:
	current_state = STATE_ATTACK
	_attack_elapsed = 0.0
	_attack_damage_done = false
	_on_attack_started()
	_play_anim(_state_action_anim(_attack_anim_name()), false)


func _begin_recover() -> void:
	current_state = STATE_RECOVER
	_state_timer = maxf(0.08, recover_duration)
	velocity *= 0.25
	_clear_telegraph_vfx()
	_play_anim(_move_anim_name(), true)
	var haste: float = maxf(0.1, _buff_attack_haste)
	_attack_cd_left = maxf(0.05, attack_cooldown / haste)
	_on_recover_started()


func _on_recover_started() -> void:
	pass


func _vfx_world() -> Node:
	var world: Node = world_ref
	if world == null or not is_instance_valid(world):
		world = get_tree().current_scene if is_inside_tree() else null
	return world


func _track_telegraph_nodes(nodes: Array) -> void:
	for node in nodes:
		if node != null:
			_telegraph_markers.append(node)


func _clear_telegraph_vfx() -> void:
	for node in _telegraph_markers:
		if is_instance_valid(node):
			node.queue_free()
	_telegraph_markers.clear()
	if _active_beam_vfx != null and is_instance_valid(_active_beam_vfx):
		_active_beam_vfx.queue_free()
	_active_beam_vfx = null


func _vfx_tile_warning(pos: Vector2, duration: float, loop_pulse: bool) -> void:
	var world: Node = _vfx_world()
	if world != null and world.has_method("spawn_combat_tile_marker"):
		var marker: Node = world.spawn_combat_tile_marker(pos, duration, loop_pulse)
		if marker != null:
			_telegraph_markers.append(marker)


func _vfx_tile_box(center_world: Vector2, duration: float, loop_pulse: bool = true) -> void:
	var world: Node = _vfx_world()
	if world == null:
		return
	_track_telegraph_nodes(MobCombatVFX.spawn_tile_box(world, center_world, duration, loop_pulse))


func _vfx_beam_path_to_point(from_pos: Vector2, to_pos: Vector2, duration: float, loop_pulse: bool = true, beam_width: float = 8.0) -> void:
	var world: Node = _vfx_world()
	if world == null:
		return
	_track_telegraph_nodes(MobCombatVFX.spawn_tile_beam_path(world, from_pos, to_pos, duration, loop_pulse))
	_active_beam_vfx = MobCombatVFX.spawn_flicker_beam_warning(world, from_pos, to_pos, duration, beam_width)


func _get_aoe_box_tiles(center_world: Vector2, box_tiles: Vector2i = Vector2i(2, 2)) -> Array[Vector2i]:
	var world: Node = _vfx_world()
	if world == null or not world.has_method("world_to_tile"):
		return []
	var anchor: Vector2i = world.call("world_to_tile", center_world)
	var tiles: Array[Vector2i] = []
	for x in range(maxi(1, box_tiles.x)):
		for y in range(maxi(1, box_tiles.y)):
			tiles.append(anchor + Vector2i(x, y))
	return tiles


func _is_player_on_tiles(tiles: Array[Vector2i]) -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return false
	var world: Node = _vfx_world()
	if world == null or not world.has_method("world_to_tile"):
		return false
	var player_tile: Vector2i = world.call("world_to_tile", target_player.global_position)
	return player_tile in tiles


func _damage_player_in_tile_box(center_world: Vector2, damage: float, box_tiles: Vector2i = Vector2i(2, 2)) -> void:
	if _is_player_on_tiles(_get_aoe_box_tiles(center_world, box_tiles)):
		_deal_attack_damage(damage)


func _telegraph_player_aoe_box(duration: float, loop_pulse: bool = true) -> void:
	_vfx_tile_box(_get_player_position(), duration, loop_pulse)


func _process_slime_hop_chase(delta: float) -> void:
	if not _is_hopping and can_attack and _attack_cd_left <= 0.0:
		var dist: float = global_position.distance_to(_get_player_position())
		if dist <= attack_range:
			_begin_windup()
			return
	if _is_hopping:
		_update_slime_hop(delta)
	else:
		velocity = Vector2.ZERO
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			_begin_slime_hop_toward_player()
	_play_anim(_move_anim_name(), true)


func _begin_slime_hop_toward_player() -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	_hop_start = global_position
	var to_target: Vector2 = target_player.global_position - global_position
	var dir: Vector2 = Vector2.RIGHT
	if to_target.length_squared() > 0.001:
		dir = to_target.normalized()
	_apply_facing_from_direction(dir)
	var max_step: float = minf(hop_distance, to_target.length())
	_hop_target = global_position + dir * max_step
	if world_ref != null and world_ref.has_method("is_world_position_on_walkable_tile"):
		if not bool(world_ref.call("is_world_position_on_walkable_tile", _hop_target)):
			if world_ref.has_method("snap_world_position_to_walkable"):
				_hop_target = world_ref.call("snap_world_position_to_walkable", _hop_target)
			else:
				_hop_timer = hop_interval
				return
	_is_hopping = true
	_hop_elapsed = 0.0
	_vfx_tile_warning(_hop_target, hop_duration, true)


func _update_slime_hop(delta: float) -> void:
	_hop_elapsed += delta
	var t: float = clampf(_hop_elapsed / maxf(0.01, hop_duration), 0.0, 1.0)
	global_position = _hop_start.lerp(_hop_target, t)
	var arc: float = sin(t * PI) * hop_height
	if sprite != null:
		sprite.position.y = -arc
		var squash: float = sin(t * PI)
		sprite.scale = Vector2(1.0 + squash * 0.08, 1.0 - squash * 0.06)
	if t >= 1.0:
		_is_hopping = false
		_hop_timer = hop_interval
		if sprite != null:
			sprite.position.y = 0.0
			sprite.scale = Vector2.ONE
		_vfx_tile_warning(global_position, 0.22, false)


func _is_contact_state_blocked() -> bool:
	return current_state in [STATE_WINDUP, STATE_ATTACK, STATE_RECOVER, STATE_HURT, STATE_DEAD]


func _update_body_bob(delta: float) -> void:
	if sprite == null:
		return
	if current_state in [STATE_WINDUP, STATE_ATTACK, STATE_RECOVER, STATE_HURT, STATE_DEAD]:
		sprite.position.y = lerpf(sprite.position.y, 0.0, 12.0 * delta)
		return
	_bob_phase += delta * body_bob_speed
	var bob: float = sin(_bob_phase) * body_bob_amount
	if can_fly:
		bob += sin(_bob_phase * 1.7) * body_bob_amount * 0.35
	sprite.position.y = bob


func _update_attack_debug_shapes() -> void:
	for node in _debug_shapes:
		if is_instance_valid(node):
			node.queue_free()
	_debug_shapes.clear()
	if not show_attack_debug:
		return
	var root: Node = MobCombatVFX.world_root(self)
	if root == null:
		return
	var ring_line: Line2D = Line2D.new()
	ring_line.width = 3.0
	ring_line.default_color = Color(1.0, 0.2, 0.2, 0.5)
	ring_line.z_index = 30
	var r: float = attack_range
	for i in range(33):
		var ang: float = TAU * float(i) / 32.0
		ring_line.add_point(global_position + Vector2(cos(ang), sin(ang)) * r)
	root.add_child(ring_line)
	_debug_shapes.append(ring_line)


func _compute_strategic_target() -> Vector2:
	if target_player == null or not is_instance_valid(target_player):
		return global_position
	var base_target: Vector2 = target_player.global_position
	var allies: Array[BaseEnemy] = _nearby_allies()
	if allies.is_empty():
		return base_target
	var ordered: Array[BaseEnemy] = allies.duplicate()
	ordered.sort_custom(func(a: BaseEnemy, b: BaseEnemy) -> bool:
		return a.get_instance_id() < b.get_instance_id()
	)
	var slot_idx: int = 0
	for i in range(ordered.size()):
		if ordered[i] == self:
			slot_idx = i
			break
	var count: int = maxi(1, ordered.size())
	var angle: float = (TAU * float(slot_idx) / float(count)) + float(Time.get_ticks_msec() % 3600) * 0.00025
	var orbit_target: Vector2 = target_player.global_position + Vector2.RIGHT.rotated(angle) * strategic_orbit_radius
	var cutoff_target: Vector2 = target_player.global_position + _player_velocity * 0.42
	return orbit_target.lerp(cutoff_target, clampf(strategic_cutoff_weight, 0.0, 1.0))


func _nearby_allies() -> Array[BaseEnemy]:
	var result: Array[BaseEnemy] = []
	for node in get_tree().get_nodes_in_group("hostile_mobs"):
		var ally: BaseEnemy = node as BaseEnemy
		if ally == null:
			continue
		if ally._is_dead:
			continue
		if ally.global_position.distance_to(global_position) > 260.0:
			continue
		result.append(ally)
	return result


func _update_player_velocity(delta: float) -> void:
	if target_player == null:
		return
	if _player_last_pos == Vector2.ZERO:
		_player_last_pos = target_player.global_position
		return
	var dt: float = maxf(0.0001, delta)
	_player_velocity = (target_player.global_position - _player_last_pos) / dt
	_player_last_pos = target_player.global_position


func _update_contact_damage() -> void:
	if _contact_cd_left > 0.0:
		return
	if target_player == null or not is_instance_valid(target_player):
		return
	var dist: float = global_position.distance_to(target_player.global_position)
	if dist > maxf(10.0, attack_range * 0.35):
		return
	if target_player.has_method("take_damage"):
		target_player.call("take_damage", contact_damage)
	elif world_ref != null and world_ref.has_method("take_damage"):
		world_ref.call("take_damage", contact_damage)
	else:
		return
	_contact_cd_left = contact_damage_cooldown


func _deal_attack_damage(amount: float) -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	if target_player.has_method("take_damage"):
		target_player.call("take_damage", amount)
	elif world_ref != null and world_ref.has_method("take_damage"):
		world_ref.call("take_damage", amount)


func _update_buffs(delta: float) -> void:
	if _buff_left <= 0.0:
		_buff_move_mult = 1.0
		_buff_attack_haste = 1.0
		return
	_buff_left = maxf(0.0, _buff_left - delta)


func _update_flash_visual() -> void:
	if sprite == null:
		return
	var flash_mix: Color = _flash_color if _flash_left > 0.0 else _base_modulate
	sprite.modulate = flash_mix


func _build_nodes() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.z_index = 6
	add_child(sprite)
	collision_shape = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 10.0
	collision_shape.shape = shape
	add_child(collision_shape)


func _build_animations() -> void:
	if sprite == null:
		return
	var shared_frames: SpriteFrames = _resolve_frames_resource()
	if shared_frames != null:
		sprite.sprite_frames = shared_frames
		return
	var frames: SpriteFrames = SpriteFrames.new()
	var specs: Dictionary = _animation_sheet_specs()
	for anim_name_variant in specs.keys():
		var anim_name: String = String(anim_name_variant)
		var spec: Dictionary = specs[anim_name_variant]
		var tex: Texture2D = spec.get("texture", null)
		var frame_count: int = int(spec.get("frames", 4))
		var fps: float = float(spec.get("fps", 8.0))
		var loop: bool = bool(spec.get("loop", true))
		_add_animation_from_sheet(frames, anim_name, tex, frame_count, fps, loop)
	sprite.sprite_frames = frames


func _resolve_frames_resource() -> SpriteFrames:
	if frames_resource != null:
		return frames_resource
	for path in _frames_resource_candidates():
		if path.strip_edges() == "":
			continue
		if not ResourceLoader.exists(path):
			continue
		var loaded: Resource = load(path)
		if loaded is SpriteFrames:
			frames_resource = loaded as SpriteFrames
			return frames_resource
	return null


func _frames_resource_candidates() -> PackedStringArray:
	var paths: PackedStringArray = PackedStringArray([
		"res://assets/mobs/%s.tres" % enemy_id,
		"res://assets/mobs/%s_walk.tres" % enemy_id,
		"res://assets/mobs/%s_walking.tres" % enemy_id
	])
	if enemy_id == "mothcloak_priest":
		paths.append("res://assets/mobs/motheye_priest.tres")
	return paths


func _state_action_anim(requested: String) -> String:
	if use_single_walk_animation:
		return _move_anim_name()
	return requested


func _add_animation_from_sheet(frames: SpriteFrames, anim_name: String, texture: Texture2D, frame_count: int, fps: float, loop: bool) -> void:
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	if texture == null:
		var fallback: Texture2D = _make_placeholder_frame(Color(0.72, 0.86, 0.78, 1.0))
		for i in range(maxi(1, frame_count)):
			frames.add_frame(anim_name, fallback)
		return
	var source_image: Image = texture.get_image()
	if source_image == null:
		var fallback2: Texture2D = _make_placeholder_frame(Color(0.72, 0.86, 0.78, 1.0))
		for i in range(maxi(1, frame_count)):
			frames.add_frame(anim_name, fallback2)
		return
	var frame_w: int = 32
	var frame_h: int = 32
	var max_cols: int = maxi(1, texture.get_width() / frame_w)
	var max_rows: int = maxi(1, texture.get_height() / frame_h)
	for i in range(maxi(1, frame_count)):
		var col: int = i % max_cols
		var row: int = i / max_cols
		if row >= max_rows:
			break
		var rect: Rect2i = Rect2i(col * frame_w, row * frame_h, frame_w, frame_h)
		var frame_img: Image = Image.create(frame_w, frame_h, false, Image.FORMAT_RGBA8)
		frame_img.blit_rect(source_image, rect, Vector2i.ZERO)
		frames.add_frame(anim_name, ImageTexture.create_from_image(frame_img))
	if frames.get_frame_count(anim_name) <= 0:
		frames.add_frame(anim_name, _make_placeholder_frame(Color(0.72, 0.86, 0.78, 1.0)))


func _make_placeholder_frame(color: Color) -> Texture2D:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var c: Vector2 = Vector2(16.0, 16.0)
	for x in range(32):
		for y in range(32):
			var d: float = Vector2(float(x), float(y)).distance_to(c) / 14.0
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a))
	return ImageTexture.create_from_image(img)


func _play_anim(anim_name: String, loop: bool) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var resolved: String = anim_name
	if not sprite.sprite_frames.has_animation(resolved):
		var move_name: String = _move_anim_name()
		if sprite.sprite_frames.has_animation(move_name):
			resolved = move_name
		else:
			var names: PackedStringArray = sprite.sprite_frames.get_animation_names()
			if names.is_empty():
				return
			resolved = String(names[0])
	sprite.sprite_frames.set_animation_loop(resolved, loop)
	if sprite.animation != resolved:
		sprite.play(resolved)
	elif not sprite.is_playing():
		sprite.play(resolved)


func _current_anim_frame_count() -> int:
	if sprite == null or sprite.sprite_frames == null:
		return 1
	if not sprite.sprite_frames.has_animation(sprite.animation):
		return 1
	return max(1, sprite.sprite_frames.get_frame_count(sprite.animation))


func _update_death_anim(delta: float) -> void:
	_death_tick_left -= delta
	if _death_tick_left > 0.0:
		return
	_death_tick_left = 0.05
	_death_frames_left -= 1
	if _death_frames_left <= 0:
		slime_died.emit(self, room_center)
		queue_free()


func _emit_death_particles() -> void:
	MobCombatVFX.spawn_particle_burst(
		MobCombatVFX.world_root(self),
		global_position,
		Color(0.82, 0.76, 0.62, 0.92),
		36,
		0.5
	)


func _update_heart_visual() -> void:
	var hearts_needed: int = maxi(0, int(ceil(health / maxf(1.0, heart_points_per_heart))))
	while _heart_sprites.size() < hearts_needed:
		var heart: Sprite2D = Sprite2D.new()
		heart.texture = _heart_texture
		heart.z_index = 24
		heart.scale = Vector2.ONE * heart_scale
		add_child(heart)
		_heart_sprites.append(heart)
	for i in range(_heart_sprites.size()):
		var sprite_heart: Sprite2D = _heart_sprites[i]
		if sprite_heart == null:
			continue
		sprite_heart.visible = i < hearts_needed
		if _heart_texture != null:
			sprite_heart.texture = _heart_texture
	_layout_hearts()


func _layout_hearts() -> void:
	var visible: Array[Sprite2D] = []
	for h in _heart_sprites:
		if h != null and h.visible:
			visible.append(h)
	if visible.is_empty():
		return
	var spacing: float = 9.0 * heart_scale
	var start_x: float = -float(visible.size() - 1) * spacing * 0.5
	var y_pos: float = -28.0
	for i in range(visible.size()):
		visible[i].position = Vector2(start_x + float(i) * spacing, y_pos)


func _make_heart_texture(tint: Color) -> Texture2D:
	var image: Image = Image.create(12, 10, false, Image.FORMAT_RGBA8)
	var fill: Color = Color(
		clampf(tint.r * 1.2, 0.15, 1.0),
		clampf(tint.g * 1.2, 0.15, 1.0),
		clampf(tint.b * 1.2, 0.15, 1.0),
		1.0
	)
	var outline: Color = Color(fill.r * 0.35, fill.g * 0.35, fill.b * 0.35, 1.0)
	var pixels: PackedVector2Array = PackedVector2Array([
		Vector2(4, 1), Vector2(5, 1), Vector2(7, 1), Vector2(8, 1),
		Vector2(3, 2), Vector2(4, 2), Vector2(5, 2), Vector2(6, 2), Vector2(7, 2), Vector2(8, 2), Vector2(9, 2),
		Vector2(2, 3), Vector2(3, 3), Vector2(4, 3), Vector2(5, 3), Vector2(6, 3), Vector2(7, 3), Vector2(8, 3), Vector2(9, 3), Vector2(10, 3),
		Vector2(3, 4), Vector2(4, 4), Vector2(5, 4), Vector2(6, 4), Vector2(7, 4), Vector2(8, 4), Vector2(9, 4),
		Vector2(4, 5), Vector2(5, 5), Vector2(6, 5), Vector2(7, 5), Vector2(8, 5),
		Vector2(5, 6), Vector2(6, 6), Vector2(7, 6),
		Vector2(6, 7)
	])
	var lookup: Dictionary = {}
	for p in pixels:
		lookup["%d_%d" % [int(p.x), int(p.y)]] = true
	for p in pixels:
		var x: int = int(p.x)
		var y: int = int(p.y)
		var border: bool = false
		for off in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			if not lookup.has("%d_%d" % [x + off.x, y + off.y]):
				border = true
				break
		image.set_pixel(x, y, outline if border else fill)
	return ImageTexture.create_from_image(image)
