class_name ShellcloakOracle
extends BaseEnemy

@export var slow_multiplier: float = 0.75
@export var slow_duration: float = 2.0

@export var shellcloak_oracle_idle: Texture2D = null
@export var shellcloak_oracle_move: Texture2D = null
@export var shellcloak_oracle_curse: Texture2D = null
@export var shellcloak_oracle_hurt: Texture2D = null
@export var shellcloak_oracle_death: Texture2D = null


func _ready() -> void:
	enemy_id = "shellcloak_oracle"
	max_health = 45.0
	movement_speed = 35.0
	contact_damage = 8.0
	detection_range = 240.0
	use_slime_hop_combat = true
	can_attack = true
	attack_damage = 11.0
	attack_range = 170.0
	attack_cooldown = 3.8
	telegraph_duration = 0.9
	recover_duration = 0.35
	hop_interval = 0.78
	hop_distance = 42.0
	hop_height = 18.0
	knockback_resistance = 0.7
	loot_drop_chance = 0.62
	difficulty_value = 1.0
	stop_distance = 6.0
	base_tint = Color(0.52, 0.70, 0.85, 1.0)
	super._ready()


func _animation_sheet_specs() -> Dictionary:
	return {
		"shellcloak_oracle_idle": {"texture": shellcloak_oracle_idle, "frames": 4, "fps": 6.0, "loop": true},
		"shellcloak_oracle_move": {"texture": shellcloak_oracle_move, "frames": 8, "fps": 8.0, "loop": true},
		"shellcloak_oracle_curse": {"texture": shellcloak_oracle_curse, "frames": 6, "fps": 10.0, "loop": false},
		"shellcloak_oracle_hurt": {"texture": shellcloak_oracle_hurt, "frames": 2, "fps": 12.0, "loop": false},
		"shellcloak_oracle_death": {"texture": shellcloak_oracle_death, "frames": 5, "fps": 9.0, "loop": false}
	}


func _idle_anim_name() -> String:
	return "shellcloak_oracle_idle"


func _move_anim_name() -> String:
	return "shellcloak_oracle_move"


func _hurt_anim_name() -> String:
	return "shellcloak_oracle_hurt"


func _death_anim_name() -> String:
	return "shellcloak_oracle_death"


func _windup_anim_name() -> String:
	return "shellcloak_oracle_curse"


func _attack_anim_name() -> String:
	return "shellcloak_oracle_curse"


func _on_windup_started() -> void:
	_clear_telegraph_vfx()
	_telegraph_player_aoe_box(_state_timer, true)


func _perform_attack() -> void:
	_damage_player_in_tile_box(_get_player_position(), attack_damage)
	var world: Node = _vfx_world()
	if world != null and world.has_method("apply_player_slow"):
		world.call("apply_player_slow", slow_multiplier, slow_duration)
	MobCombatVFX.spawn_impact_burst(world, _get_player_position(), Color(0.42, 0.72, 1.0, 0.9), 16.0, 0.32)
	_clear_telegraph_vfx()


func _update_contact_damage() -> void:
	if _contact_cd_left > 0.0:
		return
	if target_player == null or not is_instance_valid(target_player):
		return
	if global_position.distance_to(target_player.global_position) > 22.0:
		return
	if target_player.has_method("take_damage"):
		target_player.call("take_damage", contact_damage)
	elif world_ref != null and world_ref.has_method("take_damage"):
		world_ref.call("take_damage", contact_damage)
	else:
		return
	_contact_cd_left = contact_damage_cooldown
	if world_ref != null and world_ref.has_method("apply_player_slow"):
		world_ref.call("apply_player_slow", slow_multiplier, slow_duration)
