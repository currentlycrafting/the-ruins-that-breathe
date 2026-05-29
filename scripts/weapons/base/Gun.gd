class_name Gun
extends "res://scripts/weapons/Weapon.gd"

## Gun.gd
## Reusable ranged-weapon base with inspector-first tuning.

@export_group("Identity")
@export var description_text: String = ""
@export var world_settings_getter_name: String = ""
@export var floor_weapon_scale_override: Vector2 = Vector2(0.55, 0.55)
@export var weapon_offset_position: Vector2 = Vector2.ZERO
@export var hand_equip_position: Vector2 = Vector2.ZERO
@export var rarity_glow_color: Color = Color(1.0, 1.0, 1.0, 1.0)

@export_group("Core Weapon Stats")
@export var base_damage: float = 8.0
@export var base_fire_rate: float = 0.18
@export var base_charge_time: float = 1.1
@export var base_charge_damage_multiplier: float = 2.8
@export var base_projectile_speed: float = 460.0
@export var base_spawn_distance: float = 28.0
@export var base_spawn_y_offset: float = -8.0

@export_group("Projectile Pattern")
@export var projectile_animation_frames: SpriteFrames = null
@export var projectile_animation_name: String = "fly"
@export var projectile_lifetime: float = 1.10
@export var projectile_size: Vector2 = Vector2.ONE
@export var projectile_hit_radius: float = 9.0
@export var projectile_spread_degrees: float = 0.0
@export var projectiles_per_shot: int = 1
@export var shotgun_arc_degrees: float = 0.0
@export var burst_count: int = 1
@export var burst_interval: float = 0.07
@export var piercing_amount: int = 0
@export var bounce_count: int = 0
@export var bounce_speed_multiplier: float = 0.75
@export var projectile_arc_height: float = 0.0

@export_group("Charged Shot")
@export var charged_projectile_frames: SpriteFrames = null
@export var charged_projectile_animation_name: String = "fly"
@export var charged_projectile_damage: float = 20.0
@export var charged_projectile_speed: float = 340.0
@export var charged_projectile_size: Vector2 = Vector2(1.3, 1.3)
@export var charged_projectile_lifetime: float = 1.25
@export var charged_projectile_hit_radius: float = 15.0
@export var charge_screen_shake: float = 2.0
@export var charge_screen_flash_intensity: float = 0.0

@export_group("Explosion")
@export var explosion_enabled: bool = true
@export var explosion_animation_frames: SpriteFrames = null
@export var explosion_animation_name: String = "explode"
@export var explosion_radius: float = 40.0
@export var explosion_damage: float = 24.0
@export var explosion_duration: float = 0.30
@export var explosion_scale: Vector2 = Vector2.ONE
@export var explosion_damage_once: bool = true

@export_group("Game Feel")
@export var knockback_force: float = 0.0
@export var recoil_kickback: float = 5.0
@export var enable_recoil_kickback: bool = true
@export var screen_shake_amount: float = 0.45
@export var camera_shake_intensity: float = 7.0
@export var cooldown_mode: String = "after_shot"

@export_group("Visual / Audio Hooks")
@export var muzzle_flash_frames: SpriteFrames = null
@export var impact_animation_frames: SpriteFrames = null
@export var shoot_sound: AudioStream = null
@export var charge_sound: AudioStream = null
@export var player_walk_frames_override: SpriteFrames = null
@export var player_shoot_frames_override: SpriteFrames = null
@export var player_walk_scale_override: Vector2 = Vector2.ONE
@export var player_shoot_scale_override: Vector2 = Vector2.ONE
@export var ui_icon: Texture2D = null
@export var floor_pickup_sprite: Texture2D = null

var _burst_in_progress: bool = false

func _ready() -> void:
	super._ready()
	_apply_base_stats()

func get_world_settings_getter_name() -> String:
	return world_settings_getter_name

