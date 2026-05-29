class_name SlimeMob
extends Area2D

signal slime_died(slime: SlimeMob, room_center: Vector2i)

var target_player: Node2D = null
var room_center: Vector2i = Vector2i(-9999, -9999)
var heart_value: float = 50.0
var max_hearts: int = 2

var max_health: float = 100.0
var current_health: float = 100.0
var move_speed: float = 64.0
var jump_interval: float = 0.85
var jump_distance: float = 42.0
var jump_height: float = 20.0
var jump_duration: float = 0.36
var contact_damage: float = 20.0
var contact_damage_cooldown: float = 0.75
var contact_range: float = 14.0
var sprite_texture: Texture2D = null

var jump_timer: float = 0.0
var jump_elapsed: float = 0.0
var contact_cooldown_timer: float = 0.0
var jump_start_pos: Vector2 = Vector2.ZERO
var jump_target_pos: Vector2 = Vector2.ZERO
var is_jumping: bool = false

var sprite: AnimatedSprite2D = null
var heart_sprites: Array[Sprite2D] = []
var variant_scale: float = 1.0
var variant_tint: Color = Color.WHITE
var heart_texture: Texture2D = null
var hit_highlight_timer: float = 0.0
var hit_highlight_tint: Color = Color(1.65, 0.22, 0.22, 1.0)
var hit_highlight_hold_seconds: float = 0.24

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = true
	monitorable = true
	set_process(true)
	_build_collision()
	_build_visuals()
	jump_timer = randf_range(0.08, 0.28)


func configure(player_ref: Node2D, config: Dictionary) -> void:
	target_player = player_ref
	heart_value = maxf(1.0, float(config.get("heart_value", heart_value)))
	max_hearts = maxi(1, int(config.get("max_hearts", max_hearts)))
	max_health = float(config.get("max_health", float(max_hearts) * heart_value))
	current_health = max_health
	move_speed = float(config.get("move_speed", move_speed))
	jump_interval = float(config.get("jump_interval", jump_interval))
	jump_distance = float(config.get("jump_distance", jump_distance))
	jump_height = float(config.get("jump_height", jump_height))
	jump_duration = float(config.get("jump_duration", jump_duration))
	contact_damage = float(config.get("contact_damage", contact_damage))
	contact_damage_cooldown = float(config.get("contact_damage_cooldown", contact_damage_cooldown))
	contact_range = float(config.get("contact_range", contact_range))
	sprite_texture = config.get("texture", sprite_texture)
	room_center = config.get("room_center", room_center)
	variant_scale = float(config.get("variant_scale", 1.0))
	variant_tint = config.get("variant_tint", Color.WHITE)
	var speed_mult: float = float(config.get("speed_multiplier", 1.0))
	move_speed *= speed_mult
	jump_interval = maxf(0.12, jump_interval / maxf(0.25, speed_mult))
	jump_distance *= clampf(speed_mult, 0.6, 1.5)
	if sprite != null:
		sprite.sprite_frames = _build_frames_from_sheet(sprite_texture)
		sprite.play("jump")
		sprite.frame = 0
		sprite.modulate = variant_tint
		sprite.scale = Vector2.ONE * variant_scale
	heart_texture = _make_tinted_heart_texture(variant_tint)
	_update_heart_visual()


func _process(delta: float) -> void:
	contact_cooldown_timer = maxf(0.0, contact_cooldown_timer - delta)
	if hit_highlight_timer > 0.0:
		hit_highlight_timer = maxf(0.0, hit_highlight_timer - delta)
	_update_damage_highlight()
	if is_jumping:
		_update_jump(delta)
	else:
		jump_timer -= delta
		if jump_timer <= 0.0:
			_begin_jump()
	_check_contact_damage()


func take_damage(amount: float) -> void:
	var hearts_before: int = maxi(0, int(ceil(current_health / maxf(1.0, heart_value))))
	current_health = maxf(0.0, current_health - amount)
	var hearts_after: int = maxi(0, int(ceil(current_health / maxf(1.0, heart_value))))
	_update_heart_visual()
	_flash_hit(hearts_before - hearts_after)
	var world: Node = get_tree().current_scene
	if world != null and world.has_method("spawn_damage_tick"):
		world.call("spawn_damage_tick", global_position, amount, Color(1.0, 0.62, 0.28, 1.0))
	if current_health <= 0.0:
		_emit_death_fx()
		slime_died.emit(self, room_center)
		queue_free()


