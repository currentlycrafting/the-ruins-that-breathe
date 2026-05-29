extends Node2D
## Expandable shop placeholder for Haven.

const SHOP_ITEMS: Array[Dictionary] = [
	{"id": "health_up", "name": "Heart Boost", "cost": 50, "desc": "+10 max health"},
	{"id": "charge_up", "name": "Charge Speed", "cost": 75, "desc": "Faster charge"},
	{"id": "damage_up", "name": "Damage Up", "cost": 100, "desc": "+5% damage"},
]

var _save: Node = null
var _panel: PanelContainer = null


func _ready() -> void:
	_save = get_node_or_null("/root/SaveManager")
	_build_shop()


func _build_shop() -> void:
	var stand: ColorRect = ColorRect.new()
	stand.size = Vector2(64.0, 48.0)
	stand.color = Color(0.45, 0.32, 0.18, 0.95)
	add_child(stand)

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.position = Vector2(-90.0, -120.0)
	_panel.custom_minimum_size = Vector2(180.0, 140.0)
	add_child(_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	_panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Haven Shop"
	vbox.add_child(title)

	for item in SHOP_ITEMS:
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = "%s (%d)" % [item.get("name", ""), int(item.get("cost", 0))]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var buy: Button = Button.new()
		buy.text = "Buy"
		buy.pressed.connect(_purchase.bind(item))
		row.add_child(buy)
		vbox.add_child(row)

	var interact: Area2D = Area2D.new()
	interact.collision_layer = 0
	interact.collision_mask = 5
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 48.0
	shape.shape = circle
	interact.add_child(shape)
	add_child(interact)
	interact.body_entered.connect(_on_player_near)


func _on_player_near(body: Node2D) -> void:
	if body == null or body.name != "Player":
		return
	if _panel != null:
		_panel.visible = true


func _purchase(item: Dictionary) -> void:
	if _save == null:
		return
	var cost: int = int(item.get("cost", 0))
	if not _save.spend_coins(cost):
		return
	_save.purchased_shop_items[String(item.get("id", ""))] = true
	_save.save_progress()
