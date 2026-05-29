class_name WeaponManager
extends Node

## WeaponManager.gd
## Connects world/player input, inventory, HUD and equipped weapon behavior.

const WEAPON_SCRIPT: Script = preload("res://scripts/weapons/Weapon.gd")
const FLOWER_GUN_SCRIPT: Script = preload("res://scripts/weapons/FlowerGun.gd")
const MICHAEL_GUN_SCRIPT: Script = preload("res://scripts/weapons/MichaelGun.gd")
const CHARACTER_PROFILE_WEAPON_SCRIPT: Script = preload("res://scripts/weapons/CharacterProfileWeapon.gd")
const STARTING_WEAPON_SCRIPTS: Array[Script] = [
	FLOWER_GUN_SCRIPT,
	MICHAEL_GUN_SCRIPT
]

## The five purchasable classes/items. The player starts with exactly one (random);
## the rest are locked and bought in the Haven shop.
const CLASS_COST: int = 100
const CLASS_CATALOG: Array[Dictionary] = [
	{"id": "flower", "name": "Flower", "kind": "gun"},
	{"id": "michael", "name": "Michael", "kind": "gun"},
	{"id": "hero", "name": "Hero", "kind": "profile"},
	{"id": "prince", "name": "Prince", "kind": "profile"},
	{"id": "stack", "name": "Stack", "kind": "profile"},
]

var save_manager: Node = null

@export_group("Weapon HUD Layout")
@export var weapon_hud_position: Vector2 = Vector2(18.0, 18.0)
@export var weapon_hud_size: Vector2 = Vector2(360.0, 68.0)
@export var weapon_hud_scale: float = 1.0

@export_group("Inventory Panel Layout")
@export var inventory_panel_position: Vector2 = Vector2(0.0, -140.0)
@export var enable_weapon_hud: bool = false
@export var inventory_panel_size: Vector2 = Vector2(560.0, 72.0)
@export var inventory_panel_opacity: float = 0.94

@export_group("UI")
@export var enable_weapon_ui: bool = true
@export var enable_charge_circle: bool = true

@export_group("Character Inventory Icons")
@export var hero_icon_texture: Texture2D = null
@export var hero_floor_texture: Texture2D = null
@export var prince_icon_texture: Texture2D = null
@export var prince_floor_texture: Texture2D = null
@export var flower_icon_texture: Texture2D = null
@export var flower_floor_texture: Texture2D = null
@export var michael_icon_texture: Texture2D = null
@export var michael_floor_texture: Texture2D = null
@export var stack_icon_texture: Texture2D = null
@export var stack_floor_texture: Texture2D = null

@export_group("Charge UI")
@export var charge_hold_delay_seconds: float = 0.0
@export var charge_ui_fill_color: Color = Color(0.96, 0.96, 0.98, 0.98)
@export var charge_ui_base_color: Color = Color(0.02, 0.02, 0.02, 0.94)
@export var charge_ui_offset: Vector2 = Vector2(-40.0, -188.0)
@export var charge_icon_screen_offset: Vector2 = Vector2(-38.0, -150.0)
@export var time_before_icon_appears: float = 1.0
@export var full_charge_hold_before_crack: float = 3.0
@export var crack_duration: float = 0.25
@export var max_charge_damage_multiplier: float = 2.5
@export var shake_intensity: float = 2.5
@export var glow_intensity: float = 1.3

@export_group("Pickup / Drop")
@export var pickup_radius: float = 78.0
@export var pickup_drop_grace_time: float = 0.24
@export var drop_throw_distance: float = 28.0

@export_group("Debug")
@export var debug_logs_enabled: bool = false

signal weapon_changed(current_weapon: Weapon)

var player: Node2D = null
var world: Node = null
var net_node: Node = null
var equipped_weapon: Weapon = null
var all_weapons: Array[Weapon] = []

var charge_ui: Weapon.ChargeUI = null
var inventory_ui: Weapon.InventoryUI = null
var weapon_hud: Weapon.WeaponHUD = null

var is_right_charge_held: bool = false
var is_charge_pending: bool = false
var pending_charge_elapsed: float = 0.0
var elapsed_runtime: float = 0.0
var last_drop_time: float = -1000.0
var combat_input_enabled: bool = true
var ui_revealed: bool = false
var hotbar_revealed: bool = false
var suppress_initial_ui_reveal: bool = true
var charge_icon_hold_elapsed: float = 0.0
var charge_icon_full_elapsed: float = 0.0
var charge_icon_visible_phase: bool = false
var charge_icon_cracking: bool = false

