class_name CharacterProfileWeapon
extends Weapon

@export var character_profile_id: String = "hero"
@export var character_display_name: String = "Hero"

func _init() -> void:
	weapon_type = WeaponType.GENERIC
	can_charge = true
	fire_rate = 0.1
	charge_time = 3.0
	projectile_speed = 0.0
	projectile_spawn_distance = 0.0
	damage = 0.0

func _ready() -> void:
	super._ready()
	weapon_name = character_display_name
	weapon_description = "Character profile: %s" % character_display_name

func get_character_profile_id() -> String:
	return character_profile_id

func is_character_profile_weapon() -> bool:
	return true

func shoot(_direction: Vector2) -> void:
	if not can_fire():
		return
	var owner_player: Node = owner_node
	if owner_player == null:
		return
	var character_controller: Node = owner_player.get_node_or_null("CharacterController")
	if character_controller == null or not character_controller.has_method("profile_weapon_shoot"):
		return
	var fire_cooldown: float = fire_rate
	if character_controller.has_method("get_profile_fire_rate"):
		fire_cooldown = float(character_controller.call("get_profile_fire_rate", character_profile_id, false))
	cooldown_remaining = maxf(0.01, fire_cooldown)
	character_controller.call("profile_weapon_shoot", _direction.normalized())

func release_charge(_direction: Vector2) -> void:
	if not is_equipped:
		cancel_charge()
		return
	var ratio: float = get_charge_ratio()
	cancel_charge()
	if ratio < 0.15:
		if character_profile_id == "hero":
			var owner_player: Node = owner_node
			if owner_player != null:
				var character_controller: Node = owner_player.get_node_or_null("CharacterController")
				if character_controller != null and character_controller.has_method("hero_end_hold_attack"):
					character_controller.call("hero_end_hold_attack", ratio)
		else:
			shoot(_direction)
		return
	if not can_fire():
		return
	var owner_player: Node = owner_node
	if owner_player == null:
		return
	var character_controller: Node = owner_player.get_node_or_null("CharacterController")
	if character_controller == null or not character_controller.has_method("profile_weapon_release_charge"):
		return
	var fire_cooldown: float = fire_rate
	if character_controller.has_method("get_profile_fire_rate"):
		fire_cooldown = float(character_controller.call("get_profile_fire_rate", character_profile_id, true))
	cooldown_remaining = maxf(0.01, fire_cooldown)
	character_controller.call("profile_weapon_release_charge", _direction.normalized(), ratio)
