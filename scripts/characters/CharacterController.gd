class_name CharacterController
extends Node

const WEAPON_SCRIPT: Script = preload("res://scripts/weapons/Weapon.gd")
const MIRROR_HELPER_SCRIPT: Script = preload("res://scripts/characters/MirrorAnimationHelper.gd")
const SWORD_WEAPON_SCRIPT: Script = preload("res://scripts/characters/SwordWeapon.gd")
const HERO_PROFILE_SCRIPT: Script = preload("res://scripts/weapons/base/HeroProfile.gd")
const TWINS_PROFILE_SCRIPT: Script = preload("res://scripts/weapons/base/TwinsProfile.gd")
const PRINCE_PROFILE_SCRIPT: Script = preload("res://scripts/weapons/base/PrinceProfile.gd")

enum TwinsDisplayMode {
	STACK_SOLO,
	SMOKE_SOLO,
	DUO,
}

@export_enum("classic", "hero", "prince", "stack") var current_character_id: String = "classic"

@export_group("Hero Animations")
@export var hero_walk_frames: SpriteFrames = null
@export var hero_shoot_frames: SpriteFrames = null
@export var hero_charge_icon_texture: Texture2D = null

@export_group("Twins Animations")
@export var smoke_walk_frames: SpriteFrames = null
@export var smoke_shoot_frames: SpriteFrames = null
@export var stack_walk_frames: SpriteFrames = null
@export var stack_shoot_frames: SpriteFrames = null
@export var twins_spacing: Vector2 = Vector2(18.0, 0.0)
@export var twins_back_to_back_spacing: float = 8.0
@export var twins_follow_spacing: float = 12.0
@export var twins_side_by_side_spacing: float = 30.0
@export var twins_charge_icon_texture: Texture2D = null

@export_group("Prince Animations")
@export var prince_walk_frames: SpriteFrames = null
@export var prince_slash_frames: SpriteFrames = null
@export var prince_summon_frames: SpriteFrames = null
@export var caraxes_summoning_frames: SpriteFrames = null
@export var caraxes_icon_texture: Texture2D = null

@export_group("Hero Balance")
@export var hero_laser_damage: float = 1.0
@export var hero_laser_cooldown: float = 0.05
@export var hero_charged_laser_damage: float = 3.0
@export var hero_charged_laser_cooldown: float = 3.0
@export var hero_normal_laser_width: float = 5.0
@export var hero_charged_laser_width: float = 26.0
@export var hero_laser_range: float = 290.0
@export var hero_charge_hold_multiplier: float = 0.5
@export var hero_damage_tick_interval: float = 0.07
@export var hero_release_beam_duration: float = 2.0
@export var hero_small_range_multiplier: float = 2.0
@export var hero_big_range_multiplier: float = 2.0
@export var hero_beam_min_width_ratio: float = 0.05
@export var hero_release_beam_start_width_multiplier: float = 5.0
@export_range(0.3, 24.0, 0.1) var hero_normal_aim_responsiveness: float = 1.4
@export_range(0.1, 80.0, 0.05) var hero_charged_aim_responsiveness: float = 0.5
@export_range(0.0, 0.35, 0.005) var hero_charged_aim_jitter: float = 0.15
@export_range(0.0, 1.0, 0.01) var hero_charged_aim_overshoot: float = 0.28

@export_group("Twins Balance")
@export var smoke_pistol_damage: float = 1.0
@export var smoke_pistol_interval: float = 0.35
@export var smoke_pistol_range: float = 390.0
@export var smoke_pistol_charged_range: float = 495.0
@export var stack_shotgun_damage: float = 3.0
@export var stack_shotgun_windup: float = 0.45
@export var stack_shotgun_interval: float = 1.1
@export var stack_shotgun_spread_angle: float = 45.0
@export var stack_shotgun_range: float = 420.0
@export var twins_charged_duration: float = 3.0
@export var twins_charged_cooldown: float = 6.0
@export var twins_charged_smoke_interval: float = 0.15
@export var twins_charged_stack_interval: float = 0.55

@export_group("Prince Balance")
@export var prince_slash_damage: float = 65.0
@export var prince_slash_range: float = 115.0
@export var prince_slash_arc: float = 165.0
@export var prince_slash_cooldown: float = 0.52
@export var prince_slash_knockback: float = 10.0
@export var prince_max_stamina: float = 100.0
@export var prince_slash_stamina_cost: float = 18.0
@export var prince_stamina_regen_rate: float = 22.0
@export var prince_stamina_regen_delay_after_slash: float = 0.4

@export_group("Caraxes")
@export var caraxes_cooldown: float = 45.0
@export var caraxes_max_targets: int = 5
@export var caraxes_grab_frame: int = 5
@export var caraxes_grab_speed_multiplier: float = 3.0
@export var caraxes_mob_pull_strength: float = 0.98
@export var caraxes_hold_duration: float = 1.1
@export var caraxes_hold_damage: float = 4.0
@export var caraxes_release_throw_distance: float = 120.0

@export_group("Charge Icon Indicator")
@export var charge_icon_hud_position: Vector2 = Vector2(-38.0, -148.0)
@export var charge_icon_size: Vector2 = Vector2(76.0, 76.0)
@export var full_charge_hold_limit: float = 3.0
@export var full_charge_pulse_scale: float = 1.12
@export var full_charge_pulse_speed: float = 5.0
@export var full_charge_shake_amount: float = 3.0
@export var full_charge_glow_strength: float = 1.5
@export var time_before_icon_appears: float = 5.0
@export var time_to_full_charge: float = 3.0
@export var full_charge_hold_before_crack: float = 3.0
@export var crack_duration: float = 0.3
@export var max_charge_damage_multiplier: float = 2.5
@export var icon_height_offset: float = -148.0
@export var shake_intensity: float = 5.5
@export var glow_intensity: float = 1.5
@export var hero_charge_fill_color: Color = Color(1.0, 0.25, 0.22, 1.0)
@export var hero_charge_glow_color: Color = Color(1.0, 0.12, 0.12, 1.0)
@export var twins_charge_fill_color: Color = Color(0.96, 0.80, 0.34, 1.0)
@export var twins_charge_glow_color: Color = Color(1.0, 0.66, 0.26, 1.0)
@export var twins_hints_screen_offset: Vector2 = Vector2(-18.0, -72.0)
@export var prince_charge_fill_color: Color = Color(0.84, 0.2, 0.2, 1.0)
@export var prince_charge_glow_color: Color = Color(1.0, 0.18, 0.18, 1.0)

@export_group("Hero Eye Beam Alignment")
@export var hero_dual_eye_separation: float = 12.0
@export var hero_beam_face_offset: Vector2 = Vector2(0.0, -16.0)
@export var hero_beam_z_index_front: int = 100
@export var hero_beam_z_index_shoot_up: int = -10
@export var hero_eye_offset_left: Vector2 = Vector2(-18.0, -18.0)
@export var hero_eye_offset_up: Vector2 = Vector2(0.0, -26.0)
@export var hero_eye_offset_down: Vector2 = Vector2(0.0, -10.0)
@export var laser_beam_offset_x: float = 0.0
@export var laser_beam_offset_y: float = 0.0
@export var laser_start_offset_x: float = 0.0
@export var laser_start_offset_y: float = 0.0
@export var laser_spawn_delay: float = 0.0

var player: Node2D = null
var world: Node = null
var player_sprite: AnimatedSprite2D = null
var weapon_manager: Node = null

var smoke_sprite: AnimatedSprite2D = null
var stack_sprite: AnimatedSprite2D = null

var attack_cooldown_remaining: float = 0.0
var attack_holding: bool = false
var attack_hold_elapsed: float = 0.0
var base_charge_hold_time: float = 1.0

var twins_charged_remaining: float = 0.0
var twins_charged_cooldown_remaining: float = 0.0
var smoke_attack_timer: float = 0.0
var stack_attack_timer: float = 0.0
var stack_windup_timer: float = 0.0
var stack_pending_shot: bool = false
var player_last_position: Vector2 = Vector2.ZERO
var player_motion_dir: Vector2 = Vector2.DOWN
var hero_tick_timer: float = 0.0
var hero_beam_root: Node2D = null
var hero_beam_line_sets: Array = []
var hero_continuous_beam_active: bool = false
var hero_release_beam_active: bool = false
var hero_release_beam_elapsed: float = 0.0
var hero_release_beam_direction: Vector2 = Vector2.RIGHT
var hero_release_beam_charged: bool = false
var hero_release_beam_damage: float = 0.0
var hero_release_beam_start_width: float = 0.0
var hero_aim_smoothed_direction: Vector2 = Vector2.RIGHT
var hero_aim_velocity: Vector2 = Vector2.ZERO
var hero_aim_wobble_time: float = 0.0
var charge_ui: Weapon.ChargeUI = null
var charge_mode: String = ""
var charge_icon_texture: Texture2D = null
var charge_elapsed: float = 0.0
var charge_max_time: float = 1.0
var charge_full_elapsed: float = 0.0
var charge_full_hold_limit_current: float = 3.0
var charge_auto_release_enabled: bool = true
var charge_fill_color: Color = Color.WHITE
var charge_glow_color: Color = Color(1.0, 0.2, 0.2, 1.0)
var charge_icon_visible_phase: bool = false
var charge_cracking: bool = false

var hero_profile: RefCounted = null
var twins_profile: RefCounted = null
var prince_profile: RefCounted = null
var twins_front_is_smoke: bool = false
var twins_display_mode: TwinsDisplayMode = TwinsDisplayMode.STACK_SOLO
var twins_duo_tile_offset: Vector2i = Vector2i(1, 0)
var stack_hold_charge_active: bool = false

var prince_stamina: float = 100.0
var prince_regen_delay_remaining: float = 0.0
var caraxes_cooldown_remaining: float = 0.0
var summon_in_progress: bool = false
var prince_sword: RefCounted = null

var prince_stamina_bar_root: Control = null
var prince_stamina_bar: ProgressBar = null
var caraxes_icon_root: Control = null
var caraxes_icon: TextureRect = null
var caraxes_cooldown_label: Label = null
var caraxes_cooldown_overlay: ColorRect = null

var twins_hints_root: Control = null
var twins_hint_t_icon: TextureRect = null
var twins_hint_m_icon: TextureRect = null
var twins_hint_t_label: Label = null
var twins_hint_m_label: Label = null
var twins_hint_t_row: Control = null
var twins_hint_m_row: Control = null
var twins_hint_charge_row: Control = null
var twins_hint_charge_icon: TextureRect = null
var twins_hint_charge_label: Label = null
var twins_key_t_texture: Texture2D = null
var twins_key_m_texture: Texture2D = null
var twins_hint_key_rest_scale: Vector2 = Vector2(0.52, 0.52)
var twins_hit_flash_tween: Tween = null

func _ready() -> void:
	_build_character_profiles()
	_autoload_default_resources()
	player = get_parent() as Node2D
	world = get_tree().current_scene
	_sync_twins_frames_from_world()
	if player != null:
		player_sprite = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		weapon_manager = player.get_node_or_null("WeaponManager")
		player_last_position = player.global_position
	set_process(true)
	set_process_unhandled_input(true)
	_ensure_twins_nodes()
	_ensure_charge_ui()
	_ensure_prince_ui()
	_ensure_twins_mode_hints()
	_apply_character_profile()
	print("[CharacterController] Loaded character profile: ", current_character_id)