func _begin_jump() -> void:
	if target_player == null or not is_instance_valid(target_player):
		target_player = get_tree().current_scene.get_node_or_null("Player") as Node2D
	if target_player == null or not is_instance_valid(target_player):
		jump_timer = jump_interval
		return
	jump_start_pos = global_position
	var to_target: Vector2 = target_player.global_position - global_position
	var dir: Vector2 = Vector2.ZERO
	if to_target.length() > 0.001:
		dir = to_target.normalized()
		_update_slime_facing(dir)
	var dynamic_step_cap: float = maxf(8.0, move_speed * jump_duration)
	var max_step: float = minf(jump_distance, minf(dynamic_step_cap, to_target.length()))
	jump_target_pos = global_position + dir * max_step
	var world: Node = get_tree().current_scene
	if world != null:
		if world.has_method("is_world_position_on_walkable_tile") and not world.call("is_world_position_on_walkable_tile", jump_target_pos):
			if world.has_method("snap_world_position_to_walkable"):
				jump_target_pos = world.call("snap_world_position_to_walkable", jump_target_pos)
			else:
				jump_timer = jump_interval
				return
		elif world.has_method("is_walkable_tile"):
			var target_tile: Vector2i = world.call("world_to_tile", jump_target_pos)
			if not world.call("is_walkable_tile", target_tile):
				jump_timer = jump_interval
				return
	is_jumping = true
	jump_elapsed = 0.0
	if world != null and world.has_method("spawn_combat_tile_marker"):
		world.spawn_combat_tile_marker(jump_target_pos, jump_duration, true)
	if sprite != null:
		sprite.play("jump")
		sprite.frame = 0


func _update_slime_facing(dir: Vector2) -> void:
	if sprite == null or abs(dir.x) < 0.08:
		return
	sprite.flip_h = dir.x > 0.0


func _update_jump(delta: float) -> void:
	jump_elapsed += delta
	var t: float = clampf(jump_elapsed / maxf(0.01, jump_duration), 0.0, 1.0)
	var move_dir: Vector2 = jump_target_pos - jump_start_pos
	if move_dir.length_squared() > 0.001:
		_update_slime_facing(move_dir.normalized())
	global_position = jump_start_pos.lerp(jump_target_pos, t)
	var arc: float = sin(t * PI) * jump_height
	if sprite != null:
		sprite.position.y = -arc
		var frame_count: int = max(1, sprite.sprite_frames.get_frame_count("jump"))
		sprite.frame = mini(frame_count - 1, int(floor(t * float(frame_count))))
		sprite.scale = Vector2(1.0 + sin(t * PI) * 0.08, 1.0 - sin(t * PI) * 0.06)
	if t >= 1.0:
		is_jumping = false
		jump_timer = jump_interval
		var landing_world: Node = get_tree().current_scene
		if landing_world != null and landing_world.has_method("snap_world_position_to_walkable"):
			global_position = landing_world.call("snap_world_position_to_walkable", global_position)
		_emit_landing_dust()
		if sprite != null:
			sprite.position = Vector2.ZERO
			sprite.scale = Vector2.ONE * variant_scale


func _check_contact_damage() -> void:
	if target_player == null or not is_instance_valid(target_player):
		target_player = get_tree().current_scene.get_node_or_null("Player") as Node2D
	if target_player == null or not is_instance_valid(target_player):
		return
	if contact_cooldown_timer > 0.0:
		return
	var same_tile_as_player: bool = false
	var world: Node = get_tree().current_scene
	if world != null and world.has_method("world_to_tile"):
		var slime_tile: Vector2i = world.call("world_to_tile", global_position)
		var player_tile: Vector2i = world.call("world_to_tile", target_player.global_position)
		same_tile_as_player = slime_tile == player_tile
	var effective_range: float = maxf(contact_range, 24.0 * variant_scale)
	if not same_tile_as_player and global_position.distance_to(target_player.global_position) > effective_range:
		return
	var dealt_damage: bool = false
	if target_player.has_method("take_damage"):
		target_player.call("take_damage", contact_damage)
		dealt_damage = true
	elif world != null and world.has_method("take_damage"):
		world.call("take_damage", contact_damage)
		dealt_damage = true
	if not dealt_damage:
		return
	contact_cooldown_timer = contact_damage_cooldown