func apply_runtime_settings(settings: Dictionary) -> void:
	for key in settings.keys():
		if settings[key] == null and key in ["weapon_icon_texture", "ui_icon", "weapon_floor_texture", "floor_pickup_sprite"]:
			continue
		if _has_property(key):
			set(key, settings[key])
	if settings.has("visual_quality"):
		visual_quality = settings["visual_quality"]
	_apply_base_stats()

func _has_property(property_name: String) -> bool:
	for entry in get_property_list():
		if String(entry.get("name", "")) == property_name:
			return true
	return false

func _apply_base_stats() -> void:
	damage = base_damage
	fire_rate = base_fire_rate
	charge_time = base_charge_time
	charge_damage_multiplier = base_charge_damage_multiplier
	projectile_speed = base_projectile_speed
	projectile_spawn_distance = base_spawn_distance
	projectile_spawn_y_offset = base_spawn_y_offset
	can_charge = true
	weapon_floor_scale = floor_weapon_scale_override
	weapon_description = description_text
	if player_walk_frames_override != null:
		player_walk_frames = player_walk_frames_override
	if player_shoot_frames_override != null:
		player_shoot_frames = player_shoot_frames_override
	if ui_icon != null:
		weapon_icon_texture = ui_icon
	if floor_pickup_sprite != null:
		weapon_floor_texture = floor_pickup_sprite

func shoot(direction: Vector2) -> void:
	if not can_fire() or _burst_in_progress:
		return
	if is_charging:
		return
	cooldown_remaining = fire_rate
	_play_sound(shoot_sound)
	_start_fire_pattern(_sanitize_direction(direction), false, 0.0)
	_apply_fire_feedback(_sanitize_direction(direction), false)

func release_charge(direction: Vector2) -> void:
	if not is_equipped:
		cancel_charge()
		return
	var ratio: float = get_charge_ratio()
	cancel_charge()
	if ratio < 0.15:
		shoot(direction)
		return
	if not can_fire() or _burst_in_progress:
		return
	cooldown_remaining = fire_rate
	_play_sound(charge_sound)
	_start_fire_pattern(_sanitize_direction(direction), true, ratio)
	_apply_fire_feedback(_sanitize_direction(direction), true)

func _start_fire_pattern(direction: Vector2, is_charged: bool, charge_ratio: float) -> void:
	var burst_total: int = maxi(1, burst_count)
	if burst_total <= 1:
		_fire_once(direction, is_charged, charge_ratio)
		return
	_burst_in_progress = true
	_fire_burst_series(direction, is_charged, charge_ratio)

func _fire_burst_series(direction: Vector2, is_charged: bool, charge_ratio: float) -> void:
	var total_bursts: int = maxi(1, burst_count)
	for index in range(total_bursts):
		_fire_once(direction, is_charged, charge_ratio)
		if index < total_bursts - 1:
			await get_tree().create_timer(maxf(0.01, burst_interval)).timeout
	_burst_in_progress = false

func _fire_once(direction: Vector2, is_charged: bool, charge_ratio: float) -> void:
	var count: int = maxi(1, projectiles_per_shot)
	var base_angle: float = direction.angle()
	var arc: float = shotgun_arc_degrees
	if count <= 1:
		_spawn_profile_projectile(_build_projectile(is_charged, charge_ratio, direction), direction)
		return
	for i in range(count):
		var step_lerp: float = 0.0 if count <= 1 else float(i) / float(count - 1)
		var arc_offset: float = lerpf(-arc * 0.5, arc * 0.5, step_lerp)
		var random_spread: float = randf_range(-projectile_spread_degrees, projectile_spread_degrees)
		var fire_dir: Vector2 = Vector2.RIGHT.rotated(base_angle + deg_to_rad(arc_offset + random_spread)).normalized()
		_spawn_profile_projectile(_build_projectile(is_charged, charge_ratio, fire_dir), fire_dir)

func _spawn_profile_projectile(projectile: Projectile, direction: Vector2) -> void:
	if projectile == null:
		return
	_spawn_projectile(projectile, direction)

