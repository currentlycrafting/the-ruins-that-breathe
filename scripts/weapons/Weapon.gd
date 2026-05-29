class_name Weapon
extends Node2D

## Weapon.gd
## Base parent class for all weapons.
##
## This file also contains small reusable inner classes:
## - Projectile: base projectile (never rotates)
## - Explosion: animated AoE impact node
## - WorldWeapon: floor pickup wrapper
## - ChargeUI: charge ring shown while charging
## - InventoryUI: simple inventory panel
## - WeaponHUD: current weapon stats panel

signal charge_changed(progress: float)

enum WeaponType {
	GENERIC,
	GUN
}

var weapon_name: String = "Weapon"
var weapon_description: String = ""
var weapon_type: WeaponType = WeaponType.GENERIC
var weapon_icon_texture: Texture2D = null
var weapon_floor_texture: Texture2D = null
var weapon_icon_tint: Color = Color.WHITE
var weapon_floor_scale: Vector2 = Vector2(0.55, 0.55)

var damage: float = 6.0
var fire_rate: float = 0.2
var charge_time: float = 1.2
var charge_damage_multiplier: float = 2.0
var projectile_speed: float = 400.0
var projectile_spawn_distance: float = 28.0
var projectile_spawn_y_offset: float = -8.0
var can_charge: bool = true

var player_walk_frames: SpriteFrames = null
var player_shoot_frames: SpriteFrames = null

var owner_node: Node2D = null
var is_equipped: bool = false
var is_charging: bool = false
var charge_elapsed: float = 0.0
var cooldown_remaining: float = 0.0

var visual_quality: Dictionary = {
	"premium_visuals_enabled": true,
	"ultra_premium_visuals_enabled": false,
	"enable_screen_shake": true,
	"screen_shake_strength": 8.0,
	"screen_shake_duration": 0.12,
	"enable_projectile_flash": true,
	"enable_projectile_shadow": true,
	"enable_projectile_trail": false,
	"projectile_sharpness": 1.0
}

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	if not is_charging:
		return
	charge_elapsed += delta
	charge_changed.emit(get_charge_ratio())

func get_charge_ratio() -> float:
	if charge_time <= 0.0:
		return 1.0
	return clampf(charge_elapsed / charge_time, 0.0, 1.0)

func on_equipped(new_owner: Node2D) -> void:
	owner_node = new_owner
	is_equipped = true
	cancel_charge()
	visible = false

func on_unequipped() -> void:
	cancel_charge()
	owner_node = null
	is_equipped = false
	visible = false

func can_fire() -> bool:
	return is_equipped and cooldown_remaining <= 0.0

func shoot(direction: Vector2) -> void:
	if not can_fire():
		return
	cooldown_remaining = fire_rate
	var clamped_direction: Vector2 = _sanitize_direction(direction)
	var projectile: Projectile = _create_projectile(false, 0.0, clamped_direction, damage)
	_spawn_projectile(projectile, clamped_direction)

func start_charge() -> void:
	if not is_equipped or not can_charge:
		return
	if is_charging:
		return
	is_charging = true
	charge_elapsed = 0.0
	charge_changed.emit(0.0)

func release_charge(direction: Vector2) -> void:
	if not is_equipped:
		cancel_charge()
		return
	var ratio: float = get_charge_ratio()
	cancel_charge()
	if ratio < 0.15:
		shoot(direction)
		return
	if not can_fire():
		return
	cooldown_remaining = fire_rate
	var final_damage: float = damage * lerpf(1.35, charge_damage_multiplier, ratio)
	var clamped_direction: Vector2 = _sanitize_direction(direction)
	var projectile: Projectile = _create_projectile(true, ratio, clamped_direction, final_damage)
	_spawn_projectile(projectile, clamped_direction)

func cancel_charge() -> void:
	is_charging = false
	charge_elapsed = 0.0
	charge_changed.emit(0.0)