func _build_collision() -> void:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 10.0
	var body_shape: CollisionShape2D = CollisionShape2D.new()
	body_shape.shape = circle
	add_child(body_shape)


func _build_visuals() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.z_index = 4
	add_child(sprite)
	sprite.sprite_frames = _build_frames_from_sheet(sprite_texture)
	sprite.play("jump")
	_update_heart_visual()


func _update_heart_visual() -> void:
	var required_hearts: int = maxi(0, int(ceil(current_health / maxf(1.0, heart_value))))
	while heart_sprites.size() < required_hearts:
		var new_heart: Sprite2D = Sprite2D.new()
		new_heart.name = "MobHeart%d" % (heart_sprites.size() + 1)
		new_heart.texture = heart_texture if heart_texture != null else _make_tinted_heart_texture(variant_tint)
		new_heart.scale = Vector2(2.1, 2.1)
		new_heart.z_index = 20
		add_child(new_heart)
		heart_sprites.append(new_heart)
	for i in range(heart_sprites.size()):
		var heart: Sprite2D = heart_sprites[i]
		if heart == null:
			continue
		if heart_texture != null:
			heart.texture = heart_texture
		heart.visible = i < required_hearts
	_layout_heart_sprites()


func _layout_heart_sprites() -> void:
	if heart_sprites.is_empty():
		return
	var visible_hearts: Array[Sprite2D] = []
	for heart in heart_sprites:
		if heart != null and heart.visible:
			visible_hearts.append(heart)
	if visible_hearts.is_empty():
		return
	var spacing: float = 12.0
	var start_x: float = -float(visible_hearts.size() - 1) * spacing * 0.5
	var y_pos: float = -30.0 - variant_scale * 4.0
	for i in range(visible_hearts.size()):
		var h: Sprite2D = visible_hearts[i]
		h.position = Vector2(start_x + float(i) * spacing, y_pos)


func _flash_hit(lost_hearts: int) -> void:
	if lost_hearts > 0:
		_emit_heart_drop_fx(mini(lost_hearts, 4))
	_refresh_damage_highlight()


func _refresh_damage_highlight() -> void:
	hit_highlight_timer = hit_highlight_hold_seconds
	_update_damage_highlight()


func _update_damage_highlight() -> void:
	if sprite == null:
		return
	if hit_highlight_timer > 0.0:
		sprite.modulate = hit_highlight_tint
	else:
		sprite.modulate = variant_tint