func _autoload_default_resources() -> void:
	hero_walk_frames = _load_frames_if_missing(hero_walk_frames, "res://assets/player/homelander_walking.tres")
	hero_shoot_frames = _load_frames_if_missing(hero_shoot_frames, "res://assets/player/homelander_shoot.tres")
	smoke_walk_frames = _load_frames_if_missing(smoke_walk_frames, "res://assets/player/smoke_walking.tres")
	smoke_shoot_frames = _load_frames_if_missing(smoke_shoot_frames, "res://assets/player/smoke_shoot.tres")
	stack_walk_frames = _load_frames_if_missing(stack_walk_frames, "res://assets/player/stack_walking.tres")
	stack_shoot_frames = _load_frames_if_missing(stack_shoot_frames, "res://assets/player/stack_shoot.tres")
	if (smoke_walk_frames == null or smoke_walk_frames == stack_walk_frames) and ResourceLoader.exists("res://assets/player/smoke_walking.tres"):
		var smoke_walk_loaded: Resource = load("res://assets/player/smoke_walking.tres")
		if smoke_walk_loaded is SpriteFrames:
			smoke_walk_frames = smoke_walk_loaded as SpriteFrames
	if (smoke_shoot_frames == null or smoke_shoot_frames == stack_shoot_frames) and ResourceLoader.exists("res://assets/player/smoke_shoot.tres"):
		var smoke_shoot_loaded: Resource = load("res://assets/player/smoke_shoot.tres")
		if smoke_shoot_loaded is SpriteFrames:
			smoke_shoot_frames = smoke_shoot_loaded as SpriteFrames
	prince_walk_frames = _load_frames_if_missing(prince_walk_frames, "res://assets/player/daemon_walking.tres")
	prince_slash_frames = _load_frames_if_missing(prince_slash_frames, "res://assets/player/daemon_shoot.tres")
	prince_summon_frames = _load_frames_if_missing(prince_summon_frames, "res://assets/player/summoning.tres")
	caraxes_summoning_frames = _load_frames_if_missing(caraxes_summoning_frames, "res://assets/player/carafes_summoning.tres")
	if hero_charge_icon_texture == null:
		for hero_icon_path in ["res://assets/weapons/homelander.png", "res://weapons/homelander.png"]:
			if not ResourceLoader.exists(hero_icon_path):
				continue
			var hero_icon_res: Resource = load(hero_icon_path)
			if hero_icon_res is Texture2D:
				hero_charge_icon_texture = hero_icon_res as Texture2D
				break
	if twins_charge_icon_texture == null and ResourceLoader.exists("res://assets/weapons/stack-&-smoke.png"):
		var twins_icon_res: Resource = load("res://assets/weapons/stack-&-smoke.png")
		if twins_icon_res is Texture2D:
			twins_charge_icon_texture = twins_icon_res as Texture2D
	twins_key_t_texture = _load_key_from_sheet(3, 4)
	twins_key_m_texture = _load_key_from_sheet(4, 3)
	if caraxes_icon_texture == null:
		for caraxes_icon_path in ["res://assets/weapons/caraxes.png", "res://assets/player/caraxes.png"]:
			if not ResourceLoader.exists(caraxes_icon_path):
				continue
			var loaded_icon: Resource = load(caraxes_icon_path)
			if loaded_icon is Texture2D:
				caraxes_icon_texture = loaded_icon as Texture2D
				break


func _load_frames_if_missing(existing: SpriteFrames, path: String) -> SpriteFrames:
	if existing != null:
		return existing
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = load(path)
	if loaded is SpriteFrames:
		return loaded as SpriteFrames
	return null


func _sync_twins_frames_from_world() -> void:
	if world == null:
		return
	var world_smoke_walk: Variant = world.get("smoke_walk_frames")
	if world_smoke_walk is SpriteFrames:
		smoke_walk_frames = world_smoke_walk as SpriteFrames
	var world_smoke_shoot: Variant = world.get("smoke_shoot_frames")
	if world_smoke_shoot is SpriteFrames:
		smoke_shoot_frames = world_smoke_shoot as SpriteFrames
	var world_stack_walk: Variant = world.get("stack_walk_frames")
	if world_stack_walk is SpriteFrames:
		stack_walk_frames = world_stack_walk as SpriteFrames
	var world_stack_shoot: Variant = world.get("stack_shoot_frames")
	if world_stack_shoot is SpriteFrames:
		stack_shoot_frames = world_stack_shoot as SpriteFrames
	_force_twins_resource_split()


func _force_twins_resource_split() -> void:
	if smoke_walk_frames == stack_walk_frames and ResourceLoader.exists("res://assets/player/smoke_walking.tres"):
		var smoke_walk_loaded: Resource = load("res://assets/player/smoke_walking.tres")
		if smoke_walk_loaded is SpriteFrames:
			smoke_walk_frames = smoke_walk_loaded as SpriteFrames
	if smoke_shoot_frames == stack_shoot_frames and ResourceLoader.exists("res://assets/player/smoke_shoot.tres"):
		var smoke_shoot_loaded: Resource = load("res://assets/player/smoke_shoot.tres")
		if smoke_shoot_loaded is SpriteFrames:
			smoke_shoot_frames = smoke_shoot_loaded as SpriteFrames


func _build_character_profiles() -> void:
	hero_profile = HERO_PROFILE_SCRIPT.new() if HERO_PROFILE_SCRIPT != null else null
	twins_profile = TWINS_PROFILE_SCRIPT.new() if TWINS_PROFILE_SCRIPT != null else null
	prince_profile = PRINCE_PROFILE_SCRIPT.new() if PRINCE_PROFILE_SCRIPT != null else null
	if hero_profile != null:
		hero_laser_damage = float(hero_profile.get("normal_damage"))
		hero_charged_laser_damage = float(hero_profile.get("charged_damage"))
		hero_laser_cooldown = float(hero_profile.get("normal_cooldown"))
		hero_charged_laser_cooldown = float(hero_profile.get("charged_cooldown"))
		hero_normal_laser_width = float(hero_profile.get("normal_width"))
		hero_charged_laser_width = float(hero_profile.get("charged_width"))
		hero_laser_range = float(hero_profile.get("range_value"))
		hero_charge_hold_multiplier = float(hero_profile.get("charge_hold_time_multiplier"))
	if twins_profile != null:
		smoke_pistol_damage = float(twins_profile.get("smoke_damage"))
		smoke_pistol_interval = float(twins_profile.get("smoke_interval"))
		smoke_pistol_range = float(twins_profile.get("smoke_range"))
		smoke_pistol_charged_range = float(twins_profile.get("smoke_charged_range"))
		stack_shotgun_damage = float(twins_profile.get("stack_damage"))
		stack_shotgun_windup = float(twins_profile.get("stack_windup"))
		stack_shotgun_interval = float(twins_profile.get("stack_interval"))
		stack_shotgun_spread_angle = float(twins_profile.get("stack_spread_angle"))
		stack_shotgun_range = float(twins_profile.get("stack_range"))
		twins_charged_duration = float(twins_profile.get("charged_duration"))
		twins_charged_cooldown = float(twins_profile.get("charged_cooldown"))
		twins_charged_smoke_interval = float(twins_profile.get("charged_smoke_interval"))
		twins_charged_stack_interval = float(twins_profile.get("charged_stack_interval"))
	if prince_profile != null:
		prince_slash_damage = float(prince_profile.get("slash_damage"))
		prince_slash_range = float(prince_profile.get("slash_range"))
		prince_slash_arc = float(prince_profile.get("slash_arc"))
		prince_slash_cooldown = float(prince_profile.get("slash_cooldown"))
		caraxes_cooldown = float(prince_profile.get("summon_cooldown"))
		caraxes_max_targets = int(prince_profile.get("summon_max_targets"))
		caraxes_grab_frame = int(prince_profile.get("summon_grab_frame"))


func _ensure_charge_ui() -> void:
	if world == null:
		return
	var hud_layer: CanvasLayer = world.get_node_or_null("HUDLayer")
	if hud_layer == null:
		hud_layer = world.get_node_or_null("HudLayer")
	if hud_layer == null:
		return
	charge_ui = hud_layer.get_node_or_null("CharacterChargeUI") as Weapon.ChargeUI
	if charge_ui == null:
		charge_ui = WEAPON_SCRIPT.ChargeUI.new()
		charge_ui.name = "CharacterChargeUI"
		charge_ui.fill_color = Color(0.96, 0.96, 0.98, 0.98)
		charge_ui.base_color = Color(0.02, 0.02, 0.02, 0.94)
		charge_ui.use_quarter_steps = true
		charge_ui.shake_amount = 4.5
		hud_layer.add_child(charge_ui)
	if charge_ui != null:
		charge_ui.hide_charge()


func _process(delta: float) -> void:
	attack_cooldown_remaining = maxf(0.0, attack_cooldown_remaining - delta)
	twins_charged_cooldown_remaining = maxf(0.0, twins_charged_cooldown_remaining - delta)
	caraxes_cooldown_remaining = maxf(0.0, caraxes_cooldown_remaining - delta)
	if attack_holding:
		attack_hold_elapsed += delta
	charge_elapsed = attack_hold_elapsed
	_update_motion_direction()
	_update_charge_indicator(delta)
	hero_aim_wobble_time += delta
	_update_hero_aim_direction(delta)
	if current_character_id == "hero":
		if hero_continuous_beam_active:
			_update_hero_continuous_beam(delta)
		_update_hero_release_beam(delta)

	if _is_stack_character():
		if twins_display_mode == TwinsDisplayMode.DUO:
			_update_twins_duo_tile_positions()
		else:
			_reset_twin_sprite_layout()
		if stack_hold_charge_active:
			_update_twins_charge_pose(_get_aim_direction())
		else:
			_update_twins_visuals(delta)
		_update_twins_charged_fire(delta)
	else:
		_reset_twin_sprite_layout()
		_hide_twins_nodes()

	if current_character_id == "prince":
		_update_prince_stamina(delta)
	_update_prince_ui()
	_update_twins_mode_hints()


func _unhandled_input(event: InputEvent) -> void:
	if current_character_id == "classic" or current_character_id == "hero" or _is_stack_character():
		return
	if summon_in_progress:
		return

	if _is_attack_press(event):
		attack_holding = true
		attack_hold_elapsed = 0.0
		if current_character_id == "hero" or _is_stack_character():
			if not _begin_charge_mode_for_character("stack" if _is_stack_character() else current_character_id):
				attack_holding = false
		get_viewport().set_input_as_handled()
		return

	if _is_attack_release(event):
		var held_for: float = attack_hold_elapsed
		attack_holding = false
		attack_hold_elapsed = 0.0
		_end_charge_mode(true)
		if current_character_id == "hero":
			var release_ratio: float = clampf(held_for / maxf(0.001, charge_max_time), 0.0, 1.0)
			hero_end_hold_attack(release_ratio)
			get_viewport().set_input_as_handled()
			return
		_perform_character_attack(held_for)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("summon_dragon"):
		if current_character_id == "prince":
			attack_holding = true
			attack_hold_elapsed = 0.0
			if not _begin_charge_mode_for_character("prince_summon"):
				attack_holding = false
			get_viewport().set_input_as_handled()
		return
	if event.is_action_released("summon_dragon"):
		if current_character_id == "prince":
			attack_holding = false
			attack_hold_elapsed = 0.0
			if charge_mode == "prince_summon":
				_trigger_caraxes_summon()
			_end_charge_mode(false)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_T:
			if current_character_id == "prince":
				attack_holding = true
				attack_hold_elapsed = 0.0
				if not _begin_charge_mode_for_character("prince_summon"):
					attack_holding = false
				get_viewport().set_input_as_handled()
		elif not key_event.pressed and key_event.keycode == KEY_T and current_character_id == "prince":
			attack_holding = false
			attack_hold_elapsed = 0.0
			if charge_mode == "prince_summon":
				_trigger_caraxes_summon()
			_end_charge_mode(false)