func _build_projectile(is_charged: bool, charge_ratio: float, direction: Vector2) -> Projectile:
	var projectile: Projectile = Projectile.new()
	var profile: Dictionary = _build_regular_profile()
	if is_charged:
		profile = _build_charged_profile(charge_ratio)
	_customize_projectile_profile(profile, is_charged, charge_ratio)
	projectile.setup(profile, direction, visual_quality)
	return projectile

func _build_regular_profile() -> Dictionary:
	return {
		"is_charged": false,
		"frames": projectile_animation_frames,
		"animation_name": projectile_animation_name,
		"speed": projectile_speed,
		"damage": damage,
		"scale": projectile_size,
		"lifetime": projectile_lifetime,
		"hit_radius": projectile_hit_radius,
		"piercing_amount": piercing_amount,
		"bounce_count": bounce_count,
		"bounce_speed_multiplier": bounce_speed_multiplier,
		"arc_height": projectile_arc_height
	}

func _build_charged_profile(charge_ratio: float) -> Dictionary:
	var ratio: float = clampf(charge_ratio, 0.0, 1.0)
	var charged_damage: float = maxf(charged_projectile_damage, damage * lerpf(1.4, charge_damage_multiplier, ratio))
	var profile: Dictionary = {
		"is_charged": true,
		"frames": charged_projectile_frames if charged_projectile_frames != null else projectile_animation_frames,
		"animation_name": charged_projectile_animation_name,
		"speed": lerpf(charged_projectile_speed, charged_projectile_speed * 1.12, ratio),
		"damage": charged_damage,
		"scale": charged_projectile_size * (1.0 + ratio * 0.2),
		"lifetime": charged_projectile_lifetime,
		"hit_radius": charged_projectile_hit_radius * (1.0 + ratio * 0.12),
		"piercing_amount": piercing_amount,
		"bounce_count": bounce_count,
		"bounce_speed_multiplier": bounce_speed_multiplier,
		"arc_height": projectile_arc_height
	}
	if explosion_enabled:
		profile["explosion"] = {
			"damage": explosion_damage * (1.0 + ratio * 0.25),
			"radius": explosion_radius * (1.0 + ratio * 0.2),
			"duration": explosion_duration,
			"frames": explosion_animation_frames,
			"animation_name": explosion_animation_name,
			"scale": explosion_scale * (1.0 + ratio * 0.15),
			"damage_once": explosion_damage_once
		}
	return profile

func _customize_projectile_profile(_profile: Dictionary, _is_charged: bool, _charge_ratio: float) -> void:
	pass

func _apply_fire_feedback(direction: Vector2, is_charged: bool) -> void:
	var world: Node = get_tree().current_scene
	if world != null and world.has_method("request_screen_shake"):
		var shake_strength: float = screen_shake_amount
		if is_charged:
			shake_strength = maxf(shake_strength, charge_screen_shake)
		var shake_duration: float = float(visual_quality.get("screen_shake_duration", 0.12))
		world.call("request_screen_shake", shake_strength, shake_duration)
		if is_charged and charge_screen_flash_intensity > 0.0 and world.has_method("request_screen_flash"):
			world.call("request_screen_flash", charge_screen_flash_intensity, 0.12)
	if owner_node != null and enable_recoil_kickback and recoil_kickback > 0.0:
		var start_position: Vector2 = owner_node.position
		var kick: Vector2 = -direction * recoil_kickback
		var tween: Tween = owner_node.create_tween()
		tween.tween_property(owner_node, "position", start_position + kick, 0.04)
		tween.tween_property(owner_node, "position", start_position, 0.08)

func _play_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	var world: Node = get_tree().current_scene
	if world == null:
		return
	var player_node: AudioStreamPlayer = AudioStreamPlayer.new()
	player_node.stream = stream
	player_node.volume_db = -3.0
	world.add_child(player_node)
	player_node.play()
	player_node.finished.connect(func() -> void:
		if is_instance_valid(player_node):
			player_node.queue_free()
	)
