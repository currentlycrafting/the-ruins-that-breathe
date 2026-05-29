class_name BloommawLurker
extends BaseEnemy

@export var bloommaw_lurker_idle: Texture2D = null
@export var bloommaw_lurker_crawl: Texture2D = null
@export var bloommaw_lurker_pounce: Texture2D = null
@export var bloommaw_lurker_hurt: Texture2D = null
@export var bloommaw_lurker_death: Texture2D = null


func _ready() -> void:
	enemy_id = "bloommaw_lurker"
	max_health = 65.0
	movement_speed = 42.0
	contact_damage = 14.0
	detection_range = 290.0
	use_slime_hop_combat = true
	can_attack = false
	attack_range = 0.0
	hop_interval = 0.58
	hop_distance = 58.0
	hop_height = 50.0
	hop_duration = 0.38
	knockback_resistance = 0.7
	loot_drop_chance = 0.88
	difficulty_value = 2.0
	stop_distance = 6.0
	base_tint = Color(0.66, 0.88, 0.34, 1.0)
	super._ready()


func _animation_sheet_specs() -> Dictionary:
	return {
		"bloommaw_lurker_idle": {"texture": bloommaw_lurker_idle, "frames": 4, "fps": 6.0, "loop": true},
		"bloommaw_lurker_crawl": {"texture": bloommaw_lurker_crawl, "frames": 6, "fps": 8.0, "loop": true},
		"bloommaw_lurker_pounce": {"texture": bloommaw_lurker_pounce, "frames": 3, "fps": 11.0, "loop": true},
		"bloommaw_lurker_hurt": {"texture": bloommaw_lurker_hurt, "frames": 2, "fps": 12.0, "loop": false},
		"bloommaw_lurker_death": {"texture": bloommaw_lurker_death, "frames": 5, "fps": 9.0, "loop": false}
	}


func _idle_anim_name() -> String:
	return "bloommaw_lurker_idle"


func _move_anim_name() -> String:
	return "bloommaw_lurker_crawl"


func _hurt_anim_name() -> String:
	return "bloommaw_lurker_hurt"


func _death_anim_name() -> String:
	return "bloommaw_lurker_death"