func handle_world_key_input(event: InputEventKey) -> bool:
	if event == null:
		return false
	if not event.pressed or event.echo:
		return false
	if current_character_id == "prince" and event.keycode == KEY_T:
		return true
	if not _is_stack_character():
		return false
	if event.keycode == KEY_T:
		_toggle_stack_smoke_solo()
		return true
	if event.keycode == KEY_M:
		_toggle_stack_duo_mode()
		return true
	return false


func _is_stack_character() -> bool:
	return current_character_id == "stack" or current_character_id == "twins"


func set_character(character_id: String) -> void:
	if character_id == "twins":
		character_id = "stack"
	if current_character_id == character_id:
		return
	current_character_id = character_id
	_apply_character_profile()


func 	_apply_character_profile() -> void:
	attack_cooldown_remaining = 0.0
	attack_holding = false
	attack_hold_elapsed = 0.0
	_end_charge_mode(false)
	hero_tick_timer = 0.0
	hero_continuous_beam_active = false
	hero_release_beam_start_width = 0.0
	hero_aim_smoothed_direction = Vector2.RIGHT
	hero_aim_velocity = Vector2.ZERO
	_clear_hero_beam()
	smoke_attack_timer = 0.0
	stack_attack_timer = 0.0
	stack_windup_timer = 0.0
	stack_pending_shot = false
	twins_charged_remaining = 0.0
	twins_display_mode = TwinsDisplayMode.STACK_SOLO
	twins_front_is_smoke = false
	twins_duo_tile_offset = Vector2i(1, 0)
	stack_hold_charge_active = false
	_reset_twin_sprite_layout()
	_sync_twins_frames_from_world()
	var use_weapon_manager_input: bool = current_character_id != "prince"
	if weapon_manager != null and weapon_manager.has_method("set_combat_input_enabled"):
		weapon_manager.call("set_combat_input_enabled", use_weapon_manager_input)

	match current_character_id:
		"hero":
			_set_world_animation_overrides(hero_walk_frames, hero_shoot_frames, Vector2.ONE, Vector2.ONE)
			_show_main_player_sprite(true)
		"stack":
			twins_display_mode = TwinsDisplayMode.STACK_SOLO
			twins_front_is_smoke = false
			_set_world_animation_overrides(null, null, Vector2.ONE, Vector2.ONE)
			_show_main_player_sprite(false)
			_show_twins_nodes()
		"prince":
			_set_world_animation_overrides(prince_walk_frames, prince_slash_frames, Vector2.ONE, Vector2.ONE)
			_show_main_player_sprite(true)
			_setup_prince_sword()
			prince_stamina = prince_max_stamina
			prince_regen_delay_remaining = 0.0
		_:
			_set_world_animation_overrides(null, null, Vector2.ONE, Vector2.ONE)
			_show_main_player_sprite(true)
			if charge_ui != null:
				charge_ui.hide_charge()

	_update_prince_ui()


func get_profile_fire_rate(profile_id: String, charged: bool) -> float:
	match profile_id:
		"hero":
			return hero_charged_laser_cooldown if charged else hero_laser_cooldown
		"stack", "twins":
			return twins_charged_cooldown if charged else maxf(smoke_pistol_interval, 0.2)
		"prince":
			return prince_slash_cooldown
		_:
			return 0.15


func get_profile_charge_time(profile_id: String) -> float:
	match profile_id:
		"hero":
			return float(hero_profile.get("charge_max_time")) if hero_profile != null else time_to_full_charge
		"stack", "twins":
			return float(twins_profile.get("charge_max_time")) if twins_profile != null else 0.8
		"prince":
			return float(prince_profile.get("charge_max_time")) if prince_profile != null else 1.0
		_:
			return 0.8


func profile_weapon_shoot(_direction: Vector2) -> void:
	match current_character_id:
		"hero":
			hero_begin_hold_attack()
		"stack", "twins":
			_fire_twins_normal(_direction)
		"prince":
			_fire_prince_slash(_direction)
		_:
			return


func profile_weapon_release_charge(_direction: Vector2, charge_ratio: float) -> void:
	var ratio: float = clampf(charge_ratio, 0.0, 1.0)
	match current_character_id:
		"hero":
			hero_end_hold_attack(ratio)
		"stack", "twins":
			stack_end_hold_attack(ratio)
		"prince":
			_fire_prince_slash(_direction)
		_:
			return


func _begin_charge_mode_for_character(mode: String) -> bool:
	charge_mode = mode
	charge_elapsed = 0.0
	charge_full_elapsed = 0.0
	charge_icon_visible_phase = true
	charge_cracking = false
	charge_full_hold_limit_current = full_charge_hold_limit
	charge_auto_release_enabled = true
	match mode:
		"hero":
			charge_max_time = time_to_full_charge
			if hero_profile != null:
				charge_max_time = float(hero_profile.get("charge_max_time"))
				charge_full_hold_limit_current = float(hero_profile.get("full_charge_hold_limit"))
				charge_auto_release_enabled = bool(hero_profile.get("auto_release_enabled"))
			charge_icon_texture = hero_charge_icon_texture
			charge_fill_color = hero_charge_fill_color
			charge_glow_color = hero_charge_glow_color
		"stack", "twins":
			charge_max_time = time_to_full_charge
			if twins_profile != null:
				charge_max_time = float(twins_profile.get("charge_max_time"))
				charge_full_hold_limit_current = float(twins_profile.get("full_charge_hold_limit"))
				charge_auto_release_enabled = bool(twins_profile.get("auto_release_enabled"))
			charge_icon_texture = twins_charge_icon_texture
			charge_fill_color = twins_charge_fill_color
			charge_glow_color = twins_charge_glow_color
		"prince_summon":
			if caraxes_cooldown_remaining > 0.0:
				charge_mode = ""
				return false
			charge_max_time = time_to_full_charge
			if prince_profile != null:
				charge_max_time = float(prince_profile.get("charge_max_time"))
				charge_full_hold_limit_current = float(prince_profile.get("full_charge_hold_limit"))
				charge_auto_release_enabled = bool(prince_profile.get("auto_release_enabled"))
			charge_icon_texture = caraxes_icon_texture
			charge_fill_color = prince_charge_fill_color
			charge_glow_color = prince_charge_glow_color
		_:
			charge_mode = ""
			return false
	if charge_ui != null:
		charge_ui.show_charge(0.0)
	return true


func _update_charge_indicator(_delta: float) -> void:
	if charge_ui != null:
		var screen_pos: Vector2 = _get_player_screen_position() + Vector2(charge_icon_hud_position.x, icon_height_offset)
		charge_ui.set_screen_anchor(screen_pos)

	if charge_mode == "" or not attack_holding:
		if charge_ui != null:
			charge_ui.hide_charge()
		return

	var percent: float = clampf(attack_hold_elapsed / maxf(0.001, charge_max_time), 0.0, 1.0)
	if charge_ui != null:
		charge_ui.show_charge(percent)


func _auto_release_charge() -> void:
	attack_holding = false
	var held_for: float = attack_hold_elapsed
	attack_hold_elapsed = 0.0
	match charge_mode:
		"hero":
			var release_ratio: float = clampf(held_for / maxf(0.001, charge_max_time), 0.0, 1.0)
			hero_end_hold_attack(release_ratio)
		"stack", "twins":
			_perform_character_attack(held_for)
		"prince_summon":
			_trigger_caraxes_summon()
	_end_charge_mode(true)


func _end_charge_mode(_released: bool) -> void:
	charge_mode = ""
	charge_elapsed = 0.0
	charge_full_elapsed = 0.0
	charge_icon_visible_phase = false
	charge_cracking = false
	if charge_ui != null:
		charge_ui.hide_charge()


func _get_ready_charge_icon_for_current_character() -> Texture2D:
	match current_character_id:
		"hero":
			return hero_charge_icon_texture
		"stack", "twins":
			return twins_charge_icon_texture
		"prince":
			return caraxes_icon_texture
		_:
			return null


func _get_player_screen_position() -> Vector2:
	if player == null:
		return Vector2(64.0, 64.0)
	var xform: Transform2D = player.get_global_transform_with_canvas()
	return xform.origin


func _perform_character_attack(held_for: float) -> void:
	if current_character_id == "classic":
		return
	if attack_cooldown_remaining > 0.0:
		return
	var aim_dir: Vector2 = _get_aim_direction()
	match current_character_id:
		"hero":
			var charged: bool = held_for >= maxf(0.15, charge_max_time)
			_fire_hero_laser(aim_dir, charged)
		"stack", "twins":
			if twins_display_mode != TwinsDisplayMode.SMOKE_SOLO:
				var charged_twins: bool = held_for >= maxf(0.2, charge_max_time)
				if charged_twins and twins_charged_cooldown_remaining <= 0.0:
					twins_charged_remaining = twins_charged_duration
					twins_charged_cooldown_remaining = twins_charged_cooldown
					attack_cooldown_remaining = 0.2
				else:
					_fire_twins_normal(aim_dir)
			else:
				_fire_twins_normal(aim_dir)
		"prince":
			_fire_prince_slash(aim_dir)


func hero_begin_hold_attack() -> void:
	if current_character_id != "hero":
		return
	if attack_cooldown_remaining > 0.0 or hero_release_beam_active:
		return
	hero_continuous_beam_active = true
	hero_tick_timer = 0.0
	var direction: Vector2 = _get_aim_direction()
	var range_value: float = hero_laser_range * hero_small_range_multiplier
	_update_hero_beam_visual(direction, hero_normal_laser_width, false, range_value)
	if world != null and world.has_method("play_weapon_shoot_animation"):
		world.call("play_weapon_shoot_animation", _direction_name_from_vector(direction))


func hero_update_hold_attack(_delta: float) -> void:
	if current_character_id != "hero" or not hero_continuous_beam_active:
		return
	_update_hero_continuous_beam(_delta)