func _ready() -> void:
	player = get_parent() as Node2D
	world = get_tree().current_scene
	net_node = get_node_or_null("/root/Net")
	save_manager = get_node_or_null("/root/SaveManager")
	_autoload_character_inventory_icons()
	_build_ui()
	_rebuild_inventory_from_owned()
	ui_revealed = true
	_sync_inventory_visibility()
	set_process(true)
	set_process_unhandled_input(true)


func _autoload_character_inventory_icons() -> void:
	hero_icon_texture = _load_texture_if_missing(hero_icon_texture, [
		"res://assets/weapons/homelander.png",
		"res://weapons/homelander.png"
	])
	hero_floor_texture = _load_texture_if_missing(hero_floor_texture, [
		"res://assets/weapons/homelander.png",
		"res://weapons/homelander.png"
	])
	prince_icon_texture = _load_texture_if_missing(prince_icon_texture, [
		"res://assets/weapons/caraxes.png",
		"res://weapons/caraxes.png"
	])
	prince_floor_texture = _load_texture_if_missing(prince_floor_texture, [
		"res://assets/weapons/caraxes.png",
		"res://weapons/caraxes.png"
	])
	flower_icon_texture = _load_texture_if_missing(flower_icon_texture, [
		"res://assets/weapons/flower-gun.png"
	])
	flower_floor_texture = _load_texture_if_missing(flower_floor_texture, [
		"res://assets/weapons/flower-gun.png"
	])
	michael_icon_texture = _load_texture_if_missing(michael_icon_texture, [
		"res://assets/weapons/mike-jake-glove.png"
	])
	michael_floor_texture = _load_texture_if_missing(michael_floor_texture, [
		"res://assets/weapons/mike-jake-glove.png"
	])
	stack_icon_texture = _load_texture_if_missing(stack_icon_texture, [
		"res://assets/weapons/stack-&-smoke.png"
	])
	stack_floor_texture = _load_texture_if_missing(stack_floor_texture, [
		"res://assets/weapons/stack-&-smoke.png"
	])


func _load_texture_if_missing(existing: Texture2D, candidate_paths: Array[String]) -> Texture2D:
	if existing != null:
		return existing
	for path in candidate_paths:
		if not ResourceLoader.exists(path):
			continue
		var loaded: Resource = load(path)
		if loaded is Texture2D:
			return loaded as Texture2D
	return null

func _process(_delta: float) -> void:
	elapsed_runtime += _delta
	_update_charge_ui_position()
	if is_right_charge_held and _is_hero_profile_equipped():
		var character_controller: Node = _get_character_controller()
		if character_controller != null and character_controller.has_method("hero_update_hold_attack"):
			character_controller.call("hero_update_hold_attack", _delta)
	if not combat_input_enabled:
		return
	if is_charge_pending and is_right_charge_held:
		pending_charge_elapsed += _delta
		if pending_charge_elapsed >= charge_hold_delay_seconds:
			is_charge_pending = false
			if equipped_weapon != null:
				equipped_weapon.start_charge()
				_set_charge_visual(true)
	if equipped_weapon != null and equipped_weapon.is_charging and charge_ui != null:
		charge_ui.show_charge(equipped_weapon.get_charge_ratio())

func _unhandled_input(event: InputEvent) -> void:
	if _pressed_action_or_key(event, "weapon_inventory", KEY_P):
		_toggle_inventory()
		get_viewport().set_input_as_handled()
		return

	if _pressed_action_or_key(event, "weapon_pickup", KEY_E):
		_try_pickup_nearest()
		get_viewport().set_input_as_handled()
		return

	if _pressed_action_or_key(event, "weapon_drop", KEY_Q):
		drop_equipped_weapon()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if not combat_input_enabled:
				return
			if mouse_event.pressed:
				_start_charge()
			else:
				_release_charge_shot()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		var digit_index: int = _inventory_digit_index_from_key(key_event.keycode)
		if digit_index >= 0:
			_equip_by_index(digit_index)

