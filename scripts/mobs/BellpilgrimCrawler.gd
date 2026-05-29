class_name BellpilgrimCrawler
extends BaseEnemy

@export var ring_range: float = 220.0
@export var ally_move_buff: float = 1.2
@export var ally_attack_haste: float = 1.1
@export var ally_buff_duration: float = 3.0
@export var ring_close_damage: float = 5.0
@export var flee_distance: float = 140.0
@export var ring_display_duration: float = 3.2

@export var bellpilgrim_crawler_idle: Texture2D = null
@export var bellpilgrim_crawler_crawl: Texture2D = null
@export var bellpilgrim_crawler_ring: Texture2D = null
@export var bellpilgrim_crawler_hurt: Texture2D = null
@export var bellpilgrim_crawler_death: Texture2D = null


func _ready() -> void:
	enemy_id = "bellpilgrim_crawler"
	max_health = 50.0
	movement_speed = 52.0
	contact_damage = 7.0
	attack_damage = 5.0
	detection_range = 300.0
	attack_range = 200.0
	attack_cooldown = 5.0
	telegraph_duration = 1.1
	recover_duration = 0.4
	attack_hit_delay = 0.2
	attack_duration = 0.4
	knockback_resistance = 0.6
	loot_drop_chance = 0.72
	difficulty_value = 1.7
	strategic_orbit_radius = 92.0
	stop_distance = 120.0
	body_bob_amount = 2.4
	use_slime_hop_combat = false
	can_attack = true
	base_tint = Color(0.86, 0.72, 0.40, 1.0)
	super._ready()


func _animation_sheet_specs() -> Dictionary:
	return {
		"bellpilgrim_crawler_idle": {"texture": bellpilgrim_crawler_idle, "frames": 4, "fps": 6.0, "loop": true},
		"bellpilgrim_crawler_crawl": {"texture": bellpilgrim_crawler_crawl, "frames": 6, "fps": 8.0, "loop": true},
		"bellpilgrim_crawler_ring": {"texture": bellpilgrim_crawler_ring, "frames": 4, "fps": 10.0, "loop": false},
		"bellpilgrim_crawler_hurt": {"texture": bellpilgrim_crawler_hurt, "frames": 2, "fps": 12.0, "loop": false},
		"bellpilgrim_crawler_death": {"texture": bellpilgrim_crawler_death, "frames": 5, "fps": 9.0, "loop": false}
	}


func _idle_anim_name() -> String:
	return "bellpilgrim_crawler_idle"


func _move_anim_name() -> String:
	return "bellpilgrim_crawler_crawl"


func _windup_anim_name() -> String:
	return "bellpilgrim_crawler_ring"


func _attack_anim_name() -> String:
	return "bellpilgrim_crawler_ring"


func _hurt_anim_name() -> String:
	return "bellpilgrim_crawler_hurt"


func _death_anim_name() -> String:
	return "bellpilgrim_crawler_death"


func _process_chase(delta: float) -> void:
	if not _can_detect_player():
		_decelerate(delta)
		current_state = STATE_IDLE
		_play_anim(_idle_anim_name(), true)
		return
	var flee_dir: Vector2 = (global_position - target_player.global_position).normalized()
	var flee_target: Vector2 = global_position + flee_dir * flee_distance
	_apply_chase_movement(flee_target, delta)
	_face_towards(target_player.global_position)
	_play_anim(_move_anim_name(), true)
	var dist: float = global_position.distance_to(target_player.global_position)
	if can_attack and _attack_cd_left <= 0.0 and dist <= attack_range:
		_begin_windup()


func _on_windup_started() -> void:
	_clear_telegraph_vfx()
	_telegraph_player_aoe_box(ring_display_duration + telegraph_duration, true)


func _perform_attack() -> void:
	_emit_ring_wave()
	_damage_player_in_tile_box(_get_player_position(), ring_close_damage)
	if target_player != null and is_instance_valid(target_player):
		MobCombatVFX.spawn_particle_burst(
			_vfx_world(),
			target_player.global_position,
			Color(1.0, 0.82, 0.28, 0.95),
			36
		)
	for ally in _nearby_allies():
		if ally == self:
			continue
		if ally.global_position.distance_to(global_position) > ring_range:
			continue
		ally.apply_temporary_buffs(ally_move_buff, ally_attack_haste, ally_buff_duration)
		_vfx_tile_box(ally.global_position, 0.9, true)


func _emit_ring_wave() -> void:
	var world: Node = _vfx_world()
	_telegraph_player_aoe_box(ring_display_duration, true)
	MobCombatVFX.spawn_particle_burst(
		world,
		_get_player_position(),
		Color(1.0, 0.88, 0.35, 0.95),
		48,
		0.5
	)


func _end_all_abilities() -> void:
	_clear_telegraph_vfx()