func apply_runtime_settings(_settings: Dictionary) -> void:
	pass

func _create_projectile(_is_charged: bool, _charge_ratio: float, _direction: Vector2, _final_damage: float) -> Projectile:
	var projectile: Projectile = Projectile.new()
	projectile.setup({
		"is_charged": _is_charged,
		"speed": projectile_speed,
		"damage": _final_damage,
		"lifetime": 1.1,
		"hit_radius": 8.0,
		"scale": Vector2.ONE
	}, _direction, visual_quality)
	return projectile

func _spawn_projectile(projectile: Projectile, direction: Vector2) -> void:
	if projectile == null or owner_node == null:
		return
	var world: Node = get_tree().current_scene
	if world == null:
		return
	var spawn_position: Vector2 = owner_node.global_position \
		+ direction * projectile_spawn_distance \
		+ Vector2(0.0, projectile_spawn_y_offset)
	projectile.global_position = spawn_position
	world.add_child(projectile)

func _sanitize_direction(direction: Vector2) -> Vector2:
	if direction.length() < 0.001:
		return Vector2.RIGHT
	return direction.normalized()

func _make_circle_texture(size_px: int, tint: Color) -> ImageTexture:
	var image: Image = Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(float(size_px) * 0.5, float(size_px) * 0.5)
	var radius: float = float(size_px) * 0.5
	for x in range(size_px):
		for y in range(size_px):
			var distance: float = Vector2(float(x), float(y)).distance_to(center) / radius
			var alpha: float = clampf(1.0 - distance, 0.0, 1.0)
			alpha = alpha * alpha
			image.set_pixel(x, y, Color(tint.r, tint.g, tint.b, tint.a * alpha))
	return ImageTexture.create_from_image(image)


