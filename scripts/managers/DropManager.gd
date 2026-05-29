extends Node
## Spawns DropItem pickups, loads coin/slime textures, updates currency UI.

signal pickup_collected(item_id: String, value: int)

const COIN_DROP_PATH: String = "res://assets/drops/coin-drop.png"
const SLIME_DROP_PATH: String = "res://assets/drops/slime-drop.png"

@export var silver_coin_value: int = 1
@export var gold_coin_value: int = 10
@export var default_drop_spread: float = 22.0
@export_range(0.1, 2.0, 0.05) var drop_pickup_visual_scale: float = 0.4

var _silver_texture: Texture2D = null
var _gold_texture: Texture2D = null
var _slime_texture: Texture2D = null
var _heart_texture: Texture2D = null
var _drop_root: Node2D = null
var _world: Node = null
var _coin_label: Label = null
var _coin_pulse_tween: Tween = null

var _save: Node = null


func _ready() -> void:
	_save = get_node_or_null("/root/SaveManager")
	_load_textures()
	if _save != null and _save.has_signal("coins_changed"):
		_save.coins_changed.connect(_on_coins_changed)


func _load_textures() -> void:
	if ResourceLoader.exists(COIN_DROP_PATH):
		var sheet: Texture2D = load(COIN_DROP_PATH) as Texture2D
		if sheet != null:
			var half: float = sheet.get_size().x * 0.5
			var h: float = sheet.get_size().y
			var gold_atlas: AtlasTexture = AtlasTexture.new()
			gold_atlas.atlas = sheet
			gold_atlas.region = Rect2(0.0, 0.0, half, h)
			_gold_texture = gold_atlas
			var silver_atlas: AtlasTexture = AtlasTexture.new()
			silver_atlas.atlas = sheet
			silver_atlas.region = Rect2(half, 0.0, half, h)
			_silver_texture = silver_atlas
	if ResourceLoader.exists(SLIME_DROP_PATH):
		_slime_texture = load(SLIME_DROP_PATH) as Texture2D
	_heart_texture = _make_heart_texture()


func bind_world(world: Node) -> void:
	_world = world
	_drop_root = world.get_node_or_null("DropRoot") as Node2D
	if _drop_root == null:
		_drop_root = Node2D.new()
		_drop_root.name = "DropRoot"
		_drop_root.y_sort_enabled = true
		_drop_root.z_index = 30
		world.add_child(_drop_root)


func bind_coin_label(label: Label) -> void:
	_coin_label = label
	_refresh_coin_label()


func spawn_mob_drops(world_position: Vector2, mob_id: String, bonus_count: int = 0) -> void:
	if _drop_root == null or _world == null:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var rolled: Dictionary = MobDropTables.roll_drop(mob_id, rng)
	if rolled.is_empty():
		return
	var count: int = int(rolled.get("count", 1)) + bonus_count
	for i in range(count):
		var spread: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * randf_range(4.0, default_drop_spread)
		spawn_drop(String(rolled.get("id", MobDropTables.DROP_SILVER)), world_position + spread, rng)


func spawn_drop(drop_id: String, world_position: Vector2, rng: RandomNumberGenerator = null) -> DropItem:
	if _drop_root == null or _world == null:
		return null
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var config: Dictionary = _config_for_drop_id(drop_id)
	var texture: Texture2D = config.get("texture", _silver_texture)
	if texture == null:
		return null
	var drop: DropItem = DropItem.new()
	_drop_root.add_child(drop)
	drop.global_position = world_position
	config["burst_dir"] = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, -0.15)).normalized()
	config["burst_speed"] = rng.randf_range(90.0, 160.0)
	drop.setup(texture, _world, _world.get_node_or_null("Player") as Node2D, config)
	return drop


func handle_collected(drop: DropItem) -> void:
	if drop == null:
		return
	match drop.item_type:
		"coin":
			if _save != null:
				_save.add_coins(drop.value)
			pickup_collected.emit(drop.item_id, drop.value)
			_pulse_coin_counter()
			if drop.pickup_text_enabled and _world != null and _world.has_method("show_pickup_text"):
				var prefix: String = "+" + str(drop.value)
				var color: Color = Color(1.0, 0.92, 0.45, 1.0) if drop.item_id == MobDropTables.DROP_GOLD else Color(0.88, 0.92, 1.0, 1.0)
				_world.call("show_pickup_text", drop.global_position, prefix, color)
		"health":
			if _world != null and _world.has_method("heal_player"):
				_world.call("heal_player", float(drop.value))
		"material":
			pickup_collected.emit(drop.item_id, drop.value)
	_save_save_if_needed()


