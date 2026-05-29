class_name MothcloakPriest
extends BaseEnemy

@export var mothcloak_priest_idle_hover: Texture2D = null
@export var mothcloak_priest_fly: Texture2D = null
@export var mothcloak_priest_conjure: Texture2D = null
@export var mothcloak_priest_hurt: Texture2D = null
@export var mothcloak_priest_death: Texture2D = null


func _ready() -> void:
	enemy_id = "mothcloak_priest"
	max_health = 35.0
	movement_speed = 60.0
	contact_damage = 8.0
	detection_range = 340.0
	can_fly = true
	use_slime_hop_combat = true
	can_attack = true
	attack_damage = 12.0
	attack_range = 180.0
	attack_cooldown = 3.5
	telegraph_duration = 0.92
	recover_duration = 0.36
	hop_interval = 0.66
	hop_distance = 52.0
	hop_height = 26.0
	knockback_resistance = 0.3
	loot_drop_chance = 0.68
	difficulty_value = 2.2
	stop_distance = 6.0
	body_bob_amount = 3.0
	base_tint = Color(0.92, 0.82, 0.44, 1.0)
	super._ready()


func _animation_sheet_specs() -> Dictionary:
	return {
		"mothcloak_priest_idle_hover": {"texture": mothcloak_priest_idle_hover, "frames": 4, "fps": 6.0, "loop": true},
		"mothcloak_priest_fly": {"texture": mothcloak_priest_fly, "frames": 8, "fps": 10.0, "loop": true},
		"mothcloak_priest_conjure": {"texture": mothcloak_priest_conjure, "frames": 3, "fps": 11.0, "loop": false},
		"mothcloak_priest_hurt": {"texture": mothcloak_priest_hurt, "frames": 2, "fps": 12.0, "loop": false},
		"mothcloak_priest_death": {"texture": mothcloak_priest_death, "frames": 5, "fps": 9.0, "loop": false}
	}


func _idle_anim_name() -> String:
	return "mothcloak_priest_idle_hover"


func _move_anim_name() -> String:
	return "mothcloak_priest_fly"


func _hurt_anim_name() -> String:
	return "mothcloak_priest_hurt"


func _death_anim_name() -> String:
	return "mothcloak_priest_death"


func _windup_anim_name() -> String:
	return "mothcloak_priest_conjure"


func _attack_anim_name() -> String:
	return "mothcloak_priest_conjure"


func _on_windup_started() -> void:
	_clear_telegraph_vfx()
	_telegraph_player_aoe_box(_state_timer, true)


func _perform_attack() -> void:
	_damage_player_in_tile_box(_get_player_position(), attack_damage)
	MobCombatVFX.spawn_impact_burst(_vfx_world(), _get_player_position(), Color(0.95, 0.82, 0.38, 0.92), 16.0, 0.32)
	_clear_telegraph_vfx()
