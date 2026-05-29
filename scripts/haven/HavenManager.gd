extends Node2D
## Peaceful hub after World 1. No combat waves by default.

@export var haven_tree_count: int = 36
@export var haven_half_width_tiles: int = 28
@export var haven_half_height_tiles: int = 18

var _player: Node2D = null
var _board: Node = null
var _shop: Node = null
var _tile_layer: TileMapLayer = null
var _tile_source_id: int = -1
var _floor_tiles: Array[Vector2i] = []


func _ready() -> void:
	_build_haven_tilemap()
	_spawn_trees()
	_setup_board()
	_setup_shop()
	_player = get_node_or_null("Player") as Node2D
	var lighting: Node = get_node_or_null("/root/LightingManager")
	if lighting != null and lighting.has_method("bind_world"):
		lighting.call("bind_world", self)


func _build_haven_tilemap() -> void:
	_tile_layer = get_node_or_null("TileMapLayer") as TileMapLayer
	if _tile_layer == null:
		_tile_layer = TileMapLayer.new()
		_tile_layer.name = "TileMapLayer"
		add_child(_tile_layer)
		move_child(_tile_layer, 0)

	var world_scene: PackedScene = load("res://world.tscn") as PackedScene
	if world_scene == null:
		return
	var world_preview: Node = world_scene.instantiate()
	if world_preview == null:
		return
	var preview_layer: TileMapLayer = world_preview.get_node_or_null("TileMapLayer") as TileMapLayer
	if preview_layer != null and preview_layer.tile_set != null:
		_tile_layer.tile_set = preview_layer.tile_set.duplicate(true)
	world_preview.queue_free()
	if _tile_layer.tile_set == null:
		return
	_collect_floor_tiles()
	_paint_haven_floor()


func _collect_floor_tiles() -> void:
	_floor_tiles.clear()
	if _tile_layer == null or _tile_layer.tile_set == null:
		return
	var source_count: int = _tile_layer.tile_set.get_source_count()
	if source_count <= 0:
		return
	_tile_source_id = _tile_layer.tile_set.get_source_id(0)
	var source: TileSetAtlasSource = _tile_layer.tile_set.get_source(_tile_source_id) as TileSetAtlasSource
	if source == null:
		return
	for x in range(0, 20):
		for y in range(0, 12):
			var atlas: Vector2i = Vector2i(x, y)
			if source.has_tile(atlas):
				_floor_tiles.append(atlas)
	if _floor_tiles.is_empty():
		_floor_tiles.append(Vector2i.ZERO)


func _paint_haven_floor() -> void:
	if _tile_layer == null or _tile_source_id < 0 or _floor_tiles.is_empty():
		return
	_tile_layer.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 424242
	for x in range(-haven_half_width_tiles, haven_half_width_tiles + 1):
		for y in range(-haven_half_height_tiles, haven_half_height_tiles + 1):
			var cell: Vector2i = Vector2i(x, y)
			var tile: Vector2i = _floor_tiles[rng.randi_range(0, _floor_tiles.size() - 1)]
			_tile_layer.set_cell(cell, _tile_source_id, tile)


func _spawn_trees() -> void:
	var root: Node2D = Node2D.new()
	root.name = "HavenTrees"
	add_child(root)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(haven_tree_count):
		var tree: ColorRect = ColorRect.new()
		tree.size = Vector2(10.0, 18.0)
		tree.color = Color(0.18, 0.42, 0.16, 0.9)
		tree.position = Vector2(
			rng.randf_range(-float(haven_half_width_tiles) * 34.0, float(haven_half_width_tiles) * 34.0),
			rng.randf_range(-float(haven_half_height_tiles) * 26.0, float(haven_half_height_tiles) * 26.0)
		)
		root.add_child(tree)


func _setup_board() -> void:
	if get_node_or_null("CampaignBoard") != null:
		return
	var board_script: Script = load("res://scripts/haven/CampaignBoard.gd")
	if board_script == null:
		return
	_board = Node2D.new()
	_board.name = "CampaignBoard"
	_board.set_script(board_script)
	_board.position = Vector2(120.0, -40.0)
	add_child(_board)


func _setup_shop() -> void:
	if get_node_or_null("HavenShop") != null:
		return
	var shop_script: Script = load("res://scripts/haven/HavenShop.gd")
	if shop_script == null:
		return
	_shop = Node2D.new()
	_shop.name = "HavenShop"
	_shop.set_script(shop_script)
	_shop.position = Vector2(-180.0, 20.0)
	add_child(_shop)