class Projectile extends Area2D:

	var direction: Vector2 = Vector2.RIGHT
	var speed: float = 420.0
	var damage: float = 5.0
	var life_time: float = 1.2
	var age: float = 0.0
	var hit_radius: float = 8.0
	var is_charged: bool = false
	var has_hit_target: bool = false
	var fade_out_time: float = 0.10
	var pierce_remaining: int = 0
	var bounce_remaining: int = 0
	var bounce_speed_multiplier: float = 0.75
	var arc_height: float = 0.0
	var _damaged_targets: Dictionary = {}

	var frames: SpriteFrames = null
	var animation_name: String = "default"
	var explosion_profile: Dictionary = {}
	var visual_settings: Dictionary = {}

	var _sprite: AnimatedSprite2D = null
	var _shadow: Sprite2D = null
	var _trail_timer: float = 0.0

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 2
		monitoring = true
		monitorable = true
		set_physics_process(true)
		_build_collision()
		_build_visuals()
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)
		if not area_entered.is_connected(_on_area_entered):
			area_entered.connect(_on_area_entered)

	func setup(config: Dictionary, new_direction: Vector2, quality_settings: Dictionary) -> void:
		direction = new_direction.normalized()
		if direction.length() <= 0.001:
			direction = Vector2.RIGHT

		speed = float(config.get("speed", speed))
		damage = float(config.get("damage", damage))
		life_time = float(config.get("lifetime", life_time))
		hit_radius = float(config.get("hit_radius", hit_radius))
		is_charged = bool(config.get("is_charged", false))
		scale = config.get("scale", Vector2.ONE)
		pierce_remaining = int(config.get("piercing_amount", 0))
		bounce_remaining = int(config.get("bounce_count", 0))
		bounce_speed_multiplier = float(config.get("bounce_speed_multiplier", 0.75))
		arc_height = float(config.get("arc_height", 0.0))
		frames = config.get("frames", null)
		animation_name = str(config.get("animation_name", animation_name))
		explosion_profile = config.get("explosion", {})
		visual_settings = quality_settings.duplicate(true)
		# Projectiles intentionally never rotate.
		rotation = 0.0
		if _sprite != null:
			_apply_sprite_frames()
		var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
		if collision_shape != null and collision_shape.shape is CircleShape2D:
			(collision_shape.shape as CircleShape2D).radius = hit_radius

	func _physics_process(delta: float) -> void:
		age += delta
		global_position += direction * speed * delta
		rotation = 0.0
		if _sprite != null and arc_height > 0.0:
			var arc_ratio: float = clampf(age / maxf(0.001, life_time), 0.0, 1.0)
			_sprite.position.y = sin(arc_ratio * PI) * -arc_height
		_update_trail(delta)
		if age >= life_time:
			_expire()

	func _build_collision() -> void:
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = hit_radius
		var collider: CollisionShape2D = CollisionShape2D.new()
		collider.name = "CollisionShape2D"
		collider.shape = shape
		add_child(collider)

	func _build_visuals() -> void:
		_shadow = Sprite2D.new()
		_shadow.name = "Shadow"
		_shadow.texture = _make_shadow_texture()
		_shadow.position = Vector2(0.0, 4.0)
		_shadow.modulate = Color(0.0, 0.0, 0.0, 0.35)
		_shadow.visible = bool(visual_settings.get("enable_projectile_shadow", true))
		add_child(_shadow)

		_sprite = AnimatedSprite2D.new()
		_sprite.name = "Sprite"
		add_child(_sprite)
		_apply_sprite_frames()
		_apply_spawn_flash()

	func _apply_sprite_frames() -> void:
		if _sprite == null:
			return
		if frames != null:
			_sprite.sprite_frames = frames
			var chosen_animation: String = animation_name
			if not frames.has_animation(chosen_animation):
				var names: PackedStringArray = frames.get_animation_names()
				if not names.is_empty():
					chosen_animation = names[0]
			if frames.has_animation(chosen_animation):
				_sprite.animation = chosen_animation
				_sprite.play(chosen_animation)
				return
		var fallback_frames: SpriteFrames = SpriteFrames.new()
		fallback_frames.add_animation("default")
		fallback_frames.set_animation_loop("default", true)
		fallback_frames.add_frame("default", _make_bullet_texture())
		_sprite.sprite_frames = fallback_frames
		_sprite.animation = "default"
		_sprite.play("default")

	func _apply_spawn_flash() -> void:
		if not bool(visual_settings.get("enable_projectile_flash", true)):
			return
		if _sprite == null:
			return
		var tween: Tween = create_tween()
		_sprite.modulate = Color(1.25, 1.25, 1.25, 1.0)
		tween.tween_property(_sprite, "modulate", Color.WHITE, 0.08)

	func _update_trail(delta: float) -> void:
		if not bool(visual_settings.get("enable_projectile_trail", false)):
			return
		_trail_timer -= delta
		if _trail_timer > 0.0:
			return
		_trail_timer = 0.03
		var trail: Sprite2D = Sprite2D.new()
		trail.texture = _make_bullet_texture()
		trail.global_position = global_position
		trail.scale = scale * 0.8
		trail.modulate = Color(1.0, 1.0, 1.0, 0.45)
		get_tree().current_scene.add_child(trail)
		var tween: Tween = trail.create_tween()
		tween.tween_property(trail, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.15)
		tween.finished.connect(func() -> void:
			if is_instance_valid(trail):
				trail.queue_free()
		)

	func _on_body_entered(body: Node) -> void:
		_hit_target(body)

	func _on_area_entered(area: Area2D) -> void:
		_hit_target(area)

	func _hit_target(target: Node) -> void:
		if has_hit_target:
			return
		if target != null and target.has_method("take_damage"):
			var target_id: int = target.get_instance_id()
			if _damaged_targets.has(target_id):
				return
			_damaged_targets[target_id] = true
			target.call("take_damage", damage)
		if pierce_remaining > 0:
			pierce_remaining -= 1
			return
		if bounce_remaining > 0:
			bounce_remaining -= 1
			_apply_bounce()
			return
		_expire()

	func _expire() -> void:
		if has_hit_target:
			return
		has_hit_target = true
		_spawn_explosion()
		set_physics_process(false)
		monitoring = false
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), fade_out_time)
		tween.finished.connect(func() -> void:
			if is_inside_tree():
				queue_free()
		)

	func _apply_bounce() -> void:
		direction = (-direction).rotated(randf_range(-0.35, 0.35)).normalized()
		speed = maxf(60.0, speed * clampf(bounce_speed_multiplier, 0.1, 1.0))
		rotation = 0.0

	func _spawn_explosion() -> void:
		if explosion_profile.is_empty():
			return
		var world: Node = get_tree().current_scene
		if world == null:
			return
		var explosion: Explosion = Explosion.new()
		explosion.global_position = global_position
		world.add_child(explosion)
		explosion.setup(explosion_profile, visual_settings)

	func _make_bullet_texture() -> ImageTexture:
		var color: Color = Color(1.0, 0.85, 0.96, 1.0) if not is_charged else Color(1.0, 0.62, 0.90, 1.0)
		var image: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		var center: Vector2 = Vector2(8.0, 8.0)
		for x in range(16):
			for y in range(16):
				var distance: float = Vector2(float(x), float(y)).distance_to(center) / 8.0
				var alpha: float = clampf(1.0 - distance, 0.0, 1.0)
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
		return ImageTexture.create_from_image(image)

	func _make_shadow_texture() -> ImageTexture:
		var image: Image = Image.create(20, 10, false, Image.FORMAT_RGBA8)
		for x in range(20):
			for y in range(10):
				var dx: float = (float(x) - 10.0) / 10.0
				var dy: float = (float(y) - 5.0) / 5.0
				var d: float = dx * dx + dy * dy
				var a: float = clampf(1.0 - d, 0.0, 1.0) * 0.55
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, a))
		return ImageTexture.create_from_image(image)