func _build_ui() -> void:
	if world == null:
		return
	if not enable_weapon_ui and not enable_charge_circle:
		return
	var hud_layer: CanvasLayer = world.get_node_or_null("HudLayer")
	if hud_layer == null:
		hud_layer = world.get_node_or_null("HUDLayer")
	if hud_layer == null:
		hud_layer = CanvasLayer.new()
		hud_layer.name = "HudLayer"
		world.add_child(hud_layer)

	if enable_charge_circle:
		charge_ui = WEAPON_SCRIPT.ChargeUI.new()
		charge_ui.name = "WeaponChargeUI"
		charge_ui.fill_color = charge_ui_fill_color
		charge_ui.base_color = charge_ui_base_color
		charge_ui.use_quarter_steps = true
		charge_ui.shake_amount = 4.5
		hud_layer.add_child(charge_ui)
		charge_ui.hide_charge()

	if not enable_weapon_ui:
		return
	inventory_ui = WEAPON_SCRIPT.InventoryUI.new()
	inventory_ui.name = "InventoryUI"
	inventory_ui.weapon_manager = self
	inventory_ui.panel_position = inventory_panel_position
	inventory_ui.panel_size = inventory_panel_size
	inventory_ui.panel_opacity = inventory_panel_opacity
	hud_layer.add_child(inventory_ui)
	inventory_ui.visible = false

	if enable_weapon_hud:
		weapon_hud = WEAPON_SCRIPT.WeaponHUD.new()
		weapon_hud.name = "WeaponHUD"
		weapon_hud.position = weapon_hud_position
		weapon_hud.size = weapon_hud_size
		weapon_hud.scale = Vector2.ONE * weapon_hud_scale
		weapon_hud.weapon_manager = self
		hud_layer.add_child(weapon_hud)
		weapon_hud.visible = false

func all_class_ids() -> Array:
	var ids: Array = []
	for entry in CLASS_CATALOG:
		ids.append(String(entry.get("id", "")))
	return ids


func _class_entry(class_id: String) -> Dictionary:
	for entry in CLASS_CATALOG:
		if String(entry.get("id", "")) == class_id:
			return entry
	return {}


func get_owned_class_ids() -> Array:
	if save_manager != null and save_manager.has_method("get_owned_classes"):
		return save_manager.call("get_owned_classes")
	return []


func is_class_owned(class_id: String) -> bool:
	return get_owned_class_ids().has(class_id)


func get_unowned_class_ids() -> Array:
	var owned: Array = get_owned_class_ids()
	var result: Array = []
	for entry in CLASS_CATALOG:
		var id: String = String(entry.get("id", ""))
		if not owned.has(id):
			result.append(id)
	return result


func get_class_display_name(class_id: String) -> String:
	var entry: Dictionary = _class_entry(class_id)
	return String(entry.get("name", class_id.capitalize()))


func get_class_icon(class_id: String) -> Texture2D:
	match class_id:
		"flower":
			return flower_icon_texture
		"michael":
			return michael_icon_texture
		"hero":
			return hero_icon_texture
		"prince":
			return prince_icon_texture
		"stack":
			return stack_icon_texture
	return null


func _create_weapon_for_class(class_id: String) -> Weapon:
	var entry: Dictionary = _class_entry(class_id)
	if entry.is_empty():
		return null
	var kind: String = String(entry.get("kind", "gun"))
	var display_name: String = String(entry.get("name", class_id.capitalize()))
	if kind == "gun":
		var script: Script = FLOWER_GUN_SCRIPT if class_id == "flower" else MICHAEL_GUN_SCRIPT
		var weapon: Weapon = script.new() as Weapon
		if weapon == null:
			return null
		_apply_starting_weapon_icons(weapon)
		_apply_world_settings_to_weapon(weapon)
		weapon.set_meta("class_id", class_id)
		return weapon
	var icon: Texture2D = get_class_icon(class_id)
	var floor_tex: Texture2D = prince_floor_texture if class_id == "prince" else (hero_floor_texture if class_id == "hero" else stack_floor_texture)
	var profile: Weapon = _make_character_profile_weapon(class_id, display_name, icon, floor_tex)
	if profile != null:
		profile.set_meta("class_id", class_id)
	return profile


## Rebuilds the hotbar to exactly the owned classes. If none are owned yet, assign one random.
func _rebuild_inventory_from_owned() -> void:
	var owned: Array = get_owned_class_ids()
	if owned.is_empty():
		begin_new_run()
		return
	_clear_all_weapons()
	var first_weapon: Weapon = null
	for id in owned:
		var weapon: Weapon = _create_weapon_for_class(String(id))
		if weapon == null:
			continue
		add_weapon_to_inventory(weapon)
		if first_weapon == null:
			first_weapon = weapon
	if first_weapon != null:
		equip_weapon(first_weapon)