func _emit_heart_drop_fx(count: int) -> void:
	if count <= 0:
		return
	var world: Node = get_tree().current_scene
	if world == null:
		return
	for i in range(count):
		var pop: Sprite2D = Sprite2D.new()
		pop.texture = heart_texture if heart_texture != null else _make_tinted_heart_texture(variant_tint)
		pop.scale = Vector2(2.4, 2.4)
		pop.global_position = global_position + Vector2(randf_range(-8.0, 8.0), -12.0)
		pop.modulate = Color(1.0, 0.88, 0.90, 0.95)
		pop.z_index = 22
		world.add_child(pop)
		var rise: float = randf_range(20.0, 36.0)
		var drift: float = randf_range(-12.0, 12.0)
		var tween: Tween = pop.create_tween()
		tween.set_parallel(true)
		tween.tween_property(pop, "global_position", pop.global_position + Vector2(drift, -rise), 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(pop, "scale", Vector2(1.1, 1.1), 0.28)
		tween.tween_property(pop, "modulate:a", 0.0, 0.34)
		tween.chain().tween_callback(pop.queue_free)


func _emit_landing_dust() -> void:
	var world: Node = get_tree().current_scene
	if world == null:
		return
	if world != null and world.has_method("spawn_combat_tile_marker"):
		world.spawn_combat_tile_marker(global_position, 0.22, false)


func _emit_death_fx() -> void:
	var world: Node = get_tree().current_scene
	if world == null:
		return
	MobCombatVFX.spawn_particle_burst(world, global_position, Color(0.54, 0.92, 0.84, 0.9), 32, 0.45)


func _build_frames_from_sheet(tex: Texture2D) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("jump")
	frames.set_animation_loop("jump", false)
	frames.set_animation_speed("jump", 8.0)
	if tex == null:
		frames.add_frame("jump", _make_fallback_slime_texture())
		return frames

	var frame_w: int = int(tex.get_width() / 4)
	var frame_h: int = int(tex.get_height() / 2)
	for row in range(2):
		for col in range(4):
			var img: Image = tex.get_image()
			img.crop(tex.get_width(), tex.get_height())
			var region: Rect2i = Rect2i(col * frame_w, row * frame_h, frame_w, frame_h)
			var frame_img: Image = Image.create(frame_w, frame_h, false, Image.FORMAT_RGBA8)
			frame_img.blit_rect(img, region, Vector2i.ZERO)
			frames.add_frame("jump", ImageTexture.create_from_image(frame_img))
	return frames


func _make_fallback_slime_texture() -> Texture2D:
	var image: Image = Image.create(24, 20, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(12.0, 10.0)
	for x in range(24):
		for y in range(20):
			var d: float = Vector2(float(x), float(y)).distance_to(center) / 10.0
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			image.set_pixel(x, y, Color(0.30, 0.85, 0.74, a))
	return ImageTexture.create_from_image(image)


func _make_tinted_heart_texture(tint: Color) -> Texture2D:
	var size_px: int = 16
	var image: Image = Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	var fill: Color = Color(
		clampf(tint.r * 1.2, 0.2, 1.0),
		clampf(tint.g * 1.2, 0.2, 1.0),
		clampf(tint.b * 1.2, 0.2, 1.0),
		1.0
	)
	var outline: Color = Color(fill.r * 0.3, fill.g * 0.3, fill.b * 0.3, 1.0)
	var pixels: PackedVector2Array = PackedVector2Array([
		Vector2(5, 2), Vector2(6, 2), Vector2(9, 2), Vector2(10, 2),
		Vector2(4, 3), Vector2(5, 3), Vector2(6, 3), Vector2(7, 3), Vector2(8, 3), Vector2(9, 3), Vector2(10, 3), Vector2(11, 3),
		Vector2(3, 4), Vector2(4, 4), Vector2(5, 4), Vector2(6, 4), Vector2(7, 4), Vector2(8, 4), Vector2(9, 4), Vector2(10, 4), Vector2(11, 4), Vector2(12, 4),
		Vector2(3, 5), Vector2(4, 5), Vector2(5, 5), Vector2(6, 5), Vector2(7, 5), Vector2(8, 5), Vector2(9, 5), Vector2(10, 5), Vector2(11, 5), Vector2(12, 5),
		Vector2(4, 6), Vector2(5, 6), Vector2(6, 6), Vector2(7, 6), Vector2(8, 6), Vector2(9, 6), Vector2(10, 6), Vector2(11, 6),
		Vector2(5, 7), Vector2(6, 7), Vector2(7, 7), Vector2(8, 7), Vector2(9, 7), Vector2(10, 7),
		Vector2(6, 8), Vector2(7, 8), Vector2(8, 8), Vector2(9, 8),
		Vector2(7, 9), Vector2(8, 9)
	])
	var lookup: Dictionary = {}
	for p in pixels:
		lookup["%s_%s" % [int(p.x), int(p.y)]] = true
	for p in pixels:
		var x: int = int(p.x)
		var y: int = int(p.y)
		var border: bool = false
		for off in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			if not lookup.has("%s_%s" % [x + off.x, y + off.y]):
				border = true
				break
		image.set_pixel(x, y, outline if border else fill)
	return ImageTexture.create_from_image(image)