class Explosion extends Area2D:

	var damage: float = 20.0
	var radius: float = 42.0
	var duration: float = 0.30
	var frames: SpriteFrames = null
	var animation_name: String = "explode"
	var scale_value: Vector2 = Vector2.ONE
	var damage_once: bool = true
	var _hit_ids: Dictionary = {}

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 2
		monitoring = true
		monitorable = true
		_build_collision()
		_build_sprite()
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)
		if not area_entered.is_connected(_on_area_entered):
			area_entered.connect(_on_area_entered)

	func setup(config: Dictionary, quality_settings: Dictionary) -> void:
		damage = float(config.get("damage", damage))
		radius = float(config.get("radius", radius))
		duration = float(config.get("duration", duration))
		frames = config.get("frames", null)
		animation_name = str(config.get("animation_name", animation_name))
		scale_value = config.get("scale", Vector2.ONE)
		damage_once = bool(config.get("damage_once", true))
		scale = scale_value

		var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
		if collision_shape != null and collision_shape.shape is CircleShape2D:
			(collision_shape.shape as CircleShape2D).radius = radius

		var sprite: AnimatedSprite2D = get_node_or_null("Sprite")
		if sprite != null:
			if frames != null and frames.has_animation(animation_name):
				sprite.sprite_frames = frames
				sprite.animation = animation_name
				sprite.play(animation_name)
			else:
				var fallback_frames: SpriteFrames = SpriteFrames.new()
				fallback_frames.add_animation("explode")
				fallback_frames.set_animation_loop("explode", false)
				fallback_frames.add_frame("explode", _make_explosion_texture())
				sprite.sprite_frames = fallback_frames
				sprite.animation = "explode"
				sprite.play("explode")
			sprite.speed_scale = maxf(0.01, sprite.sprite_frames.get_animation_speed(sprite.animation))
			if sprite.sprite_frames != null:
				sprite.sprite_frames.set_animation_loop(sprite.animation, false)

		var should_shake: bool = bool(quality_settings.get("enable_screen_shake", true))
		if should_shake:
			var world: Node = get_tree().current_scene
			if world != null and world.has_method("request_screen_shake"):
				var strength: float = float(quality_settings.get("screen_shake_strength", 6.0))
				var shake_duration: float = float(quality_settings.get("screen_shake_duration", 0.1))
				world.call("request_screen_shake", strength, shake_duration)

		var timer: SceneTreeTimer = get_tree().create_timer(duration)
		timer.timeout.connect(func() -> void:
			if is_inside_tree():
				queue_free()
		)

	func _build_collision() -> void:
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = radius
		var collider: CollisionShape2D = CollisionShape2D.new()
		collider.name = "CollisionShape2D"
		collider.shape = shape
		add_child(collider)

	func _build_sprite() -> void:
		var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		sprite.name = "Sprite"
		add_child(sprite)

	func _on_body_entered(body: Node) -> void:
		_damage_target(body)

	func _on_area_entered(area: Area2D) -> void:
		_damage_target(area)

	func _damage_target(target: Node) -> void:
		if target == null or not target.has_method("take_damage"):
			return
		var id: int = target.get_instance_id()
		if damage_once and _hit_ids.has(id):
			return
		_hit_ids[id] = true
		target.call("take_damage", damage)

	func _make_explosion_texture() -> ImageTexture:
		var image: Image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		var center: Vector2 = Vector2(32.0, 32.0)
		for x in range(64):
			for y in range(64):
				var d: float = Vector2(float(x), float(y)).distance_to(center) / 32.0
				var a: float = clampf(1.0 - d, 0.0, 1.0)
				image.set_pixel(x, y, Color(1.0, 0.72, 0.90, a))
		return ImageTexture.create_from_image(image)