func _clear_all_weapons() -> void:
	if equipped_weapon != null:
		_disconnect_weapon_signals(equipped_weapon)
		if equipped_weapon.get_parent() == player:
			player.remove_child(equipped_weapon)
		equipped_weapon = null
	for weapon in all_weapons:
		if weapon != null and is_instance_valid(weapon):
			if weapon.get_parent() != null:
				weapon.get_parent().remove_child(weapon)
			weapon.queue_free()
	all_weapons.clear()
	if inventory_ui != null:
		inventory_ui.refresh()


## Starts a fresh run: exactly one random class owned, equipped, in the hotbar.
func begin_new_run() -> void:
	var ids: Array = all_class_ids()
	if ids.is_empty():
		return
	var chosen: String = String(ids[randi() % ids.size()])
	if save_manager != null and save_manager.has_method("reset_owned_classes_to"):
		save_manager.call("reset_owned_classes_to", chosen)
	_clear_all_weapons()
	var weapon: Weapon = _create_weapon_for_class(chosen)
	if weapon != null:
		add_weapon_to_inventory(weapon)
		equip_weapon(weapon)


## Buys a locked class with coins; unlocks it and adds it to the hotbar. Returns true on success.
func purchase_class(class_id: String) -> bool:
	if class_id == "" or _class_entry(class_id).is_empty():
		return false
	if is_class_owned(class_id):
		return false
	if save_manager == null:
		return false
	if not save_manager.has_method("spend_coins") or not bool(save_manager.call("spend_coins", CLASS_COST)):
		return false
	if save_manager.has_method("add_owned_class"):
		save_manager.call("add_owned_class", class_id)
	var weapon: Weapon = _create_weapon_for_class(class_id)
	if weapon != null:
		add_weapon_to_inventory(weapon)
	if inventory_ui != null:
		inventory_ui.refresh()
	return true


func _make_character_profile_weapon(profile_id: String, display_name: String, icon: Texture2D, floor_tex: Texture2D) -> Weapon:
	if CHARACTER_PROFILE_WEAPON_SCRIPT == null:
		return null
	var created: Variant = CHARACTER_PROFILE_WEAPON_SCRIPT.new()
	var profile_weapon: Weapon = created as Weapon
	if profile_weapon == null:
		return null
	profile_weapon.set("character_profile_id", profile_id)
	profile_weapon.set("character_display_name", display_name)
	profile_weapon.weapon_name = display_name
	profile_weapon.weapon_icon_texture = icon
	profile_weapon.weapon_floor_texture = floor_tex
	return profile_weapon


func _apply_hotbar_icon(weapon: Weapon, icon: Texture2D, floor_tex: Texture2D = null) -> void:
	if weapon == null or icon == null:
		return
	var floor_texture: Texture2D = floor_tex if floor_tex != null else icon
	weapon.weapon_icon_texture = icon
	weapon.weapon_floor_texture = floor_texture
	if _weapon_has_property(weapon, "ui_icon"):
		weapon.set("ui_icon", icon)
	if _weapon_has_property(weapon, "floor_pickup_sprite"):
		weapon.set("floor_pickup_sprite", floor_texture)


func _weapon_has_property(weapon: Weapon, property_name: String) -> bool:
	for entry in weapon.get_property_list():
		if String(entry.get("name", "")) == property_name:
			return true
	return false


func _apply_starting_weapon_icons(weapon: Weapon) -> void:
	if weapon == null:
		return
	var weapon_script: Script = weapon.get_script()
	if weapon_script == FLOWER_GUN_SCRIPT:
		_apply_hotbar_icon(weapon, flower_icon_texture, flower_floor_texture)
	elif weapon_script == MICHAEL_GUN_SCRIPT:
		_apply_hotbar_icon(weapon, michael_icon_texture, michael_floor_texture)

func add_weapon_to_inventory(weapon: Weapon) -> void:
	if weapon == null:
		return
	if all_weapons.has(weapon):
		return
	all_weapons.append(weapon)
	if not suppress_initial_ui_reveal:
		_set_weapon_ui_visible(true)
	if inventory_ui != null:
		inventory_ui.refresh()