func _scaled_drop_size(base_scale: float) -> float:
	return base_scale * drop_pickup_visual_scale


func _config_for_drop_id(drop_id: String) -> Dictionary:
	match drop_id:
		MobDropTables.DROP_GOLD:
			return {
				"item_id": drop_id,
				"item_name": "Gold Coin",
				"item_type": "coin",
				"value": gold_coin_value,
				"rarity": "uncommon",
				"texture": _gold_texture,
				"scale": _scaled_drop_size(1.35),
				"glow_color": Color(1.0, 0.82, 0.22, 1.0),
				"glow_energy": 0.55,
				"glow_scale": 0.22,
				"magnet_radius": 110.0,
			}
		MobDropTables.DROP_HEART:
			return {
				"item_id": drop_id,
				"item_name": "Heart",
				"item_type": "health",
				"value": 25,
				"texture": _heart_texture,
				"scale": _scaled_drop_size(1.2),
				"glow_color": Color(1.0, 0.35, 0.45, 1.0),
				"glow_scale": 0.2,
			}
		MobDropTables.DROP_SLIME:
			return {
				"item_id": drop_id,
				"item_name": "Slime Drop",
				"item_type": "material",
				"value": 1,
				"texture": _slime_texture,
				"scale": _scaled_drop_size(1.25),
				"glow_color": Color(0.35, 0.95, 0.82, 1.0),
				"glow_scale": 0.2,
			}
		MobDropTables.DROP_CHARGE:
			return {
				"item_id": drop_id,
				"item_name": "Charge Orb",
				"item_type": "charge",
				"value": 1,
				"texture": _slime_texture,
				"scale": _scaled_drop_size(1.1),
				"glow_color": Color(0.55, 0.75, 1.0, 1.0),
				"glow_scale": 0.18,
			}
		MobDropTables.DROP_XP:
			return {
				"item_id": drop_id,
				"item_name": "XP Orb",
				"item_type": "material",
				"value": 1,
				"texture": _slime_texture,
				"scale": _scaled_drop_size(1.05),
				"glow_color": Color(0.58, 0.86, 1.0, 1.0),
				"glow_scale": 0.16,
			}
		_:
			return {
				"item_id": MobDropTables.DROP_SILVER,
				"item_name": "Silver Coin",
				"item_type": "coin",
				"value": silver_coin_value,
				"texture": _silver_texture,
				"scale": _scaled_drop_size(1.2),
				"glow_color": Color(0.82, 0.88, 1.0, 1.0),
				"glow_scale": 0.2,
			}


func _refresh_coin_label() -> void:
	if _coin_label == null or _save == null:
		return
	_coin_label.text = "Coins: %d" % int(_save.coins)


func _on_coins_changed(_total: int) -> void:
	_refresh_coin_label()


func _pulse_coin_counter() -> void:
	_refresh_coin_label()
	if _coin_label == null:
		return
	if _coin_pulse_tween != null and _coin_pulse_tween.is_valid():
		_coin_pulse_tween.kill()
	_coin_label.scale = Vector2.ONE
	_coin_pulse_tween = _coin_label.create_tween()
	_coin_pulse_tween.tween_property(_coin_label, "scale", Vector2(1.14, 1.14), 0.08)
	_coin_pulse_tween.tween_property(_coin_label, "scale", Vector2.ONE, 0.12)


func _save_save_if_needed() -> void:
	if _save != null:
		_save.save_progress()


func _make_heart_texture() -> Texture2D:
	var image: Image = Image.create(14, 12, false, Image.FORMAT_RGBA8)
	var fill: Color = Color(1.0, 0.25, 0.35, 1.0)
	for x in range(14):
		for y in range(12):
			var p: Vector2 = Vector2(float(x) - 6.5, float(y) - 5.0)
			if p.length() < 4.5:
				image.set_pixel(x, y, fill)
	return ImageTexture.create_from_image(image)