func hero_end_hold_attack(charge_ratio: float) -> void:
	if current_character_id != "hero":
		return
	hero_continuous_beam_active = false
	var ratio: float = clampf(charge_ratio, 0.0, 1.0)
	if ratio < 0.999:
		_clear_hero_beam()
		attack_cooldown_remaining = hero_laser_cooldown
		return
	hero_release_beam_direction = _get_aim_direction()
	hero_release_beam_charged = true
	hero_release_beam_elapsed = 0.0
	hero_release_beam_active = true
	hero_tick_timer = 0.0
	hero_release_beam_start_width = hero_charged_laser_width * hero_release_beam_start_width_multiplier
	hero_release_beam_damage = hero_charged_laser_damage * max_charge_damage_multiplier
	if world != null and world.has_method("lock_player_shoot_animation"):
		world.call("lock_player_shoot_animation", _direction_name_from_vector(hero_release_beam_direction))
	elif world != null and world.has_method("play_weapon_shoot_animation"):
		world.call("play_weapon_shoot_animation", _direction_name_from_vector(hero_release_beam_direction))


func hero_cancel_hold_attack() -> void:
	hero_continuous_beam_active = false
	if not hero_release_beam_active:
		_clear_hero_beam()


func stack_begin_hold_charge() -> void:
	if not _is_stack_character() or not can_stack_hold_charge():
		return
	stack_hold_charge_active = true
	stack_windup_timer = 0.0
	stack_pending_shot = false
	smoke_attack_timer = 0.0
	stack_attack_timer = 0.0
	_update_twins_charge_pose(_get_aim_direction())


func stack_update_hold_charge(_delta: float, charge_ratio: float) -> void:
	if not _is_stack_character() or not stack_hold_charge_active:
		return
	_update_twins_charge_pose(_get_aim_direction())


func stack_end_hold_attack(charge_ratio: float) -> void:
	if not _is_stack_character():
		return
	stack_hold_charge_active = false
	stack_windup_timer = 0.0
	stack_pending_shot = false
	var ratio: float = clampf(charge_ratio, 0.0, 1.0)
	var direction: Vector2 = _get_aim_direction()
	if ratio < 0.15:
		if twins_display_mode == TwinsDisplayMode.SMOKE_SOLO or twins_display_mode == TwinsDisplayMode.DUO:
			_fire_smoke_tap_shot(direction)
		return
	if world != null and world.has_method("play_weapon_shoot_animation"):
		world.call("play_weapon_shoot_animation", _direction_name_from_vector(direction))
	_update_twins_hold_attack_anim(direction)
	var fire_stack: bool = twins_display_mode != TwinsDisplayMode.SMOKE_SOLO
	var stack_origin: Vector2 = stack_sprite.global_position if stack_sprite != null else player.global_position
	if fire_stack:
		var pellet_count: int = int(lerpf(5.0, 14.0, ratio))
		if ratio >= 0.999:
			pellet_count = 12
		var spread_multiplier: float = lerpf(0.75, 1.35, ratio)
		_fire_stack_shotgun(direction, ratio >= 0.85, stack_origin, pellet_count, spread_multiplier)
	attack_cooldown_remaining = maxf(0.12, lerpf(0.35, 0.08, ratio))


func stack_cancel_hold_attack() -> void:
	stack_hold_charge_active = false
	stack_windup_timer = 0.0
	stack_pending_shot = false


func _toggle_stack_smoke_solo() -> void:
	if not _is_stack_character():
		return
	_squash_hint_key_icon(twins_hint_t_icon)
	if twins_display_mode == TwinsDisplayMode.DUO:
		twins_display_mode = TwinsDisplayMode.SMOKE_SOLO
		twins_front_is_smoke = true
		_reset_twin_sprite_layout()
		return
	twins_front_is_smoke = not twins_front_is_smoke
	twins_display_mode = TwinsDisplayMode.SMOKE_SOLO if twins_front_is_smoke else TwinsDisplayMode.STACK_SOLO
	_reset_twin_sprite_layout()


func _toggle_stack_duo_mode() -> void:
	if not _is_stack_character():
		return
	_squash_hint_key_icon(twins_hint_m_icon)
	if twins_display_mode == TwinsDisplayMode.DUO:
		twins_display_mode = TwinsDisplayMode.STACK_SOLO
		twins_front_is_smoke = false
		_reset_twin_sprite_layout()
	else:
		twins_display_mode = TwinsDisplayMode.DUO
		_init_duo_tile_offset()


func _update_hero_continuous_beam(delta: float) -> void:
	if not hero_continuous_beam_active or current_character_id != "hero":
		return
	var direction: Vector2 = _get_aim_direction()
	var range_value: float = hero_laser_range * hero_small_range_multiplier
	_update_hero_beam_visual(direction, hero_normal_laser_width, false, range_value)
	hero_tick_timer += delta
	if hero_tick_timer < hero_damage_tick_interval:
		return
	hero_tick_timer = 0.0
	var beam_start: Vector2 = _hero_beam_origin(direction)
	_damage_mobs_on_beam(
		beam_start,
		beam_start + direction * range_value,
		hero_normal_laser_width,
		hero_laser_damage
	)


func _fire_hero_laser(direction: Vector2, charged: bool) -> void:
	var damage: float = hero_laser_damage
	var width: float = hero_normal_laser_width
	var cooldown: float = hero_laser_cooldown
	var range_value: float = hero_laser_range * hero_small_range_multiplier
	if charged:
		damage = hero_charged_laser_damage
		width = hero_charged_laser_width
		cooldown = hero_charged_laser_cooldown
		range_value = hero_laser_range * hero_big_range_multiplier
	attack_cooldown_remaining = cooldown

	if world != null and world.has_method("play_weapon_shoot_animation"):
		world.call("play_weapon_shoot_animation", _direction_name_from_vector(direction))

	var beam_start: Vector2 = _hero_beam_origin(direction)
	var beam_origins: Array[Vector2] = _hero_beam_origins(direction)
	for origin in beam_origins:
		_spawn_laser_line_from_point(origin, direction, width * 1.9, Color(0.88, 0.0, 0.0, 0.48), range_value)
		_spawn_laser_line_from_point(origin, direction, width, Color(1.0, 0.18, 0.16, 0.85), range_value)
		_spawn_laser_line_from_point(origin, direction, maxf(2.4, width * 0.35), Color(1.0, 1.0, 1.0, 0.92), range_value)
	_damage_mobs_on_beam(beam_start, beam_start + direction * range_value, width, damage)


func _update_hero_release_beam(delta: float) -> void:
	if current_character_id != "hero":
		hero_release_beam_active = false
		_clear_hero_beam()
		return
	if not hero_release_beam_active:
		return
	hero_release_beam_elapsed += delta
	hero_release_beam_direction = _get_aim_direction()
	if hero_release_beam_elapsed >= hero_release_beam_duration:
		hero_release_beam_active = false
		hero_release_beam_start_width = 0.0
		attack_cooldown_remaining = maxf(hero_laser_cooldown, hero_charged_laser_cooldown)
		_clear_hero_beam()
		if world != null and world.has_method("unlock_player_shoot_animation"):
			world.call("unlock_player_shoot_animation")
		return
	var t: float = clampf(hero_release_beam_elapsed / maxf(0.001, hero_release_beam_duration), 0.0, 1.0)
	var start_width: float = hero_release_beam_start_width if hero_release_beam_start_width > 0.0 else hero_charged_laser_width
	if not hero_release_beam_charged:
		start_width = hero_normal_laser_width
	var live_width: float = lerpf(start_width, maxf(2.0, start_width * hero_beam_min_width_ratio), pow(t, 1.35))
	var base_range: float = hero_laser_range * (hero_big_range_multiplier if hero_release_beam_charged else hero_small_range_multiplier)
	var live_range: float = lerpf(base_range, base_range * 0.65, t)
	var beam_start: Vector2 = _hero_beam_origin(hero_release_beam_direction)
	_update_hero_beam_visual(hero_release_beam_direction, live_width, hero_release_beam_charged, live_range)
	hero_tick_timer += delta
	if hero_tick_timer >= hero_damage_tick_interval:
		hero_tick_timer = 0.0
		_damage_mobs_on_beam(beam_start, beam_start + hero_release_beam_direction * live_range, live_width, hero_release_beam_damage)


func _fire_twins_normal(direction: Vector2) -> void:
	match twins_display_mode:
		TwinsDisplayMode.SMOKE_SOLO:
			_fire_smoke_tap_shot(direction)
			_update_twins_attack_anim(direction, false, true)
		TwinsDisplayMode.STACK_SOLO:
			_update_twins_attack_anim(direction, false, false)
		TwinsDisplayMode.DUO:
			_fire_smoke_tap_shot(direction)
			_update_twins_hold_attack_anim(direction)
	attack_cooldown_remaining = 0.05


func _fire_smoke_tap_shot(direction: Vector2) -> void:
	var smoke_origin: Vector2 = smoke_sprite.global_position if smoke_sprite != null else player.global_position
	if smoke_attack_timer <= 0.0:
		smoke_attack_timer = smoke_pistol_interval
		_fire_smoke_pistol(direction, smoke_origin, 0.0)


func _update_twins_charged_fire(delta: float) -> void:
	smoke_attack_timer = maxf(0.0, smoke_attack_timer - delta)
	stack_attack_timer = maxf(0.0, stack_attack_timer - delta)
	stack_windup_timer = maxf(0.0, stack_windup_timer - delta)

	var direction: Vector2 = _get_aim_direction()
	var stack_origin: Vector2 = stack_sprite.global_position if stack_sprite != null else player.global_position
	var smoke_origin: Vector2 = smoke_sprite.global_position if smoke_sprite != null else player.global_position

	if twins_charged_remaining > 0.0:
		twins_charged_remaining = maxf(0.0, twins_charged_remaining - delta)
		_update_twins_attack_anim(direction, true, twins_front_is_smoke)
		if twins_display_mode == TwinsDisplayMode.STACK_SOLO or twins_display_mode == TwinsDisplayMode.DUO:
			if stack_attack_timer <= 0.0 and stack_windup_timer <= 0.0:
				stack_attack_timer = twins_charged_stack_interval
				_fire_stack_shotgun(direction, true, stack_origin)


func _update_twins_continuous_side_fire() -> void:
	if not _is_stack_character():
		return
	if twins_charged_remaining > 0.0:
		return
	var moving: bool = player_motion_dir.length() > 0.05
	var side_to_side: bool = absf(player_motion_dir.x) > absf(player_motion_dir.y)
	if not moving or not side_to_side:
		return
	_fire_twins_normal(player_motion_dir.normalized())


func _fire_stack_shotgun(direction: Vector2, charged: bool = false, origin: Vector2 = Vector2.INF, pellet_count: int = -1, spread_multiplier: float = 1.0) -> void:
	var start_origin: Vector2 = origin if origin != Vector2.INF else player.global_position
	var spread: float = deg_to_rad(stack_shotgun_spread_angle * 0.5 * spread_multiplier)
	var range_value: float = stack_shotgun_range * (1.15 if charged else 1.0)
	var damage: float = stack_shotgun_damage * (1.2 if charged else 1.0)
	var pellets: int = pellet_count if pellet_count > 0 else (5 if charged else 4)
	_spawn_muzzle_flash(start_origin, direction, Color(1.0, 0.96, 0.62, 1.0), 16.0)
	for i in range(pellets):
		var t: float = 0.0 if pellets <= 1 else float(i) / float(pellets - 1)
		var angle_offset: float = lerpf(-spread, spread, t)
		var dir: Vector2 = direction.rotated(angle_offset).normalized()
		var tracer_length: float = range_value * 0.72
		_spawn_gunshot_tracer(start_origin, dir, tracer_length, 4.2, Color(1.0, 0.84, 0.34, 1.0), 0.14)
		_spawn_gunshot_tracer(start_origin, dir, tracer_length * 0.82, 2.6, Color(1.0, 0.94, 0.58, 0.82), 0.11)
		_spawn_gunshot_tracer(start_origin, dir, tracer_length * 0.42, 1.4, Color(1.0, 1.0, 0.92, 0.55), 0.08)
		_damage_mobs_on_beam(start_origin, start_origin + dir * range_value, 5.5, damage)