class WorldWeapon extends Node2D:

	signal picked_up(player: Node2D, weapon: Weapon)

	var weapon: Weapon = null
	var pickup_radius: float = 56.0
	var floor_sprite: Sprite2D = null
	var label: Label = null

	func setup(new_weapon: Weapon, world_position: Vector2) -> void:
		weapon = new_weapon
		global_position = world_position
		if weapon != null and weapon.get_parent() != null:
			weapon.get_parent().remove_child(weapon)
		if weapon != null:
			weapon.visible = false
			add_child(weapon)
		_build_visuals()
		set_process(true)

	func _build_visuals() -> void:
		floor_sprite = Sprite2D.new()
		floor_sprite.name = "FloorSprite"
		if weapon != null and weapon.weapon_floor_texture != null:
			floor_sprite.texture = weapon.weapon_floor_texture
		else:
			floor_sprite.texture = _make_placeholder_weapon_texture()
		if weapon != null:
			floor_sprite.scale = weapon.weapon_floor_scale
		add_child(floor_sprite)

		label = Label.new()
		label.name = "PickupLabel"
		label.position = Vector2(-74.0, -58.0)
		label.text = "[E] Pick up"
		label.modulate = Color(1.0, 0.95, 0.68, 0.95)
		add_child(label)

	func _process(delta: float) -> void:
		var player: Node2D = get_tree().current_scene.get_node_or_null("Player")
		if player == null:
			return
		var near_player: bool = global_position.distance_to(player.global_position) <= pickup_radius
		if label != null:
			label.visible = near_player
			if near_player and weapon != null:
				label.text = "[E] Pick up " + weapon.weapon_name
		if floor_sprite != null:
			floor_sprite.position.y = sin(Time.get_ticks_msec() * 0.006) * 2.5
			floor_sprite.rotation = sin(Time.get_ticks_msec() * 0.002) * 0.04

	func try_pickup(player: Node2D) -> bool:
		if weapon == null:
			return false
		if global_position.distance_to(player.global_position) > pickup_radius:
			return false
		if weapon.get_parent() == self:
			remove_child(weapon)
		picked_up.emit(player, weapon)
		queue_free()
		return true

	func _make_placeholder_weapon_texture() -> ImageTexture:
		var image: Image = Image.create(36, 20, false, Image.FORMAT_RGBA8)
		for x in range(36):
			for y in range(20):
				var alpha: float = 0.0
				if x > 4 and x < 28 and y > 7 and y < 13:
					alpha = 1.0
				if x > 24 and x < 34 and y > 5 and y < 15:
					alpha = 1.0
				image.set_pixel(x, y, Color(1.0, 0.72, 0.90, alpha))
		return ImageTexture.create_from_image(image)


