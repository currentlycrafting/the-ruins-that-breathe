extends Node
## Dynamic Light2D / LightOccluder2D helpers for world decorations.

@export var enable_dynamic_lighting: bool = true
@export_range(0.0, 1.5, 0.01) var ambient_light_strength: float = 0.42
@export var player_light_enabled: bool = true
@export var shadow_enabled: bool = true
@export var decoration_occluders_enabled: bool = true
@export var portal_glow_enabled: bool = true
@export var pickup_glow_enabled: bool = true
@export_range(0.1, 2.0, 0.05) var tree_light_energy: float = 0.28
@export_range(0.1, 2.0, 0.05) var portal_light_energy: float = 0.65

var _world: Node = null
var _canvas_modulate: CanvasModulate = null
var _player_light: PointLight2D = null


func bind_world(world: Node) -> void:
	_world = world
	_apply_ambient()
	_setup_player_light()


func _apply_ambient() -> void:
	if _world == null:
		return
	_canvas_modulate = _world.get_node_or_null("CanvasModulate") as CanvasModulate
	if _canvas_modulate == null and enable_dynamic_lighting:
		_canvas_modulate = CanvasModulate.new()
		_canvas_modulate.name = "CanvasModulate"
		_world.add_child(_canvas_modulate)
	if _canvas_modulate != null:
		var base: Color = Color(0.92 + ambient_light_strength * 0.06, 0.90 + ambient_light_strength * 0.05, 0.86 + ambient_light_strength * 0.04, 1.0)
		_canvas_modulate.color = base


func _setup_player_light() -> void:
	if _world == null or not player_light_enabled:
		return
	var player: Node2D = _world.get_node_or_null("Player") as Node2D
	if player == null:
		return
	_player_light = player.get_node_or_null("CampaignPlayerLight") as PointLight2D
	if _player_light == null:
		_player_light = PointLight2D.new()
		_player_light.name = "CampaignPlayerLight"
		_player_light.energy = 0.55
		_player_light.texture_scale = 1.6
		_player_light.color = Color(1.0, 0.9, 0.62, 1.0)
		_player_light.shadow_enabled = shadow_enabled
		player.add_child(_player_light)


func attach_tree_lighting(tree_node: Node2D) -> void:
	if not enable_dynamic_lighting or tree_node == null:
		return
	if decoration_occluders_enabled:
		_add_simple_occluder(tree_node, Vector2(12.0, 28.0))
	if pickup_glow_enabled:
		var glow: PointLight2D = PointLight2D.new()
		glow.name = "TreeAmbientLight"
		glow.energy = tree_light_energy
		glow.texture_scale = 0.9
		glow.color = Color(0.55, 0.95, 0.45, 1.0)
		glow.position = Vector2(0.0, -20.0)
		tree_node.add_child(glow)


func attach_portal_glow(node: Node2D, color: Color = Color(0.65, 0.85, 1.0, 1.0)) -> void:
	if not portal_glow_enabled or node == null:
		return
	var light: PointLight2D = PointLight2D.new()
	light.name = "PortalGlow"
	light.energy = portal_light_energy
	light.texture_scale = 1.4
	light.color = color
	node.add_child(light)


func _add_simple_occluder(parent: Node2D, size: Vector2) -> void:
	var occluder: LightOccluder2D = LightOccluder2D.new()
	occluder.name = "Occluder"
	var poly: OccluderPolygon2D = OccluderPolygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-size.x, 0.0),
		Vector2(size.x, 0.0),
		Vector2(size.x * 0.6, size.y),
		Vector2(-size.x * 0.6, size.y),
	])
	occluder.occluder = poly
	parent.add_child(occluder)