func equip_weapon(weapon: Weapon) -> void:
	if weapon == null or player == null:
		return
	_stop_charge_state()
	if equipped_weapon != null:
		_disconnect_weapon_signals(equipped_weapon)
		if equipped_weapon.has_method("on_unequipped"):
			equipped_weapon.on_unequipped()
		if equipped_weapon.get_parent() == player:
			player.remove_child(equipped_weapon)

	equipped_weapon = weapon
	if not all_weapons.has(equipped_weapon):
		all_weapons.append(equipped_weapon)

	if equipped_weapon.get_parent() != null:
		equipped_weapon.get_parent().remove_child(equipped_weapon)
	player.add_child(equipped_weapon)
	equipped_weapon.position = Vector2.ZERO
	equipped_weapon.visible = false

	_apply_world_settings_to_weapon(equipped_weapon)
	equipped_weapon.on_equipped(player)
	_connect_weapon_signals(equipped_weapon)

	if world != null and world.has_method("set_player_has_weapon"):
		world.call("set_player_has_weapon", true)
	if world != null and world.has_method("set_equipped_weapon"):
		world.call("set_equipped_weapon", equipped_weapon)
	_sync_character_profile_for_equipped_weapon()
	if inventory_ui != null:
		inventory_ui.refresh()
	if not suppress_initial_ui_reveal:
		_set_weapon_ui_visible(true)
	weapon_changed.emit(equipped_weapon)
	_log("Equipped weapon: %s" % equipped_weapon.weapon_name)


func _sync_character_profile_for_equipped_weapon() -> void:
	if player == null:
		return
	var character_controller: Node = player.get_node_or_null("CharacterController")
	if character_controller == null or not character_controller.has_method("set_character"):
		return
	if equipped_weapon != null and equipped_weapon.has_method("get_character_profile_id"):
		var profile_id: String = str(equipped_weapon.call("get_character_profile_id"))
		if profile_id != "":
			character_controller.call("set_character", profile_id)
			if character_controller.has_method("get_profile_charge_time"):
				equipped_weapon.charge_time = float(character_controller.call("get_profile_charge_time", profile_id))
			if character_controller.has_method("get_profile_fire_rate"):
				equipped_weapon.fire_rate = float(character_controller.call("get_profile_fire_rate", profile_id, false))
			return
	character_controller.call("set_character", "classic")

func refresh_equipped_weapon_settings() -> void:
	if equipped_weapon == null:
		return
	_apply_world_settings_to_weapon(equipped_weapon)
	if inventory_ui != null:
		inventory_ui.refresh()

func spawn_world_weapon(weapon: Weapon, world_position: Vector2) -> Weapon.WorldWeapon:
	if world == null or weapon == null:
		return null
	var world_weapon: Weapon.WorldWeapon = WEAPON_SCRIPT.WorldWeapon.new()
	world.add_child(world_weapon)
	world_weapon.setup(weapon, world_position)
	world_weapon.picked_up.connect(_on_world_weapon_picked_up)
	_log("Spawned floor weapon: %s" % weapon.weapon_name)
	return world_weapon

func drop_equipped_weapon() -> void:
	if equipped_weapon == null or world == null or player == null:
		return
	_stop_charge_state()
	var dropped_weapon: Weapon = equipped_weapon
	_disconnect_weapon_signals(dropped_weapon)
	if dropped_weapon.get_parent() == player:
		player.remove_child(dropped_weapon)
	all_weapons.erase(dropped_weapon)
	equipped_weapon = null
	var drop_direction: Vector2 = _get_aim_direction()
	var drop_position: Vector2 = player.global_position + drop_direction * drop_throw_distance
	var spawned_drop: Weapon.WorldWeapon = spawn_world_weapon(dropped_weapon, drop_position)
	var drop_uid: String = "%s_%s" % [str(multiplayer.get_unique_id()), str(Time.get_ticks_msec())]
	if spawned_drop != null:
		spawned_drop.set_meta("net_drop_id", drop_uid)
		if world != null and world.has_method("register_network_world_weapon"):
			world.call("register_network_world_weapon", drop_uid, spawned_drop)
	last_drop_time = elapsed_runtime
	if net_node != null and net_node.has_method("send_weapon_dropped"):
		var weapon_key: String = _weapon_network_key(dropped_weapon)
		net_node.call("send_weapon_dropped", weapon_key, drop_position, drop_uid)
	if world.has_method("set_player_has_weapon"):
		world.call("set_player_has_weapon", false)
	if world.has_method("set_equipped_weapon"):
		world.call("set_equipped_weapon", null)
	if not all_weapons.is_empty():
		equip_weapon(all_weapons[0])
	if inventory_ui != null:
		inventory_ui.refresh()
	weapon_changed.emit(equipped_weapon)
	_log("Dropped weapon.")