func _fire_smoke_pistol(direction: Vector2, origin: Vector2, charge_ratio: float) -> void:
	var ratio: float = clampf(charge_ratio, 0.0, 1.0)
	var range_value: float = lerpf(smoke_pistol_range, smoke_pistol_charged_range, ratio)
	var damage: float = smoke_pistol_damage * lerpf(1.0, 1.35, ratio)
	var tracer_length: float = range_value * 0.82
	_spawn_muzzle_flash(origin, direction, Color(1.0, 0.98, 0.72, 1.0), 12.0)
	_spawn_gunshot_tracer(origin, direction, tracer_length, 3.6, Color(1.0, 0.94, 0.48, 1.0), 0.12)
	_spawn_gunshot_tracer(origin, direction, tracer_length * 0.72, 2.2, Color(1.0, 0.98, 0.72, 0.78), 0.10)
	_spawn_gunshot_tracer(origin, direction, tracer_length * 0.34, 1.2, Color(1.0, 1.0, 0.96, 0.62), 0.07)
	_damage_mobs_on_beam(origin, origin + direction * range_value, 4.5, damage)


func _fire_prince_slash(direction: Vector2) -> void:
	if prince_sword == null:
		_setup_prince_sword()
	attack_cooldown_remaining = prince_slash_cooldown

	if world != null and world.has_method("play_weapon_shoot_animation"):
		world.call("play_weapon_shoot_animation", _direction_name_from_vector(direction))

	var slash_origin: Vector2 = player.global_position
	_spawn_prince_slash_visual(slash_origin, direction)
	var mobs: Array[Node2D] = _get_alive_mobs()
	var hit_mobs: Array[Node2D] = prince_sword.call("swing", slash_origin, direction, mobs)
	for mob in hit_mobs:
		if mob == null or not is_instance_valid(mob):
			continue
		if mob.has_method("take_damage"):
			mob.call("take_damage", prince_slash_damage)
		var knock_dir: Vector2 = (mob.global_position - slash_origin).normalized()
		if knock_dir.length() <= 0.001:
			knock_dir = direction.normalized()
		mob.global_position += knock_dir * prince_slash_knockback
		_spawn_slash_hit_fx(mob.global_position)


func _trigger_caraxes_summon() -> void:
	if current_character_id != "prince":
		return
	if summon_in_progress:
		return
	if caraxes_cooldown_remaining > 0.0:
		return
	_end_charge_mode(true)
	caraxes_cooldown_remaining = caraxes_cooldown
	print("[CharacterController] Caraxes summon ready.")
	_do_caraxes_summon_sequence()


func _do_caraxes_summon_sequence() -> void:
	summon_in_progress = true
	var direction: Vector2 = _get_aim_direction()
	if world != null and world.has_method("play_weapon_shoot_animation"):
		world.call("play_weapon_shoot_animation", _direction_name_from_vector(direction))

	var dragon: AnimatedSprite2D = AnimatedSprite2D.new()
	dragon.name = "CaraxesSummon"
	dragon.z_index = 140
	dragon.global_position = player.global_position + Vector2(0.0, -80.0)
	if caraxes_summoning_frames != null:
		dragon.sprite_frames = caraxes_summoning_frames
		var anims: PackedStringArray = dragon.sprite_frames.get_animation_names()
		if not anims.is_empty():
			dragon.play(anims[0])
	dragon.speed_scale = maxf(1.0, caraxes_grab_speed_multiplier)
	if world != null:
		world.add_child(dragon)

	var frame_delay: float = 0.22
	if dragon.sprite_frames != null and dragon.animation != "":
		var speed: float = maxf(1.0, dragon.sprite_frames.get_animation_speed(dragon.animation))
		frame_delay = maxf(0.03, 1.0 / speed)
	var grab_wait: float = frame_delay * float(maxi(1, caraxes_grab_frame))
	grab_wait /= maxf(1.0, caraxes_grab_speed_multiplier)
	await get_tree().create_timer(grab_wait).timeout

	var targets: Array[Node2D] = _get_nearest_mobs(player.global_position, caraxes_max_targets)
	var hold_offsets: Dictionary = {}
	for i in range(targets.size()):
		var mob: Node2D = targets[i]
		if mob == null or not is_instance_valid(mob):
			continue
		var around_angle: float = TAU * (float(i) / maxf(1.0, float(targets.size())))
		hold_offsets[mob.get_instance_id()] = Vector2(cos(around_angle), sin(around_angle)) * 22.0 + Vector2(0.0, -12.0)
	var hold_elapsed: float = 0.0
	while hold_elapsed < caraxes_hold_duration:
		hold_elapsed += 0.05
		targets = _filter_valid_mobs(targets)
		for mob in targets:
			if mob == null or not is_instance_valid(mob):
				continue
			var key: int = mob.get_instance_id()
			var offset: Vector2 = hold_offsets.get(key, Vector2.ZERO)
			mob.global_position = mob.global_position.lerp(dragon.global_position + offset, caraxes_mob_pull_strength)
			if mob.has_method("take_damage"):
				mob.call("take_damage", caraxes_hold_damage * 0.05)
		await get_tree().create_timer(0.05).timeout

	print("[CharacterController] Caraxes grabbed %d mobs." % targets.size())
	targets = _filter_valid_mobs(targets)
	var fly_off_target: Vector2 = dragon.global_position + Vector2(0.0, -420.0)
	var fly_tween: Tween = create_tween()
	fly_tween.set_parallel(true)
	fly_tween.tween_property(dragon, "global_position", fly_off_target, 0.55)
	fly_tween.tween_property(dragon, "modulate:a", 0.0, 0.55)
	for mob in targets:
		if mob == null or not is_instance_valid(mob):
			continue
		var key: int = mob.get_instance_id()
		var offset: Vector2 = hold_offsets.get(key, Vector2.ZERO)
		fly_tween.tween_property(mob, "global_position", fly_off_target + offset, 0.55)
		fly_tween.tween_property(mob, "modulate:a", 0.0, 0.55)
	await fly_tween.finished
	for mob in targets:
		if mob == null or not is_instance_valid(mob):
			continue
		_defeat_mob(mob)
	if is_instance_valid(dragon):
		dragon.queue_free()
	summon_in_progress = false


func _defeat_mob(mob) -> void:
	if mob == null or not is_instance_valid(mob):
		return
	if mob.has_method("take_damage"):
		mob.call("take_damage", 999999.0)
	elif is_instance_valid(mob):
		mob.queue_free()


func _filter_valid_mobs(mobs: Array[Node2D]) -> Array[Node2D]:
	var valid: Array[Node2D] = []
	for mob in mobs:
		if mob != null and is_instance_valid(mob):
			valid.append(mob)
	return valid


func _update_prince_stamina(delta: float) -> void:
	return


func _damage_mobs_on_beam(start_pos: Vector2, end_pos: Vector2, beam_width: float, damage: float) -> void:
	var mobs: Array[Node2D] = _get_alive_mobs()
	for mob in mobs:
		var p: Vector2 = mob.global_position
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(p, start_pos, end_pos)
		if nearest.distance_to(p) <= beam_width + 8.0:
			if mob.has_method("take_damage"):
				mob.call("take_damage", damage)


func _get_alive_mobs() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if world == null:
		return result
	var mob_root: Node = world.get_node_or_null("MobRoot")
	if mob_root == null:
		return result
	for child in mob_root.get_children():
		var mob: Node2D = child as Node2D
		if mob == null or not is_instance_valid(mob):
			continue
		if mob.has_method("take_damage"):
			result.append(mob)
	return result


func _get_nearest_mobs(origin: Vector2, count: int) -> Array[Node2D]:
	var mobs: Array[Node2D] = _get_alive_mobs()
	mobs.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_to(origin) < b.global_position.distance_to(origin)
	)
	if mobs.size() <= count:
		return mobs
	var result: Array[Node2D] = []
	for i in range(count):
		result.append(mobs[i])
	return result


func _add_hero_laser_line(start_global: Vector2, end_global: Vector2, width: float, color: Color, direction: Vector2 = Vector2.ZERO) -> void:
	if player == null:
		return
	var beam_direction: Vector2 = direction
	if beam_direction.length() <= 0.001:
		beam_direction = end_global - start_global
	var line: Line2D = Line2D.new()
	line.width = width
	line.default_color = color
	line.z_index = _hero_beam_line_z_index(beam_direction)
	line.add_point(player.to_local(start_global))
	line.add_point(player.to_local(end_global))
	player.add_child(line)
	var tween: Tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.12)
	tween.finished.connect(func() -> void:
		if is_instance_valid(line):
			line.queue_free()
	)


func _spawn_gunshot_tracer(
	start_pos: Vector2,
	direction: Vector2,
	length: float,
	width: float,
	color: Color,
	fade_time: float
) -> void:
	if player == null or world == null:
		return
	var dir: Vector2 = direction.normalized() if direction.length() > 0.001 else Vector2.RIGHT
	var host: Node = world
	var line: Line2D = Line2D.new()
	line.width = width
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.z_index = 96
	line.add_point(host.to_local(start_pos))
	line.add_point(host.to_local(start_pos + dir * length))
	host.add_child(line)
	var tween: Tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, fade_time)
	tween.finished.connect(func() -> void:
		if is_instance_valid(line):
			line.queue_free()
	)


func _spawn_muzzle_flash(start_pos: Vector2, direction: Vector2, color: Color, size: float) -> void:
	if world == null:
		return
	var dir: Vector2 = direction.normalized() if direction.length() > 0.001 else Vector2.RIGHT
	var flash: Polygon2D = Polygon2D.new()
	var half: float = size * 0.5
	flash.polygon = PackedVector2Array([
		Vector2(-half * 0.35, -half),
		Vector2(half * 1.1, 0.0),
		Vector2(-half * 0.35, half)
	])
	flash.color = color
	flash.modulate = Color(1.35, 1.35, 1.35, 1.0)
	flash.rotation = dir.angle()
	flash.global_position = start_pos + dir * 4.0
	flash.z_index = 97
	world.add_child(flash)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "modulate:a", 0.0, 0.11)
	tween.tween_property(flash, "scale", Vector2(1.55, 1.55), 0.11)
	tween.finished.connect(func() -> void:
		if is_instance_valid(flash):
			flash.queue_free()
	)


