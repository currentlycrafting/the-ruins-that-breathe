class_name PetalwretchOoze
extends BaseEnemy

@export var petalwretch_ooze_idle: Texture2D = null
@export var petalwretch_ooze_seep: Texture2D = null
@export var petalwretch_ooze_summon: Texture2D = null
@export var petalwretch_ooze_hurt: Texture2D = null
@export var petalwretch_ooze_death: Texture2D = null


func _ready() -> void:
	enemy_id = "petalwretch_ooze"
	max_health = 55.0
	movement_speed = 34.0
	contact_damage = 9.0
	detection_range = 280.0
	use_slime_hop_combat = true
	can_attack = true
	attack_damage = 10.0
	attack_range = 160.0
	attack_cooldown = 3.7
	telegraph_duration = 0.86
	recover_duration = 0.33
	hop_interval = 0.68
	hop_distance = 50.0
	hop_height = 22.0
	knockback_resistance = 0.6
	loot_drop_chance = 0.72
	difficulty_value = 1.2
	stop_distance = 6.0
	base_tint = Color(0.86, 0.36, 0.58, 1.0)
	super._ready()


func _animation_sheet_specs() -> Dictionary:
	return {
		"petalwretch_ooze_idle": {"texture": petalwretch_ooze_idle, "frames": 4, "fps": 6.0, "loop": true},
		"petalwretch_ooze_seep": {"texture": petalwretch_ooze_seep, "frames": 6, "fps": 8.0, "loop": true},
		"petalwretch_ooze_summon": {"texture": petalwretch_ooze_summon, "frames": 3, "fps": 10.0, "loop": false},
		"petalwretch_ooze_hurt": {"texture": petalwretch_ooze_hurt, "frames": 2, "fps": 12.0, "loop": false},
		"petalwretch_ooze_death": {"texture": petalwretch_ooze_death, "frames": 5, "fps": 9.0, "loop": false}
	}


func _idle_anim_name() -> String:
	return "petalwretch_ooze_idle"


func _move_anim_name() -> String:
	return "petalwretch_ooze_seep"


func _hurt_anim_name() -> String:
	return "petalwretch_ooze_hurt"


func _death_anim_name() -> String:
	return "petalwretch_ooze_death"


func _windup_anim_name() -> String:
	return "petalwretch_ooze_summon"


func _attack_anim_name() -> String:
	return "petalwretch_ooze_summon"


func _on_windup_started() -> void:
	_clear_telegraph_vfx()
	_telegraph_player_aoe_box(_state_timer, true)


func _perform_attack() -> void:
	_damage_player_in_tile_box(_get_player_position(), attack_damage)
	MobCombatVFX.spawn_impact_burst(_vfx_world(), _get_player_position(), Color(0.92, 0.34, 0.62, 0.9), 16.0, 0.32)
	_clear_telegraph_vfx()
