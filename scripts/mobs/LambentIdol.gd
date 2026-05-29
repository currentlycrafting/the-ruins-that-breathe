class_name LambentIdol
extends BaseEnemy

@export var lambent_idol_idle: Texture2D = null
@export var lambent_idol_walk: Texture2D = null
@export var lambent_idol_charge: Texture2D = null
@export var lambent_idol_hurt: Texture2D = null
@export var lambent_idol_death: Texture2D = null


func _ready() -> void:
	enemy_id = "lambent_idol"
	max_health = 60.0
	movement_speed = 45.0
	contact_damage = 14.0
	detection_range = 280.0
	use_slime_hop_combat = true
	can_attack = true
	attack_damage = 16.0
	attack_range = 165.0
	attack_cooldown = 3.6
	telegraph_duration = 0.85
	recover_duration = 0.32
	hop_interval = 0.62
	hop_distance = 54.0
	hop_height = 24.0
	knockback_resistance = 0.8
	loot_drop_chance = 0.70
	difficulty_value = 1.5
	stop_distance = 6.0
	base_tint = Color(0.95, 0.72, 0.34, 1.0)
	super._ready()


func _animation_sheet_specs() -> Dictionary:
	return {
		"lambent_idol_idle": {"texture": lambent_idol_idle, "frames": 4, "fps": 6.0, "loop": true},
		"lambent_idol_walk": {"texture": lambent_idol_walk, "frames": 6, "fps": 8.0, "loop": true},
		"lambent_idol_charge": {"texture": lambent_idol_charge, "frames": 4, "fps": 12.0, "loop": true},
		"lambent_idol_hurt": {"texture": lambent_idol_hurt, "frames": 2, "fps": 12.0, "loop": false},
		"lambent_idol_death": {"texture": lambent_idol_death, "frames": 5, "fps": 9.0, "loop": false}
	}


func _idle_anim_name() -> String:
	return "lambent_idol_idle"


func _move_anim_name() -> String:
	return "lambent_idol_walk"


func _hurt_anim_name() -> String:
	return "lambent_idol_hurt"


func _death_anim_name() -> String:
	return "lambent_idol_death"


func _windup_anim_name() -> String:
	return "lambent_idol_charge"


func _attack_anim_name() -> String:
	return "lambent_idol_charge"


func _on_windup_started() -> void:
	_clear_telegraph_vfx()
	_telegraph_player_aoe_box(_state_timer, true)


func _perform_attack() -> void:
	_damage_player_in_tile_box(_get_player_position(), attack_damage)
	MobCombatVFX.spawn_impact_burst(_vfx_world(), _get_player_position(), Color(1.0, 0.72, 0.22, 0.95), 18.0, 0.3)
	_clear_telegraph_vfx()