class ChargeUI extends Control:

	var progress: float = 0.0
	var progress_visual: float = 0.0
	var alpha_target: float = 0.0
	var alpha_current: float = 0.0
	var fill_color: Color = Color(0.96, 0.96, 0.98, 0.98)
	var base_color: Color = Color(0.02, 0.02, 0.02, 0.94)
	var use_quarter_steps: bool = true
	var wave_time: float = 0.0
	var shake_amount: float = 4.5
	var anchor_position: Vector2 = Vector2.ZERO
	var shake_offset: Vector2 = Vector2.ZERO

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(82.0, 82.0)
		set_process(true)

	func set_screen_anchor(screen_pos: Vector2) -> void:
		anchor_position = screen_pos
		position = anchor_position + shake_offset

	func _process(delta: float) -> void:
		alpha_current = lerpf(alpha_current, alpha_target, 12.0 * delta)
		progress_visual = lerpf(progress_visual, progress, 10.0 * delta)
		wave_time += delta * 4.0
		var quarter_progress: float = ceil(progress_visual * 4.0) / 4.0 if use_quarter_steps else progress_visual
		var is_full: bool = quarter_progress >= 1.0
		if is_full and alpha_target > 0.5:
			shake_offset = Vector2(
				randf_range(-shake_amount, shake_amount),
				randf_range(-shake_amount, shake_amount)
			)
		else:
			shake_offset = Vector2.ZERO
		position = anchor_position + shake_offset
		queue_redraw()

	func show_charge(new_progress: float) -> void:
		progress = clampf(new_progress, 0.0, 1.0)
		alpha_target = 1.0

	func hide_charge() -> void:
		progress = 0.0
		alpha_target = 0.0

	func _draw() -> void:
		if alpha_current <= 0.01:
			return
		var center: Vector2 = size * 0.5
		var radius: float = 24.0
		var outer_radius: float = 29.0
		var progress_value: float = progress_visual
		if use_quarter_steps:
			progress_value = ceil(progress_visual * 4.0) / 4.0
		progress_value = clampf(progress_value, 0.0, 1.0)

		var bg: Color = Color(base_color.r, base_color.g, base_color.b, base_color.a * alpha_current)
		var fg: Color = Color(fill_color.r, fill_color.g, fill_color.b, fill_color.a * alpha_current)

		draw_circle(center, outer_radius + 4.0, Color(0.0, 0.0, 0.0, 0.18 * alpha_current))
		draw_circle(center, outer_radius, Color(0.01, 0.01, 0.01, 0.32 * alpha_current))
		draw_circle(center, radius, bg)

		# Water fill with animated wave crest.
		if progress_value > 0.0:
			_draw_water_fill(center, radius, progress_value, fg)

		# Crisp ring + subtle highlights + quarter ticks.
		draw_arc(center, radius + 0.5, 0.0, TAU, 64, Color(0.95, 0.95, 1.0, 0.36 * alpha_current), 2.4, true)
		draw_arc(center, radius - 3.5, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.06 * alpha_current), 1.6, true)
		_draw_quarter_ticks(center, radius + 3.5)

	func _draw_water_fill(center: Vector2, radius: float, progress_value: float, water_color: Color) -> void:
		var steps: int = 46
		var level_y: float = lerpf(radius, -radius, progress_value)
		var wave_amp: float = lerpf(2.8, 1.0, progress_value)
		var top_points: PackedVector2Array = PackedVector2Array()
		var bottom_points: PackedVector2Array = PackedVector2Array()
		var crest_points: PackedVector2Array = PackedVector2Array()

		for i in range(steps + 1):
			var t: float = float(i) / float(steps)
			var x: float = lerpf(-radius, radius, t)
			var circle_y: float = sqrt(maxf(0.0, radius * radius - x * x))
			var wave_y: float = level_y + sin(wave_time + x * 0.25) * wave_amp
			var top_y: float = clampf(maxf(wave_y, -circle_y), -circle_y, circle_y)
			var bottom_y: float = circle_y
			top_points.append(center + Vector2(x, top_y))
			bottom_points.append(center + Vector2(x, bottom_y))
			crest_points.append(center + Vector2(x, top_y))

		var poly_points: PackedVector2Array = PackedVector2Array()
		for point in top_points:
			poly_points.append(point)
		for i in range(bottom_points.size() - 1, -1, -1):
			poly_points.append(bottom_points[i])
		draw_colored_polygon(poly_points, Color(water_color.r, water_color.g, water_color.b, water_color.a * 0.9))

		var foam_color: Color = Color(1.0, 1.0, 1.0, 0.28 * alpha_current)
		draw_polyline(crest_points, foam_color, 1.8, true)

	func _draw_quarter_ticks(center: Vector2, radius: float) -> void:
		var tick_color: Color = Color(1.0, 1.0, 1.0, 0.22 * alpha_current)
		for i in range(4):
			var angle: float = -PI * 0.5 + TAU * (float(i) / 4.0)
			var start: Vector2 = center + Vector2(cos(angle), sin(angle)) * (radius - 2.0)
			var finish: Vector2 = center + Vector2(cos(angle), sin(angle)) * (radius + 2.2)
			draw_line(start, finish, tick_color, 1.8)


