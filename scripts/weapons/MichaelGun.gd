class_name MichaelGun
extends Gun

var mj_shoot_frames_path: String = "res://assets/player/michael_jackson_shoot.tres"
var mj_walk_frames_path: String = "res://assets/player/michael_jackson_walking.tres"
var bad_shoot_frames_path: String = "res://assets/player/bad_shoot.tres"
var glove_texture_path: String = "res://assets/weapons/mike-jake-glove.png"

func _ready() -> void:
	world_settings_getter_name = "get_michael_gun_settings"
	description_text = "Smooth rhythm blaster with MJ style."
	weapon_name = "Michael Gun"
	weapon_type = WeaponType.GUN

	var loaded_mj_shoot_frames: Resource = load(mj_shoot_frames_path)
	if loaded_mj_shoot_frames is SpriteFrames:
		player_shoot_frames_override = loaded_mj_shoot_frames as SpriteFrames

	var loaded_mj_walk_frames: Resource = load(mj_walk_frames_path)
	if loaded_mj_walk_frames is SpriteFrames:
		player_walk_frames_override = loaded_mj_walk_frames as SpriteFrames

	var loaded_bad_shoot_frames: Resource = load(bad_shoot_frames_path)
	if loaded_bad_shoot_frames is SpriteFrames:
		projectile_animation_frames = loaded_bad_shoot_frames as SpriteFrames
		charged_projectile_frames = loaded_bad_shoot_frames as SpriteFrames
		explosion_animation_frames = loaded_bad_shoot_frames as SpriteFrames

	var loaded_glove_texture: Resource = load(glove_texture_path)
	if loaded_glove_texture is Texture2D:
		weapon_icon_texture = loaded_glove_texture as Texture2D
		weapon_floor_texture = loaded_glove_texture as Texture2D
		floor_pickup_sprite = loaded_glove_texture as Texture2D
		ui_icon = loaded_glove_texture as Texture2D

	floor_weapon_scale_override = Vector2(0.62, 0.62)
	player_shoot_scale_override = Vector2(1.5, 1.5)
	player_walk_scale_override = Vector2.ONE

	base_damage = 7.0
	base_fire_rate = 0.12
	base_charge_time = 1.0
	base_charge_damage_multiplier = 2.6
	base_projectile_speed = 560.0
	base_spawn_distance = 32.0
	base_spawn_y_offset = -10.0

	projectile_animation_name = "bad"
	projectile_lifetime = 0.95
	projectile_size = Vector2(1.16, 1.16)
	projectile_hit_radius = 10.0

	charged_projectile_animation_name = "bad"
	charged_projectile_speed = 420.0
	charged_projectile_damage = 18.0
	charged_projectile_size = Vector2(1.56, 1.56)
	charged_projectile_lifetime = 0.72
	charged_projectile_hit_radius = 18.0

	explosion_enabled = true
	explosion_radius = 58.0
	explosion_damage = 22.0
	explosion_duration = 0.30
	explosion_scale = Vector2(1.25, 1.25)
	explosion_damage_once = true
	explosion_animation_name = "bad"

	screen_shake_amount = 0.6
	charge_screen_shake = 2.0
	super._ready()
