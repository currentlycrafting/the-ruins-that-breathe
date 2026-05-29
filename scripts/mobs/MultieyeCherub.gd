class_name MultieyeCherub
extends BaseEnemy

@export var beam_range: float = 520.0
@export var beam_damage: float = 18.0

@export var multieye_cherub_idle: Texture2D = null
@export var multieye_cherub_walk: Texture2D = null
@export var multieye_cherub_beam: Texture2D = null
@export var multieye_cherub_hurt: Texture2D = null
@export var multieye_cherub_death: Texture2D = null


func _ready() -> void:
	enemy_id = "multieye_cherub"
	max_health = 70.0
	movement_speed = 22.0
	contact_damage = 12.0
	detection_range = 360.0
	use_slime_hop_combat = true
	can_attack = true
	attack_damage = beam_damage
	attack_range = 400.0
	attack_cooldown = 4.4
	telegraph_duration = 1.05
	recover_duration = 0.45
	attack_hit_delay = 0.18
	attack_duration = 0.42
	hop_interval = 0.82
	hop_distance = 40.0
	hop_height = 16.0
	knockback_resistance = 0.9
	loot_drop_chance = 0.9
	difficulty_value = 2.5
	stop_distance = 6.0
	base_tint = Color(0.80, 0.64, 0.94, 1.0)
	super._ready()


func _animation_sheet_specs() -> Dictionary:
	return {
		"multieye_cherub_idle": {"texture": multieye_cherub_idle, "frames": 4, "fps": 6.0, "loop": true},
		"multieye_cherub_walk": {"texture": multieye_cherub_walk, "frames": 4, "fps": 7.0, "loop": true},
		"multieye_cherub_beam": {"texture": multieye_cherub_beam, "frames": 4, "fps": 10.0, "loop": false},
		"multieye_cherub_hurt": {"texture": multieye_cherub_hurt, "frames": 2, "fps": 12.0, "loop": false},
		"multieye_cherub_death": {"texture": multieye_cherub_death, "frames": 5, "fps": 9.0, "loop": false}
	}


func _idle_anim_name() -> String:
	return "multieye_cherub_idle"


func _move_anim_name() -> String:
	return "multieye_cherub_walk"


func _windup_anim_name() -> String:
	return "multieye_cherub_beam"


func _attack_anim_name() -> String:
	return "multieye_cherub_beam"


func _hurt_anim_name() -> String:
	return "multieye_cherub_hurt"


func _death_anim_name() -> String:
	return "multieye_cherub_death"


func _beam_end_position() -> Vector2:
	var player_pos: Vector2 = _get_player_position()
	var dir: Vector2 = player_pos - global_position
	if dir.length_squared() <= 0.001:
		dir = Vector2.RIGHT
	else:
		dir = dir.normalized()
	return global_position + dir * beam_range


func _on_windup_started() -> void:
	_clear_telegraph_vfx()
	_vfx_beam_path_to_point(global_position, _beam_end_position(), _state_timer, true, 11.0)


func _perform_attack() -> void:
	var beam_end: Vector2 = _beam_end_position()
	var world: Node = _vfx_world()
	MobCombatVFX.spawn_beam_flash(world, global_position, beam_end, 14.0, 0.38)
	if _is_player_on_beam(beam_end):
		_deal_attack_damage(beam_damage)
	_clear_telegraph_vfx()


func _is_player_on_beam(beam_end: Vector2) -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return false
	var world: Node = _vfx_world()
	if world == null or not world.has_method("world_to_tile"):
		return global_position.distance_to(target_player.global_position) <= 36.0
	var player_tile: Vector2i = world.call("world_to_tile", target_player.global_position)
	var seen: Dictionary = {}
	var steps: int = maxi(2, int(ceil(global_position.distance_to(beam_end) / 28.0)))
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var sample: Vector2 = global_position.lerp(beam_end, t)
		var tile: Vector2i = world.call("world_to_tile", sample)
		if seen.has(tile):
			continue
		seen[tile] = true
		if player_tile == tile:
			return true
	return false