func _update_twins_charge_pose(direction: Vector2) -> void:
	if smoke_sprite == null or stack_sprite == null:
		return
	var dir_name: String = _direction_name_from_vector(direction)
	match twins_display_mode:
		TwinsDisplayMode.DUO:
			smoke_sprite.visible = true
			stack_sprite.visible = true
			_play_twin_animation(smoke_sprite, smoke_walk_frames, smoke_shoot_frames, false, dir_name, false)
			_play_twin_animation(stack_sprite, stack_walk_frames, stack_shoot_frames, false, dir_name, false)
		TwinsDisplayMode.SMOKE_SOLO:
			smoke_sprite.visible = true
			stack_sprite.visible = false
			_play_twin_animation(smoke_sprite, smoke_walk_frames, smoke_shoot_frames, false, dir_name, false)
		TwinsDisplayMode.STACK_SOLO:
			smoke_sprite.visible = false
			stack_sprite.visible = true
			_play_twin_animation(stack_sprite, stack_walk_frames, stack_shoot_frames, false, dir_name, false)


func _spawn_laser_line(direction: Vector2, width: float, color: Color, range_value: float = -1.0) -> void:
	if player == null:
		return
	var final_range: float = hero_laser_range if range_value <= 0.0 else range_value
	var start_global: Vector2 = player.global_position
	var end_global: Vector2 = start_global + direction * final_range
	_add_hero_laser_line(start_global, end_global, width, color, direction)


func _spawn_laser_line_from_point(start_pos: Vector2, direction: Vector2, width: float, color: Color, range_value: float = -1.0) -> void:
	if player == null:
		return
	var final_range: float = hero_laser_range if range_value <= 0.0 else range_value
	var end_pos: Vector2 = start_pos + direction * final_range
	_add_hero_laser_line(start_pos, end_pos, width, color, direction)


func _spawn_prince_slash_visual(origin: Vector2, direction: Vector2) -> void:
	if world == null:
		return
	var aim: Vector2 = direction.normalized() if direction.length() > 0.001 else Vector2.RIGHT
	var slash_root: Node2D = Node2D.new()
	slash_root.name = "PrinceSlashVisual"
	slash_root.z_index = 118
	slash_root.global_position = origin
	slash_root.rotation = aim.angle()
	world.add_child(slash_root)

	var fill: Polygon2D = Polygon2D.new()
	var outline: Line2D = Line2D.new()
	outline.default_color = Color(1.0, 0.92, 0.58, 0.78)
	outline.width = 3.0
	outline.closed = true
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	var half_arc: float = deg_to_rad(prince_slash_arc * 0.5)
	var segments: int = 14
	var fill_points: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var sample_angle: float = lerpf(-half_arc, half_arc, t)
		var point: Vector2 = Vector2(cos(sample_angle), sin(sample_angle)) * prince_slash_range
		fill_points.append(point)
		outline.add_point(point)
	fill.polygon = fill_points
	fill.color = Color(1.0, 0.84, 0.42, 0.24)
	slash_root.add_child(fill)
	slash_root.add_child(outline)

	var edge: Line2D = Line2D.new()
	edge.default_color = Color(1.0, 0.98, 0.88, 0.92)
	edge.width = 4.5
	edge.joint_mode = Line2D.LINE_JOINT_ROUND
	edge.begin_cap_mode = Line2D.LINE_CAP_ROUND
	edge.end_cap_mode = Line2D.LINE_CAP_ROUND
	edge.add_point(Vector2.ZERO)
	edge.add_point(Vector2(cos(-half_arc), sin(-half_arc)) * prince_slash_range)
	edge.add_point(Vector2(cos(half_arc), sin(half_arc)) * prince_slash_range)
	slash_root.add_child(edge)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(slash_root, "modulate:a", 0.0, 0.16)
	tween.tween_property(slash_root, "scale", Vector2(1.08, 1.08), 0.16)
	tween.finished.connect(func() -> void:
		if is_instance_valid(slash_root):
			slash_root.queue_free()
	)


func _spawn_slash_hit_fx(at_pos: Vector2) -> void:
	if world == null:
		return
	var spark: ColorRect = ColorRect.new()
	spark.size = Vector2(12.0, 12.0)
	spark.position = at_pos - spark.size * 0.5
	spark.color = Color(1.0, 0.94, 0.86, 0.72)
	spark.z_index = 130
	world.add_child(spark)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(spark, "scale", Vector2(2.2, 2.2), 0.10)
	tween.tween_property(spark, "modulate:a", 0.0, 0.10)
	tween.finished.connect(func() -> void:
		if is_instance_valid(spark):
			spark.queue_free()
	)


func _update_hero_beam_visual(direction: Vector2, width: float, charged: bool, range_override: float = -1.0) -> void:
	if world == null or player == null:
		return
	_ensure_hero_beam_lines()
	hero_beam_root.z_index = _hero_beam_line_z_index(direction)
	var beam_range: float = hero_laser_range if range_override <= 0.0 else range_override
	var outer_scale: float = 1.85 if charged else 1.55
	var mid_scale: float = 1.05 if charged else 0.95
	var outer_col: Color = Color(0.9, 0.0, 0.0, 0.62) if charged else Color(0.92, 0.08, 0.08, 0.48)
	var mid_col: Color = Color(1.0, 0.18, 0.12, 0.82) if charged else Color(1.0, 0.24, 0.2, 0.76)
	var core_col: Color = Color(1.0, 1.0, 1.0, 0.92)
	var origins: Array[Vector2] = _hero_beam_origins(direction)
	for beam_index in range(origins.size()):
		if beam_index >= hero_beam_line_sets.size():
			continue
		var line_set: Array = hero_beam_line_sets[beam_index]
		if line_set.size() < 3:
			continue
		var outer_line: Line2D = line_set[0] as Line2D
		var mid_line: Line2D = line_set[1] as Line2D
		var core_line: Line2D = line_set[2] as Line2D
		var start_global: Vector2 = origins[beam_index]
		var end_global: Vector2 = start_global + direction * beam_range
		var start_pos: Vector2 = player.to_local(start_global)
		var end_pos: Vector2 = player.to_local(end_global)
		outer_line.width = width * outer_scale
		mid_line.width = width * mid_scale
		core_line.width = maxf(2.5, width * 0.38)
		outer_line.default_color = outer_col
		mid_line.default_color = mid_col
		core_line.default_color = core_col
		for line in [outer_line, mid_line, core_line]:
			line.clear_points()
			line.add_point(start_pos)
			line.add_point(end_pos)


func _ensure_hero_beam_lines() -> void:
	if hero_beam_root != null:
		return
	if player == null:
		return
	hero_beam_root = Node2D.new()
	hero_beam_root.name = "HeroContinuousBeam"
	hero_beam_root.z_index = hero_beam_z_index_front
	hero_beam_root.top_level = false
	player.add_child(hero_beam_root)
	hero_beam_line_sets = []
	for _beam_index in range(2):
		var line_set: Array[Line2D] = []
		for _layer_index in range(3):
			var line: Line2D = Line2D.new()
			line.joint_mode = Line2D.LINE_JOINT_ROUND
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			hero_beam_root.add_child(line)
			line_set.append(line)
		hero_beam_line_sets.append(line_set)


func _hero_beam_origins(direction: Vector2) -> Array[Vector2]:
	if player == null:
		return [Vector2.ZERO, Vector2.ZERO]
	var base_offset: Vector2 = Vector2(
		laser_beam_offset_x + laser_start_offset_x,
		laser_beam_offset_y + laser_start_offset_y
	)
	var center: Vector2 = player.global_position + hero_beam_face_offset + base_offset
	var half_sep: float = hero_dual_eye_separation * 0.5
	# Keep both eyes level; separate only on the horizontal axis like real eyes.
	return [center + Vector2(-half_sep, 0.0), center + Vector2(half_sep, 0.0)]


func _hero_beam_line_z_index(direction: Vector2) -> int:
	if _direction_name_from_vector(direction) == "up":
		return hero_beam_z_index_shoot_up
	return hero_beam_z_index_front


func _hero_beam_origin(direction: Vector2) -> Vector2:
	var origins: Array[Vector2] = _hero_beam_origins(direction)
	if origins.is_empty():
		return Vector2.ZERO
	if origins.size() == 1:
		return origins[0]
	return (origins[0] + origins[1]) * 0.5


func _clear_hero_beam() -> void:
	if hero_beam_root != null and is_instance_valid(hero_beam_root):
		hero_beam_root.queue_free()
	hero_beam_root = null
	hero_beam_line_sets = []


func _get_aim_direction() -> Vector2:
	if player == null:
		return Vector2.RIGHT
	if current_character_id == "hero":
		if hero_aim_smoothed_direction.length() > 0.001:
			return hero_aim_smoothed_direction.normalized()
		return Vector2.RIGHT
	var delta: Vector2 = player.get_global_mouse_position() - player.global_position
	if delta.length() <= 0.001:
		return Vector2.RIGHT
	return delta.normalized()


func _update_hero_aim_direction(delta: float) -> void:
	if player == null or current_character_id != "hero":
		return
	var raw_delta: Vector2 = player.get_global_mouse_position() - player.global_position
	if raw_delta.length() <= 0.001:
		return
	var raw_direction: Vector2 = raw_delta.normalized()
	var charge_ratio: float = 0.0
	if charge_max_time > 0.001 and attack_holding and charge_mode == "hero":
		charge_ratio = clampf(attack_hold_elapsed / charge_max_time, 0.0, 1.0)

	var responsiveness: float = hero_normal_aim_responsiveness
	var use_wild_aim: bool = hero_release_beam_active
	if not use_wild_aim and hero_continuous_beam_active:
		responsiveness = hero_normal_aim_responsiveness
	elif not use_wild_aim and attack_holding and charge_mode == "hero":
		responsiveness = lerpf(hero_normal_aim_responsiveness, hero_charged_aim_responsiveness, charge_ratio * charge_ratio)
	else:
		use_wild_aim = true
		responsiveness = hero_charged_aim_responsiveness

	if use_wild_aim:
		var jitter: float = sin(hero_aim_wobble_time * 37.0) * hero_charged_aim_jitter
		jitter += cos(hero_aim_wobble_time * 23.0 + 1.2) * hero_charged_aim_jitter * 0.65
		raw_direction = raw_direction.rotated(jitter)
		var snap_strength: float = clampf(delta * responsiveness, 0.0, 1.0)
		hero_aim_smoothed_direction = hero_aim_smoothed_direction.lerp(raw_direction, snap_strength).normalized()
		if hero_aim_overshoot_enabled(charge_ratio):
			var overshoot_dir: Vector2 = (raw_direction - hero_aim_smoothed_direction).normalized()
			hero_aim_smoothed_direction = hero_aim_smoothed_direction.rotated(
				overshoot_dir.angle_to(raw_direction) * hero_charged_aim_overshoot * snap_strength
			).normalized()
	else:
		var blend: float = clampf(delta * responsiveness, 0.0, 1.0)
		hero_aim_smoothed_direction = hero_aim_smoothed_direction.lerp(raw_direction, blend).normalized()


func hero_aim_overshoot_enabled(charge_ratio: float) -> bool:
	return hero_release_beam_active or (attack_holding and charge_ratio >= 0.55)


func can_stack_hold_charge() -> bool:
	return _is_stack_character() and twins_display_mode != TwinsDisplayMode.SMOKE_SOLO