class InventoryUI extends Control:

	var weapon_manager: Node = null
	var is_open: bool = false
	var panel: PanelContainer = null
	var slot_row: HBoxContainer = null

	var panel_position: Vector2 = Vector2(44.0, 280.0)
	var panel_size: Vector2 = Vector2(360.0, 320.0)
	var panel_opacity: float = 0.95
	var slot_count: int = 9

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		apply_layout()
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = true
		_build_panel()
		set_process(true)

	func apply_layout() -> void:
		offset_left = 0.0
		offset_right = 0.0
		offset_top = panel_position.y - panel_size.y
		offset_bottom = panel_position.y
		if panel != null:
			panel.size = panel_size
			panel.position = Vector2(-panel_size.x * 0.5 + panel_position.x, 0.0)

	func _build_panel() -> void:
		panel = PanelContainer.new()
		panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		panel.size = panel_size
		panel.position = Vector2(-panel_size.x * 0.5 + panel_position.x, 0.0)
		panel.modulate = Color(1.0, 1.0, 1.0, panel_opacity)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var frame_style: StyleBoxFlat = StyleBoxFlat.new()
		frame_style.bg_color = Color(0.07, 0.07, 0.07, 0.86)
		frame_style.border_color = Color(0.2, 0.2, 0.2, 0.95)
		frame_style.set_border_width_all(2)
		frame_style.set_corner_radius_all(2)
		frame_style.content_margin_left = 8.0
		frame_style.content_margin_right = 8.0
		frame_style.content_margin_top = 8.0
		frame_style.content_margin_bottom = 8.0
		panel.add_theme_stylebox_override("panel", frame_style)
		add_child(panel)
		slot_row = HBoxContainer.new()
		slot_row.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_row.add_theme_constant_override("separation", 6)
		slot_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(slot_row)
		refresh()

	func toggle() -> void:
		# Keep hotbar always visible, P just forces refresh.
		is_open = false
		visible = true
		refresh()

	func close() -> void:
		is_open = false
		visible = true

	func refresh() -> void:
		if slot_row == null:
			return
		for child in slot_row.get_children():
			child.queue_free()
		var weapons: Array = []
		var equipped: Weapon = null
		if weapon_manager != null:
			weapons = weapon_manager.get("all_weapons")
			equipped = weapon_manager.get("equipped_weapon")
		for i in range(slot_count):
			var slot_weapon: Weapon = null
			if i < weapons.size():
				slot_weapon = weapons[i] as Weapon
			_add_hotbar_slot(i, slot_weapon, slot_weapon != null and slot_weapon == equipped)

	func _process(_delta: float) -> void:
		refresh()

	func _add_hotbar_slot(slot_index: int, weapon: Weapon, is_equipped_weapon: bool) -> void:
		var slot_panel: PanelContainer = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(54.0, 54.0)
		slot_panel.size_flags_horizontal = Control.SIZE_FILL
		slot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 0.95)
		style.border_color = Color(0.45, 0.45, 0.45, 1.0)
		style.set_border_width_all(2)
		style.set_corner_radius_all(2)
		if is_equipped_weapon:
			style.bg_color = Color(0.28, 0.26, 0.14, 0.96)
			style.border_color = Color(0.96, 0.85, 0.35, 1.0)
			style.set_border_width_all(3)
		slot_panel.add_theme_stylebox_override("panel", style)
		slot_row.add_child(slot_panel)

		var content: Control = Control.new()
		content.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_panel.add_child(content)

		var index_label: Label = Label.new()
		index_label.text = str(slot_index + 1)
		index_label.position = Vector2(3.0, 2.0)
		index_label.add_theme_font_size_override("font_size", 12)
		index_label.modulate = Color(0.94, 0.94, 0.94, 0.9)
		content.add_child(index_label)

		if weapon == null:
			return

		var icon: TextureRect = TextureRect.new()
		icon.texture = weapon.weapon_icon_texture if weapon.weapon_icon_texture != null else weapon.get("ui_icon")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = weapon.weapon_icon_tint
		icon.position = Vector2(6.0, 8.0)
		icon.size = Vector2(42.0, 40.0)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)

		if icon.texture == null:
			var initials: Label = Label.new()
			initials.text = weapon.weapon_name.left(1)
			initials.position = Vector2(34.0, 36.0)
			initials.add_theme_font_size_override("font_size", 11)
			initials.modulate = Color(0.93, 0.93, 0.93, 0.82)
			content.add_child(initials)


