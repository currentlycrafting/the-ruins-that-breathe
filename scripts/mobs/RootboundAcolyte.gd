class_name RootboundAcolyte
extends BaseEnemy

@export var rootbound_acolyte_idle: Texture2D = null
@export var rootbound_acolyte_walk: Texture2D = null
@export var rootbound_acolyte_root_shoot: Texture2D = null
@export var rootbound_acolyte_hurt: Texture2D = null
@export var rootbound_acolyte_death: Texture2D = null


func _ready() -> void:
	enemy_id = "rootbound_acolyte"
	max_health = 40.0
	movement_speed = 38.0
	contact_damage = 10.0
	detection_range = 320.0
	use_slime_hop_combat = true
	can_attack = true
	attack_damage = 13.0
	attack_range = 175.0
	attack_cooldown = 3.4
	telegraph_duration = 0.88
	recover_duration = 0.34
	hop_interval = 0.74
	hop_distance = 46.0
	hop_height = 18.0
	knockback_resistance = 0.4
	loot_drop_chance = 0.66
	difficulty_value = 1.8
	stop_distance = 6.0
	base_tint = Color(0.58, 0.44, 0.28, 1.0)
	super._ready()


func _animation_sheet_specs() -> Dictionary:
	return {
		"rootbound_acolyte_idle": {"texture": rootbound_acolyte_idle, "frames": 4, "fps": 6.0, "loop": true},
		"rootbound_acolyte_walk": {"texture": rootbound_acolyte_walk, "frames": 6, "fps": 8.0, "loop": true},
		"rootbound_acolyte_root_shoot": {"texture": rootbound_acolyte_root_shoot, "frames": 4, "fps": 11.0, "loop": false},
		"rootbound_acolyte_hurt": {"texture": rootbound_acolyte_hurt, "frames": 2, "fps": 12.0, "loop": false},
		"rootbound_acolyte_death": {"texture": rootbound_acolyte_death, "frames": 5, "fps": 9.0, "loop": false}
	}


func _idle_anim_name() -> String:
	return "rootbound_acolyte_idle"


func _move_anim_name() -> String:
	return "rootbound_acolyte_walk"


func _hurt_anim_name() -> String:
	return "rootbound_acolyte_hurt"


func _death_anim_name() -> String:
	return "rootbound_acolyte_death"


func _windup_anim_name() -> String:
	return "rootbound_acolyte_root_shoot"


func _attack_anim_name() -> String:
	return "rootbound_acolyte_root_shoot"


func _on_windup_started() -> void:
	_clear_telegraph_vfx()
	_telegraph_player_aoe_box(_state_timer, true)


func _perform_attack() -> void:
	_damage_player_in_tile_box(_get_player_position(), attack_damage)
	MobCombatVFX.spawn_impact_burst(_vfx_world(), _get_player_position(), Color(0.58, 0.42, 0.22, 0.92), 16.0, 0.32)
	_clear_telegraph_vfx()