func _on_world_weapon_picked_up(_pickup_player: Node2D, weapon: Weapon) -> void:
	add_weapon_to_inventory(weapon)
	if equipped_weapon == null:
		equip_weapon(weapon)
	if inventory_ui != null:
		inventory_ui.refresh()
	if not suppress_initial_ui_reveal:
		_set_weapon_ui_visible(true)

func _try_pickup_nearest() -> void:
	if world == null or player == null:
		return
	if elapsed_runtime - last_drop_time < pickup_drop_grace_time:
		return
	var nearest: Weapon.WorldWeapon = null
	var nearest_distance: float = pickup_radius
	for child in world.get_children():
		var floor_weapon: Weapon.WorldWeapon = child as Weapon.WorldWeapon
		if floor_weapon == null:
			continue
		var distance_to_player: float = player.global_position.distance_to(floor_weapon.global_position)
		if distance_to_player < nearest_distance:
			nearest_distance = distance_to_player
			nearest = floor_weapon
	if nearest != null:
		var picked_up: bool = nearest.try_pickup(player)
		if picked_up and net_node != null and net_node.has_method("send_weapon_picked"):
			var drop_uid_variant: Variant = nearest.get_meta("net_drop_id", "")
			var drop_uid: String = str(drop_uid_variant)
			if drop_uid != "":
				net_node.call("send_weapon_picked", drop_uid)
				if world != null and world.has_method("_on_net_remote_weapon_picked"):
					world.call("_on_net_remote_weapon_picked", multiplayer.get_unique_id(), drop_uid)
		_log("Picked up nearest weapon.")

func _apply_world_settings_to_weapon(weapon: Weapon) -> void:
	if weapon == null or world == null:
		return
	var settings: Dictionary = {}
	var getter_name: String = ""
	if weapon.has_method("get_world_settings_getter_name"):
		getter_name = String(weapon.call("get_world_settings_getter_name"))
	var weapon_script: Script = weapon.get_script()
	if getter_name != "" and world.has_method(getter_name):
		settings = world.call(getter_name)
	elif weapon_script == FLOWER_GUN_SCRIPT and world.has_method("get_flower_gun_settings"):
		settings = world.call("get_flower_gun_settings")
	if world.has_method("get_visual_quality_settings"):
		settings["visual_quality"] = world.call("get_visual_quality_settings")
	weapon.apply_runtime_settings(settings)
	_apply_starting_weapon_icons(weapon)

func _fire_normal_shot() -> void:
	if _inventory_open():
		return
	if equipped_weapon == null:
		return
	if equipped_weapon.is_charging:
		return
	var aim_direction: Vector2 = _get_aim_direction()
	_play_shoot_animation(aim_direction)
	equipped_weapon.shoot(aim_direction)

func _start_charge() -> void:
	if _inventory_open():
		return
	if equipped_weapon == null:
		return
	if _is_hero_profile_equipped():
		var character_controller: Node = _get_character_controller()
		if character_controller != null:
			if float(character_controller.get("attack_cooldown_remaining")) > 0.0:
				return
			if character_controller.has_method("hero_begin_hold_attack"):
				character_controller.call("hero_begin_hold_attack")
	if _is_stack_profile_equipped():
		var stack_controller: Node = _get_character_controller()
		if stack_controller != null and stack_controller.has_method("can_stack_hold_charge"):
			if not bool(stack_controller.call("can_stack_hold_charge")):
				return
		if stack_controller != null and stack_controller.has_method("stack_begin_hold_charge"):
			stack_controller.call("stack_begin_hold_charge")
	is_right_charge_held = true
	is_charge_pending = true
	pending_charge_elapsed = 0.0
	charge_icon_hold_elapsed = 0.0
	charge_icon_full_elapsed = 0.0
	charge_icon_visible_phase = true
	charge_icon_cracking = false
	if charge_ui != null:
		charge_ui.show_charge(0.0)