class WeaponHUD extends Control:

	var weapon_manager: Node = null
	var panel: PanelContainer = null
	var title_label: Label = null
	var stats_label: Label = null

	func _ready() -> void:
		_build()
		set_process(true)

	func _build() -> void:
		panel = PanelContainer.new()
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		add_child(panel)
		var root: VBoxContainer = VBoxContainer.new()
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_theme_constant_override("separation", 4)
		panel.add_child(root)
		title_label = Label.new()
		title_label.text = "Weapon: None"
		title_label.add_theme_font_size_override("font_size", 18)
		root.add_child(title_label)
		stats_label = Label.new()
		stats_label.text = "-"
		stats_label.add_theme_font_size_override("font_size", 13)
		stats_label.modulate = Color(0.82, 0.91, 1.0, 0.95)
		root.add_child(stats_label)

	func _process(_delta: float) -> void:
		_refresh()

	func _refresh() -> void:
		if weapon_manager == null:
			title_label.text = "Weapon: None"
			stats_label.text = "-"
			return
		var weapon: Weapon = weapon_manager.get("equipped_weapon")
		if weapon == null:
			title_label.text = "Weapon: None"
			stats_label.text = "-"
			return
		title_label.text = "Weapon: %s" % weapon.weapon_name
		stats_label.text = "DMG %.1f   SPD %.0f   CHARGE %.2fs   SIZE %.2f" % [
			weapon.damage,
			weapon.projectile_speed,
			weapon.charge_time,
			weapon.projectile_spawn_distance
		]