func _direction_name_from_vector(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x >= 0.0 else "left"
	return "down" if direction.y >= 0.0 else "up"


func _is_attack_press(event: InputEvent) -> bool:
	if event.is_action_pressed("attack"):
		return true
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		return mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed
	return false


func _is_attack_release(event: InputEvent) -> bool:
	if event.is_action_released("attack"):
		return true
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		return mb.button_index == MOUSE_BUTTON_RIGHT and not mb.pressed
	return false


func _set_world_animation_overrides(walk_frames: SpriteFrames, shoot_frames: SpriteFrames, walk_scale: Vector2, shoot_scale: Vector2) -> void:
	if world == null:
		return
	if world.has_method("set_character_animation_overrides"):
		world.call("set_character_animation_overrides", current_character_id, walk_frames, shoot_frames, walk_scale, shoot_scale)


func _ensure_twins_nodes() -> void:
	if player == null:
		return
	smoke_sprite = player.get_node_or_null("TwinSmoke") as AnimatedSprite2D
	if smoke_sprite == null:
		smoke_sprite = AnimatedSprite2D.new()
		smoke_sprite.name = "TwinSmoke"
		smoke_sprite.z_index = 88
		player.add_child(smoke_sprite)
	stack_sprite = player.get_node_or_null("TwinStack") as AnimatedSprite2D
	if stack_sprite == null:
		stack_sprite = AnimatedSprite2D.new()
		stack_sprite.name = "TwinStack"
		stack_sprite.z_index = 87
		player.add_child(stack_sprite)
	_hide_twins_nodes()


func _show_twins_nodes() -> void:
	if smoke_sprite != null:
		smoke_sprite.visible = true
	if stack_sprite != null:
		stack_sprite.visible = true


func _hide_twins_nodes() -> void:
	if smoke_sprite != null:
		smoke_sprite.visible = false
	if stack_sprite != null:
		stack_sprite.visible = false


func _show_main_player_sprite(visible: bool) -> void:
	if player_sprite != null:
		player_sprite.visible = visible


func _init_duo_tile_offset() -> void:
	if player == null or world == null or not world.has_method("world_to_tile"):
		return
	var stack_tile: Vector2i = world.call("world_to_tile", player.global_position)
	twins_duo_tile_offset = _pick_duo_tile_offset(stack_tile)


func _int_sign(value: int) -> int:
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0


func _pick_duo_tile_offset(stack_tile: Vector2i, prefer_dir: Vector2i = Vector2i.ZERO) -> Vector2i:
	var candidates: Array[Vector2i] = []
	if prefer_dir != Vector2i.ZERO:
		candidates.append(prefer_dir)
	if player_motion_dir.length() > 0.05:
		var motion_tile_dir: Vector2i = Vector2i(
			_int_sign(int(round(player_motion_dir.x))),
			_int_sign(int(round(player_motion_dir.y)))
		)
		if motion_tile_dir != Vector2i.ZERO:
			candidates.append(motion_tile_dir)
	candidates.append_array([Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)])
	var seen: Dictionary = {}
	for dir in candidates:
		if seen.has(dir):
			continue
		seen[dir] = true
		if _is_duo_partner_tile_walkable(stack_tile, dir):
			return dir
	return Vector2i(1, 0)


func _is_duo_partner_tile_walkable(stack_tile: Vector2i, offset: Vector2i) -> bool:
	if offset == Vector2i.ZERO:
		return false
	if world == null or not world.has_method("is_walkable_tile"):
		return true
	return bool(world.call("is_walkable_tile", stack_tile + offset))


func _ensure_duo_tile_offset(stack_tile: Vector2i) -> void:
	if _is_duo_partner_tile_walkable(stack_tile, twins_duo_tile_offset):
		return
	var flipped: Vector2i = -twins_duo_tile_offset
	if flipped != Vector2i.ZERO and _is_duo_partner_tile_walkable(stack_tile, flipped):
		twins_duo_tile_offset = flipped
		return
	twins_duo_tile_offset = _pick_duo_tile_offset(stack_tile)


func _update_twins_duo_tile_positions() -> void:
	if player == null or smoke_sprite == null or stack_sprite == null or world == null:
		return
	if twins_display_mode != TwinsDisplayMode.DUO:
		return
	var stack_tile: Vector2i = world.call("world_to_tile", player.global_position)
	_ensure_duo_tile_offset(stack_tile)
	stack_sprite.top_level = false
	stack_sprite.position = Vector2.ZERO
	smoke_sprite.top_level = true
	if world.has_method("get_duo_partner_world_position"):
		smoke_sprite.global_position = world.call("get_duo_partner_world_position", twins_duo_tile_offset)
	elif world.has_method("tile_to_world"):
		smoke_sprite.global_position = world.call("tile_to_world", stack_tile + twins_duo_tile_offset)
	var smoke_y: float = smoke_sprite.global_position.y
	var stack_y: float = player.global_position.y
	smoke_sprite.z_index = 89 if smoke_y < stack_y else 87
	stack_sprite.z_index = 89 if stack_y <= smoke_y else 87


func _reset_twin_sprite_layout() -> void:
	if smoke_sprite != null:
		smoke_sprite.top_level = false
		smoke_sprite.position = Vector2.ZERO
	if stack_sprite != null:
		stack_sprite.top_level = false
		stack_sprite.position = Vector2.ZERO


func _update_twins_visuals(_delta: float) -> void:
	if smoke_sprite == null or stack_sprite == null:
		return
	if stack_hold_charge_active:
		return
	var moving: bool = false
	if world != null:
		moving = bool(world.get("is_moving_to_click"))
	var move_dir: Vector2 = player_motion_dir if moving else _get_aim_direction()
	if move_dir.length() <= 0.001:
		move_dir = Vector2.DOWN
	var smoke_dir: String = _direction_name_from_vector(move_dir)
	var stack_dir: String = smoke_dir
	match twins_display_mode:
		TwinsDisplayMode.DUO:
			smoke_sprite.visible = true
			stack_sprite.visible = true
			_play_twin_animation(smoke_sprite, smoke_walk_frames, smoke_shoot_frames, moving, smoke_dir)
			_play_twin_animation(stack_sprite, stack_walk_frames, stack_shoot_frames, moving, stack_dir)
		TwinsDisplayMode.SMOKE_SOLO:
			smoke_sprite.visible = true
			stack_sprite.visible = false
			smoke_sprite.z_index = 88
			_play_twin_animation(smoke_sprite, smoke_walk_frames, smoke_shoot_frames, moving, smoke_dir)
		TwinsDisplayMode.STACK_SOLO:
			smoke_sprite.visible = false
			stack_sprite.visible = true
			stack_sprite.z_index = 88
			_play_twin_animation(stack_sprite, stack_walk_frames, stack_shoot_frames, moving, stack_dir)


func _update_twins_hold_attack_anim(direction: Vector2) -> void:
	if smoke_sprite == null or stack_sprite == null:
		return
	var smoke_dir: String = _direction_name_from_vector(direction)
	var stack_dir: String = smoke_dir
	match twins_display_mode:
		TwinsDisplayMode.DUO:
			smoke_sprite.visible = true
			stack_sprite.visible = true
			_play_twin_animation(smoke_sprite, smoke_walk_frames, smoke_shoot_frames, false, smoke_dir, true)
			_play_twin_animation(stack_sprite, stack_walk_frames, stack_shoot_frames, false, stack_dir, true)
		TwinsDisplayMode.SMOKE_SOLO:
			smoke_sprite.visible = true
			stack_sprite.visible = false
			_play_twin_animation(smoke_sprite, smoke_walk_frames, smoke_shoot_frames, false, smoke_dir, true)
		TwinsDisplayMode.STACK_SOLO:
			smoke_sprite.visible = false
			stack_sprite.visible = true
			_play_twin_animation(stack_sprite, stack_walk_frames, stack_shoot_frames, false, stack_dir, true)


func _update_twins_attack_anim(direction: Vector2, _charged: bool, use_smoke: bool) -> void:
	if smoke_sprite == null or stack_sprite == null:
		return
	if twins_display_mode == TwinsDisplayMode.DUO:
		_update_twins_hold_attack_anim(direction)
		return
	var smoke_dir: String = _direction_name_from_vector(direction)
	var stack_dir: String = smoke_dir
	if use_smoke:
		smoke_sprite.visible = true
		stack_sprite.visible = false
		_play_twin_animation(smoke_sprite, smoke_walk_frames, smoke_shoot_frames, false, smoke_dir, true)
	else:
		smoke_sprite.visible = false
		stack_sprite.visible = true
		_play_twin_animation(stack_sprite, stack_walk_frames, stack_shoot_frames, false, stack_dir, true)


func _play_twin_animation(sprite: AnimatedSprite2D, walk_frames: SpriteFrames, shoot_frames: SpriteFrames, moving: bool, direction_name: String, force_shoot: bool = false) -> void:
	if sprite == null:
		return
	var frames: SpriteFrames = shoot_frames if force_shoot else walk_frames
	if frames == null:
		return
	var prefix: String = "shoot" if force_shoot else ("walk" if moving else "idle")
	var requested_anim: String = "%s_%s" % [prefix, direction_name]
	var resolved: Dictionary = MIRROR_HELPER_SCRIPT.resolve_with_mirror(frames, requested_anim)
	if not bool(resolved.get("found", false)):
		return
	sprite.sprite_frames = frames
	sprite.flip_h = bool(resolved.get("flip_h", false))
	var anim_name: String = str(resolved.get("animation", requested_anim))
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)


func _opposite_direction(direction_name: String) -> String:
	match direction_name:
		"up":
			return "down"
		"down":
			return "up"
		"left":
			return "right"
		"right":
			return "left"
		_:
			return "down"


func _ensure_prince_ui() -> void:
	if world == null:
		return
	var hud_layer: CanvasLayer = world.get_node_or_null("HUDLayer")
	if hud_layer == null:
		return
	prince_stamina_bar_root = hud_layer.get_node_or_null("PrinceStaminaRoot") as Control
	if prince_stamina_bar_root == null:
		prince_stamina_bar_root = Control.new()
		prince_stamina_bar_root.name = "PrinceStaminaRoot"
		prince_stamina_bar_root.position = Vector2(18.0, get_viewport().size.y - 72.0)
		hud_layer.add_child(prince_stamina_bar_root)
		prince_stamina_bar = ProgressBar.new()
		prince_stamina_bar.name = "PrinceStaminaBar"
		prince_stamina_bar.position = Vector2.ZERO
		prince_stamina_bar.size = Vector2(230.0, 18.0)
		prince_stamina_bar.show_percentage = false
		prince_stamina_bar_root.add_child(prince_stamina_bar)
	else:
		prince_stamina_bar = prince_stamina_bar_root.get_node_or_null("PrinceStaminaBar") as ProgressBar

	caraxes_icon_root = hud_layer.get_node_or_null("CaraxesIconRoot") as Control
	if caraxes_icon_root == null:
		caraxes_icon_root = Control.new()
		caraxes_icon_root.name = "CaraxesIconRoot"
		hud_layer.add_child(caraxes_icon_root)
		caraxes_icon = TextureRect.new()
		caraxes_icon.name = "CaraxesIcon"
		caraxes_icon.size = Vector2(64.0, 64.0)
		caraxes_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		caraxes_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		caraxes_icon_root.add_child(caraxes_icon)
		caraxes_cooldown_overlay = ColorRect.new()
		caraxes_cooldown_overlay.name = "CooldownOverlay"
		caraxes_cooldown_overlay.color = Color(0.02, 0.02, 0.02, 0.62)
		caraxes_cooldown_overlay.size = Vector2(64.0, 64.0)
		caraxes_icon_root.add_child(caraxes_cooldown_overlay)
		caraxes_cooldown_label = Label.new()
		caraxes_cooldown_label.name = "CooldownLabel"
		caraxes_cooldown_label.size = Vector2(64.0, 64.0)
		caraxes_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caraxes_cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caraxes_icon_root.add_child(caraxes_cooldown_label)
	else:
		caraxes_icon = caraxes_icon_root.get_node_or_null("CaraxesIcon") as TextureRect
		caraxes_cooldown_overlay = caraxes_icon_root.get_node_or_null("CooldownOverlay") as ColorRect
		caraxes_cooldown_label = caraxes_icon_root.get_node_or_null("CooldownLabel") as Label