func _release_charge_shot() -> void:
	if equipped_weapon == null:
		_stop_charge_state()
		return
	var aim_direction: Vector2 = _get_aim_direction()
	var release_ratio: float = 0.0
	if is_charge_pending:
		is_charge_pending = false
		pending_charge_elapsed = 0.0
		if _is_hero_profile_equipped():
			_play_shoot_animation(aim_direction)
			_hero_release_hold_attack(release_ratio)
			_stop_charge_state()
			return
		if _is_stack_profile_equipped():
			_play_shoot_animation(aim_direction)
			var stack_controller: Node = _get_character_controller()
			if stack_controller != null and stack_controller.has_method("stack_end_hold_attack"):
				stack_controller.call("stack_end_hold_attack", release_ratio)
			_stop_charge_state()
			return
		_fire_normal_shot()
		_stop_charge_state()
		return
	if equipped_weapon.is_charging:
		release_ratio = equipped_weapon.get_charge_ratio()
	_play_shoot_animation(aim_direction)
	if _is_stack_profile_equipped():
		var stack_controller: Node = _get_character_controller()
		if stack_controller != null and stack_controller.has_method("stack_end_hold_attack"):
			stack_controller.call("stack_end_hold_attack", release_ratio)
		equipped_weapon.cancel_charge()
		_stop_charge_state()
		return
	if _is_hero_profile_equipped() and release_ratio < 0.999:
		var character_controller: Node = _get_character_controller()
		if character_controller != null and character_controller.has_method("hero_end_hold_attack"):
			character_controller.call("hero_end_hold_attack", release_ratio)
		_stop_charge_state()
		return
	equipped_weapon.release_charge(aim_direction)
	if not _is_hero_profile_equipped():
		if net_node != null and net_node.has_method("send_charged_attack_fx") and player != null:
			var fx_pos: Vector2 = player.global_position + aim_direction * 110.0
			net_node.call("send_charged_attack_fx", fx_pos)
		if world != null and world.has_method("_show_remote_charged_explosion_fx") and player != null:
			var local_fx_pos: Vector2 = player.global_position + aim_direction * 110.0
			world.call("_show_remote_charged_explosion_fx", local_fx_pos)
	_stop_charge_state()

func _stop_charge_state() -> void:
	is_right_charge_held = false
	is_charge_pending = false
	pending_charge_elapsed = 0.0
	charge_icon_hold_elapsed = 0.0
	charge_icon_full_elapsed = 0.0
	charge_icon_visible_phase = false
	charge_icon_cracking = false
	_set_charge_visual(false)
	if equipped_weapon != null:
		equipped_weapon.cancel_charge()
	if _is_hero_profile_equipped():
		var character_controller: Node = _get_character_controller()
		if character_controller != null and character_controller.has_method("hero_cancel_hold_attack"):
			var release_active: bool = bool(character_controller.get("hero_release_beam_active"))
			if not release_active:
				character_controller.call("hero_cancel_hold_attack")
	if _is_stack_profile_equipped():
		var stack_controller: Node = _get_character_controller()
		if stack_controller != null and stack_controller.has_method("stack_cancel_hold_attack"):
			stack_controller.call("stack_cancel_hold_attack")
	if charge_ui != null:
		charge_ui.hide_charge()

func _toggle_inventory() -> void:
	if inventory_ui == null:
		return
	_set_weapon_ui_visible(true)
	inventory_ui.toggle()
	if inventory_ui.is_open:
		_stop_charge_state()

func _inventory_open() -> bool:
	return inventory_ui != null and inventory_ui.is_open

func _equip_by_index(index: int) -> void:
	if index < 0 or index >= all_weapons.size():
		return
	equip_weapon(all_weapons[index])

func _get_aim_direction() -> Vector2:
	if player == null:
		return Vector2.RIGHT
	var delta: Vector2 = player.get_global_mouse_position() - player.global_position
	if delta.length() <= 0.001:
		return Vector2.RIGHT
	return delta.normalized()

func _play_shoot_animation(direction: Vector2) -> void:
	if world == null or not world.has_method("play_weapon_shoot_animation"):
		return
	var direction_name: String = _direction_name_from_vector(direction)
	world.call("play_weapon_shoot_animation", direction_name)

func _set_charge_visual(active: bool) -> void:
	if world == null or not world.has_method("set_player_charge_visual"):
		return
	var direction_name: String = _direction_name_from_vector(_get_aim_direction())
	world.call("set_player_charge_visual", active, direction_name)

