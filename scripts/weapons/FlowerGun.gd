class_name FlowerGun
extends Gun

## FlowerGun.gd
## Polished flower weapon implementation using the base Weapon structure.

@export_group("Small Petal Shot")
@export var small_petal_projectile_frames: SpriteFrames = null
@export var small_petal_animation_name: String = "fly"
@export var small_petal_speed: float = 530.0
@export var small_petal_size: Vector2 = Vector2(1.22, 1.22)
@export var small_petal_damage: float = 5.0
@export var small_petal_lifetime: float = 1.15
@export var small_petal_hit_radius: float = 8.6

@export_group("Charged Bloom Shot")
@export var big_petal_projectile_frames: SpriteFrames = null
@export var big_petal_animation_name: String = "fly"
@export var big_petal_speed: float = 320.0
@export var big_petal_size: Vector2 = Vector2(1.55, 1.55)
@export var big_petal_damage: float = 16.0
@export var big_petal_lifetime: float = 0.85
@export var big_petal_hit_radius: float = 18.0

@export_group("Bloom Explosion")
@export var flower_explosion_animation_frames: SpriteFrames = null
@export var flower_explosion_animation_name: String = "explode"

func _ready() -> void:
	var flower_icon_path: String = "res://assets/weapons/flower-gun.png"
	if ResourceLoader.exists(flower_icon_path):
		var loaded_flower_icon: Resource = load(flower_icon_path)
		if loaded_flower_icon is Texture2D:
			ui_icon = loaded_flower_icon as Texture2D
			floor_pickup_sprite = loaded_flower_icon as Texture2D
			weapon_icon_texture = loaded_flower_icon as Texture2D
			weapon_floor_texture = loaded_flower_icon as Texture2D

	if small_petal_projectile_frames == null:
		small_petal_projectile_frames = _build_default_flower_projectile_frames()
	if big_petal_projectile_frames == null:
		big_petal_projectile_frames = _build_default_flower_projectile_frames(Color(1.0, 0.78, 0.90, 1.0), Color(0.98, 0.90, 0.98, 1.0))

	world_settings_getter_name = "get_flower_gun_settings"
	description_text = "Quick petals and a charged bloom explosion."
	floor_weapon_scale_override = Vector2(0.56, 0.56)
	base_damage = 4.0
	base_fire_rate = 0.15
	base_charge_time = 1.25
	base_charge_damage_multiplier = 3.9
	base_projectile_speed = 510.0
	base_spawn_distance = 30.0
	base_spawn_y_offset = -10.0
	projectile_spread_degrees = 1.5
	projectiles_per_shot = 1
	burst_count = 1
	projectile_lifetime = small_petal_lifetime
	projectile_size = small_petal_size
	projectile_hit_radius = small_petal_hit_radius
	projectile_animation_frames = small_petal_projectile_frames
	projectile_animation_name = small_petal_animation_name
	charged_projectile_frames = big_petal_projectile_frames
	charged_projectile_animation_name = big_petal_animation_name
	charged_projectile_speed = big_petal_speed
	charged_projectile_damage = big_petal_damage
	charged_projectile_size = big_petal_size
	charged_projectile_lifetime = big_petal_lifetime
	charged_projectile_hit_radius = big_petal_hit_radius
	explosion_enabled = true
	explosion_radius = 56.0
	explosion_damage = 16.0
	explosion_duration = 0.35
	explosion_scale = Vector2(1.2, 1.2)
	explosion_damage_once = true
	explosion_animation_frames = flower_explosion_animation_frames
	explosion_animation_name = flower_explosion_animation_name
	screen_shake_amount = 0.4
	charge_screen_shake = 1.8
	camera_shake_intensity = 1.8
	super._ready()
	weapon_name = "Flower Gun"
	weapon_type = WeaponType.GUN
	weapon_icon_tint = Color(1.0, 0.70, 0.90, 1.0)
	weapon_floor_scale = floor_weapon_scale_override

func _customize_projectile_profile(profile: Dictionary, is_charged: bool, charge_ratio: float) -> void:
	var ratio: float = clampf(charge_ratio, 0.0, 1.0)
	if is_charged:
		var shortened_lifetime: float = maxf(0.35, big_petal_lifetime * 0.58)
		profile["frames"] = big_petal_projectile_frames
		profile["animation_name"] = big_petal_animation_name
		profile["speed"] = lerpf(big_petal_speed, big_petal_speed * 1.08, ratio)
		profile["damage"] = maxf(big_petal_damage, float(profile.get("damage", big_petal_damage)))
		profile["scale"] = big_petal_size * (1.0 + ratio * 0.35)
		profile["lifetime"] = shortened_lifetime
		profile["hit_radius"] = big_petal_hit_radius * (1.0 + ratio * 0.25)
		profile["explosion"] = {
			"damage": explosion_damage * (1.0 + ratio * 0.25),
			"radius": explosion_radius * (1.0 + ratio * 0.20),
			"duration": explosion_duration,
			"frames": flower_explosion_animation_frames,
			"animation_name": flower_explosion_animation_name,
			"scale": explosion_scale * (1.0 + ratio * 0.15),
			"damage_once": explosion_damage_once
		}
		return

	profile["frames"] = small_petal_projectile_frames
	profile["animation_name"] = small_petal_animation_name
	profile["speed"] = small_petal_speed
	profile["damage"] = small_petal_damage
	profile["scale"] = small_petal_size * 1.05
	profile["lifetime"] = small_petal_lifetime
	profile["hit_radius"] = small_petal_hit_radius


func _build_default_flower_projectile_frames(petal_color: Color = Color(1.0, 0.58, 0.82, 1.0), center_color: Color = Color(1.0, 0.93, 0.56, 1.0)) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_loop("fly", true)
	frames.set_animation_speed("fly", 11.0)
	frames.add_frame("fly", _make_flower_texture(petal_color, center_color, 0.0))
	frames.add_frame("fly", _make_flower_texture(petal_color.lightened(0.05), center_color, 0.35))
	frames.add_frame("fly", _make_flower_texture(petal_color, center_color.lightened(0.08), 0.7))
	return frames


func _make_flower_texture(petal_color: Color, center_color: Color, phase: float) -> Texture2D:
	var size_px: int = 48
	var image: Image = Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(float(size_px) * 0.5, float(size_px) * 0.5)
	var petal_count: int = 6
	var petal_distance: float = 9.0
	var petal_radius: float = 6.2 + sin(phase * TAU) * 0.3
	for x in range(size_px):
		for y in range(size_px):
			var p: Vector2 = Vector2(float(x), float(y))
			var alpha: float = 0.0
			for i in range(petal_count):
				var angle: float = TAU * float(i) / float(petal_count) + phase * 0.08
				var petal_center: Vector2 = center + Vector2(cos(angle), sin(angle)) * petal_distance
				var d: float = p.distance_to(petal_center) / petal_radius
				alpha = maxf(alpha, clampf(1.0 - d, 0.0, 1.0))
			var c_dist: float = p.distance_to(center) / 4.0
			var c_alpha: float = clampf(1.0 - c_dist, 0.0, 1.0)
			if c_alpha > alpha:
				image.set_pixel(x, y, Color(center_color.r, center_color.g, center_color.b, c_alpha))
			elif alpha > 0.0:
				image.set_pixel(x, y, Color(petal_color.r, petal_color.g, petal_color.b, alpha))
	return ImageTexture.create_from_image(image)