func _ensure_twins_mode_hints() -> void:
	if twins_hints_root != null:
		return
	var hud_layer: CanvasLayer = null
	if world != null:
		hud_layer = world.get_node_or_null("HudLayer") as CanvasLayer
		if hud_layer == null:
			hud_layer = world.get_node_or_null("HUDLayer") as CanvasLayer
	if hud_layer == null:
		return
	if twins_key_t_texture == null:
		twins_key_t_texture = _load_key_from_sheet(3, 4)
	if twins_key_m_texture == null:
		twins_key_m_texture = _load_key_from_sheet(4, 3)
	twins_hints_root = HBoxContainer.new()
	twins_hints_root.name = "TwinsModeHints"
	twins_hints_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	twins_hints_root.add_theme_constant_override("separation", 14)
	twins_hints_root.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	twins_hints_root.offset_left = -320.0
	twins_hints_root.offset_top = twins_hints_screen_offset.y - 80.0
	twins_hints_root.offset_right = twins_hints_screen_offset.x
	twins_hints_root.offset_bottom = twins_hints_screen_offset.y
	hud_layer.add_child(twins_hints_root)
	var charge_hint: Dictionary = _make_twins_hint_badge(twins_charge_icon_texture, "Hold to Fire")
	var t_hint: Dictionary = _make_twins_hint_badge(twins_key_t_texture, "Switch Smoke")
	var m_hint: Dictionary = _make_twins_hint_badge(twins_key_m_texture, "Duo Mode")
	twins_hint_charge_row = charge_hint.get("row") as Control
	twins_hint_t_row = t_hint.get("row") as Control
	twins_hint_m_row = m_hint.get("row") as Control
	twins_hint_charge_icon = charge_hint.get("icon") as TextureRect
	twins_hint_t_icon = t_hint.get("icon") as TextureRect
	twins_hint_m_icon = m_hint.get("icon") as TextureRect
	if twins_hint_charge_icon != null:
		twins_hint_charge_icon.scale = Vector2(0.40, 0.40)
		twins_hint_charge_icon.pivot_offset = Vector2(28.0, 28.0)
	twins_hint_charge_label = charge_hint.get("label") as Label
	twins_hint_t_label = t_hint.get("label") as Label
	twins_hint_m_label = m_hint.get("label") as Label
	twins_hints_root.add_child(twins_hint_charge_row)
	twins_hints_root.add_child(twins_hint_t_row)
	twins_hints_root.add_child(twins_hint_m_row)
	twins_hints_root.visible = false


func _make_twins_hint_badge(key_texture: Texture2D, default_label: String) -> Dictionary:
	var row: VBoxContainer = VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon: TextureRect = TextureRect.new()
	icon.name = "KeyIcon"
	icon.custom_minimum_size = Vector2(56.0, 56.0)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = key_texture
	icon.scale = twins_hint_key_rest_scale
	icon.pivot_offset = Vector2(28.0, 28.0)
	icon.position.y = -10.0
	row.add_child(icon)
	var hint_label: Label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = default_label
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_constant_override("outline_size", 3)
	hint_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.95))
	hint_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.98, 0.96))
	row.add_child(hint_label)
	return {"row": row, "icon": icon, "label": hint_label}


func _squash_hint_key_icon(icon: TextureRect) -> void:
	if icon == null:
		return
	if icon.has_meta("hint_bounce_tween"):
		var old_tween: Tween = icon.get_meta("hint_bounce_tween") as Tween
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()
	var rest_scale: Vector2 = twins_hint_key_rest_scale
	var rest_y: float = -10.0
	icon.scale = rest_scale
	icon.position.y = rest_y
	var pressed_scale: Vector2 = rest_scale * Vector2(0.94, 0.70)
	var overshoot_scale: Vector2 = rest_scale * Vector2(1.05, 1.08)
	var tween: Tween = create_tween()
	icon.set_meta("hint_bounce_tween", tween)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", pressed_scale, 0.05)
	tween.parallel().tween_property(icon, "position:y", rest_y + 5.0, 0.05)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", overshoot_scale, 0.09)
	tween.parallel().tween_property(icon, "position:y", rest_y - 3.0, 0.09)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", rest_scale, 0.08)
	tween.parallel().tween_property(icon, "position:y", rest_y, 0.08)
	tween.finished.connect(func() -> void:
		icon.scale = rest_scale
		icon.position.y = rest_y
		if icon.has_meta("hint_bounce_tween"):
			icon.remove_meta("hint_bounce_tween")
	)


func _load_texture_if_exists(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = load(path)
	if loaded is Texture2D:
		return loaded as Texture2D
	return null


func _load_key_from_sheet(column: int, row: int) -> Texture2D:
	var sheet_path: String = "res://assets/ui/keyboard-keys-sheet.png"
	if not ResourceLoader.exists(sheet_path):
		return null
	var sheet: Texture2D = load(sheet_path) as Texture2D
	if sheet == null:
		return null
	var columns: int = 8
	var rows: int = 6
	var cell_w: float = float(sheet.get_width()) / float(columns)
	var cell_h: float = float(sheet.get_height()) / float(rows)
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(column * cell_w, row * cell_h, cell_w, cell_h)
	return atlas


func flash_twins_hit(hit_color: Color) -> void:
	if twins_hit_flash_tween != null and twins_hit_flash_tween.is_valid():
		twins_hit_flash_tween.kill()
	for sprite in [smoke_sprite, stack_sprite]:
		if sprite != null and sprite.visible:
			sprite.modulate = hit_color
	twins_hit_flash_tween = create_tween()
	twins_hit_flash_tween.tween_interval(0.22)
	twins_hit_flash_tween.tween_callback(restore_twins_hit_flash)


func restore_twins_hit_flash() -> void:
	if smoke_sprite != null and smoke_sprite.visible:
		smoke_sprite.modulate = Color.WHITE
	if stack_sprite != null and stack_sprite.visible:
		stack_sprite.modulate = Color.WHITE


func _update_twins_mode_hints() -> void:
	if twins_hints_root == null:
		return
	var show_hints: bool = _is_stack_character()
	twins_hints_root.visible = show_hints
	if not show_hints:
		return
	var stack_solo: bool = twins_display_mode == TwinsDisplayMode.STACK_SOLO
	if twins_hint_charge_row != null:
		twins_hint_charge_row.visible = stack_solo
	if twins_hint_charge_label != null:
		twins_hint_charge_label.text = "Charged Attacks Only"
		twins_hint_charge_label.modulate = Color(1.0, 0.92, 0.55, 1.0) if stack_solo else Color(0.94, 0.94, 0.98, 0.96)
	if twins_hint_charge_icon != null:
		twins_hint_charge_icon.modulate = Color(1.12, 1.08, 0.82, 1.0) if stack_solo else Color.WHITE
	if twins_hint_t_label != null:
		match twins_display_mode:
			TwinsDisplayMode.SMOKE_SOLO:
				twins_hint_t_label.text = "Switch Stack"
			TwinsDisplayMode.DUO:
				twins_hint_t_label.text = "Pick Twin"
			_:
				twins_hint_t_label.text = "Switch Smoke"
	if twins_hint_m_label != null:
		if twins_display_mode == TwinsDisplayMode.DUO:
			twins_hint_m_label.text = "Solo Stack"
			twins_hint_m_label.modulate = Color(1.0, 0.92, 0.55, 1.0)
		else:
			twins_hint_m_label.text = "Duo Mode"
			twins_hint_m_label.modulate = Color(0.94, 0.94, 0.98, 0.96)
	if twins_hint_m_icon != null:
		twins_hint_m_icon.modulate = Color(1.18, 1.12, 0.82, 1.0) if twins_display_mode == TwinsDisplayMode.DUO else Color.WHITE


func _update_prince_ui() -> void:
	var is_prince: bool = current_character_id == "prince"
	if prince_stamina_bar_root != null:
		prince_stamina_bar_root.visible = false
		prince_stamina_bar_root.position = Vector2(18.0, get_viewport().size.y - 72.0)
	if prince_stamina_bar != null:
		prince_stamina_bar.max_value = prince_max_stamina
		prince_stamina_bar.value = prince_stamina
	if caraxes_icon_root != null:
		caraxes_icon_root.visible = is_prince
		caraxes_icon_root.position = Vector2(get_viewport().size.x - 86.0, get_viewport().size.y - 90.0)
	if caraxes_icon != null:
		caraxes_icon.texture = caraxes_icon_texture
		caraxes_icon.modulate = Color.WHITE if caraxes_cooldown_remaining <= 0.0 else Color(0.52, 0.52, 0.52, 1.0)
	if caraxes_cooldown_overlay != null:
		caraxes_cooldown_overlay.visible = is_prince and caraxes_cooldown_remaining > 0.0
	if caraxes_cooldown_label != null:
		caraxes_cooldown_label.visible = is_prince and caraxes_cooldown_remaining > 0.0
		caraxes_cooldown_label.text = str(ceili(caraxes_cooldown_remaining))


func _setup_prince_sword() -> void:
	prince_sword = SWORD_WEAPON_SCRIPT.new()
	prince_sword.set("slash_damage", prince_slash_damage)
	prince_sword.set("slash_range", prince_slash_range)
	prince_sword.set("slash_arc", prince_slash_arc)
	prince_sword.set("slash_cooldown", prince_slash_cooldown)
	prince_sword.set("slash_stamina_cost", prince_slash_stamina_cost)
	prince_sword.set("max_stamina", prince_max_stamina)
	prince_sword.set("stamina_regen_rate", prince_stamina_regen_rate)
	prince_sword.set("can_combo", true)


func _update_motion_direction() -> void:
	if player == null:
		return
	var delta: Vector2 = player.global_position - player_last_position
	player_last_position = player.global_position
	if delta.length() > 0.001:
		player_motion_dir = delta.normalized()


func cancel_active_charge() -> void:
	attack_holding = false
	attack_hold_elapsed = 0.0
	_end_charge_mode(false)
	hero_cancel_hold_attack()
	if hero_release_beam_active:
		hero_release_beam_active = false
		hero_release_beam_start_width = 0.0
		if world != null and world.has_method("unlock_player_shoot_animation"):
			world.call("unlock_player_shoot_animation")
	_clear_hero_beam()