func _direction_name_from_vector(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x >= 0.0 else "left"
	return "down" if direction.y >= 0.0 else "up"

func _update_charge_ui_position() -> void:
	if player == null:
		return
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera == null and world != null:
		camera = world.get_node_or_null("Camera2D")
	if camera == null:
		camera = get_viewport().get_camera_2d()
	if camera == null:
		if charge_ui != null:
			charge_ui.set_screen_anchor(Vector2(70.0, 40.0))
		return
	var viewport_size: Vector2 = player.get_viewport_rect().size
	var screen_position: Vector2 = (player.global_position - camera.global_position) * camera.zoom + viewport_size * 0.5
	if charge_ui != null:
		charge_ui.set_screen_anchor(screen_position + charge_ui_offset)

func _connect_weapon_signals(weapon: Weapon) -> void:
	if weapon == null:
		return
	var callback: Callable = Callable(self, "_on_weapon_charge_changed")
	if not weapon.charge_changed.is_connected(callback):
		weapon.charge_changed.connect(callback)

func _disconnect_weapon_signals(weapon: Weapon) -> void:
	if weapon == null:
		return
	var callback: Callable = Callable(self, "_on_weapon_charge_changed")
	if weapon.charge_changed.is_connected(callback):
		weapon.charge_changed.disconnect(callback)

func _on_weapon_charge_changed(progress: float) -> void:
	if charge_ui != null:
		charge_ui.show_charge(progress)
	if world != null and world.has_method("set_player_charge_progress"):
		world.call("set_player_charge_progress", progress)

func _pressed_action_or_key(event: InputEvent, action_name: String, keycode: Key) -> bool:
	if event.is_action_pressed(action_name):
		return true
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		return key_event.pressed and not key_event.echo and key_event.keycode == keycode
	return false

func _log(message: String) -> void:
	if not debug_logs_enabled:
		return
	print("[WeaponManager] ", message)


func set_combat_input_enabled(enabled: bool) -> void:
	combat_input_enabled = enabled
	if not combat_input_enabled:
		_stop_charge_state()


func _get_character_controller() -> Node:
	if player == null:
		return null
	return player.get_node_or_null("CharacterController")


func _is_hero_profile_equipped() -> bool:
	if equipped_weapon == null or not equipped_weapon.has_method("get_character_profile_id"):
		return false
	return str(equipped_weapon.call("get_character_profile_id")) == "hero"


func _is_stack_profile_equipped() -> bool:
	if equipped_weapon == null or not equipped_weapon.has_method("get_character_profile_id"):
		return false
	var profile_id: String = str(equipped_weapon.call("get_character_profile_id"))
	return profile_id == "stack" or profile_id == "twins"


func _hero_release_hold_attack(charge_ratio: float) -> void:
	var character_controller: Node = _get_character_controller()
	if character_controller == null or not character_controller.has_method("hero_end_hold_attack"):
		return
	character_controller.call("hero_end_hold_attack", charge_ratio)


func _weapon_network_key(weapon: Weapon) -> String:
	if weapon == null:
		return ""
	var weapon_script: Script = weapon.get_script()
	if weapon_script == FLOWER_GUN_SCRIPT:
		return "flower"
	if weapon_script == MICHAEL_GUN_SCRIPT:
		return "michael"
	return ""


func _sync_inventory_visibility() -> void:
	if inventory_ui != null:
		inventory_ui.visible = ui_revealed and hotbar_revealed


func reveal_hotbar() -> void:
	if hotbar_revealed:
		return
	hotbar_revealed = true
	_sync_inventory_visibility()


func reset_hotbar_for_level() -> void:
	hotbar_revealed = false
	_sync_inventory_visibility()


func _set_weapon_ui_visible(visible: bool) -> void:
	ui_revealed = visible
	_sync_inventory_visibility()
	if weapon_hud != null and enable_weapon_hud:
		weapon_hud.visible = visible


func on_level_started() -> void:
	ui_revealed = true
	reset_hotbar_for_level()


func _inventory_digit_index_from_key(keycode: Key) -> int:
	match keycode:
		KEY_1, KEY_KP_1:
			return 0
		KEY_2, KEY_KP_2:
			return 1
		KEY_3, KEY_KP_3:
			return 2
		KEY_4, KEY_KP_4:
			return 3
		KEY_5, KEY_KP_5:
			return 4
		KEY_6, KEY_KP_6:
			return 5
		KEY_7, KEY_KP_7:
			return 6
		KEY_8, KEY_KP_8:
			return 7
		KEY_9, KEY_KP_9:
			return 8
		_:
			return -1


func cancel_active_charge() -> void:
	_stop_charge_state()
