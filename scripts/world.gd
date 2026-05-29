extends Node2D

# Godot 4 single-file isometric world script.
# Attach this to your root World Node2D.

const WEAPON_MANAGER_SCRIPT: Script = preload("res://scripts/weapons/WeaponManager.gd")
const CHARACTER_CONTROLLER_SCRIPT: Script = preload("res://scripts/characters/CharacterController.gd")
const MIRROR_ANIMATION_HELPER_SCRIPT: Script = preload("res://scripts/characters/MirrorAnimationHelper.gd")
const SLIME_MOB_SCRIPT: Script = preload("res://scripts/mobs/SlimeMob.gd")
const BASE_ENEMY_SCRIPT: Script = preload("res://scripts/mobs/BaseEnemy.gd")
const SHELLCLOAK_ORACLE_SCRIPT: Script = preload("res://scripts/mobs/ShellcloakOracle.gd")
const LAMBENT_IDOL_SCRIPT: Script = preload("res://scripts/mobs/LambentIdol.gd")
const BELLPILGRIM_CRAWLER_SCRIPT: Script = preload("res://scripts/mobs/BellpilgrimCrawler.gd")
const ROOTBOUND_ACOLYTE_SCRIPT: Script = preload("res://scripts/mobs/RootboundAcolyte.gd")
const MOTHCLOAK_PRIEST_SCRIPT: Script = preload("res://scripts/mobs/MothcloakPriest.gd")
const MULTIEYE_CHERUB_SCRIPT: Script = preload("res://scripts/mobs/MultieyeCherub.gd")
const PETALWRETCH_OOZE_SCRIPT: Script = preload("res://scripts/mobs/PetalwretchOoze.gd")
const BLOOMMAW_LURKER_SCRIPT: Script = preload("res://scripts/mobs/BloommawLurker.gd")
const FLOWER_GUN_SCRIPT: Script = preload("res://scripts/weapons/FlowerGun.gd")
const MICHAEL_GUN_SCRIPT: Script = preload("res://scripts/weapons/MichaelGun.gd")
const DEFAULT_OST_STREAM: AudioStream = preload("res://assets/audio/Cradle.wav")
const DEFAULT_OST_CD_TEXTURE: Texture2D = preload("res://assets/ui/ost-cd.png")
const DEFAULT_SLIME_TEXTURE_PATH: String = "res://assets/mobs/slime-mob.png"
const EXTERNAL_OST_WAV_PATH: String = "/Users/someoneguy/Desktop/As the Clocks Tick.wav"

class MiniMapDrawer:
	extends Control

	var world: Node = null
	var minimap_size: Vector2 = Vector2(220, 220)
	var expanded_size: Vector2 = Vector2(620, 620)
	var tile_scale: float = 1.15
	var expanded_tile_scale: float = 2.35

	func _ready() -> void:
		custom_minimum_size = minimap_size
		size = minimap_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(_delta: float) -> void:
		if world == null:
			return

		# Pull customizable minimap size/placement values from the main world script every frame.
		minimap_size = world.minimap_small_size
		expanded_size = world.minimap_large_size
		tile_scale = world.minimap_small_tile_scale
		expanded_tile_scale = world.minimap_large_tile_scale

		visible = world.game_started and not world.is_dead
		if not visible:
			return

		var target_size: Vector2 = minimap_size
		var target_position: Vector2 = world.minimap_small_position
		if world.minimap_expanded:
			target_size = expanded_size
			target_position = world.minimap_large_position

		var viewport_size: Vector2 = get_viewport_rect().size
		var edge_margin: Vector2 = Vector2(10.0, 10.0)
		var max_size: Vector2 = Vector2(
			maxf(80.0, viewport_size.x - edge_margin.x * 2.0),
			maxf(80.0, viewport_size.y - edge_margin.y * 2.0)
		)
		if target_size.x > max_size.x or target_size.y > max_size.y:
			var fit_scale: float = minf(max_size.x / maxf(1.0, target_size.x), max_size.y / maxf(1.0, target_size.y))
			target_size *= clampf(fit_scale, 0.1, 1.0)
		var max_pos: Vector2 = viewport_size - target_size - edge_margin
		target_position.x = clampf(target_position.x, edge_margin.x, maxf(edge_margin.x, max_pos.x))
		target_position.y = clampf(target_position.y, edge_margin.y, maxf(edge_margin.y, max_pos.y))

		position = position.lerp(target_position, world.minimap_animation_speed)
		if position.distance_to(target_position) < 1.0:
			position = target_position

		# Important: do NOT set custom_minimum_size to the current animated size.
		# A large minimum size prevents the minimap from shrinking again after expansion.
		custom_minimum_size = Vector2.ZERO
		size = size.lerp(target_size, 0.22)
		if size.distance_to(target_size) < 1.0:
			size = target_size
		queue_redraw()

	func _draw() -> void:
		if world == null:
			return

		var is_expanded: bool = world.minimap_expanded
		var map_size: Vector2 = size
		var scale_value: float = tile_scale
		if is_expanded:
			scale_value = expanded_tile_scale

		var bg_alpha: float = 0.88
		if is_expanded:
			bg_alpha = 0.94

		var bg_color: Color = world.minimap_background_color
		bg_color.a = bg_alpha
		draw_rect(Rect2(Vector2.ZERO, map_size), bg_color, true)
		draw_rect(Rect2(Vector2.ZERO, map_size), world.minimap_border_color, false, world.minimap_border_width)

		var player_tile: Vector2i = world.current_tile
		var center: Vector2 = map_size / 2.0

		if is_expanded and not world.walkable_tiles.is_empty():
			var bounds: Rect2i = world.get_walkable_bounds()
			var bounds_center: Vector2 = Vector2(float(bounds.position.x) + float(bounds.size.x) * 0.5, float(bounds.position.y) + float(bounds.size.y) * 0.5)
			center = map_size / 2.0 - bounds_center * scale_value

		for cell_variant in world.walkable_tiles.keys():
			var cell: Vector2i = cell_variant
			var is_revealed: bool = world.revealed_tiles.has(cell)
			var is_recent: bool = world.visible_tiles.has(cell)

			var pos: Vector2
			if is_expanded:
				pos = center + Vector2(float(cell.x), float(cell.y)) * scale_value
			else:
				pos = center + Vector2(float(cell.x - player_tile.x), float(cell.y - player_tile.y)) * scale_value

			if pos.x < 2.0 or pos.y < 2.0 or pos.x > map_size.x - 2.0 or pos.y > map_size.y - 2.0:
				continue

			if not is_revealed:
				continue

			var col: Color = world.minimap_grass_color
			if world.road_tiles.has(cell):
				col = world.minimap_road_color

			if not is_recent:
				col = col.darkened(0.38)
				col.a *= 0.64

			draw_rect(Rect2(pos, Vector2(scale_value + 0.65, scale_value + 0.65)), col, true)

		# Soft fog-of-war layer over unexplored/old sections.
		for cell_variant in world.walkable_tiles.keys():
			var cell2: Vector2i = cell_variant
			var pos2: Vector2
			if is_expanded:
				pos2 = center + Vector2(float(cell2.x), float(cell2.y)) * scale_value
			else:
				pos2 = center + Vector2(float(cell2.x - player_tile.x), float(cell2.y - player_tile.y)) * scale_value

			if pos2.x < 2.0 or pos2.y < 2.0 or pos2.x > map_size.x - 2.0 or pos2.y > map_size.y - 2.0:
				continue

			if not world.revealed_tiles.has(cell2):
				if is_expanded:
					draw_rect(Rect2(pos2, Vector2(scale_value + 0.65, scale_value + 0.65)), world.minimap_unrevealed_fog_color, true)
			elif not world.visible_tiles.has(cell2):
				draw_rect(Rect2(pos2, Vector2(scale_value + 0.65, scale_value + 0.65)), world.minimap_memory_fog_color, true)

		for key_cell in world.key_tiles:
			if world.collected_keys.has(key_cell):
				continue
			if not world.revealed_tiles.has(key_cell):
				continue

			var key_pos: Vector2
			if is_expanded:
				key_pos = center + Vector2(float(key_cell.x), float(key_cell.y)) * scale_value
			else:
				key_pos = center + Vector2(float(key_cell.x - player_tile.x), float(key_cell.y - player_tile.y)) * scale_value
			draw_circle(key_pos, 3.4 if not is_expanded else 5.2, world.minimap_key_color)

		if world.goal_tile != Vector2i.ZERO and world.revealed_tiles.has(world.goal_tile):
			var door_pos: Vector2
			if is_expanded:
				door_pos = center + Vector2(float(world.goal_tile.x), float(world.goal_tile.y)) * scale_value
			else:
				door_pos = center + Vector2(float(world.goal_tile.x - player_tile.x), float(world.goal_tile.y - player_tile.y)) * scale_value
			draw_circle(door_pos, 3.8 if not is_expanded else 6.0, world.minimap_goal_color)

		var player_pos: Vector2 = center
		if is_expanded:
			player_pos = center + Vector2(float(player_tile.x), float(player_tile.y)) * scale_value

		draw_circle(player_pos, world.minimap_player_radius if not is_expanded else world.minimap_player_radius * 1.45, world.minimap_player_color)
		for id_variant in world.remote_players.keys():
			var remote_id: int = int(id_variant)
			var ghost: Node2D = world.remote_players[remote_id] as Node2D
			if ghost == null or not is_instance_valid(ghost):
				continue

			var remote_tile: Vector2i = world.world_to_tile(ghost.global_position)
			if not world.revealed_tiles.has(remote_tile):
				continue

			var friend_pos: Vector2
			if is_expanded:
				friend_pos = center + Vector2(float(remote_tile.x), float(remote_tile.y)) * scale_value
			else:
				friend_pos = center + Vector2(float(remote_tile.x - player_tile.x), float(remote_tile.y - player_tile.y)) * scale_value

			if friend_pos.x < 2.0 or friend_pos.y < 2.0 or friend_pos.x > map_size.x - 2.0 or friend_pos.y > map_size.y - 2.0:
				continue

			var friend_radius: float = world.minimap_remote_player_radius if not is_expanded else world.minimap_remote_player_radius * 1.45
			draw_circle(friend_pos, friend_radius, world.minimap_friend_color)
			draw_arc(friend_pos, friend_radius + 1.5, 0.0, TAU, 12, world.minimap_friend_outline_color, 1.2, true)

		if world.enable_minimap_scanline and world.game_started:
			var sweep_y: float = fmod(world.elapsed_time * 48.0, maxf(1.0, map_size.y))
			draw_rect(Rect2(Vector2(0.0, sweep_y), Vector2(map_size.x, 2.0)), world.minimap_scanline_color, true)
			draw_rect(Rect2(Vector2(0.0, sweep_y - 7.0), Vector2(map_size.x, 14.0)), Color(world.minimap_scanline_color.r, world.minimap_scanline_color.g, world.minimap_scanline_color.b, world.minimap_scanline_color.a * 0.25), true)

		if is_expanded:
			draw_string(get_theme_default_font(), Vector2(18.0, map_size.y - 20.0), "T / ESC: close map", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(1.0, 0.94, 0.68, 0.9))
		else:
			draw_string(get_theme_default_font(), Vector2(12.0, map_size.y - 10.0), "T", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(1.0, 0.94, 0.68, 0.75))


@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: Node2D = $Player
@onready var player_sprite: AnimatedSprite2D = $Player/AnimatedSprite2D
@onready var click_marker: Sprite2D = $ClickMarker

var deco_layer: TileMapLayer = null
var island_shadow_layer: TileMapLayer = null
var camera: Camera2D = null
var home_screen: Control = null
var death_screen: Control = null
var menu_layer: CanvasLayer = null
var start_button: Button = null
var quit_button: Button = null
var retry_button: Button = null
var home_button: Button = null
var multiplayer_button: Button = null
var haven_hint_label: Label = null
var controls_help_panel: Control = null
var controls_help_visible: bool = false
var key_hint_bar: Control = null
var mp_panel: Control = null
var mp_name_field: LineEdit = null
var mp_room_field: LineEdit = null
var mp_status_label: Label = null
var mp_join_button: Button = null
var health_back: ColorRect = null
var health_fill: ColorRect = null
var health_bar_root: Node2D = null
var health_hearts: Array[Sprite2D] = []
var local_health_ui_root: Node2D = null
var local_health_ui_hearts: Array[Sprite2D] = []
var heart_full_texture: Texture2D = null
var heart_empty_texture: Texture2D = null
var minimap: MiniMapDrawer = null
var canvas_modulate: CanvasModulate = null
var player_light: PointLight2D = null
var ui_layer: CanvasLayer = null
var level_label: Label = null
var key_label: Label = null
var map_button: Button = null
var tutorial_panel: Control = null
var tutorial_title: Label = null
var tutorial_subtitle: Label = null
var tutorial_key_icon: TextureRect = null
var objective_arrow: Label = null
var objective_text: Label = null
var combo_label: Label = null
var level_banner: Label = null
var atmosphere_layer: CanvasLayer = null
var vignette_rect: ColorRect = null
var darkness_rect: ColorRect = null
var fog_rect_1: ColorRect = null
var fog_rect_2: ColorRect = null
var fog_rect_3: ColorRect = null
var particle_root: Node2D = null
var dust_particles: CPUParticles2D = null
var leaf_particles: CPUParticles2D = null
var firefly_particles: CPUParticles2D = null
var low_mist_particles: CPUParticles2D = null
var key_wisp_particles: CPUParticles2D = null
var letterbox_top: ColorRect = null
var letterbox_bottom: ColorRect = null
var light_sweep_rect: ColorRect = null
var sharpness_rect: ColorRect = null
var film_grain_rect: ColorRect = null
var god_rays_rect: ColorRect = null
var cloud_shadow_rect: ColorRect = null
var color_grade_rect: ColorRect = null
var sun_glow_rect: ColorRect = null
var void_shimmer_rect: ColorRect = null
var edge_haze_rect: ColorRect = null
var map_scan_rect: ColorRect = null
var focus_spotlight_rect: ColorRect = null
var chromatic_edge_rect: ColorRect = null
var color_pop_rect: ColorRect = null
var depth_shadow_rect: ColorRect = null
var warm_corner_glow_rect: ColorRect = null
var texture_lines_rect: ColorRect = null
var magic_sparkle_particles: CPUParticles2D = null
var floating_pollen_particles: CPUParticles2D = null
var foreground_mist_particles: CPUParticles2D = null
var player_rim_light: PointLight2D = null
var player_halo: Sprite2D = null
var breadcrumb_root: Node2D = null
var locked_hint_cooldown: float = 0.0
var key_combo_timer: float = 0.0
var key_combo_count: int = 0
var objective_ping_tween: Tween = null
var click_marker_light: PointLight2D = null
var background_layer: CanvasLayer = null
var background_sprite: Sprite2D = null
var weapon_manager: Node = null
var character_controller: Node = null
var equipped_weapon: Node = null
var music_player: AudioStreamPlayer = null
var music_widget: Control = null
var music_cd_icon: TextureRect = null
var music_title_label: Label = null
var screen_flash_rect: ColorRect = null
var intro_cutscene_root: Control = null
var intro_cutscene_image: TextureRect = null
var intro_cutscene_text: Label = null
var intro_cutscene_prompt: Label = null
var intro_cutscene_prompt_icon: TextureRect = null
var intro_cutscene_fade: ColorRect = null
var aim_cone_node: Polygon2D = null
var soundtrack_playlist: Array[AudioStream] = []
var soundtrack_titles: Array[String] = []
var soundtrack_index: int = -1
var external_ost_stream: AudioStream = null

@export_group("Player Animation SpriteFrames")
@export var player_default_walk_frames: SpriteFrames = null
@export var player_with_gun_shoot_frames: SpriteFrames = null
@export var player_flower_shoot_frames: SpriteFrames = null
@export var player_michael_jackson_walk_frames: SpriteFrames = null
@export var player_michael_jackson_shoot_frames: SpriteFrames = null
@export var michael_jackson_walk_scale: Vector2 = Vector2(1.0, 1.0)
@export var michael_jackson_shoot_scale: Vector2 = Vector2(1.5, 1.5)

@export_group("Character System")
@export_enum("classic", "hero", "prince") var selected_character_id: String = "classic"
@export var hero_walk_frames: SpriteFrames = null
@export var hero_shoot_frames: SpriteFrames = null
@export var smoke_walk_frames: SpriteFrames = null
@export var smoke_shoot_frames: SpriteFrames = null
@export var stack_walk_frames: SpriteFrames = null
@export var stack_shoot_frames: SpriteFrames = null
@export var prince_walk_frames: SpriteFrames = null
@export var prince_slash_frames: SpriteFrames = null
@export var prince_summoning_frames: SpriteFrames = null
@export var caraxes_summoning_frames: SpriteFrames = null
@export var hero_charge_icon_texture: Texture2D = null
@export var caraxes_icon_texture: Texture2D = null
@export var laser_beam_offset_x: float = 0.0
@export var laser_beam_offset_y: float = 0.0
@export var laser_start_offset_x: float = 0.0
@export var laser_start_offset_y: float = 0.0
@export var laser_spawn_delay: float = 0.0
@export var hero_laser_offset_right: Vector2 = Vector2(18.0, -18.0)
@export var hero_laser_offset_left: Vector2 = Vector2(-18.0, -18.0)
@export var hero_laser_offset_up: Vector2 = Vector2(0.0, -26.0)
@export var hero_laser_offset_down: Vector2 = Vector2(0.0, -10.0)

@export_group("Aiming Cone")
@export var aiming_cone_enabled: bool = false
@export var aiming_cone_length: float = 96.0
@export var aiming_cone_angle_degrees: float = 38.0
@export var aiming_cone_color: Color = Color(1.0, 0.86, 0.42, 0.22)
@export var aiming_cone_idle_alpha: float = 0.08
@export var aiming_cone_active_alpha: float = 0.26

@export_group("Flower Weapon Animation Settings")
@export var flower_small_projectile_frames: SpriteFrames = null
@export var flower_charged_projectile_frames: SpriteFrames = null
@export var flower_explosion_animation_frames: SpriteFrames = null
@export var flower_weapon_icon_texture: Texture2D = null
@export var flower_weapon_floor_texture: Texture2D = null

@export_group("Flower Weapon Runtime Settings")
@export var flower_base_damage: float = 4.0
@export var flower_base_fire_rate: float = 0.15
@export var flower_base_charge_time: float = 1.25
@export var flower_base_charge_damage_multiplier: float = 3.9
@export var flower_base_projectile_speed: float = 510.0
@export var flower_base_spawn_distance: float = 30.0
@export var flower_base_spawn_y_offset: float = -10.0
@export var flower_small_petal_speed: float = 530.0
@export var flower_small_petal_size: Vector2 = Vector2(0.9, 0.9)
@export var flower_small_petal_damage: float = 5.0
@export var flower_small_petal_lifetime: float = 1.15
@export var flower_small_petal_hit_radius: float = 7.0
@export var flower_big_petal_speed: float = 320.0
@export var flower_big_petal_size: Vector2 = Vector2(1.55, 1.55)
@export var flower_big_petal_damage: float = 12.0
@export var flower_big_petal_lifetime: float = 1.45
@export var flower_big_petal_hit_radius: float = 18.0
@export var flower_explosion_radius: float = 56.0
@export var flower_explosion_damage: float = 16.0
@export var flower_explosion_duration: float = 0.35
@export var flower_explosion_scale: Vector2 = Vector2(1.2, 1.2)
@export var flower_floor_weapon_scale: Vector2 = Vector2(0.56, 0.56)

var player_has_weapon: bool = false
var current_character_id: String = "classic"
var character_walk_frames_override: SpriteFrames = null
var character_shoot_frames_override: SpriteFrames = null
var character_walk_scale_override: Vector2 = Vector2.ONE
var character_shoot_scale_override: Vector2 = Vector2.ONE
var shoot_anim_timer: float = 0.0
const SHOOT_ANIM_DURATION: float = 0.22
var player_shoot_anim_locked: bool = false
var player_shoot_anim_freeze_frame: int = -1
const BIG_LASER_SHOOT_FREEZE_FRAME: int = 2
var player_charge_visual_active: bool = false
var player_charge_direction: String = "down"
var player_charge_shake_time: float = 0.0
var player_charge_fully_charged: bool = false
var mob_root: Node2D = null
var player_sprite_base_position: Vector2 = Vector2.ZERO
var player_sprite_base_scale: Vector2 = Vector2.ONE
var player_sprite_scale_compensation: Vector2 = Vector2.ZERO
var intro_cutscene_active: bool = false
var intro_cutscene_slide_index: int = 0
var intro_spacebar_rest_scale: Vector2 = Vector2(0.97, 0.97)
var intro_spacebar_rest_offset_top: float = -117.0
var intro_spacebar_rest_offset_bottom: float = -16.0
var intro_spacebar_press_tween: Tween = null
var intro_spacebar_is_down: bool = false
var intro_spacebar_last_advance_ms: int = 0

const GROUND_SOURCE_ID: int = 1
const TILE_ALTERNATIVE: int = 0
const MAX_WORLD_STAGE: int = 5
const NEW_TILE_SHEET_PATH: String = "res://assets/tiles/new-tile-sheet.png"
const WORLD_TREES_TEXTURE_PATH: String = "res://assets/trees/world-trees.png"
const NEW_TILE_ATLAS_CELL_SIZE: Vector2i = Vector2i(64, 64)

const ATLAS_KEY: Vector2i = Vector2i(8, 2)
const ATLAS_LOCKED_DOOR: Vector2i = Vector2i(11, 2)
const ATLAS_OPEN_DOOR: Vector2i = Vector2i(13, 2)
const ATLAS_STATUE: Vector2i = Vector2i(6, 2)
const ATLAS_PILLAR: Vector2i = Vector2i(7, 2)
const ATLAS_PEDESTAL: Vector2i = Vector2i(15, 2)

@export var auto_start_for_testing: bool = false
@export var debug_tiles: bool = true
@export var background_texture: Texture2D = null
@export var background_texture_path: String = "res://assets/background/world1_background_texture.png"
@export var map_width: int = 320
@export var map_height: int = 320
## Multiplies room sizes and corridor spacing so the explorable area scales up.
## ~1.45 roughly doubles the playable footprint (area scales with the square of this).
@export_range(1.0, 2.0, 0.01) var playable_area_scale: float = 1.45
@export_range(12, 48, 1) var world_edge_buffer_tiles: int = 24
@export var move_speed: float = 290.0
@export_group("Haven Layout")
@export_range(24, 140, 1) var haven_circle_radius: int = 68
@export_range(6, 140, 1) var haven_cross_half_length: int = 58
@export_range(1, 18, 1) var haven_cross_half_width: int = 3
@export_range(8, 120, 1) var haven_gap_offset: int = 34
@export_range(4, 40, 1) var haven_gap_radius: int = 13
@export_range(0.4, 1.2, 0.01) var haven_camera_zoom: float = 0.72
@export_range(1.0, 4.0, 0.05) var haven_click_speed_multiplier: float = 1.85
@export var haven_tilesheet_res_path: String = "res://assets/tiles/erhaven-tilesheet.png"
@export var haven_tilesheet_file_path: String = "/Users/someoneguy/.cursor/projects/Users-someoneguy-Desktop-the-ruins-that-breathe/assets/erhaven-tilesheet-51bd113d-91e5-496e-9baa-5a47a268315a.png"
@export var haven_structure_scale: float = 0.55
@export var haven_shop_character_costs: PackedInt32Array = PackedInt32Array([120, 200, 320])
@export var cursor_follow_deadzone: float = 14.0
@export var tile_visual_offset: Vector2 = Vector2.ZERO
@export var max_health: float = 100.0
@export var camera_smooth_speed: float = 7.5
@export var enable_cursor_follow: bool = false
@export_group("Progression / Difficulty")
@export_range(1.0, 2.0, 0.01) var level_size_multiplier: float = 1.20
@export var base_main_room_count: int = 10
@export var base_side_room_count: int = 6
@export_range(0.0, 2.0, 0.01) var key_count_growth: float = 0.35

@export_group("Minimap Fog / Reveal")
@export var minimap_reveal_radius: int = 10
@export var minimap_recent_radius: int = 6
@export var minimap_expanded: bool = false
@export_group("Minimap Layout / Customization")
@export var minimap_small_position: Vector2 = Vector2(18.0, 18.0)
@export var minimap_large_position: Vector2 = Vector2(120.0, 80.0)
@export var minimap_small_size: Vector2 = Vector2(220.0, 220.0)
@export var minimap_large_size: Vector2 = Vector2(620.0, 620.0)
@export_range(0.25, 8.0, 0.01) var minimap_small_tile_scale: float = 1.15
@export_range(0.25, 8.0, 0.01) var minimap_large_tile_scale: float = 2.35
@export_range(0.01, 1.0, 0.01) var minimap_animation_speed: float = 0.22
@export_range(1.0, 8.0, 0.25) var minimap_border_width: float = 2.0
@export_range(1.0, 14.0, 0.1) var minimap_player_radius: float = 5.0
@export_range(1.0, 14.0, 0.1) var minimap_remote_player_radius: float = 4.3
@export var map_button_position: Vector2 = Vector2(28.0, 318.0)
@export var map_button_size: Vector2 = Vector2(112.0, 34.0)
@export var local_health_ui_top_right_margin: Vector2 = Vector2(24.0, 18.0)
@export_group("Minimap Fog / Reveal")
@export var minimap_background_color: Color = Color(0.01, 0.01, 0.012, 0.90)
@export var minimap_border_color: Color = Color(0.78, 0.70, 0.38, 0.45)
@export var minimap_unrevealed_fog_color: Color = Color(0.0, 0.0, 0.0, 0.92)
@export var minimap_memory_fog_color: Color = Color(0.02, 0.03, 0.04, 0.46)
@export var minimap_grass_color: Color = Color(0.40, 0.55, 0.30, 0.72)
@export var minimap_road_color: Color = Color(0.58, 0.46, 0.28, 0.76)
@export var minimap_player_color: Color = Color(0.10, 0.85, 1.0, 1.0)
@export var minimap_friend_color: Color = Color(0.44, 1.0, 0.64, 1.0)
@export var minimap_friend_outline_color: Color = Color(0.04, 0.16, 0.08, 0.95)
@export var minimap_key_color: Color = Color(1.0, 0.85, 0.10, 1.0)
@export var minimap_goal_color: Color = Color(0.68, 0.30, 1.0, 1.0)

@export_group("Tutorial / Objective UI")
@export var show_level_intro_popup: bool = true
@export var level_intro_duration: float = 3.2
@export var objective_arrow_enabled: bool = true
@export var key_pickup_text_enabled: bool = true
@export var map_toggle_key_text: String = "T"
@export var level_intro_title_text: String = "GET THE KEYS"
@export var level_intro_subtitle_text: String = "Find keys like this to unlock the door."

@export_group("Intro Cutscene")
@export var enable_intro_cutscene: bool = true
@export var intro_continue_prompt: String = "Press SPACE"
@export var intro_continue_icon_texture: Texture2D = null
@export var intro_continue_icon_file: String = "/Users/someoneguy/.cursor/projects/Users-someoneguy-Desktop-the-ruins-that-breathe/assets/space-7854afd8-6115-4664-a281-34d237d7e3e5.png"
@export var intro_cutscene_slide_1: Texture2D = null
@export var intro_cutscene_slide_2: Texture2D = null
@export var intro_cutscene_slide_3: Texture2D = null
@export var intro_cutscene_slide_4: Texture2D = null
@export var intro_cutscene_slide_5: Texture2D = null
@export var intro_cutscene_image_files: PackedStringArray = PackedStringArray([
	"/Users/someoneguy/.cursor/projects/Users-someoneguy-Desktop-the-ruins-that-breathe/assets/1-export-a37d0de1-100b-49eb-b8e8-a8d58c1ecd85.png",
	"/Users/someoneguy/.cursor/projects/Users-someoneguy-Desktop-the-ruins-that-breathe/assets/2-export-015b826a-04cc-4184-a38f-7ad3fd12e23e.png",
	"/Users/someoneguy/.cursor/projects/Users-someoneguy-Desktop-the-ruins-that-breathe/assets/3-export-4c87f426-3908-49f1-97b9-4d2604eada53.png",
	"/Users/someoneguy/.cursor/projects/Users-someoneguy-Desktop-the-ruins-that-breathe/assets/4-export-b61278ec-7cf1-41f2-8a78-e4b7565b8cb7.png",
	"/Users/someoneguy/.cursor/projects/Users-someoneguy-Desktop-the-ruins-that-breathe/assets/5-export-2e32a2b3-ccec-466e-8962-5611429173ea.png"
])
@export var intro_cutscene_texts: PackedStringArray = PackedStringArray([
	"In an age of fractured kingdoms, the ruins still breathed beneath a fading sun.",
	"A nameless wanderer rose from quiet grass, called by an oath they could not remember.",
	"From blossom and steel, a relic answered their hand: a flower-gun blooming with light.",
	"Each shot carved petals through the dusk, and each charge promised ruin to what lurked ahead.",
	"Now the path is sealed by monsters and keys of old. Step forward, and survive the breathing ruins."
])

@export_group("Music / Soundtrack")
@export var enable_music: bool = true
@export var menu_music: AudioStream = null
@export var gameplay_music: AudioStream = null
@export var stage_music_tracks: Array[AudioStream] = []
@export var default_song_title: String = "Untitled Track"
@export var show_music_widget: bool = true
@export var music_widget_position: Vector2 = Vector2(28.0, 402.0)
@export var music_widget_size: Vector2 = Vector2(250.0, 42.0)
@export var music_widget_scale: float = 1.0
@export var cd_disc_texture: Texture2D = null
@export var music_volume: float = 0.7
@export var song_title_prefix: String = "Now Playing: "
@export_range(0.0, 6.0, 0.01) var cd_spin_speed: float = 1.2
@export_range(0.0, 18.0, 0.1) var cd_max_x_offset: float = 2.0
@export_range(0.0, 8.0, 0.01) var cd_hover_strength: float = 1.2
@export_range(0.0, 8.0, 0.01) var cd_hover_speed: float = 1.6
@export var cd_enable_color_hue_shift: bool = false

@export_group("Extra Gameplay Polish")
@export var enable_screen_shake_on_key: bool = true
@export var enable_player_step_dust: bool = true
@export var step_dust_interval: float = 0.18
@export var enable_goal_pulse: bool = true
@export_range(0.0, 20.0, 0.1) var key_screen_shake_strength: float = 4.0
@export_range(0.0, 1.0, 0.01) var key_screen_shake_duration: float = 0.12
@export_range(0.0, 20.0, 0.1) var door_open_screen_shake_strength: float = 7.0
@export_range(0.0, 1.0, 0.01) var door_open_screen_shake_duration: float = 0.20
@export var close_expanded_map_with_escape: bool = true
@export var objective_ping_key_text: String = "R"

@export_group("Click Marker Customization")
@export var click_marker_color: Color = Color(1.0, 0.82, 0.22, 0.42)
@export var click_marker_glow_color: Color = Color(1.0, 0.72, 0.12, 0.45)
@export var blocked_marker_color: Color = Color(1.0, 0.22, 0.24, 0.82)
@export var blocked_marker_glow_color: Color = Color(1.0, 0.08, 0.08, 0.95)
@export_range(0.05, 2.0, 0.01) var blocked_marker_fade_time: float = 0.24
@export_range(0.1, 2.0, 0.01) var click_marker_start_scale: float = 0.62
@export_range(0.1, 2.0, 0.01) var click_marker_end_scale: float = 0.86
@export_range(0.1, 2.0, 0.01) var click_marker_pulse_big_scale: float = 0.93
@export_range(0.1, 2.0, 0.01) var click_marker_pulse_small_scale: float = 0.80
@export_range(0.0, 1.0, 0.01) var click_marker_alpha: float = 0.38
@export_range(0.05, 2.0, 0.01) var click_marker_fade_in_time: float = 0.14
@export_range(0.1, 3.0, 0.01) var click_marker_pulse_time: float = 0.62
@export var enable_click_marker_light: bool = true
@export_range(0.0, 3.0, 0.01) var click_marker_light_energy: float = 0.18
@export_range(0.1, 4.0, 0.01) var click_marker_light_scale: float = 0.80

@export_group("Extra Visual Features")
@export var enable_fireflies: bool = true
@export var firefly_count: int = 28
@export var firefly_color: Color = Color(1.0, 0.88, 0.38, 0.36)
@export var enable_low_mist: bool = true
@export var low_mist_count: int = 34
@export var low_mist_color: Color = Color(0.58, 0.72, 0.86, 0.12)
@export var enable_cinematic_letterbox: bool = true
@export_range(0.0, 80.0, 1.0) var letterbox_height: float = 28.0
@export var letterbox_color: Color = Color(0.0, 0.0, 0.0, 0.36)
@export var enable_light_sweep: bool = true
@export var light_sweep_color: Color = Color(1.0, 0.86, 0.42, 0.08)
@export var enable_key_wisps: bool = true
@export var key_wisp_color: Color = Color(1.0, 0.84, 0.22, 0.55)
@export var enable_breadcrumb_trail: bool = true
@export_range(0.05, 1.0, 0.01) var breadcrumb_interval: float = 0.24
@export var breadcrumb_color: Color = Color(1.0, 0.80, 0.24, 0.22)
@export var enable_level_banner: bool = true
@export var level_banner_prefix: String = "WORLD"
@export var enable_combo_feedback: bool = true
@export_range(0.5, 8.0, 0.1) var combo_reset_time: float = 3.0
@export_group("Visual Composition")
@export var screen_zoom: float = 1.0
@export var enable_sharpness_postprocess: bool = true
@export_range(0.0, 2.0, 0.01) var screen_sharpen_strength: float = 0.44
@export_range(0.5, 1.8, 0.01) var screen_contrast: float = 1.16
@export_range(0.2, 2.0, 0.01) var screen_saturation: float = 1.12
@export_range(-0.25, 0.25, 0.01) var screen_brightness: float = 0.025
@export_group("Premium Visual Upgrade Pack")
@export var enable_film_grain: bool = true
@export_range(0.0, 0.20, 0.005) var film_grain_strength: float = 0.035
@export var film_grain_color: Color = Color(1.0, 0.95, 0.80, 1.0)
@export var enable_god_rays: bool = true
@export var god_rays_color: Color = Color(1.0, 0.86, 0.42, 0.105)
@export_range(0.0, 1.0, 0.01) var god_rays_strength: float = 0.26
@export var enable_cloud_shadows: bool = true
@export var cloud_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.155)
@export_range(0.0, 1.0, 0.01) var cloud_shadow_strength: float = 0.22
@export var enable_premium_color_grade: bool = true
@export var color_grade_shadow_tint: Color = Color(0.52, 0.64, 0.76, 1.0)
@export var color_grade_highlight_tint: Color = Color(1.0, 0.88, 0.58, 1.0)
@export_range(0.0, 1.0, 0.01) var color_grade_strength: float = 0.18
@export var enable_sun_glow: bool = true
@export var sun_glow_color: Color = Color(1.0, 0.78, 0.32, 0.16)
@export var enable_void_shimmer: bool = true
@export var void_shimmer_color: Color = Color(0.38, 0.76, 1.0, 0.095)
@export var enable_edge_haze: bool = true
@export var edge_haze_color: Color = Color(0.56, 0.76, 0.88, 0.11)
@export var enable_player_halo: bool = true
@export var player_halo_color: Color = Color(1.0, 0.82, 0.28, 0.33)
@export_range(0.1, 3.0, 0.01) var player_halo_scale: float = 0.78
@export var enable_camera_breathing: bool = true
@export_range(0.0, 0.06, 0.001) var camera_breathing_amount: float = 0.012
@export_range(0.0, 5.0, 0.05) var camera_breathing_speed: float = 0.75
@export var enable_minimap_scanline: bool = true
@export var minimap_scanline_color: Color = Color(0.90, 0.82, 0.34, 0.16)
@export var ui_hidden_on_home: bool = true
@export var background_tint: Color = Color(0.44, 0.58, 0.64, 0.58)
@export var background_cover_scale: float = 2.1
@export var background_screen_offset: Vector2 = Vector2(50.0, 0.0)
@export var background_haze_color: Color = Color(0.35, 0.52, 0.62, 0.18)
@export var canvas_mood_color: Color = Color(0.92, 0.96, 0.86, 1.0)
@export var global_darkness_color: Color = Color(0.015, 0.022, 0.045, 0.11)
@export var vignette_color: Color = Color(0.0, 0.0, 0.0, 0.46)
@export_range(0.0, 1.0, 0.01) var vignette_strength: float = 0.46
@export_range(0.1, 1.2, 0.01) var vignette_radius: float = 0.52
@export_range(0.05, 1.0, 0.01) var vignette_softness: float = 0.42

@export_group("Ultra Visual Customization Pack")
@export var enable_focus_spotlight: bool = true
@export var focus_spotlight_color: Color = Color(0.0, 0.0, 0.0, 0.22)
@export_range(0.05, 1.0, 0.01) var focus_spotlight_radius: float = 0.34
@export_range(0.05, 1.0, 0.01) var focus_spotlight_softness: float = 0.42
@export var enable_chromatic_edges: bool = true
@export_range(0.0, 5.0, 0.05) var chromatic_edge_strength: float = 0.85
@export_range(0.0, 1.0, 0.01) var chromatic_edge_fade: float = 0.58
@export var enable_color_pop: bool = true
@export_range(0.0, 1.0, 0.01) var color_pop_strength: float = 0.12
@export_range(0.5, 2.0, 0.01) var color_pop_contrast: float = 1.08
@export var enable_depth_shadow_gradient: bool = true
@export var depth_shadow_gradient_color: Color = Color(0.0, 0.0, 0.0, 0.22)
@export var enable_warm_corner_glow: bool = true
@export var warm_corner_glow_color: Color = Color(1.0, 0.70, 0.28, 0.10)
@export var enable_texture_lines: bool = false
@export var texture_lines_color: Color = Color(1.0, 0.94, 0.72, 0.055)
@export_range(20.0, 400.0, 1.0) var texture_lines_frequency: float = 120.0
@export var enable_magic_sparkles: bool = true
@export var magic_sparkle_count: int = 34
@export var magic_sparkle_color: Color = Color(1.0, 0.82, 0.30, 0.42)
@export var enable_floating_pollen: bool = true
@export var floating_pollen_count: int = 42
@export var floating_pollen_color: Color = Color(0.80, 1.0, 0.45, 0.20)
@export var enable_foreground_mist: bool = true
@export var foreground_mist_count: int = 20
@export var foreground_mist_color: Color = Color(0.72, 0.88, 1.0, 0.10)
@export var enable_player_rim_light: bool = true
@export var player_rim_light_color: Color = Color(0.64, 0.88, 1.0, 1.0)
@export_range(0.0, 3.0, 0.01) var player_rim_light_energy: float = 0.34
@export_range(0.1, 4.0, 0.01) var player_rim_light_scale: float = 0.92
@export var enable_camera_pixel_snap: bool = true

@export_group("Fog")
@export var fog_enabled: bool = true
@export var fog_far_color: Color = Color(0.62, 0.75, 0.86, 0.13)
@export var fog_mid_color: Color = Color(0.70, 0.82, 0.90, 0.16)
@export var fog_near_color: Color = Color(0.55, 0.68, 0.84, 0.10)
@export_range(0.0, 1.0, 0.01) var fog_far_density: float = 0.22
@export_range(0.0, 1.0, 0.01) var fog_mid_density: float = 0.30
@export_range(0.0, 1.0, 0.01) var fog_near_density: float = 0.26
@export var fog_far_drift: Vector2 = Vector2(0.006, 0.002)
@export var fog_mid_drift: Vector2 = Vector2(0.018, 0.0)
@export var fog_near_drift: Vector2 = Vector2(-0.008, 0.010)
@export_range(0.5, 12.0, 0.1) var fog_far_scale: float = 2.8
@export_range(0.5, 12.0, 0.1) var fog_mid_scale: float = 5.0
@export_range(0.5, 12.0, 0.1) var fog_near_scale: float = 3.7

@export_group("Tile Lighting / Depth")
@export var tile_light_color: Color = Color(1.0, 0.86, 0.55, 1.0)
@export_range(0.0, 0.7, 0.01) var tile_light_strength: float = 0.24
@export var tile_light_direction: Vector2 = Vector2(-0.65, -0.76)
@export var tile_far_fog_color: Color = Color(0.35, 0.49, 0.62, 1.0)
@export_range(0.0, 0.8, 0.01) var tile_depth_strength: float = 0.11
@export_range(0.0, 0.8, 0.01) var tile_edge_darkening: float = 0.30

@export_group("Composition / World Generation")
@export_range(0.0, 1.0, 0.01) var grass_floor_chance: float = 0.88
@export_range(0.0, 1.0, 0.01) var room_horizontal_road_chance: float = 0.58
@export_range(0.0, 1.0, 0.01) var room_vertical_road_chance: float = 0.28
@export_range(0.0, 1.0, 0.01) var extra_corridor_grass_edge_chance: float = 0.18
@export_range(0.0, 1.0, 0.01) var decoration_density: float = 0.90
@export_range(0.0, 1.0, 0.01) var landmark_density: float = 0.42

@export_group("World Trees")
@export var world_trees_texture_path: String = WORLD_TREES_TEXTURE_PATH
@export_range(0, 80, 1) var world_tree_count: int = 22
@export_range(0.4, 3.0, 0.05) var world_tree_scale: float = 1.35
@export_range(0.05, 1.0, 0.01) var world_tree_behind_alpha: float = 0.45
@export_range(0, 5, 1) var world_tree_fade_tile_radius: int = 2
@export var world_tree_sort_foot_offset: float = 28.0
@export var world_tree_outline_color: Color = Color(0.06, 0.12, 0.04, 0.92)
@export_range(1.0, 1.2, 0.01) var world_tree_outline_scale: float = 1.05

@export_group("Island Depth Edge")
@export var enable_island_drop_shadow: bool = true
@export var island_shadow_offset: Vector2 = Vector2(14.0, 20.0)
@export var island_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.23)
@export var island_shadow_atlas_tile: Vector2i = Vector2i(8, 0)

@export_group("Particles / Life")
@export var ambient_particle_count: int = 54
@export var leaf_particle_count: int = 18
@export var dust_particle_color: Color = Color(0.95, 0.88, 0.62, 0.18)
@export var leaf_particle_color: Color = Color(0.64, 0.50, 0.24, 0.34)
@export var particle_area_extents: Vector2 = Vector2(900.0, 520.0)
@export var leaf_area_extents: Vector2 = Vector2(820.0, 340.0)
@export_range(0.0, 6.0, 0.1) var grass_sway_strength: float = 1.4
@export_range(0.0, 8.0, 0.1) var grass_sway_speed: float = 1.8

@export_group("Glow")
@export var player_glow_color: Color = Color(1.0, 0.84, 0.46, 1.0)
@export_range(0.0, 3.0, 0.01) var player_glow_energy: float = 0.78
@export_range(0.1, 4.0, 0.01) var player_glow_scale: float = 1.45

var current_health: float = 100.0
var game_started: bool = false
var is_dead: bool = false
var world_complete: bool = false
var current_stage: int = 1
var unlocked_stage: int = 1
var cursor_follow_active: bool = false
var current_tile: Vector2i = Vector2i.ZERO
var spawn_tile: Vector2i = Vector2i.ZERO
var goal_tile: Vector2i = Vector2i.ZERO
var door_unlocked: bool = false
var key_tiles: Array[Vector2i] = []
var collected_keys: Dictionary = {}
var walkable_tiles: Dictionary = {}
var room_centers: Array[Vector2i] = []
var main_path_rooms: Array[Vector2i] = []
var main_room_lookup: Dictionary = {}
var room_tiles_by_center: Dictionary = {}
var room_membership: Dictionary = {}
var side_room_spawned: Dictionary = {}
var cleared_main_rooms: Dictionary = {}
var active_main_room: Vector2i = Vector2i(-9999, -9999)
var active_main_wave_index: int = -1
var active_main_wave_spawning: bool = false
var active_main_room_locked: bool = false
var active_main_blocked_tiles: Dictionary = {}
var boss_room_center: Vector2i = Vector2i(-9999, -9999)
var active_wave_counts: PackedInt32Array = PackedInt32Array()
var active_room_is_boss: bool = false
var active_main_block_markers: Dictionary = {}
var room_slime_counts: Dictionary = {}
var occupied_deco_tiles: Dictionary = {}
var ground_biomes: Dictionary = {}
var road_tiles: Dictionary = {}
var room_tiles: Dictionary = {}
var plaza_tiles: Dictionary = {}
var border_tiles: Dictionary = {}
var revealed_tiles: Dictionary = {}
var visible_tiles: Dictionary = {}
var last_reveal_tile: Vector2i = Vector2i(-9999, -9999)
var keys_collected_this_level: int = 0
var last_step_dust_time: float = 0.0
var last_breadcrumb_time: float = 0.0
var screen_shake_time: float = 0.0
var screen_shake_strength: float = 0.0
var shadow_nodes: Array[Node2D] = []
var animated_deco_nodes: Array[CanvasItem] = []
var world_trees_root: Node2D = null
var world_tree_nodes: Array[Node2D] = []
var wave_visual_controller: Node = null
var coin_counter_label: Label = null
var haven_quick_button: Button = null
var in_haven_mode: bool = false
var haven_area_centers: Dictionary = {}
var haven_transition_root: Node2D = null
var haven_structures_root: Node2D = null
var haven_shop_panel: PanelContainer = null
var haven_shop_stall_sprite: Sprite2D = null
var haven_shop_open: bool = false
var haven_click_target_queue: Array[Vector2i] = []
var player_move_slow_multiplier: float = 1.0
var player_move_slow_timer: float = 0.0
var _player_moved_for_tutorial: bool = false
var _player_shot_for_tutorial: bool = false
var world_tree_textures: Array[Texture2D] = []

var grass_core_tiles: Array[Vector2i] = []
var grass_detail_tiles: Array[Vector2i] = []
var road_core_tiles: Array[Vector2i] = []
var road_detail_tiles: Array[Vector2i] = []
var stone_border_tiles: Array[Vector2i] = []
var ruin_border_tiles: Array[Vector2i] = []
var plant_deco_tiles: Array[Vector2i] = []
var utility_deco_tiles: Array[Vector2i] = []
var atlas_tile_columns: int = 0
var atlas_tile_rows: int = 0

var target_tile: Vector2i = Vector2i.ZERO
var target_world_position: Vector2 = Vector2.ZERO
var click_path: Array[Vector2i] = []
var is_moving_to_click: bool = false
var marker_tween: Tween = null
var marker_pulse_tween: Tween = null
var player_hit_tween: Tween = null
var last_direction: String = "down"
var current_anim: String = ""
var elapsed_time: float = 0.0
var tile_place_attempts: int = 0
var tile_place_successes: int = 0
var tile_place_failures: int = 0
var missing_tiles: Dictionary = {}

# -----------------------------
# Multiplayer state
# -----------------------------
var multiplayer_enabled: bool = false
var multiplayer_map_seed: int = 0
var remote_players: Dictionary = {}
var remote_target_positions: Dictionary = {}
var remote_last_positions: Dictionary = {}
var remote_velocities: Dictionary = {}
var remote_state_received_at: Dictionary = {}
var remote_last_shot_fx_at: Dictionary = {}
var net_world_weapons: Dictionary = {}
var last_net_send_time: float = 0.0
var net_idle_timer: float = 0.0
var last_sent_pos: Vector2 = Vector2.INF
var last_sent_tile: Vector2i = Vector2i(-99999, -99999)
var last_sent_anim: String = ""
var last_sent_direction: String = ""
var net_force_state_send: bool = false
var net_node: Node = null
var multiplayer_connect_requested: bool = false

@export_group("Multiplayer")
@export var enable_multiplayer_test_mode: bool = false
@export var multiplayer_server_url: String = "ws://127.0.0.1:10000"
## Production WebSocket URL (Render). Used automatically on web/exported builds.
## Replace with your deployed server, e.g. "wss://your-app.onrender.com".
@export var multiplayer_server_url_production: String = "wss://REPLACE-WITH-YOUR-RENDER-HOST.onrender.com"
## When true, always use the production URL even in the editor (handy for testing a live server).
@export var force_production_server_url: bool = false
@export var multiplayer_room_code: String = "ABC123"
@export var multiplayer_player_name: String = "Player"
@export_range(0.03, 0.25, 0.01) var net_send_rate: float = 0.10
@export_range(0.05, 1.0, 0.01) var multiplayer_interpolation_amount: float = 0.42
@export var debug_mode_enabled: bool = false
@export var net_position_threshold: float = 4.0
@export var net_idle_heartbeat: float = 0.5
@export_range(0.0, 0.35, 0.01) var multiplayer_prediction_lead_seconds: float = 0.10
@export_range(8.0, 400.0, 1.0) var multiplayer_max_extrapolation_distance: float = 88.0
@export_range(20.0, 500.0, 1.0) var multiplayer_snap_distance: float = 180.0
@export_range(0.0, 1200.0, 1.0) var multiplayer_max_remote_speed: float = 420.0
@export_range(0.05, 2.0, 0.01) var ally_charge_fx_shake_strength: float = 0.75
@export_range(0.02, 0.4, 0.01) var ally_charge_fx_shake_duration: float = 0.08

@export_group("Mobs - Overall")
@export var mob_settings_resource: Resource = null
@export var mobs_enabled: bool = true
@export var enable_meadow_cult_mobs: bool = true
@export var spawn_mobs_on_level_start: bool = true
@export_range(0, 64, 1) var global_mob_cap: int = 8
@export_range(0, 24, 1) var slime_spawn_count: int = 3
@export_range(2.0, 80.0, 0.5) var slime_spawn_min_distance_from_player: float = 14.0
@export_range(8.0, 120.0, 0.5) var slime_spawn_max_distance_from_player: float = 36.0
@export_range(4, 12, 1) var side_room_batch_min: int = 5
@export_range(4, 16, 1) var side_room_batch_max: int = 8

@export_group("Mobs - Slime")
@export var slime_settings_resource: Resource = null
@export var slime_texture: Texture2D = null
@export_range(1.0, 20.0, 0.5) var slime_max_health: float = 2.0
@export_range(1.0, 500.0, 1.0) var slime_health_per_heart: float = 50.0
@export_range(1, 10, 1) var slime_min_hearts: int = 1
@export_range(1, 12, 1) var slime_max_hearts: int = 5
@export_range(10.0, 240.0, 1.0) var slime_move_speed: float = 64.0
@export_range(0.2, 2.5, 0.01) var slime_jump_interval: float = 0.85
@export_range(8.0, 180.0, 1.0) var slime_jump_distance: float = 42.0
@export_range(2.0, 120.0, 1.0) var slime_jump_height: float = 20.0
@export_range(0.1, 3.0, 0.01) var slime_jump_duration: float = 0.36
@export_range(0.0, 100.0, 0.5) var slime_contact_damage: float = 20.0
@export_range(0.1, 3.0, 0.01) var slime_contact_damage_cooldown: float = 0.75
@export_range(4.0, 140.0, 0.5) var slime_contact_range: float = 14.0

@export_group("Combat Encounters")
@export var enable_main_room_lockdown: bool = true
## Normal combat rooms run these waves (array length = number of waves, values = mobs per wave).
@export var main_room_wave_counts: PackedInt32Array = PackedInt32Array([3, 4, 5, 6, 8])
## The portal/boss room (the room containing the level exit) runs these 8 escalating waves.
@export var boss_room_wave_counts: PackedInt32Array = PackedInt32Array([4, 5, 6, 7, 9, 11, 13, 16])
@export_range(0.05, 2.0, 0.01) var wave_spawn_delay: float = 0.35
@export_range(0.05, 2.0, 0.01) var next_wave_delay: float = 0.85
@export_range(0.05, 1.5, 0.01) var lock_tile_shake_time: float = 0.22
@export_range(0.05, 2.0, 0.01) var lock_regenerate_delay: float = 0.55
@export_range(0.0, 6.0, 0.1) var lock_screen_shake_strength: float = 2.4
@export_range(0.0, 6.0, 0.1) var unlock_screen_shake_strength: float = 1.2


func _ready() -> void:
	randomize()

	# Keep the original tile anchor. Do not lift the player above the clicked tile.
	tile_visual_offset = Vector2.ZERO
	setup_new_tile_sheet()
	setup_tile_lists()
	setup_missing_nodes()
	setup_layers()
	setup_world_trees_layer()
	setup_camera()
	setup_background()
	setup_hud()
	setup_intro_cutscene_ui()
	setup_music()
	setup_minimap()
	setup_lighting()
	setup_atmosphere()
	setup_particles()
	setup_extra_polish_nodes()
	_autoload_character_resources()
	setup_weapon_system()
	setup_character_system()
	setup_aiming_cone()
	setup_mob_system()
	setup_campaign_systems()
	apply_shader_materials()

	game_started = false
	is_dead = false
	current_health = max_health

	if click_marker != null:
		click_marker.visible = false
		click_marker.material = make_click_marker_material()
	if player_sprite != null:
		player_sprite_base_position = player_sprite.position
		player_sprite_base_scale = player_sprite.scale

	update_health_bar()
	update_hud()
	play_animation("idle_down")
	show_home_screen()
	print_debug_header()
	setup_multiplayer_hooks()
	_try_start_pending_haven_campaign()

	var args: PackedStringArray = OS.get_cmdline_user_args()
	if enable_multiplayer_test_mode or _should_auto_connect_multiplayer(args):
		print("AUTO MULTIPLAYER TEST MODE ACTIVE")
		print("This client will connect to the server first and only generate the map after receiving the shared room seed.")
		enable_multiplayer_test_mode = true
		auto_start_for_testing = false
		await get_tree().create_timer(0.5).timeout
		quick_multiplayer_test()
		return

	if auto_start_for_testing:
		print("AUTO START SINGLE PLAYER MODE")
		start_level(1)



func setup_weapon_system() -> void:
	if player == null:
		push_error("Weapon system failed: Player node is missing.")
		return

	weapon_manager = player.get_node_or_null("WeaponManager")

	if weapon_manager == null:
		weapon_manager = WEAPON_MANAGER_SCRIPT.new()
		weapon_manager.name = "WeaponManager"
		player.add_child(weapon_manager)

	print("WeaponManager attached to Player.")


func setup_character_system() -> void:
	if player == null:
		push_error("Character system failed: Player node is missing.")
		return
	character_controller = player.get_node_or_null("CharacterController")
	if character_controller == null:
		character_controller = CHARACTER_CONTROLLER_SCRIPT.new()
		character_controller.name = "CharacterController"
	character_controller.set("hero_walk_frames", hero_walk_frames)
	character_controller.set("hero_shoot_frames", hero_shoot_frames)
	character_controller.set("smoke_walk_frames", smoke_walk_frames)
	character_controller.set("smoke_shoot_frames", smoke_shoot_frames)
	character_controller.set("stack_walk_frames", stack_walk_frames)
	character_controller.set("stack_shoot_frames", stack_shoot_frames)
	character_controller.set("prince_walk_frames", prince_walk_frames)
	character_controller.set("prince_slash_frames", prince_slash_frames)
	character_controller.set("prince_summon_frames", prince_summoning_frames)
	character_controller.set("caraxes_summoning_frames", caraxes_summoning_frames)
	character_controller.set("hero_charge_icon_texture", hero_charge_icon_texture)
	character_controller.set("caraxes_icon_texture", caraxes_icon_texture)
	character_controller.set("laser_beam_offset_x", laser_beam_offset_x)
	character_controller.set("laser_beam_offset_y", laser_beam_offset_y)
	character_controller.set("laser_start_offset_x", laser_start_offset_x)
	character_controller.set("laser_start_offset_y", laser_start_offset_y)
	character_controller.set("laser_spawn_delay", laser_spawn_delay)
	character_controller.set("hero_eye_offset_right", hero_laser_offset_right)
	character_controller.set("hero_eye_offset_left", hero_laser_offset_left)
	character_controller.set("hero_eye_offset_up", hero_laser_offset_up)
	character_controller.set("hero_eye_offset_down", hero_laser_offset_down)
	character_controller.set("current_character_id", selected_character_id)
	if character_controller.get_parent() == null:
		player.add_child(character_controller)
	if character_controller.has_method("_apply_character_profile"):
		character_controller.call("_apply_character_profile")
	print("CharacterController attached to Player.")


func setup_aiming_cone() -> void:
	if player == null:
		return
	if not aiming_cone_enabled:
		if aim_cone_node != null:
			aim_cone_node.queue_free()
		aim_cone_node = null
		return
	aim_cone_node = player.get_node_or_null("AimingCone") as Polygon2D
	if aim_cone_node == null:
		aim_cone_node = Polygon2D.new()
		aim_cone_node.name = "AimingCone"
		player.add_child(aim_cone_node)
	aim_cone_node.z_index = -5
	_update_aiming_cone_shape()
	aim_cone_node.visible = not intro_cutscene_active and game_started


func _update_aiming_cone_shape() -> void:
	if aim_cone_node == null:
		return
	var half_angle: float = deg_to_rad(aiming_cone_angle_degrees * 0.5)
	var left: Vector2 = Vector2.RIGHT.rotated(-half_angle) * aiming_cone_length
	var right: Vector2 = Vector2.RIGHT.rotated(half_angle) * aiming_cone_length
	aim_cone_node.polygon = PackedVector2Array([
		Vector2.ZERO,
		left,
		right
	])
	aim_cone_node.position = Vector2(0.0, 10.0)
	aim_cone_node.color = aiming_cone_color


func _autoload_character_resources() -> void:
	if hero_walk_frames == null:
		hero_walk_frames = _load_sprite_frames_if_exists("res://assets/player/homelander_walking.tres")
	if hero_shoot_frames == null:
		hero_shoot_frames = _load_sprite_frames_if_exists("res://assets/player/homelander_shoot.tres")
	if smoke_walk_frames == null:
		smoke_walk_frames = _load_sprite_frames_if_exists("res://assets/player/smoke_walking.tres")
	if smoke_shoot_frames == null:
		smoke_shoot_frames = _load_sprite_frames_if_exists("res://assets/player/smoke_shoot.tres")
	if stack_walk_frames == null:
		stack_walk_frames = _load_sprite_frames_if_exists("res://assets/player/stack_walking.tres")
	if stack_shoot_frames == null:
		stack_shoot_frames = _load_sprite_frames_if_exists("res://assets/player/stack_shoot.tres")
	if prince_walk_frames == null:
		prince_walk_frames = _load_sprite_frames_if_exists("res://assets/player/daemon_walking.tres")
	if prince_slash_frames == null:
		prince_slash_frames = _load_sprite_frames_if_exists("res://assets/player/daemon_shoot.tres")
	if prince_summoning_frames == null:
		prince_summoning_frames = _load_sprite_frames_if_exists("res://assets/player/summoning.tres")
	if flower_weapon_icon_texture == null:
		flower_weapon_icon_texture = _load_texture_if_exists("res://assets/weapons/flower-gun.png")
	if flower_weapon_floor_texture == null:
		flower_weapon_floor_texture = flower_weapon_icon_texture
	if hero_charge_icon_texture == null:
		hero_charge_icon_texture = _load_texture_if_exists("res://assets/weapons/homelander.png")
	if caraxes_icon_texture == null:
		caraxes_icon_texture = _load_texture_if_exists("res://assets/weapons/caraxes.png")


func _load_sprite_frames_if_exists(path: String) -> SpriteFrames:
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = load(path)
	if loaded is SpriteFrames:
		return loaded as SpriteFrames
	return null


func _load_texture_if_exists(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = load(path)
	if loaded is Texture2D:
		return loaded as Texture2D
	return null


func setup_mob_system() -> void:
	mob_root = get_node_or_null("MobRoot") as Node2D
	if mob_root == null:
		mob_root = Node2D.new()
		mob_root.name = "MobRoot"
		add_child(mob_root)
	_apply_mob_resource_settings()
	if slime_texture == null:
		var loaded_slime_texture: Resource = load(DEFAULT_SLIME_TEXTURE_PATH)
		if loaded_slime_texture is Texture2D:
			slime_texture = loaded_slime_texture as Texture2D


func _apply_mob_resource_settings() -> void:
	if mob_settings_resource != null:
		mobs_enabled = bool(mob_settings_resource.get("mobs_enabled"))
		spawn_mobs_on_level_start = bool(mob_settings_resource.get("spawn_on_level_start"))
		global_mob_cap = int(mob_settings_resource.get("global_mob_cap"))
		slime_spawn_count = int(mob_settings_resource.get("slime_spawn_count"))
		slime_spawn_min_distance_from_player = float(mob_settings_resource.get("slime_spawn_min_distance_from_player"))
		slime_spawn_max_distance_from_player = float(mob_settings_resource.get("slime_spawn_max_distance_from_player"))

	if slime_settings_resource != null:
		var slime_tex_variant: Variant = slime_settings_resource.get("slime_texture")
		if slime_tex_variant is Texture2D:
			slime_texture = slime_tex_variant as Texture2D
		slime_max_health = float(slime_settings_resource.get("slime_max_health"))
		if slime_settings_resource.get("slime_health_per_heart") != null:
			slime_health_per_heart = float(slime_settings_resource.get("slime_health_per_heart"))
		if slime_settings_resource.get("slime_min_hearts") != null:
			slime_min_hearts = int(slime_settings_resource.get("slime_min_hearts"))
		if slime_settings_resource.get("slime_max_hearts") != null:
			slime_max_hearts = int(slime_settings_resource.get("slime_max_hearts"))
		slime_move_speed = float(slime_settings_resource.get("slime_move_speed"))
		slime_jump_interval = float(slime_settings_resource.get("slime_jump_interval"))
		slime_jump_distance = float(slime_settings_resource.get("slime_jump_distance"))
		slime_jump_height = float(slime_settings_resource.get("slime_jump_height"))
		slime_jump_duration = float(slime_settings_resource.get("slime_jump_duration"))
		slime_contact_damage = float(slime_settings_resource.get("slime_contact_damage"))
		slime_contact_damage_cooldown = float(slime_settings_resource.get("slime_contact_damage_cooldown"))
		slime_contact_range = float(slime_settings_resource.get("slime_contact_range"))


func setup_multiplayer_hooks() -> void:
	net_node = get_node_or_null("/root/Net")

	if net_node == null:
		print("Net AutoLoad not found. Add res://scripts/Net.gd as AutoLoad named Net.")
		return

	if not net_node.is_connected("room_joined", Callable(self, "_on_net_room_joined")):
		net_node.connect("room_joined", Callable(self, "_on_net_room_joined"))

	if not net_node.is_connected("player_joined", Callable(self, "_on_net_player_joined")):
		net_node.connect("player_joined", Callable(self, "_on_net_player_joined"))

	if not net_node.is_connected("player_left", Callable(self, "_on_net_player_left")):
		net_node.connect("player_left", Callable(self, "_on_net_player_left"))

	if not net_node.is_connected("remote_player_state", Callable(self, "_on_net_remote_player_state")):
		net_node.connect("remote_player_state", Callable(self, "_on_net_remote_player_state"))

	if not net_node.is_connected("remote_player_clicked", Callable(self, "_on_net_remote_player_clicked")):
		net_node.connect("remote_player_clicked", Callable(self, "_on_net_remote_player_clicked"))

	if not net_node.is_connected("remote_key_collected", Callable(self, "_on_net_remote_key_collected")):
		net_node.connect("remote_key_collected", Callable(self, "_on_net_remote_key_collected"))

	if net_node.has_signal("remote_level_started") and not net_node.is_connected("remote_level_started", Callable(self, "_on_net_remote_level_started")):
		net_node.connect("remote_level_started", Callable(self, "_on_net_remote_level_started"))

	if net_node.has_signal("connected_to_server") and not net_node.is_connected("connected_to_server", Callable(self, "_on_net_connected_to_server")):
		net_node.connect("connected_to_server", Callable(self, "_on_net_connected_to_server"))

	if net_node.has_signal("connection_failed") and not net_node.is_connected("connection_failed", Callable(self, "_on_net_connection_failed")):
		net_node.connect("connection_failed", Callable(self, "_on_net_connection_failed"))
	if net_node.has_signal("remote_weapon_dropped") and not net_node.is_connected("remote_weapon_dropped", Callable(self, "_on_net_remote_weapon_dropped")):
		net_node.connect("remote_weapon_dropped", Callable(self, "_on_net_remote_weapon_dropped"))
	if net_node.has_signal("remote_weapon_picked") and not net_node.is_connected("remote_weapon_picked", Callable(self, "_on_net_remote_weapon_picked")):
		net_node.connect("remote_weapon_picked", Callable(self, "_on_net_remote_weapon_picked"))
	if net_node.has_signal("remote_charged_attack_fx") and not net_node.is_connected("remote_charged_attack_fx", Callable(self, "_on_net_remote_charged_attack_fx")):
		net_node.connect("remote_charged_attack_fx", Callable(self, "_on_net_remote_charged_attack_fx"))
	if net_node.has_signal("room_join_rejected") and not net_node.is_connected("room_join_rejected", Callable(self, "_on_net_room_join_rejected")):
		net_node.connect("room_join_rejected", Callable(self, "_on_net_room_join_rejected"))

func _on_net_connected_to_server() -> void:
	print("CONNECTED TO MULTIPLAYER SERVER. Waiting for room join response...")
	_set_mp_status("Connected. Joining room...")


func _on_net_connection_failed() -> void:
	multiplayer_connect_requested = false
	multiplayer_enabled = false
	_set_mp_status("Connection failed. Is the server running?")
	push_error("MULTIPLAYER CONNECTION FAILED. Check the server URL (%s)." % _resolve_multiplayer_server_url())


func _on_net_room_join_rejected(reason: String) -> void:
	multiplayer_connect_requested = false
	multiplayer_enabled = false
	_set_mp_status("Join rejected: %s" % reason)
	push_error("ROOM JOIN REJECTED: %s" % reason)


func quick_multiplayer_test() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var player_index: int = _extract_player_index_arg(args)

	var chosen_name: String = multiplayer_player_name
	var cmdline_name: String = _read_cmdline_option(args, "--player-name")
	if cmdline_name != "":
		chosen_name = cmdline_name
	elif player_index > 0:
		chosen_name = "Player %s" % player_index
	elif chosen_name.strip_edges() == "":
		chosen_name = "Player"

	var cmdline_room: String = _read_cmdline_option(args, "--room")
	var chosen_room: String = multiplayer_room_code.strip_edges().to_upper()
	if cmdline_room != "":
		chosen_room = cmdline_room.strip_edges().to_upper()
	if chosen_room == "":
		chosen_room = "ABC123"

	var cmdline_url: String = _read_cmdline_option(args, "--server-url")
	if cmdline_url != "":
		multiplayer_server_url = cmdline_url.strip_edges()

	print("QUICK MULTIPLAYER TEST REQUESTED name=", chosen_name, " room=", chosen_room, " url=", multiplayer_server_url)
	connect_to_multiplayer_room(chosen_room, chosen_name)


func _resolve_multiplayer_server_url() -> String:
	# Allow runtime override via env var (set on the static host / shell) before anything else.
	var env_url: String = OS.get_environment("MULTIPLAYER_SERVER_URL")
	if env_url.strip_edges() != "":
		return env_url.strip_edges()
	# Exported web builds (and forced production) use the deployed wss:// server.
	if force_production_server_url or OS.has_feature("web") or not OS.has_feature("editor"):
		if multiplayer_server_url_production.strip_edges() != "":
			return multiplayer_server_url_production.strip_edges()
	return multiplayer_server_url.strip_edges()


func connect_to_multiplayer_room(room: String, name_text: String) -> void:
	if multiplayer_connect_requested:
		print("Multiplayer connection already requested. Skipping duplicate connect.")
		return

	if net_node == null:
		net_node = get_node_or_null("/root/Net")

	if net_node == null:
		push_error("Cannot connect. Net AutoLoad is missing. Add res://scripts/Net.gd as AutoLoad named Net.")
		return

	multiplayer_connect_requested = true
	game_started = false
	multiplayer_enabled = false

	if home_screen != null:
		home_screen.visible = true

	var clean_room: String = room.strip_edges().to_upper()
	if clean_room == "":
		clean_room = "ABC123"

	var clean_name: String = name_text.strip_edges()
	if clean_name == "":
		clean_name = "Player"

	var active_url: String = _resolve_multiplayer_server_url()
	_set_mp_status("Connecting to %s..." % active_url)
	print("Connecting to multiplayer server: ", active_url, " room: ", clean_room, " name: ", clean_name)
	net_node.call("connect_to_server", active_url, clean_room, clean_name)


func _on_net_room_joined(code: String, player_id: int, map_seed: int, players: Dictionary) -> void:
	multiplayer_enabled = true
	multiplayer_map_seed = map_seed
	multiplayer_connect_requested = false

	print("JOINED MULTIPLAYER ROOM: ", code)
	print("LOCAL PLAYER ID: ", player_id)
	print("MULTIPLAYER MAP SEED: ", map_seed)
	print("PLAYERS IN ROOM: ", players.keys())

	game_started = true
	is_dead = false
	world_complete = false
	current_health = max_health
	remote_target_positions.clear()
	remote_last_positions.clear()
	remote_velocities.clear()
	remote_state_received_at.clear()
	remote_last_shot_fx_at.clear()
	net_world_weapons.clear()
	last_sent_pos = Vector2.INF
	last_sent_tile = Vector2i(-99999, -99999)
	last_sent_anim = ""
	last_sent_direction = ""
	net_idle_timer = 0.0
	net_force_state_send = false

	if home_screen != null:
		home_screen.visible = false
	if death_screen != null:
		death_screen.visible = false

	# IMPORTANT: The level starts only after the shared room seed arrives.
	start_level(1)

	for id_variant in players.keys():
		var remote_id: int = int(id_variant)
		var local_id: int = int(net_node.get("local_player_id"))

		if remote_id == local_id:
			continue

		var data: Dictionary = players[id_variant]
		var spawn_pos: Vector2 = tile_to_world(spawn_tile)
		var spawn_cell: Vector2i = spawn_tile

		if data.has("tile") and data["tile"] is Vector2i and data["tile"] != Vector2i.ZERO:
			spawn_cell = data["tile"]
			spawn_pos = tile_to_world(spawn_cell)

		if data.has("pos") and data["pos"] is Vector2 and data["pos"] != Vector2.ZERO:
			spawn_pos = data["pos"]

		print("SPAWNING EXISTING REMOTE PLAYER: ", remote_id, " at ", spawn_pos)
		spawn_remote_player(remote_id, str(data.get("name", "Player")), spawn_pos, spawn_cell)


func _on_net_player_joined(player_id: int, new_player_name: String, pos: Vector2, tile: Vector2i) -> void:
	print("REMOTE PLAYER JOINED ROOM: ", player_id, " name: ", new_player_name, " pos: ", pos, " tile: ", tile)

	var spawn_pos: Vector2 = tile_to_world(spawn_tile)
	var spawn_cell: Vector2i = spawn_tile

	if tile != Vector2i.ZERO:
		spawn_cell = tile
		spawn_pos = tile_to_world(spawn_cell)

	if pos != Vector2.ZERO:
		spawn_pos = pos

	spawn_remote_player(player_id, new_player_name, spawn_pos, spawn_cell)


func _on_net_player_left(player_id: int) -> void:
	if not remote_players.has(player_id):
		return

	var ghost: Node2D = remote_players[player_id] as Node2D
	if is_instance_valid(ghost):
		ghost.queue_free()

	remote_players.erase(player_id)
	remote_target_positions.erase(player_id)
	remote_last_positions.erase(player_id)
	remote_velocities.erase(player_id)
	remote_state_received_at.erase(player_id)
	remote_last_shot_fx_at.erase(player_id)


func _on_net_remote_player_state(player_id: int, pos: Vector2, tile: Vector2i, anim: String, direction: String) -> void:
	if not remote_players.has(player_id):
		spawn_remote_player(player_id, "Player", pos, tile)

	var ghost: Node2D = remote_players[player_id] as Node2D
	if not is_instance_valid(ghost):
		return

	var now_sec: float = float(Time.get_ticks_msec()) * 0.001
	var previous_pos: Vector2 = pos
	var previous_received_at: float = now_sec
	if remote_target_positions.has(player_id):
		previous_pos = remote_target_positions[player_id]
	if remote_state_received_at.has(player_id):
		previous_received_at = float(remote_state_received_at[player_id])
	var delta_time: float = maxf(0.001, now_sec - previous_received_at)
	var inferred_velocity: Vector2 = (pos - previous_pos) / delta_time
	if inferred_velocity.length() > multiplayer_max_remote_speed:
		inferred_velocity = inferred_velocity.normalized() * multiplayer_max_remote_speed

	remote_last_positions[player_id] = previous_pos
	remote_target_positions[player_id] = pos
	remote_velocities[player_id] = inferred_velocity
	remote_state_received_at[player_id] = now_sec

	var sprite: AnimatedSprite2D = ghost.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null and sprite.sprite_frames != null:
		var incoming_anim: String = anim
		if incoming_anim.strip_edges() == "":
			incoming_anim = "idle_" + normalize_direction_name(direction)
		var actual_anim: String = resolve_animation(incoming_anim)
		var incoming_is_shoot: bool = actual_anim.begins_with("shoot_")
		if incoming_is_shoot:
			var shoot_frames: SpriteFrames = _resolve_remote_shoot_frames()
			if shoot_frames != null:
				sprite.sprite_frames = shoot_frames
		else:
			var base_frames: SpriteFrames = _resolve_remote_base_frames()
			if base_frames != null:
				sprite.sprite_frames = base_frames

		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(actual_anim):
			if incoming_is_shoot:
				sprite.play(actual_anim)
				sprite.frame = 0
				_show_remote_friend_shot_feedback(player_id, pos)
			elif sprite.animation != actual_anim:
				sprite.play(actual_anim)


func _on_net_remote_player_clicked(player_id: int, tile: Vector2i) -> void:
	if not remote_players.has(player_id):
		return

	show_remote_click_marker(tile)


func _on_net_remote_key_collected(player_id: int, key_tile: Vector2i) -> void:
	collect_key_shared(key_tile, true)


func _on_net_remote_level_started(stage: int, map_seed: int) -> void:
	multiplayer_map_seed = map_seed
	if stage <= 0:
		if in_haven_mode:
			return
		_prepare_haven_return_state()
		start_level(1, true)
		return
	if game_started and current_stage == stage:
		return
	if debug_mode_enabled:
		print("Remote requested level sync -> stage=", stage, " seed=", map_seed)
	start_level(stage)


func _on_net_remote_weapon_dropped(_player_id: int, weapon_key: String, world_position: Vector2, drop_uid: String) -> void:
	if weapon_manager == null:
		return
	if drop_uid == "":
		return
	if net_world_weapons.has(drop_uid):
		return
	var weapon: Weapon = _create_weapon_from_network_key(weapon_key)
	if weapon == null:
		return
	var world_weapon: Weapon.WorldWeapon = weapon_manager.call("spawn_world_weapon", weapon, world_position) as Weapon.WorldWeapon
	if world_weapon == null:
		return
	register_network_world_weapon(drop_uid, world_weapon)


func _on_net_remote_weapon_picked(_player_id: int, drop_uid: String) -> void:
	if drop_uid == "":
		return
	if not net_world_weapons.has(drop_uid):
		return
	var world_weapon: Weapon.WorldWeapon = net_world_weapons[drop_uid] as Weapon.WorldWeapon
	if world_weapon != null and is_instance_valid(world_weapon):
		world_weapon.queue_free()
	net_world_weapons.erase(drop_uid)


func _on_net_remote_charged_attack_fx(_player_id: int, fx_world_pos: Vector2) -> void:
	_show_remote_charged_explosion_fx(fx_world_pos)


func register_network_world_weapon(drop_uid: String, world_weapon: Weapon.WorldWeapon) -> void:
	if drop_uid == "" or world_weapon == null:
		return
	if net_world_weapons.has(drop_uid):
		var old_weapon: Weapon.WorldWeapon = net_world_weapons[drop_uid] as Weapon.WorldWeapon
		if old_weapon != null and is_instance_valid(old_weapon):
			old_weapon.queue_free()
	net_world_weapons[drop_uid] = world_weapon
	world_weapon.set_meta("net_drop_id", drop_uid)


func _show_remote_charged_explosion_fx(world_pos: Vector2) -> void:
	var blast: Sprite2D = Sprite2D.new()
	blast.texture = make_ring_texture(54, Color(1.0, 0.92, 0.98, 0.84))
	blast.global_position = world_pos
	blast.z_index = 98
	blast.scale = Vector2(0.55, 0.55)
	add_child(blast)

	var ring: Sprite2D = Sprite2D.new()
	ring.texture = make_ring_texture(74, Color(0.98, 0.42, 0.92, 0.65))
	ring.global_position = world_pos
	ring.z_index = 97
	ring.scale = Vector2(0.45, 0.45)
	add_child(ring)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(blast, "scale", Vector2(2.2, 2.2), 0.24)
	tween.tween_property(blast, "modulate:a", 0.0, 0.24)
	tween.tween_property(ring, "scale", Vector2(2.9, 2.9), 0.24)
	tween.tween_property(ring, "modulate:a", 0.0, 0.24)
	tween.chain().tween_callback(blast.queue_free)
	tween.chain().tween_callback(ring.queue_free)

	start_screen_shake(ally_charge_fx_shake_strength, ally_charge_fx_shake_duration)


func _create_weapon_from_network_key(weapon_key: String) -> Weapon:
	match weapon_key:
		"flower":
			var flower: Weapon = FLOWER_GUN_SCRIPT.new() as Weapon
			if weapon_manager != null:
				weapon_manager.call("_apply_world_settings_to_weapon", flower)
			return flower
		"michael":
			var michael: Weapon = MICHAEL_GUN_SCRIPT.new() as Weapon
			if weapon_manager != null:
				weapon_manager.call("_apply_world_settings_to_weapon", michael)
			return michael
		_:
			return null


func spawn_remote_player(player_id: int, new_player_name: String, pos: Vector2, tile: Vector2i) -> void:
	if remote_players.has(player_id):
		return

	if player == null:
		return

	var spawn_pos: Vector2 = pos
	if spawn_pos == Vector2.ZERO:
		spawn_pos = tile_to_world(spawn_tile)

	var ghost: Node2D = player.duplicate() as Node2D
	ghost.name = "RemotePlayer_%s" % player_id
	ghost.global_position = spawn_pos
	ghost.z_index = player.z_index + 1
	ghost.z_as_relative = false
	ghost.modulate = Color(0.72, 0.90, 1.0, 0.95)

	add_child(ghost)
	remote_players[player_id] = ghost
	remote_target_positions[player_id] = spawn_pos
	remote_last_positions[player_id] = spawn_pos
	remote_velocities[player_id] = Vector2.ZERO
	remote_state_received_at[player_id] = float(Time.get_ticks_msec()) * 0.001
	_optimize_remote_player_node(ghost)

	var ghost_weapon_manager: Node = ghost.get_node_or_null("WeaponManager")
	if ghost_weapon_manager != null:
		ghost_weapon_manager.set_process(false)
		ghost_weapon_manager.set_process_unhandled_input(false)
		ghost_weapon_manager.set_physics_process(false)
		ghost_weapon_manager.visible = false

	var health_bar: Node = ghost.get_node_or_null("HealthBar")
	if health_bar != null:
		var ghost_health_bar: Node2D = health_bar as Node2D
		if ghost_health_bar != null:
			ghost_health_bar.visible = true
			_layout_health_hearts_for_root(ghost_health_bar)

	var label: Label = Label.new()
	label.name = "NameLabel"
	label.text = new_player_name
	label.position = Vector2(-34.0, -76.0)
	label.add_theme_font_size_override("font_size", 14)
	label.modulate = Color(0.78, 0.92, 1.0, 0.95)
	label.z_index = 120
	ghost.add_child(label)

	var sprite: AnimatedSprite2D = ghost.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle_down"):
		sprite.play("idle_down")

	print("Spawned remote player: ", player_id, " ", new_player_name)


func show_remote_click_marker(tile: Vector2i) -> void:
	var world_pos: Vector2 = tile_to_world(tile)
	var marker: Sprite2D = Sprite2D.new()
	if click_marker != null:
		marker.texture = click_marker.texture
		marker.material = click_marker.material
	marker.global_position = world_pos
	marker.z_index = 96
	marker.scale = Vector2(click_marker_start_scale, click_marker_start_scale)
	marker.modulate = Color(0.05, 0.07, 0.10, click_marker_alpha * 0.92)
	add_child(marker)
	var shadow: Sprite2D = Sprite2D.new()
	shadow.texture = marker.texture
	shadow.material = marker.material
	shadow.global_position = world_pos + Vector2(2.0, 3.0)
	shadow.scale = marker.scale * 1.06
	shadow.modulate = Color(0.0, 0.0, 0.0, click_marker_alpha * 0.55)
	shadow.z_index = 95
	add_child(shadow)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(marker, "scale", Vector2(click_marker_end_scale, click_marker_end_scale), 0.35)
	tween.tween_property(marker, "modulate:a", 0.0, 0.35)
	tween.tween_property(shadow, "scale", Vector2(click_marker_end_scale * 1.06, click_marker_end_scale * 1.06), 0.35)
	tween.tween_property(shadow, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(marker.queue_free)
	tween.chain().tween_callback(shadow.queue_free)


func _show_remote_friend_shot_feedback(player_id: int, world_pos: Vector2) -> void:
	var now_sec: float = float(Time.get_ticks_msec()) * 0.001
	var last_time: float = -999.0
	if remote_last_shot_fx_at.has(player_id):
		last_time = float(remote_last_shot_fx_at[player_id])
	if now_sec - last_time < 0.14:
		return
	remote_last_shot_fx_at[player_id] = now_sec

	var marker: Sprite2D = Sprite2D.new()
	marker.texture = make_ring_texture(44, Color(1.0, 0.78, 0.90, 0.72))
	marker.global_position = world_pos
	marker.z_index = 97
	marker.scale = Vector2(0.55, 0.55)
	add_child(marker)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(marker, "scale", Vector2(2.0, 2.0), 0.20)
	tween.tween_property(marker, "modulate:a", 0.0, 0.20)
	tween.chain().tween_callback(marker.queue_free)

	if camera != null:
		start_screen_shake(0.35, 0.06)


func send_multiplayer_state_if_needed(delta: float) -> void:
	if not multiplayer_enabled:
		return

	if net_node == null:
		return

	last_net_send_time += delta
	net_idle_timer += delta
	var is_actively_moving: bool = is_moving_to_click or not click_path.is_empty()
	var send_interval: float = net_send_rate
	if is_actively_moving:
		send_interval = minf(net_send_rate, 0.05)
	if not net_force_state_send and last_net_send_time < send_interval:
		return

	last_net_send_time = 0.0

	var anim_name: String = current_anim
	if anim_name == "":
		anim_name = "idle"

	var should_send: bool = false
	if last_sent_pos == Vector2.INF:
		should_send = true
	elif player.global_position.distance_to(last_sent_pos) >= net_position_threshold:
		should_send = true
	elif current_tile != last_sent_tile:
		should_send = true
	elif anim_name != last_sent_anim or last_direction != last_sent_direction:
		should_send = true
	elif net_force_state_send:
		should_send = true
	elif net_idle_timer >= net_idle_heartbeat:
		should_send = true

	if not should_send:
		return

	net_node.call("send_player_state", player.global_position, current_tile, anim_name, last_direction)
	last_sent_pos = player.global_position
	last_sent_tile = current_tile
	last_sent_anim = anim_name
	last_sent_direction = last_direction
	net_idle_timer = 0.0
	net_force_state_send = false


func collect_key_shared(key_cell: Vector2i, from_remote: bool = false) -> void:
	if collected_keys.has(key_cell):
		return

	collected_keys[key_cell] = true
	keys_collected_this_level += 1

	if deco_layer != null:
		deco_layer.erase_cell(key_cell)

	if key_pickup_text_enabled:
		var text: String = "+ KEY"
		if from_remote:
			text = "ALLY KEY"
		show_floating_text(tile_to_world(key_cell), text, Color(1.0, 0.86, 0.18, 1.0))

	spawn_key_wisp_burst(tile_to_world(key_cell))
	register_key_combo()
	var tutorial: Node = get_node_or_null("/root/TutorialManager")
	if tutorial != null and tutorial.has_method("notify_trigger"):
		tutorial.call("notify_trigger", "key")

	if enable_screen_shake_on_key and not from_remote:
		start_screen_shake(key_screen_shake_strength, key_screen_shake_duration)

	if collected_keys.size() >= key_tiles.size():
		unlock_door()

	update_hud()
	update_minimap()


func setup_new_tile_sheet() -> void:
	if tilemap == null:
		return

	var loaded_sheet: Resource = load(NEW_TILE_SHEET_PATH)
	if not loaded_sheet is Texture2D:
		print("NEW TILE SHEET NOT FOUND AT: ", NEW_TILE_SHEET_PATH)
		print("Put new-tile-sheet.png at res://assets/tiles/new-tile-sheet.png or update NEW_TILE_SHEET_PATH.")
		return

	var sheet_texture: Texture2D = loaded_sheet as Texture2D
	if tilemap.tile_set == null:
		tilemap.tile_set = TileSet.new()

	# Always rebuild the ground atlas source so stale/incompatible editor data
	# cannot produce overlapping tile regions during headless startup.
	if tilemap.tile_set.has_source(GROUND_SOURCE_ID):
		tilemap.tile_set.remove_source(GROUND_SOURCE_ID)

	var atlas_source: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas_source.texture_region_size = NEW_TILE_ATLAS_CELL_SIZE
	tilemap.tile_set.add_source(atlas_source, GROUND_SOURCE_ID)

	atlas_source.texture = sheet_texture
	atlas_source.texture_region_size = NEW_TILE_ATLAS_CELL_SIZE

	atlas_tile_columns = int(sheet_texture.get_width() / NEW_TILE_ATLAS_CELL_SIZE.x)
	atlas_tile_rows = int(sheet_texture.get_height() / NEW_TILE_ATLAS_CELL_SIZE.y)
	if atlas_tile_columns <= 0 or atlas_tile_rows <= 0:
		print("NEW TILE SHEET INVALID FOR ATLAS CELL SIZE: ", NEW_TILE_ATLAS_CELL_SIZE, " texture=", sheet_texture.get_size())
		return

	for y in range(0, atlas_tile_rows):
		for x in range(0, atlas_tile_columns):
			var atlas_coord: Vector2i = Vector2i(x, y)
			if not atlas_source.has_tile(atlas_coord):
				atlas_source.create_tile(atlas_coord)

	print("Loaded new tile sheet: ", NEW_TILE_SHEET_PATH)


func setup_tile_lists() -> void:
	grass_core_tiles = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	grass_detail_tiles = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(12, 0), Vector2i(13, 0), Vector2i(14, 0), Vector2i(15, 0)]
	road_core_tiles = [Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)]
	road_detail_tiles = [Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0), Vector2i(9, 0)]
	stone_border_tiles = [Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0), Vector2i(11, 0), Vector2i(12, 0), Vector2i(13, 0), Vector2i(14, 0), Vector2i(15, 0)]
	ruin_border_tiles = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1)]
	plant_deco_tiles = [Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1), Vector2i(11, 1), Vector2i(12, 1), Vector2i(13, 1), Vector2i(14, 1), Vector2i(15, 1), Vector2i(0, 2), Vector2i(1, 2)]
	utility_deco_tiles = [ATLAS_STATUE, ATLAS_PILLAR, ATLAS_PEDESTAL]

	# Keep generation robust if the current tile sheet is smaller than expected.
	grass_core_tiles = _filter_existing_atlas_coords(grass_core_tiles, Vector2i(0, 0))
	grass_detail_tiles = _filter_existing_atlas_coords(grass_detail_tiles, Vector2i(0, 0))
	road_core_tiles = _filter_existing_atlas_coords(road_core_tiles, Vector2i(0, 0))
	road_detail_tiles = _filter_existing_atlas_coords(road_detail_tiles, Vector2i(0, 0))
	stone_border_tiles = _filter_existing_atlas_coords(stone_border_tiles, Vector2i(0, 0))
	ruin_border_tiles = _filter_existing_atlas_coords(ruin_border_tiles, Vector2i(0, 0))
	plant_deco_tiles = _filter_existing_atlas_coords(plant_deco_tiles, Vector2i(0, 0))
	utility_deco_tiles = _filter_existing_atlas_coords(utility_deco_tiles, Vector2i(0, 0))


func _filter_existing_atlas_coords(candidates: Array[Vector2i], fallback: Vector2i) -> Array[Vector2i]:
	var filtered: Array[Vector2i] = []
	for atlas_coord in candidates:
		if tile_exists_atlas(atlas_coord):
			filtered.append(atlas_coord)

	if filtered.is_empty():
		if tile_exists_atlas(fallback):
			filtered.append(fallback)
		elif tile_exists_atlas(Vector2i.ZERO):
			filtered.append(Vector2i.ZERO)
	return filtered


func setup_missing_nodes() -> void:
	menu_layer = get_node_or_null("MenuLayer") as CanvasLayer
	if menu_layer == null:
		menu_layer = CanvasLayer.new()
		menu_layer.name = "MenuLayer"
		menu_layer.layer = 110
		add_child(menu_layer)

	home_screen = get_node_or_null("UI/HomeScreen") as Control
	death_screen = get_node_or_null("UI/DeathScreen") as Control
	if home_screen == null:
		home_screen = get_node_or_null("HomeScreen") as Control
	if death_screen == null:
		death_screen = get_node_or_null("DeathScreen") as Control

	start_button = get_node_or_null("UI/HomeScreen/StartButton") as Button
	quit_button = get_node_or_null("UI/HomeScreen/QuitButton") as Button
	retry_button = get_node_or_null("UI/DeathScreen/RetryButton") as Button
	home_button = get_node_or_null("UI/DeathScreen/HomeButton") as Button

	if start_button == null and home_screen != null:
		start_button = home_screen.get_node_or_null("StartButton") as Button
	if quit_button == null and home_screen != null:
		quit_button = home_screen.get_node_or_null("QuitButton") as Button
	if retry_button == null and death_screen != null:
		retry_button = death_screen.get_node_or_null("RetryButton") as Button
	if home_button == null and death_screen != null:
		home_button = death_screen.get_node_or_null("HomeButton") as Button

	_ensure_menu_controls_are_canvas()
	setup_health_bar()

	# The canvas home screen wires SINGLEPLAYER to _on_singleplayer_pressed directly.
	# Only fall back to start_game for a raw .tscn StartButton that isn't already wired.
	if start_button != null and not start_button.pressed.is_connected(_on_singleplayer_pressed) and not start_button.pressed.is_connected(start_game):
		start_button.pressed.connect(start_game)
	if quit_button != null and not quit_button.pressed.is_connected(quit_game):
		quit_button.pressed.connect(quit_game)
	if retry_button != null and not retry_button.pressed.is_connected(retry_game):
		retry_button.pressed.connect(retry_game)
	if home_button != null and not home_button.pressed.is_connected(return_home):
		home_button.pressed.connect(return_home)

	print("HomeScreen found: ", home_screen != null)
	print("DeathScreen found: ", death_screen != null)
	print("StartButton found: ", start_button != null)
	print("RetryButton found: ", retry_button != null)


func _ensure_menu_controls_are_canvas() -> void:
	if menu_layer == null:
		return
	var home_is_canvas: bool = home_screen != null and home_screen.get_parent() is CanvasLayer
	if not home_is_canvas:
		if home_screen != null:
			home_screen.visible = false
		_build_canvas_home_screen()
	if death_screen != null and not (death_screen.get_parent() is CanvasLayer):
		death_screen.visible = false


func _build_canvas_home_screen() -> void:
	var root: Control = menu_layer.get_node_or_null("HomeScreen") as Control
	if root == null:
		root = Control.new()
		root.name = "HomeScreen"
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		menu_layer.add_child(root)

	var bg: ColorRect = root.get_node_or_null("Background") as ColorRect
	if bg == null:
		bg = ColorRect.new()
		bg.name = "Background"
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0.10, 0.14, 0.11, 0.88)
		root.add_child(bg)

	var panel: PanelContainer = root.get_node_or_null("MenuPanel") as PanelContainer
	if panel == null:
		panel = PanelContainer.new()
		panel.name = "MenuPanel"
		panel.set_anchors_preset(Control.PRESET_CENTER)
		panel.custom_minimum_size = Vector2(260.0, 190.0)
		panel.position = Vector2(0, 0)
		root.add_child(panel)

	var vbox: VBoxContainer = panel.get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		vbox = VBoxContainer.new()
		vbox.name = "VBox"
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.add_child(vbox)

	panel.custom_minimum_size = Vector2(320.0, 300.0)
	panel.position = Vector2(0, 0)

	var title: Label = vbox.get_node_or_null("Title") as Label
	if title == null:
		title = Label.new()
		title.name = "Title"
		title.text = "THE RUINS THAT BREATHE"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 24)
		vbox.add_child(title)

	# SINGLEPLAYER (kept as start_button so existing wiring still works).
	start_button = vbox.get_node_or_null("StartButton") as Button
	if start_button == null:
		start_button = Button.new()
		start_button.name = "StartButton"
		start_button.text = "SINGLEPLAYER"
		start_button.custom_minimum_size = Vector2(220.0, 36.0)
		vbox.add_child(start_button)
	if not start_button.pressed.is_connected(_on_singleplayer_pressed):
		start_button.pressed.connect(_on_singleplayer_pressed)

	multiplayer_button = vbox.get_node_or_null("MultiplayerButton") as Button
	if multiplayer_button == null:
		multiplayer_button = Button.new()
		multiplayer_button.name = "MultiplayerButton"
		multiplayer_button.text = "MULTIPLAYER"
		multiplayer_button.custom_minimum_size = Vector2(220.0, 36.0)
		vbox.add_child(multiplayer_button)
	if not multiplayer_button.pressed.is_connected(_on_multiplayer_menu_pressed):
		multiplayer_button.pressed.connect(_on_multiplayer_menu_pressed)

	quit_button = vbox.get_node_or_null("QuitButton") as Button
	if quit_button == null:
		quit_button = Button.new()
		quit_button.name = "QuitButton"
		quit_button.text = "QUIT"
		quit_button.custom_minimum_size = Vector2(220.0, 36.0)
		vbox.add_child(quit_button)

	_build_multiplayer_panel(vbox)

	home_screen = root


func _build_multiplayer_panel(vbox: VBoxContainer) -> void:
	mp_panel = vbox.get_node_or_null("MPPanel") as Control
	if mp_panel != null:
		return
	var mp: VBoxContainer = VBoxContainer.new()
	mp.name = "MPPanel"
	mp.alignment = BoxContainer.ALIGNMENT_CENTER
	mp.visible = false
	vbox.add_child(mp)

	var name_label: Label = Label.new()
	name_label.text = "Display Name"
	name_label.add_theme_font_size_override("font_size", 13)
	mp.add_child(name_label)

	mp_name_field = LineEdit.new()
	mp_name_field.name = "NameField"
	mp_name_field.placeholder_text = "Your name"
	mp_name_field.text = multiplayer_player_name
	mp_name_field.max_length = 16
	mp_name_field.custom_minimum_size = Vector2(220.0, 30.0)
	mp.add_child(mp_name_field)

	var room_label: Label = Label.new()
	room_label.text = "Room Code"
	room_label.add_theme_font_size_override("font_size", 13)
	mp.add_child(room_label)

	mp_room_field = LineEdit.new()
	mp_room_field.name = "RoomField"
	mp_room_field.placeholder_text = "e.g. ABC123"
	mp_room_field.text = multiplayer_room_code
	mp_room_field.max_length = 12
	mp_room_field.custom_minimum_size = Vector2(220.0, 30.0)
	mp.add_child(mp_room_field)

	mp_join_button = Button.new()
	mp_join_button.name = "JoinButton"
	mp_join_button.text = "JOIN ROOM"
	mp_join_button.custom_minimum_size = Vector2(220.0, 34.0)
	mp_join_button.pressed.connect(_on_join_multiplayer_pressed)
	mp.add_child(mp_join_button)

	mp_status_label = Label.new()
	mp_status_label.name = "StatusLabel"
	mp_status_label.text = ""
	mp_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mp_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mp_status_label.custom_minimum_size = Vector2(220.0, 18.0)
	mp_status_label.add_theme_font_size_override("font_size", 12)
	mp.add_child(mp_status_label)

	mp_panel = mp


func _on_singleplayer_pressed() -> void:
	multiplayer_enabled = false
	enable_multiplayer_test_mode = false
	multiplayer_connect_requested = false
	_begin_new_run_loadout()
	if enable_intro_cutscene:
		_start_intro_cutscene()
		return
	world_complete = false
	start_level(unlocked_stage)


func _begin_new_run_loadout() -> void:
	# Fresh game: grant exactly one random class; the rest are locked until bought in the Haven.
	if weapon_manager != null and weapon_manager.has_method("begin_new_run"):
		weapon_manager.call("begin_new_run")


func _on_multiplayer_menu_pressed() -> void:
	if mp_panel != null:
		mp_panel.visible = not mp_panel.visible
	_set_mp_status("")


func _on_join_multiplayer_pressed() -> void:
	var chosen_name: String = multiplayer_player_name
	var chosen_room: String = multiplayer_room_code
	if mp_name_field != null and mp_name_field.text.strip_edges() != "":
		chosen_name = mp_name_field.text.strip_edges()
	if mp_room_field != null and mp_room_field.text.strip_edges() != "":
		chosen_room = mp_room_field.text.strip_edges()
	multiplayer_player_name = chosen_name
	multiplayer_room_code = chosen_room.to_upper()
	enable_multiplayer_test_mode = true
	_begin_new_run_loadout()
	connect_to_multiplayer_room(multiplayer_room_code, multiplayer_player_name)


func _set_mp_status(text: String) -> void:
	if mp_status_label != null and is_instance_valid(mp_status_label):
		mp_status_label.text = text

func setup_health_bar() -> void:
	health_bar_root = get_node_or_null("Player/HealthBar") as Node2D
	if health_bar_root == null:
		health_bar_root = Node2D.new()
		health_bar_root.name = "HealthBar"
		player.add_child(health_bar_root)

	var legacy_back: Node = health_bar_root.get_node_or_null("HealthBack")
	if legacy_back != null:
		legacy_back.queue_free()
	var legacy_fill: Node = health_bar_root.get_node_or_null("HealthFill")
	if legacy_fill != null:
		legacy_fill.queue_free()

	heart_full_texture = _make_pixel_heart_texture(Color(0.92, 0.18, 0.22, 1.0), Color(0.32, 0.04, 0.05, 1.0))
	heart_empty_texture = _make_pixel_heart_texture(Color(0.28, 0.28, 0.30, 0.95), Color(0.10, 0.10, 0.12, 1.0))

	health_hearts.clear()
	for child in health_bar_root.get_children():
		var heart_sprite: Sprite2D = child as Sprite2D
		if heart_sprite != null and heart_sprite.name.begins_with("Heart"):
			health_hearts.append(heart_sprite)

	if health_hearts.size() < 3:
		for index in range(3):
			var existing_name: String = "Heart%d" % (index + 1)
			var heart: Sprite2D = health_bar_root.get_node_or_null(existing_name) as Sprite2D
			if heart == null:
				heart = Sprite2D.new()
				heart.name = existing_name
				health_bar_root.add_child(heart)
			heart.texture = heart_full_texture
			heart.scale = Vector2(3.0, 3.0)
			heart.z_index = 82

		health_hearts.clear()
		for index in range(3):
			var heart_node: Sprite2D = health_bar_root.get_node_or_null("Heart%d" % (index + 1)) as Sprite2D
			if heart_node != null:
				health_hearts.append(heart_node)
	_layout_health_hearts()
	if health_bar_root != null:
		health_bar_root.visible = true

	health_back = null
	health_fill = null


func _make_pixel_heart_texture(fill_color: Color, outline_color: Color) -> ImageTexture:
	var size_px: int = 16
	var image: Image = Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	var heart_pixels: PackedVector2Array = PackedVector2Array([
		Vector2(5, 2), Vector2(6, 2), Vector2(9, 2), Vector2(10, 2),
		Vector2(4, 3), Vector2(5, 3), Vector2(6, 3), Vector2(7, 3), Vector2(8, 3), Vector2(9, 3), Vector2(10, 3), Vector2(11, 3),
		Vector2(3, 4), Vector2(4, 4), Vector2(5, 4), Vector2(6, 4), Vector2(7, 4), Vector2(8, 4), Vector2(9, 4), Vector2(10, 4), Vector2(11, 4), Vector2(12, 4),
		Vector2(3, 5), Vector2(4, 5), Vector2(5, 5), Vector2(6, 5), Vector2(7, 5), Vector2(8, 5), Vector2(9, 5), Vector2(10, 5), Vector2(11, 5), Vector2(12, 5),
		Vector2(4, 6), Vector2(5, 6), Vector2(6, 6), Vector2(7, 6), Vector2(8, 6), Vector2(9, 6), Vector2(10, 6), Vector2(11, 6),
		Vector2(5, 7), Vector2(6, 7), Vector2(7, 7), Vector2(8, 7), Vector2(9, 7), Vector2(10, 7),
		Vector2(6, 8), Vector2(7, 8), Vector2(8, 8), Vector2(9, 8),
		Vector2(7, 9), Vector2(8, 9)
	])
	var pixel_lookup: Dictionary = {}
	for pixel in heart_pixels:
		pixel_lookup["%s_%s" % [int(pixel.x), int(pixel.y)]] = true
	for pixel in heart_pixels:
		var x: int = int(pixel.x)
		var y: int = int(pixel.y)
		var border: bool = false
		for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			var key: String = "%s_%s" % [x + offset.x, y + offset.y]
			if not pixel_lookup.has(key):
				border = true
				break
		image.set_pixel(x, y, outline_color if border else fill_color)
	return ImageTexture.create_from_image(image)


func setup_layers() -> void:
	tilemap.z_index = 0
	tilemap.y_sort_enabled = true
	player.z_index = 50
	player.z_as_relative = false

	if click_marker != null:
		click_marker.z_index = 60
		click_marker.z_as_relative = false

	deco_layer = get_node_or_null("DecoLayer") as TileMapLayer
	if deco_layer == null:
		deco_layer = TileMapLayer.new()
		deco_layer.name = "DecoLayer"
		add_child(deco_layer)

	deco_layer.tile_set = tilemap.tile_set
	deco_layer.z_index = 10
	deco_layer.y_sort_enabled = true

	island_shadow_layer = get_node_or_null("IslandDropShadowLayer") as TileMapLayer
	if island_shadow_layer == null:
		island_shadow_layer = TileMapLayer.new()
		island_shadow_layer.name = "IslandDropShadowLayer"
		add_child(island_shadow_layer)
		move_child(island_shadow_layer, 0)

	island_shadow_layer.tile_set = tilemap.tile_set
	island_shadow_layer.z_index = -8
	island_shadow_layer.y_sort_enabled = false
	island_shadow_layer.position = island_shadow_offset
	island_shadow_layer.modulate = island_shadow_color


func setup_world_trees_layer() -> void:
	world_trees_root = get_node_or_null("WorldTrees") as Node2D
	if world_trees_root == null:
		world_trees_root = Node2D.new()
		world_trees_root.name = "WorldTrees"
		add_child(world_trees_root)
		if tilemap != null:
			move_child(world_trees_root, tilemap.get_index())
	world_trees_root.y_sort_enabled = true
	world_trees_root.z_index = 12
	world_tree_textures = _load_world_tree_textures()


func _load_world_tree_textures() -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var path: String = world_trees_texture_path if world_trees_texture_path != "" else WORLD_TREES_TEXTURE_PATH
	if not ResourceLoader.exists(path):
		return textures
	var sheet: Texture2D = load(path) as Texture2D
	if sheet == null:
		return textures
	var sheet_size: Vector2 = sheet.get_size()
	if sheet_size.x <= 1.0 or sheet_size.y <= 1.0:
		return textures
	var half_w: float = sheet_size.x * 0.5
	var region_h: float = sheet_size.y
	for region_x in [0.0, half_w]:
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(region_x, 0.0, half_w, region_h)
		textures.append(atlas)
	return textures


func setup_camera() -> void:
	var player_camera: Camera2D = get_node_or_null("Player/Camera2D") as Camera2D
	if player_camera != null:
		camera = player_camera
	else:
		camera = get_node_or_null("Camera2D") as Camera2D
		if camera == null:
			camera = Camera2D.new()
			camera.name = "Camera2D"
			add_child(camera)

	if camera.get_parent() != player:
		var duplicate_player_camera: Camera2D = get_node_or_null("Player/Camera2D") as Camera2D
		if duplicate_player_camera != null and duplicate_player_camera != camera:
			duplicate_player_camera.enabled = false

	camera.enabled = true
	camera.position_smoothing_enabled = false
	camera.position_smoothing_speed = camera_smooth_speed
	camera.zoom = Vector2(_get_active_screen_zoom(), _get_active_screen_zoom())
	camera.limit_smoothed = false
	if camera.get_parent() == player:
		camera.position = Vector2.ZERO
		camera.offset = Vector2.ZERO
		camera.limit_enabled = false
	else:
		camera.position_smoothing_enabled = true
		camera.limit_smoothed = true
	camera.make_current()


func setup_background() -> void:
	var old_parallax: ParallaxBackground = get_node_or_null("ParallaxBackground") as ParallaxBackground
	if old_parallax != null:
		old_parallax.queue_free()

	if camera != null:
		var legacy_bg: Node = camera.get_node_or_null("WorldBackground")
		if legacy_bg != null:
			legacy_bg.queue_free()

	background_layer = get_node_or_null("WorldBackgroundLayer") as CanvasLayer
	if background_layer == null:
		background_layer = CanvasLayer.new()
		background_layer.name = "WorldBackgroundLayer"
		background_layer.layer = -100
		add_child(background_layer)
		move_child(background_layer, 0)

	background_sprite = background_layer.get_node_or_null("WorldBackground") as Sprite2D
	if background_sprite == null:
		background_sprite = Sprite2D.new()
		background_sprite.name = "WorldBackground"
		background_layer.add_child(background_sprite)

	background_sprite.centered = true
	background_sprite.z_index = 0
	background_sprite.z_as_relative = false
	background_sprite.modulate = background_tint
	background_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	if background_texture != null:
		background_sprite.texture = background_texture
	else:
		var loaded_texture: Resource = load(background_texture_path)
		if loaded_texture is Texture2D:
			background_sprite.texture = loaded_texture as Texture2D
		else:
			print("BACKGROUND TEXTURE NOT FOUND AT: ", background_texture_path)

	_fit_background_sprite_to_viewport()


func _fit_background_sprite_to_viewport() -> void:
	if background_sprite == null or background_sprite.texture == null:
		return
	var tex_size: Vector2 = background_sprite.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var cover: float = maxf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)
	background_sprite.scale = Vector2.ONE * cover * maxf(background_cover_scale, 0.01)
	background_sprite.position = viewport_size * 0.5 + background_screen_offset


func setup_hud() -> void:
	ui_layer = get_node_or_null("HUDLayer") as CanvasLayer
	if ui_layer == null:
		ui_layer = CanvasLayer.new()
		ui_layer.name = "HUDLayer"
		ui_layer.layer = 50
		add_child(ui_layer)

	level_label = get_node_or_null("HUDLayer/LevelLabel") as Label
	if level_label == null:
		level_label = Label.new()
		level_label.name = "LevelLabel"
		level_label.position = Vector2(28.0, 250.0)
		level_label.add_theme_font_size_override("font_size", 28)
		ui_layer.add_child(level_label)

	key_label = get_node_or_null("HUDLayer/KeyLabel") as Label
	if key_label == null:
		key_label = Label.new()
		key_label.name = "KeyLabel"
		key_label.position = Vector2(28.0, 288.0)
		key_label.add_theme_font_size_override("font_size", 20)
		ui_layer.add_child(key_label)

	var existing_map_button_node: Node = get_node_or_null("HUDLayer/MapButton")
	if existing_map_button_node != null and existing_map_button_node.get_class() != "Button":
		existing_map_button_node.queue_free()
		existing_map_button_node = null
	map_button = existing_map_button_node as Button
	if map_button == null:
		map_button = Button.new()
		map_button.name = "MapButton"
		map_button.position = map_button_position
		map_button.size = map_button_size
		map_button.text = "MAP (" + map_toggle_key_text + ")"
		ui_layer.add_child(map_button)
	map_button.position = map_button_position
	map_button.size = map_button_size
	if not map_button.pressed.is_connected(toggle_minimap_zoom):
		map_button.pressed.connect(toggle_minimap_zoom)

	objective_arrow = get_node_or_null("HUDLayer/ObjectiveArrow") as Label
	if objective_arrow == null:
		objective_arrow = Label.new()
		objective_arrow.name = "ObjectiveArrow"
		objective_arrow.text = "➤"
		objective_arrow.add_theme_font_size_override("font_size", 34)
		objective_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		objective_arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		objective_arrow.visible = false
		ui_layer.add_child(objective_arrow)

	objective_text = get_node_or_null("HUDLayer/ObjectiveText") as Label
	if objective_text == null:
		objective_text = Label.new()
		objective_text.name = "ObjectiveText"
		objective_text.add_theme_font_size_override("font_size", 16)
		objective_text.modulate = Color(1.0, 0.90, 0.45, 0.92)
		objective_text.visible = false
		ui_layer.add_child(objective_text)

	combo_label = get_node_or_null("HUDLayer/ComboLabel") as Label
	if combo_label == null:
		combo_label = Label.new()
		combo_label.name = "ComboLabel"
		combo_label.position = Vector2(28.0, 360.0)
		combo_label.add_theme_font_size_override("font_size", 16)
		combo_label.modulate = Color(1.0, 0.88, 0.35, 0.0)
		ui_layer.add_child(combo_label)

	level_banner = get_node_or_null("HUDLayer/LevelBanner") as Label
	if level_banner == null:
		level_banner = Label.new()
		level_banner.name = "LevelBanner"
		level_banner.add_theme_font_size_override("font_size", 38)
		level_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		level_banner.modulate = Color(1.0, 0.92, 0.60, 0.0)
		ui_layer.add_child(level_banner)

	setup_tutorial_popup()

	level_label.modulate = Color(1.0, 0.94, 0.68, 1.0)
	key_label.modulate = Color(1.0, 0.84, 0.18, 1.0)

	coin_counter_label = ui_layer.get_node_or_null("CoinCounterLabel") as Label
	if coin_counter_label == null:
		coin_counter_label = Label.new()
		coin_counter_label.name = "CoinCounterLabel"
		coin_counter_label.position = Vector2(28.0, 320.0)
		coin_counter_label.add_theme_font_size_override("font_size", 18)
		coin_counter_label.modulate = Color(1.0, 0.9, 0.45, 1.0)
		ui_layer.add_child(coin_counter_label)
	var drop_mgr: Node = get_node_or_null("/root/DropManager")
	if drop_mgr != null and drop_mgr.has_method("bind_coin_label"):
		drop_mgr.call("bind_coin_label", coin_counter_label)

	haven_quick_button = ui_layer.get_node_or_null("HavenQuickButton") as Button
	if haven_quick_button == null:
		haven_quick_button = Button.new()
		haven_quick_button.name = "HavenQuickButton"
		ui_layer.add_child(haven_quick_button)
	haven_quick_button.text = "HAVEN [H]"
	haven_quick_button.custom_minimum_size = Vector2(126.0, 38.0)
	if not haven_quick_button.pressed.is_connected(_go_to_haven):
		haven_quick_button.pressed.connect(_go_to_haven)
	haven_quick_button.visible = false
	_update_haven_button_position()


func setup_campaign_systems() -> void:
	var drop_mgr: Node = get_node_or_null("/root/DropManager")
	if drop_mgr != null and drop_mgr.has_method("bind_world"):
		drop_mgr.call("bind_world", self)
	var trail: Node = get_node_or_null("/root/ObjectiveTrailManager")
	if trail != null and trail.has_method("bind_world"):
		trail.call("bind_world", self)
	var lighting: Node = get_node_or_null("/root/LightingManager")
	if lighting != null and lighting.has_method("bind_world"):
		lighting.call("bind_world", self)
	var tutorial: Node = get_node_or_null("/root/TutorialManager")
	if tutorial != null:
		var hud: CanvasLayer = ui_layer if ui_layer != null else get_node_or_null("HudLayer") as CanvasLayer
		if hud == null:
			hud = get_node_or_null("HUDLayer") as CanvasLayer
		if tutorial.has_method("bind_ui") and hud != null:
			tutorial.call("bind_ui", hud)
	if wave_visual_controller == null:
		var wave_script: Script = load("res://scripts/gameplay/WaveVisualController.gd")
		if wave_script != null:
			wave_visual_controller = Node.new()
			wave_visual_controller.name = "WaveVisualController"
			wave_visual_controller.set_script(wave_script)
			add_child(wave_visual_controller)
			wave_visual_controller.call("bind_world", self)


func setup_intro_cutscene_ui() -> void:
	if ui_layer == null:
		return
	intro_cutscene_root = ui_layer.get_node_or_null("IntroCutsceneOverlay") as Control
	if intro_cutscene_root == null:
		intro_cutscene_root = Control.new()
		intro_cutscene_root.name = "IntroCutsceneOverlay"
		intro_cutscene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		intro_cutscene_root.mouse_filter = Control.MOUSE_FILTER_STOP
		ui_layer.add_child(intro_cutscene_root)

		intro_cutscene_image = TextureRect.new()
		intro_cutscene_image.name = "SlideImage"
		intro_cutscene_image.set_anchors_preset(Control.PRESET_FULL_RECT)
		intro_cutscene_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		intro_cutscene_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		intro_cutscene_root.add_child(intro_cutscene_image)

		intro_cutscene_text = Label.new()
		intro_cutscene_text.name = "StoryText"
		intro_cutscene_text.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		intro_cutscene_text.offset_left = 44.0
		intro_cutscene_text.offset_right = -44.0
		intro_cutscene_text.offset_top = -196.0
		intro_cutscene_text.offset_bottom = -42.0
		intro_cutscene_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		intro_cutscene_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		intro_cutscene_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		intro_cutscene_text.add_theme_font_size_override("font_size", 34)
		intro_cutscene_text.add_theme_constant_override("outline_size", 8)
		intro_cutscene_text.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 0.98))
		intro_cutscene_text.modulate = Color(0.98, 0.94, 0.84, 1.0)
		intro_cutscene_root.add_child(intro_cutscene_text)

		intro_cutscene_prompt = Label.new()
		intro_cutscene_prompt.name = "ContinuePrompt"
		intro_cutscene_prompt.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		intro_cutscene_prompt.offset_left = -330.0
		intro_cutscene_prompt.offset_top = -48.0
		intro_cutscene_prompt.offset_right = -24.0
		intro_cutscene_prompt.offset_bottom = -18.0
		intro_cutscene_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		intro_cutscene_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		intro_cutscene_prompt.add_theme_font_size_override("font_size", 18)
		intro_cutscene_prompt.modulate = Color(1.0, 0.92, 0.72, 0.94)
		intro_cutscene_root.add_child(intro_cutscene_prompt)

		intro_cutscene_prompt_icon = TextureRect.new()
		intro_cutscene_prompt_icon.name = "ContinuePromptIcon"
		intro_cutscene_prompt_icon.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		intro_cutscene_prompt_icon.offset_left = -172.0
		intro_cutscene_prompt_icon.offset_top = -117.0
		intro_cutscene_prompt_icon.offset_right = -20.0
		intro_cutscene_prompt_icon.offset_bottom = -16.0
		intro_cutscene_prompt_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		intro_cutscene_prompt_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		intro_cutscene_prompt_icon.scale = Vector2(0.97, 0.97)
		intro_cutscene_prompt_icon.z_index = 60
		intro_cutscene_root.add_child(intro_cutscene_prompt_icon)

		intro_cutscene_fade = ColorRect.new()
		intro_cutscene_fade.name = "Fade"
		intro_cutscene_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		intro_cutscene_fade.color = Color(0.0, 0.0, 0.0, 0.0)
		intro_cutscene_root.add_child(intro_cutscene_fade)
	else:
		intro_cutscene_image = intro_cutscene_root.get_node_or_null("SlideImage") as TextureRect
		intro_cutscene_text = intro_cutscene_root.get_node_or_null("StoryText") as Label
		intro_cutscene_prompt = intro_cutscene_root.get_node_or_null("ContinuePrompt") as Label
		intro_cutscene_prompt_icon = intro_cutscene_root.get_node_or_null("ContinuePromptIcon") as TextureRect
		intro_cutscene_fade = intro_cutscene_root.get_node_or_null("Fade") as ColorRect

	var old_bottom_bg: ColorRect = intro_cutscene_root.get_node_or_null("BottomBG") as ColorRect
	if old_bottom_bg != null:
		old_bottom_bg.queue_free()

	if intro_cutscene_prompt != null:
		intro_cutscene_prompt.text = "Press SPACE"
		intro_cutscene_prompt.visible = false
		intro_cutscene_prompt.z_index = 61
	if intro_cutscene_text != null:
		intro_cutscene_text.add_theme_constant_override("outline_size", 8)
		intro_cutscene_text.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 0.98))
	if intro_cutscene_prompt_icon != null:
		intro_cutscene_prompt_icon.texture = _resolve_intro_continue_icon_texture()
		intro_cutscene_prompt_icon.offset_left = -172.0
		intro_cutscene_prompt_icon.offset_top = -117.0
		intro_cutscene_prompt_icon.offset_right = -20.0
		intro_cutscene_prompt_icon.offset_bottom = -16.0
		intro_cutscene_prompt_icon.scale = Vector2(0.97, 0.97)
		intro_cutscene_prompt_icon.visible = intro_cutscene_prompt_icon.texture != null
		intro_cutscene_prompt_icon.move_to_front()
		if intro_cutscene_prompt != null and not intro_cutscene_prompt_icon.visible:
			intro_cutscene_prompt.visible = true
	if intro_cutscene_root != null:
		intro_cutscene_root.visible = false


func setup_music() -> void:
	if menu_music == null:
		menu_music = DEFAULT_OST_STREAM
	if gameplay_music == null:
		gameplay_music = DEFAULT_OST_STREAM
	if cd_disc_texture == null:
		cd_disc_texture = DEFAULT_OST_CD_TEXTURE
	if default_song_title.strip_edges() == "":
		default_song_title = "OST"

	music_player = get_node_or_null("MusicPlayer") as AudioStreamPlayer
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		music_player.name = "MusicPlayer"
		add_child(music_player)
	music_player.autoplay = false
	music_player.bus = "Master"
	music_player.volume_db = linear_to_db(clampf(music_volume, 0.001, 1.0))
	if not music_player.finished.is_connected(_on_music_track_finished):
		music_player.finished.connect(_on_music_track_finished)

	if ui_layer == null:
		return

	music_widget = ui_layer.get_node_or_null("MusicWidget") as Control
	if music_widget == null:
		var panel: PanelContainer = PanelContainer.new()
		panel.name = "MusicWidget"
		panel.position = music_widget_position
		panel.size = music_widget_size
		ui_layer.add_child(panel)
		music_widget = panel

		var row: HBoxContainer = HBoxContainer.new()
		row.name = "Row"
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)

		music_cd_icon = TextureRect.new()
		music_cd_icon.name = "CDIcon"
		music_cd_icon.custom_minimum_size = Vector2(28.0, 28.0)
		music_cd_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		music_cd_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(music_cd_icon)

		music_title_label = Label.new()
		music_title_label.name = "SongTitle"
		music_title_label.text = song_title_prefix + default_song_title
		music_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		music_title_label.add_theme_font_size_override("font_size", 14)
		music_title_label.clip_text = true
		row.add_child(music_title_label)
	else:
		music_cd_icon = music_widget.get_node_or_null("Row/CDIcon") as TextureRect
		music_title_label = music_widget.get_node_or_null("Row/SongTitle") as Label

	if music_cd_icon != null:
		if cd_disc_texture != null:
			music_cd_icon.texture = cd_disc_texture
		else:
			music_cd_icon.texture = _make_default_cd_texture()
	if music_widget != null:
		music_widget.position = music_widget_position
		music_widget.size = Vector2(70.0, 70.0)
		music_widget.scale = Vector2.ONE * music_widget_scale
		music_widget.visible = show_music_widget
		if music_widget is PanelContainer:
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
			style.border_width_left = 0
			style.border_width_top = 0
			style.border_width_right = 0
			style.border_width_bottom = 0
			(music_widget as PanelContainer).add_theme_stylebox_override("panel", style)
	if music_title_label != null:
		music_title_label.visible = false
	if music_cd_icon != null:
		music_cd_icon.custom_minimum_size = Vector2(64.0, 64.0)
		music_cd_icon.position = Vector2(3.0, 3.0)
	_set_song_title(default_song_title)
	_rebuild_soundtrack_playlist()
	_play_next_soundtrack(true)


func _play_music_track(stream: AudioStream, title: String) -> void:
	if music_player == null:
		return
	if not enable_music:
		music_player.stop()
		return
	if stream == null:
		return
	if music_player.stream == stream and music_player.playing:
		if title != "":
			_set_song_title(title)
		return
	var list_index: int = soundtrack_playlist.find(stream)
	if list_index >= 0:
		soundtrack_index = list_index
	music_player.stream = stream
	music_player.play()
	_set_song_title(title if title != "" else default_song_title)


func _set_song_title(song_name: String) -> void:
	if music_title_label == null:
		return
	var safe_title: String = song_name.strip_edges()
	if safe_title == "":
		safe_title = default_song_title
	music_title_label.text = "OST: " + safe_title


func _get_stage_track(stage_number: int) -> AudioStream:
	var index: int = clampi(stage_number - 1, 0, stage_music_tracks.size() - 1)
	if stage_music_tracks.is_empty():
		return gameplay_music
	var track: AudioStream = stage_music_tracks[index]
	if track == null:
		return gameplay_music
	return track


func _on_music_track_finished() -> void:
	_play_next_soundtrack(false)


func _play_next_soundtrack(reset_to_start: bool) -> void:
	if music_player == null:
		return
	if not enable_music:
		music_player.stop()
		return
	_rebuild_soundtrack_playlist()
	if soundtrack_playlist.is_empty():
		if DEFAULT_OST_STREAM != null:
			_play_music_track(DEFAULT_OST_STREAM, default_song_title)
		return
	if reset_to_start or soundtrack_index < 0 or soundtrack_index >= soundtrack_playlist.size():
		soundtrack_index = 0
	else:
		soundtrack_index = (soundtrack_index + 1) % soundtrack_playlist.size()
	var next_stream: AudioStream = soundtrack_playlist[soundtrack_index]
	var next_title: String = soundtrack_titles[soundtrack_index]
	_play_music_track(next_stream, next_title)


func _rebuild_soundtrack_playlist() -> void:
	soundtrack_playlist.clear()
	soundtrack_titles.clear()
	var seen: Dictionary = {}
	var candidates: Array[AudioStream] = []
	if menu_music != null:
		candidates.append(menu_music)
	if gameplay_music != null:
		candidates.append(gameplay_music)
	for stream in stage_music_tracks:
		if stream != null:
			candidates.append(stream)
	# Pull in every audio file the player drops into res://assets/audio/.
	for scanned in _scan_audio_directory():
		candidates.append(scanned)
	if external_ost_stream == null:
		external_ost_stream = _load_external_wav_track(EXTERNAL_OST_WAV_PATH)
	if external_ost_stream != null:
		candidates.append(external_ost_stream)
	for stream in candidates:
		if stream == null:
			continue
		var key: String = stream.resource_path
		if key == "":
			key = str(stream.get_instance_id())
		if seen.has(key):
			continue
		seen[key] = true
		soundtrack_playlist.append(stream)
		var title: String = stream.resource_name.strip_edges()
		if title == "":
			var base_name: String = stream.resource_path.get_file().get_basename()
			title = base_name if base_name != "" else default_song_title
		soundtrack_titles.append(title)


func _scan_audio_directory() -> Array[AudioStream]:
	var result: Array[AudioStream] = []
	var dir_path: String = "res://assets/audio"
	var da: DirAccess = DirAccess.open(dir_path)
	if da == null:
		return result
	var seen_names: Dictionary = {}
	da.list_dir_begin()
	var fname: String = da.get_next()
	while fname != "":
		if not da.current_is_dir():
			var clean: String = fname
			# Exported builds expose imported assets as .import/.remap entries.
			if clean.ends_with(".import"):
				clean = clean.substr(0, clean.length() - 7)
			elif clean.ends_with(".remap"):
				clean = clean.substr(0, clean.length() - 6)
			var lower: String = clean.to_lower()
			if (lower.ends_with(".wav") or lower.ends_with(".ogg") or lower.ends_with(".mp3")) and not seen_names.has(clean):
				seen_names[clean] = true
				var path: String = dir_path + "/" + clean
				if ResourceLoader.exists(path):
					var res: Resource = load(path)
					if res is AudioStream:
						result.append(res as AudioStream)
		fname = da.get_next()
	da.list_dir_end()
	return result


## R key: advance to the next track in the scanned/curated playlist.
func _cycle_music_track() -> void:
	if not enable_music:
		return
	_play_next_soundtrack(false)
	var current_title: String = default_song_title
	if soundtrack_index >= 0 and soundtrack_index < soundtrack_titles.size():
		current_title = soundtrack_titles[soundtrack_index]
	show_floating_text(player.global_position + Vector2(0.0, -40.0), "♪ " + current_title, Color(0.78, 0.92, 1.0, 0.96))


func _load_external_wav_track(file_path: String) -> AudioStream:
	if file_path.strip_edges() == "":
		return null
	if not FileAccess.file_exists(file_path):
		return null
	return AudioStreamWAV.load_from_file(file_path)


func _make_default_cd_texture() -> ImageTexture:
	var image: Image = Image.create(72, 72, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(36.0, 36.0)
	for x in range(72):
		for y in range(72):
			var distance: float = Vector2(float(x), float(y)).distance_to(center)
			var normalized: float = distance / 36.0
			var alpha: float = 0.0
			if normalized < 1.0 and normalized > 0.20:
				alpha = 0.95 - normalized * 0.65
			var color: Color = Color(0.9, 0.9, 0.92, alpha)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)



func setup_tutorial_popup() -> void:
	tutorial_panel = get_node_or_null("HUDLayer/TutorialPanel") as Control
	if tutorial_panel == null:
		tutorial_panel = PanelContainer.new()
		tutorial_panel.name = "TutorialPanel"
		tutorial_panel.position = Vector2(0.0, 0.0)
		tutorial_panel.size = Vector2(420.0, 130.0)
		tutorial_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
		tutorial_panel.visible = false
		ui_layer.add_child(tutorial_panel)

	var box: VBoxContainer = tutorial_panel.get_node_or_null("VBox") as VBoxContainer
	if box == null:
		box = VBoxContainer.new()
		box.name = "VBox"
		box.set_anchors_preset(Control.PRESET_FULL_RECT)
		box.add_theme_constant_override("separation", 8)
		tutorial_panel.add_child(box)

	var top_row: HBoxContainer = box.get_node_or_null("TopRow") as HBoxContainer
	if top_row == null:
		top_row = HBoxContainer.new()
		top_row.name = "TopRow"
		top_row.alignment = BoxContainer.ALIGNMENT_CENTER
		top_row.add_theme_constant_override("separation", 16)
		box.add_child(top_row)

	tutorial_key_icon = top_row.get_node_or_null("KeyIcon") as TextureRect
	if tutorial_key_icon == null:
		tutorial_key_icon = TextureRect.new()
		tutorial_key_icon.name = "KeyIcon"
		tutorial_key_icon.custom_minimum_size = Vector2(64.0, 64.0)
		tutorial_key_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tutorial_key_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		top_row.add_child(tutorial_key_icon)

	tutorial_title = top_row.get_node_or_null("Title") as Label
	if tutorial_title == null:
		tutorial_title = Label.new()
		tutorial_title.name = "Title"
		tutorial_title.text = level_intro_title_text
		tutorial_title.add_theme_font_size_override("font_size", 32)
		tutorial_title.modulate = Color(1.0, 0.90, 0.35, 1.0)
		top_row.add_child(tutorial_title)

	tutorial_subtitle = box.get_node_or_null("Subtitle") as Label
	if tutorial_subtitle == null:
		tutorial_subtitle = Label.new()
		tutorial_subtitle.name = "Subtitle"
		tutorial_subtitle.text = level_intro_subtitle_text
		tutorial_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tutorial_subtitle.add_theme_font_size_override("font_size", 16)
		tutorial_subtitle.modulate = Color(0.92, 0.96, 1.0, 0.92)
		box.add_child(tutorial_subtitle)

	tutorial_key_icon.texture = make_atlas_icon_texture(ATLAS_KEY)


func make_atlas_icon_texture(atlas_coord: Vector2i) -> Texture2D:
	var loaded_sheet: Resource = load(NEW_TILE_SHEET_PATH)
	if not loaded_sheet is Texture2D:
		return null

	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = loaded_sheet as Texture2D
	atlas_texture.region = Rect2(
		Vector2(float(atlas_coord.x * NEW_TILE_ATLAS_CELL_SIZE.x), float(atlas_coord.y * NEW_TILE_ATLAS_CELL_SIZE.y)),
		Vector2(float(NEW_TILE_ATLAS_CELL_SIZE.x), float(NEW_TILE_ATLAS_CELL_SIZE.y))
	)
	return atlas_texture


func show_level_intro() -> void:
	if not show_level_intro_popup or tutorial_panel == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	tutorial_panel.position = Vector2((viewport_size.x - 420.0) * 0.5, 84.0)
	tutorial_panel.size = Vector2(420.0, 130.0)
	tutorial_panel.visible = true
	tutorial_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	tutorial_panel.scale = Vector2(0.94, 0.94)

	if tutorial_title != null:
		tutorial_title.text = level_intro_title_text
	if tutorial_subtitle != null:
		tutorial_subtitle.text = level_intro_subtitle_text + "  Collect " + str(key_tiles.size()) + "."

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(tutorial_panel, "modulate:a", 1.0, 0.45)
	tween.tween_property(tutorial_panel, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_interval(level_intro_duration)
	tween.chain().tween_property(tutorial_panel, "modulate:a", 0.0, 0.55)
	tween.tween_callback(func() -> void:
		if tutorial_panel != null:
			tutorial_panel.visible = false
	)


func toggle_minimap_zoom() -> void:
	if not game_started or is_dead:
		return
	set_minimap_expanded(not minimap_expanded, true)


func set_minimap_expanded(value: bool, snap_if_closing: bool = false) -> void:
	minimap_expanded = value

	if minimap != null:
		# Reset the Control minimum size first so a previously expanded map is allowed to shrink.
		minimap.custom_minimum_size = Vector2.ZERO
		if snap_if_closing and not minimap_expanded:
			minimap.position = minimap_small_position
			minimap.size = minimap_small_size
		minimap.queue_redraw()

	if map_button != null:
		if minimap_expanded:
			map_button.text = "CLOSE MAP (ESC)"
		else:
			map_button.text = "MAP (" + map_toggle_key_text + ")"


func get_stage_scale() -> float:
	return pow(level_size_multiplier, float(maxi(0, current_stage - 1)))


func reveal_minimap_around_player() -> void:
	if current_tile == last_reveal_tile:
		return

	last_reveal_tile = current_tile
	visible_tiles.clear()

	for x in range(current_tile.x - minimap_reveal_radius, current_tile.x + minimap_reveal_radius + 1):
		for y in range(current_tile.y - minimap_reveal_radius, current_tile.y + minimap_reveal_radius + 1):
			var cell: Vector2i = Vector2i(x, y)
			if not walkable_tiles.has(cell):
				continue

			var distance: float = Vector2(float(cell.x - current_tile.x), float(cell.y - current_tile.y)).length()
			if distance <= float(minimap_reveal_radius):
				revealed_tiles[cell] = true
			if distance <= float(minimap_recent_radius):
				visible_tiles[cell] = true

	if minimap != null:
		minimap.queue_redraw()


func get_walkable_bounds() -> Rect2i:
	if walkable_tiles.is_empty():
		return Rect2i(Vector2i.ZERO, Vector2i.ONE)

	var min_x: int = 999999
	var min_y: int = 999999
	var max_x: int = -999999
	var max_y: int = -999999

	for cell_variant in walkable_tiles.keys():
		var cell: Vector2i = cell_variant
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)

	return Rect2i(Vector2i(min_x, min_y), Vector2i(maxi(1, max_x - min_x + 1), maxi(1, max_y - min_y + 1)))


func get_current_objective_tile() -> Vector2i:
	for key_cell in key_tiles:
		if not collected_keys.has(key_cell):
			return key_cell

	return goal_tile


func update_objective_arrow() -> void:
	if objective_arrow == null or objective_text == null:
		return

	if not objective_arrow_enabled or not game_started or is_dead:
		objective_arrow.visible = false
		objective_text.visible = false
		return

	var objective_tile: Vector2i = get_current_objective_tile()
	if objective_tile == Vector2i.ZERO:
		objective_arrow.visible = false
		objective_text.visible = false
		return

	var objective_world: Vector2 = tile_to_world(objective_tile)
	var direction: Vector2 = objective_world - player.global_position
	if direction.length() < 48.0:
		objective_arrow.visible = false
		objective_text.visible = false
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var center: Vector2 = viewport_size * 0.5
	var dir: Vector2 = direction.normalized()
	var radius: float = minf(viewport_size.x, viewport_size.y) * 0.34
	var pos: Vector2 = center + dir * radius

	objective_arrow.visible = true
	objective_arrow.position = pos - Vector2(18.0, 18.0)
	objective_arrow.rotation = dir.angle()
	objective_arrow.modulate = Color(1.0, 0.82, 0.28, 0.88)

	objective_text.visible = true
	objective_text.position = pos + Vector2(-24.0, 22.0)

	if collected_keys.size() < key_tiles.size():
		objective_text.text = "KEY"
	else:
		objective_text.text = "DOOR"


func show_floating_text(world_position: Vector2, text: String, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = color
	label.z_index = 200
	label.global_position = world_position + Vector2(-20.0, -46.0)
	add_child(label)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector2(0.0, -36.0), 0.75)
	tween.tween_property(label, "modulate:a", 0.0, 0.75)
	tween.chain().tween_callback(label.queue_free)


func spawn_damage_tick(world_position: Vector2, amount: float, color: Color) -> void:
	if amount <= 0.0:
		return
	var label: Label = Label.new()
	var rounded: int = int(round(amount))
	label.text = str(rounded) if absf(amount - float(rounded)) < 0.05 else ("%.1f" % amount)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.95))
	label.modulate = color
	label.z_index = 260
	label.global_position = world_position + Vector2(randf_range(-8.0, 8.0), -24.0)
	add_child(label)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector2(0.0, -28.0), 0.55)
	tween.tween_property(label, "scale", Vector2(1.12, 1.12), 0.12)
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.08)
	tween.chain().tween_callback(label.queue_free)


func start_screen_shake(strength: float, duration: float) -> void:
	screen_shake_strength = maxf(screen_shake_strength, strength)
	screen_shake_time = maxf(screen_shake_time, duration)


func request_screen_shake(strength: float, duration: float) -> void:
	start_screen_shake(strength, duration)


func request_screen_flash(intensity: float, duration: float) -> void:
	if ui_layer == null:
		return
	if screen_flash_rect == null:
		screen_flash_rect = ui_layer.get_node_or_null("ScreenFlash") as ColorRect
	if screen_flash_rect == null:
		screen_flash_rect = ColorRect.new()
		screen_flash_rect.name = "ScreenFlash"
		screen_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		screen_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		screen_flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)
		ui_layer.add_child(screen_flash_rect)
	screen_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_flash_rect.visible = true
	screen_flash_rect.color = Color(1.0, 0.96, 0.92, clampf(intensity, 0.0, 1.0))
	var tween: Tween = create_tween()
	tween.tween_property(screen_flash_rect, "color:a", 0.0, maxf(0.05, duration))
	tween.finished.connect(func() -> void:
		if screen_flash_rect != null:
			screen_flash_rect.visible = false
	)


func update_screen_shake(delta: float) -> void:
	if camera == null:
		return

	if screen_shake_time <= 0.0:
		return

	screen_shake_time = maxf(0.0, screen_shake_time - delta)
	var amount: float = screen_shake_strength * (screen_shake_time / maxf(0.01, screen_shake_time + delta))
	camera.offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))

	if screen_shake_time <= 0.0:
		camera.offset = Vector2.ZERO
		screen_shake_strength = 0.0


func spawn_step_dust() -> void:
	if not enable_player_step_dust:
		return

	if elapsed_time - last_step_dust_time < step_dust_interval:
		return

	last_step_dust_time = elapsed_time

	var puff: CPUParticles2D = CPUParticles2D.new()
	puff.name = "StepDust"
	puff.amount = 7
	puff.one_shot = true
	puff.lifetime = 0.45
	puff.explosiveness = 0.85
	puff.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	puff.emission_sphere_radius = 3.0
	puff.gravity = Vector2(0.0, -12.0)
	puff.initial_velocity_min = 8.0
	puff.initial_velocity_max = 22.0
	puff.scale_amount_min = 0.8
	puff.scale_amount_max = 1.8
	puff.color = Color(0.74, 0.66, 0.46, 0.22)
	puff.texture = make_particle_texture(7, Color(0.74, 0.66, 0.46, 0.22))
	puff.global_position = player.global_position + Vector2(0.0, 12.0)
	puff.z_index = 70
	add_child(puff)
	puff.emitting = true

	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(puff.queue_free)


func setup_minimap() -> void:
	var map_layer: CanvasLayer = get_node_or_null("MiniMapLayer") as CanvasLayer
	if map_layer == null:
		map_layer = CanvasLayer.new()
		map_layer.name = "MiniMapLayer"
		map_layer.layer = 55
		add_child(map_layer)

	minimap = map_layer.get_node_or_null("MiniMap") as MiniMapDrawer
	if minimap == null:
		minimap = MiniMapDrawer.new()
		minimap.name = "MiniMap"
		minimap.position = minimap_small_position
		map_layer.add_child(minimap)

	minimap.world = self
	minimap.minimap_size = minimap_small_size
	minimap.expanded_size = minimap_large_size
	minimap.tile_scale = minimap_small_tile_scale
	minimap.expanded_tile_scale = minimap_large_tile_scale
	minimap.position = minimap_small_position
	minimap.custom_minimum_size = Vector2.ZERO
	minimap.size = minimap_small_size


func setup_lighting() -> void:
	canvas_modulate = get_node_or_null("CanvasModulate") as CanvasModulate
	if canvas_modulate == null:
		canvas_modulate = CanvasModulate.new()
		canvas_modulate.name = "CanvasModulate"
		add_child(canvas_modulate)

	canvas_modulate.color = canvas_mood_color
	player_light = get_node_or_null("Player/PlayerGlow") as PointLight2D
	if player_light == null:
		player_light = PointLight2D.new()
		player_light.name = "PlayerGlow"
		player.add_child(player_light)

	player_light.position = Vector2(0.0, -8.0)
	player_light.texture = make_light_texture(192, player_glow_color)
	player_light.texture_scale = player_glow_scale
	player_light.energy = player_glow_energy
	player_light.color = player_glow_color
	player_light.z_index = -5

	create_shadow_for_node(player, Vector2(38.0, 12.0), 0.30)


func setup_atmosphere() -> void:
	atmosphere_layer = get_node_or_null("AtmosphereLayer") as CanvasLayer
	if atmosphere_layer == null:
		atmosphere_layer = CanvasLayer.new()
		atmosphere_layer.name = "AtmosphereLayer"
		atmosphere_layer.layer = 40
		add_child(atmosphere_layer)

	darkness_rect = create_fullscreen_rect("GlobalDarkness", atmosphere_layer, 0)
	darkness_rect.color = global_darkness_color

	fog_rect_3 = create_fullscreen_rect("BackgroundHaze", atmosphere_layer, 1)
	fog_rect_3.color = background_haze_color
	fog_rect_3.visible = fog_enabled

	fog_rect_1 = create_fullscreen_rect("FogLayerFar", atmosphere_layer, 2)
	fog_rect_1.material = make_fog_material(fog_far_color, fog_far_drift, fog_far_scale, fog_far_density)
	fog_rect_1.visible = fog_enabled

	fog_rect_2 = create_fullscreen_rect("FogLayerMid", atmosphere_layer, 3)
	fog_rect_2.material = make_fog_material(fog_mid_color, fog_mid_drift, fog_mid_scale, fog_mid_density)
	fog_rect_2.visible = fog_enabled

	var fog_near: ColorRect = create_fullscreen_rect("FogLayerNear", atmosphere_layer, 4)
	fog_near.material = make_fog_material(fog_near_color, fog_near_drift, fog_near_scale, fog_near_density)
	fog_near.visible = fog_enabled

	vignette_rect = create_fullscreen_rect("Vignette", atmosphere_layer, 10)
	vignette_rect.material = make_vignette_material()


func create_fullscreen_rect(node_name: String, parent: CanvasLayer, z: int) -> ColorRect:
	var rect: ColorRect = parent.get_node_or_null(node_name) as ColorRect
	if rect == null:
		rect = ColorRect.new()
		rect.name = node_name
		parent.add_child(rect)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = z
	return rect


func setup_particles() -> void:
	particle_root = get_node_or_null("AmbientParticles") as Node2D
	if particle_root == null:
		particle_root = Node2D.new()
		particle_root.name = "AmbientParticles"
		add_child(particle_root)

	dust_particles = particle_root.get_node_or_null("Dust") as CPUParticles2D
	if dust_particles == null:
		dust_particles = CPUParticles2D.new()
		dust_particles.name = "Dust"
		particle_root.add_child(dust_particles)

	dust_particles.amount = ambient_particle_count
	dust_particles.lifetime = 9.0
	dust_particles.preprocess = 9.0
	dust_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust_particles.emission_rect_extents = particle_area_extents
	dust_particles.gravity = Vector2(5.0, -3.0)
	dust_particles.initial_velocity_min = 6.0
	dust_particles.initial_velocity_max = 18.0
	dust_particles.scale_amount_min = 1.0
	dust_particles.scale_amount_max = 2.5
	dust_particles.color = dust_particle_color
	dust_particles.texture = make_particle_texture(8, dust_particle_color)
	dust_particles.z_index = 90
	dust_particles.emitting = true

	leaf_particles = particle_root.get_node_or_null("Leaves") as CPUParticles2D
	if leaf_particles == null:
		leaf_particles = CPUParticles2D.new()
		leaf_particles.name = "Leaves"
		particle_root.add_child(leaf_particles)

	leaf_particles.amount = leaf_particle_count
	leaf_particles.lifetime = 12.0
	leaf_particles.preprocess = 12.0
	leaf_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaf_particles.emission_rect_extents = leaf_area_extents
	leaf_particles.gravity = Vector2(-9.0, 20.0)
	leaf_particles.initial_velocity_min = 10.0
	leaf_particles.initial_velocity_max = 28.0
	leaf_particles.angular_velocity_min = -90.0
	leaf_particles.angular_velocity_max = 90.0
	leaf_particles.scale_amount_min = 2.0
	leaf_particles.scale_amount_max = 4.0
	leaf_particles.color = leaf_particle_color
	leaf_particles.texture = make_leaf_texture(12, 7, leaf_particle_color)
	leaf_particles.z_index = 91
	leaf_particles.emitting = true


func setup_extra_polish_nodes() -> void:
	setup_cinematic_overlays()
	setup_premium_visual_nodes()
	setup_ultra_visual_nodes()
	setup_sharpness_postprocess()
	setup_firefly_particles()
	setup_low_mist_particles()
	setup_magic_sparkle_particles()
	setup_floating_pollen_particles()
	setup_foreground_mist_particles()
	setup_player_rim_light()
	setup_breadcrumb_root()
	setup_click_marker_light()


func setup_cinematic_overlays() -> void:
	if atmosphere_layer == null:
		return

	letterbox_top = create_fullscreen_rect("LetterboxTop", atmosphere_layer, 20)
	letterbox_bottom = create_fullscreen_rect("LetterboxBottom", atmosphere_layer, 21)
	letterbox_top.color = letterbox_color
	letterbox_bottom.color = letterbox_color
	letterbox_top.visible = enable_cinematic_letterbox
	letterbox_bottom.visible = enable_cinematic_letterbox

	light_sweep_rect = create_fullscreen_rect("LightSweep", atmosphere_layer, 8)
	light_sweep_rect.visible = enable_light_sweep
	light_sweep_rect.material = make_light_sweep_material()



func setup_premium_visual_nodes() -> void:
	if atmosphere_layer == null:
		return

	color_grade_rect = create_fullscreen_rect("PremiumColorGrade", atmosphere_layer, 31)
	color_grade_rect.material = make_color_grade_material()
	color_grade_rect.visible = enable_premium_color_grade

	cloud_shadow_rect = create_fullscreen_rect("CloudShadowOverlay", atmosphere_layer, 12)
	cloud_shadow_rect.material = make_cloud_shadow_material()
	cloud_shadow_rect.visible = enable_cloud_shadows

	god_rays_rect = create_fullscreen_rect("GodRaysOverlay", atmosphere_layer, 13)
	god_rays_rect.material = make_god_rays_material()
	god_rays_rect.visible = enable_god_rays

	sun_glow_rect = create_fullscreen_rect("SunGlowOverlay", atmosphere_layer, 14)
	sun_glow_rect.material = make_sun_glow_material()
	sun_glow_rect.visible = enable_sun_glow

	void_shimmer_rect = create_fullscreen_rect("VoidShimmerOverlay", atmosphere_layer, 6)
	void_shimmer_rect.material = make_void_shimmer_material()
	void_shimmer_rect.visible = enable_void_shimmer

	edge_haze_rect = create_fullscreen_rect("EdgeHazeOverlay", atmosphere_layer, 15)
	edge_haze_rect.material = make_edge_haze_material()
	edge_haze_rect.visible = enable_edge_haze

	film_grain_rect = create_fullscreen_rect("FilmGrainOverlay", atmosphere_layer, 38)
	film_grain_rect.material = make_film_grain_material()
	film_grain_rect.visible = enable_film_grain

	setup_player_halo()


func setup_ultra_visual_nodes() -> void:
	if atmosphere_layer == null:
		return

	depth_shadow_rect = create_fullscreen_rect("DepthShadowGradient", atmosphere_layer, 5)
	depth_shadow_rect.material = make_depth_shadow_gradient_material()
	depth_shadow_rect.visible = enable_depth_shadow_gradient

	focus_spotlight_rect = create_fullscreen_rect("FocusSpotlight", atmosphere_layer, 16)
	focus_spotlight_rect.material = make_focus_spotlight_material()
	focus_spotlight_rect.visible = enable_focus_spotlight

	warm_corner_glow_rect = create_fullscreen_rect("WarmCornerGlow", atmosphere_layer, 17)
	warm_corner_glow_rect.material = make_warm_corner_glow_material()
	warm_corner_glow_rect.visible = enable_warm_corner_glow

	texture_lines_rect = create_fullscreen_rect("TextureLines", atmosphere_layer, 18)
	texture_lines_rect.material = make_texture_lines_material()
	texture_lines_rect.visible = enable_texture_lines

	color_pop_rect = create_fullscreen_rect("ColorPopPostProcess", atmosphere_layer, 34)
	color_pop_rect.material = make_color_pop_material()
	color_pop_rect.visible = enable_color_pop

	chromatic_edge_rect = create_fullscreen_rect("ChromaticEdges", atmosphere_layer, 37)
	chromatic_edge_rect.material = make_chromatic_edge_material()
	chromatic_edge_rect.visible = enable_chromatic_edges

func setup_player_halo() -> void:
	if player == null:
		return
	player_halo = player.get_node_or_null("PlayerHalo") as Sprite2D
	if player_halo == null:
		player_halo = Sprite2D.new()
		player_halo.name = "PlayerHalo"
		player.add_child(player_halo)
	player_halo.texture = make_ring_texture(128, player_halo_color)
	player_halo.position = Vector2(0.0, 11.0)
	player_halo.scale = Vector2(player_halo_scale, player_halo_scale * 0.34)
	player_halo.modulate = player_halo_color
	player_halo.z_index = -2
	player_halo.visible = enable_player_halo


func update_premium_visuals(_delta: float) -> void:
	var active: bool = game_started and not is_dead
	if film_grain_rect != null:
		film_grain_rect.visible = enable_film_grain and active
		if film_grain_rect.material is ShaderMaterial:
			var grain_mat: ShaderMaterial = film_grain_rect.material as ShaderMaterial
			grain_mat.set_shader_parameter("grain_strength", film_grain_strength)
			grain_mat.set_shader_parameter("grain_color", film_grain_color)
	if god_rays_rect != null:
		god_rays_rect.visible = enable_god_rays and active
		if god_rays_rect.material is ShaderMaterial:
			var rays_mat: ShaderMaterial = god_rays_rect.material as ShaderMaterial
			rays_mat.set_shader_parameter("ray_color", god_rays_color)
			rays_mat.set_shader_parameter("ray_strength", god_rays_strength)
	if cloud_shadow_rect != null:
		cloud_shadow_rect.visible = enable_cloud_shadows and active
		if cloud_shadow_rect.material is ShaderMaterial:
			var cloud_mat: ShaderMaterial = cloud_shadow_rect.material as ShaderMaterial
			cloud_mat.set_shader_parameter("shadow_color", cloud_shadow_color)
			cloud_mat.set_shader_parameter("shadow_strength", cloud_shadow_strength)
	if color_grade_rect != null:
		color_grade_rect.visible = enable_premium_color_grade and active
		if color_grade_rect.material is ShaderMaterial:
			var grade_mat: ShaderMaterial = color_grade_rect.material as ShaderMaterial
			grade_mat.set_shader_parameter("shadow_tint", color_grade_shadow_tint)
			grade_mat.set_shader_parameter("highlight_tint", color_grade_highlight_tint)
			grade_mat.set_shader_parameter("grade_strength", color_grade_strength)
	if sun_glow_rect != null:
		sun_glow_rect.visible = enable_sun_glow and active
		if sun_glow_rect.material is ShaderMaterial:
			var sun_mat: ShaderMaterial = sun_glow_rect.material as ShaderMaterial
			sun_mat.set_shader_parameter("sun_color", sun_glow_color)
	if void_shimmer_rect != null:
		void_shimmer_rect.visible = enable_void_shimmer and active
		if void_shimmer_rect.material is ShaderMaterial:
			var void_mat: ShaderMaterial = void_shimmer_rect.material as ShaderMaterial
			void_mat.set_shader_parameter("shimmer_color", void_shimmer_color)
	if edge_haze_rect != null:
		edge_haze_rect.visible = enable_edge_haze and active
		if edge_haze_rect.material is ShaderMaterial:
			var edge_mat: ShaderMaterial = edge_haze_rect.material as ShaderMaterial
			edge_mat.set_shader_parameter("haze_color", edge_haze_color)
	if player_halo != null:
		player_halo.visible = enable_player_halo and active
		var pulse: float = 1.0 + sin(elapsed_time * 2.8) * 0.06
		player_halo.scale = Vector2(player_halo_scale * pulse, player_halo_scale * 0.34 * pulse)
		player_halo.modulate = Color(player_halo_color.r, player_halo_color.g, player_halo_color.b, player_halo_color.a * (0.82 + sin(elapsed_time * 3.5) * 0.10))
	if camera != null and enable_camera_breathing and active and screen_shake_time <= 0.0:
		var breathe: float = 1.0 + sin(elapsed_time * camera_breathing_speed) * camera_breathing_amount
		var base_zoom: float = _get_active_screen_zoom()
		camera.zoom = Vector2(base_zoom * breathe, base_zoom * breathe)
		_fit_background_sprite_to_viewport()
	elif camera != null and not enable_camera_breathing:
		var base_zoom_no_breathe: float = _get_active_screen_zoom()
		camera.zoom = Vector2(base_zoom_no_breathe, base_zoom_no_breathe)
	_fit_background_sprite_to_viewport()

func setup_sharpness_postprocess() -> void:
	if atmosphere_layer == null:
		return
	sharpness_rect = create_fullscreen_rect("SharpnessPostProcess", atmosphere_layer, 35)
	sharpness_rect.visible = enable_sharpness_postprocess
	sharpness_rect.material = make_sharpness_material()

func setup_firefly_particles() -> void:
	if not enable_fireflies or particle_root == null:
		return
	firefly_particles = particle_root.get_node_or_null("Fireflies") as CPUParticles2D
	if firefly_particles == null:
		firefly_particles = CPUParticles2D.new()
		firefly_particles.name = "Fireflies"
		particle_root.add_child(firefly_particles)
	firefly_particles.amount = firefly_count
	firefly_particles.lifetime = 10.0
	firefly_particles.preprocess = 10.0
	firefly_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	firefly_particles.emission_rect_extents = particle_area_extents
	firefly_particles.gravity = Vector2(2.0, -6.0)
	firefly_particles.initial_velocity_min = 4.0
	firefly_particles.initial_velocity_max = 18.0
	firefly_particles.scale_amount_min = 0.9
	firefly_particles.scale_amount_max = 2.2
	firefly_particles.color = firefly_color
	firefly_particles.texture = make_particle_texture(9, firefly_color)
	firefly_particles.z_index = 92
	firefly_particles.emitting = true


func setup_magic_sparkle_particles() -> void:
	if not enable_magic_sparkles or particle_root == null:
		return
	magic_sparkle_particles = particle_root.get_node_or_null("MagicSparkles") as CPUParticles2D
	if magic_sparkle_particles == null:
		magic_sparkle_particles = CPUParticles2D.new()
		magic_sparkle_particles.name = "MagicSparkles"
		particle_root.add_child(magic_sparkle_particles)
	magic_sparkle_particles.amount = magic_sparkle_count
	magic_sparkle_particles.lifetime = 7.5
	magic_sparkle_particles.preprocess = 7.5
	magic_sparkle_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	magic_sparkle_particles.emission_rect_extents = particle_area_extents
	magic_sparkle_particles.gravity = Vector2(0.0, -10.0)
	magic_sparkle_particles.initial_velocity_min = 4.0
	magic_sparkle_particles.initial_velocity_max = 16.0
	magic_sparkle_particles.scale_amount_min = 0.8
	magic_sparkle_particles.scale_amount_max = 2.0
	magic_sparkle_particles.color = magic_sparkle_color
	magic_sparkle_particles.texture = make_particle_texture(8, magic_sparkle_color)
	magic_sparkle_particles.z_index = 93
	magic_sparkle_particles.emitting = true


func setup_floating_pollen_particles() -> void:
	if not enable_floating_pollen or particle_root == null:
		return
	floating_pollen_particles = particle_root.get_node_or_null("FloatingPollen") as CPUParticles2D
	if floating_pollen_particles == null:
		floating_pollen_particles = CPUParticles2D.new()
		floating_pollen_particles.name = "FloatingPollen"
		particle_root.add_child(floating_pollen_particles)
	floating_pollen_particles.amount = floating_pollen_count
	floating_pollen_particles.lifetime = 11.0
	floating_pollen_particles.preprocess = 11.0
	floating_pollen_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	floating_pollen_particles.emission_rect_extents = particle_area_extents
	floating_pollen_particles.gravity = Vector2(-5.0, -2.0)
	floating_pollen_particles.initial_velocity_min = 3.0
	floating_pollen_particles.initial_velocity_max = 12.0
	floating_pollen_particles.scale_amount_min = 0.7
	floating_pollen_particles.scale_amount_max = 1.6
	floating_pollen_particles.color = floating_pollen_color
	floating_pollen_particles.texture = make_particle_texture(6, floating_pollen_color)
	floating_pollen_particles.z_index = 94
	floating_pollen_particles.emitting = true


func setup_foreground_mist_particles() -> void:
	if not enable_foreground_mist or particle_root == null:
		return
	foreground_mist_particles = particle_root.get_node_or_null("ForegroundMist") as CPUParticles2D
	if foreground_mist_particles == null:
		foreground_mist_particles = CPUParticles2D.new()
		foreground_mist_particles.name = "ForegroundMist"
		particle_root.add_child(foreground_mist_particles)
	foreground_mist_particles.amount = foreground_mist_count
	foreground_mist_particles.lifetime = 13.0
	foreground_mist_particles.preprocess = 13.0
	foreground_mist_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	foreground_mist_particles.emission_rect_extents = Vector2(particle_area_extents.x, particle_area_extents.y * 0.40)
	foreground_mist_particles.position = Vector2(0.0, particle_area_extents.y * 0.28)
	foreground_mist_particles.gravity = Vector2(10.0, -1.0)
	foreground_mist_particles.initial_velocity_min = 8.0
	foreground_mist_particles.initial_velocity_max = 22.0
	foreground_mist_particles.scale_amount_min = 4.0
	foreground_mist_particles.scale_amount_max = 9.0
	foreground_mist_particles.color = foreground_mist_color
	foreground_mist_particles.texture = make_particle_texture(24, foreground_mist_color)
	foreground_mist_particles.z_index = 96
	foreground_mist_particles.emitting = true


func setup_player_rim_light() -> void:
	if player == null:
		return
	player_rim_light = player.get_node_or_null("PlayerRimLight") as PointLight2D
	if player_rim_light == null:
		player_rim_light = PointLight2D.new()
		player_rim_light.name = "PlayerRimLight"
		player.add_child(player_rim_light)
	player_rim_light.position = Vector2(-16.0, -18.0)
	player_rim_light.texture = make_light_texture(128, player_rim_light_color)
	player_rim_light.texture_scale = player_rim_light_scale
	player_rim_light.energy = player_rim_light_energy
	player_rim_light.color = player_rim_light_color
	player_rim_light.z_index = -4
	player_rim_light.visible = enable_player_rim_light

func setup_low_mist_particles() -> void:
	if not enable_low_mist or particle_root == null:
		return
	low_mist_particles = particle_root.get_node_or_null("LowMist") as CPUParticles2D
	if low_mist_particles == null:
		low_mist_particles = CPUParticles2D.new()
		low_mist_particles.name = "LowMist"
		particle_root.add_child(low_mist_particles)
	low_mist_particles.amount = low_mist_count
	low_mist_particles.lifetime = 14.0
	low_mist_particles.preprocess = 14.0
	low_mist_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	low_mist_particles.emission_rect_extents = Vector2(particle_area_extents.x, particle_area_extents.y * 0.42)
	low_mist_particles.position = Vector2(0.0, particle_area_extents.y * 0.20)
	low_mist_particles.gravity = Vector2(16.0, -1.0)
	low_mist_particles.initial_velocity_min = 6.0
	low_mist_particles.initial_velocity_max = 22.0
	low_mist_particles.scale_amount_min = 5.0
	low_mist_particles.scale_amount_max = 12.0
	low_mist_particles.color = low_mist_color
	low_mist_particles.texture = make_particle_texture(24, low_mist_color)
	low_mist_particles.z_index = 30
	low_mist_particles.emitting = true


func setup_breadcrumb_root() -> void:
	breadcrumb_root = get_node_or_null("BreadcrumbTrail") as Node2D
	if breadcrumb_root == null:
		breadcrumb_root = Node2D.new()
		breadcrumb_root.name = "BreadcrumbTrail"
		add_child(breadcrumb_root)
	breadcrumb_root.z_index = 45


func setup_click_marker_light() -> void:
	if click_marker == null or not enable_click_marker_light:
		return
	click_marker_light = click_marker.get_node_or_null("ClickMarkerLight") as PointLight2D
	if click_marker_light == null:
		click_marker_light = PointLight2D.new()
		click_marker_light.name = "ClickMarkerLight"
		click_marker.add_child(click_marker_light)
	click_marker_light.texture = make_light_texture(128, click_marker_glow_color)
	click_marker_light.energy = click_marker_light_energy
	click_marker_light.texture_scale = click_marker_light_scale
	click_marker_light.color = click_marker_glow_color


func apply_shader_materials() -> void:
	if tilemap != null:
		tilemap.material = make_tile_lighting_material()
	if deco_layer != null:
		deco_layer.material = make_sway_lighting_material()


func make_light_texture(size: int, tint: Color) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(float(size) / 2.0, float(size) / 2.0)
	var radius: float = float(size) / 2.0
	for x in range(size):
		for y in range(size):
			var pixel_pos: Vector2 = Vector2(float(x), float(y))
			var d: float = pixel_pos.distance_to(center) / radius
			var alpha: float = clampf(1.0 - d, 0.0, 1.0)
			alpha = alpha * alpha * 0.95
			img.set_pixel(x, y, Color(tint.r, tint.g, tint.b, alpha))
	return ImageTexture.create_from_image(img)


func make_particle_texture(size: int, tint: Color) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(float(size) * 0.5, float(size) * 0.5)
	var radius: float = float(size) * 0.5
	for x in range(size):
		for y in range(size):
			var p: Vector2 = Vector2(float(x), float(y))
			var d: float = p.distance_to(center) / radius
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = a * a * tint.a
			img.set_pixel(x, y, Color(tint.r, tint.g, tint.b, a))
	return ImageTexture.create_from_image(img)


func make_leaf_texture(width: int, height: int, tint: Color) -> ImageTexture:
	var img: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(float(width) * 0.5, float(height) * 0.5)
	for x in range(width):
		for y in range(height):
			var dx: float = absf(float(x) - center.x) / maxf(1.0, center.x)
			var dy: float = absf(float(y) - center.y) / maxf(1.0, center.y)
			var mask: float = clampf(1.0 - dx * 0.72 - dy * 1.15, 0.0, 1.0)
			img.set_pixel(x, y, Color(tint.r, tint.g, tint.b, mask * tint.a))
	return ImageTexture.create_from_image(img)


func make_tile_lighting_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_mix;
uniform vec4 light_color : source_color = vec4(1.0, 0.86, 0.55, 1.0);
uniform float light_strength = 0.18;
uniform vec2 light_direction = vec2(-0.65, -0.76);
uniform vec4 far_fog_color : source_color = vec4(0.35, 0.49, 0.62, 1.0);
uniform float depth_strength = 0.18;
uniform float edge_darkening = 0.24;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float top_left = clamp(dot(normalize(vec2(0.5 - UV.x, 0.5 - UV.y)), -normalize(light_direction)) * 0.5 + 0.5, 0.0, 1.0);
	float lower_right = smoothstep(0.42, 1.0, UV.x * 0.55 + UV.y * 0.75);
	float edge = smoothstep(0.34, 0.52, abs(UV.x - 0.5) + abs(UV.y - 0.5));
	float depth = smoothstep(0.55, 1.0, SCREEN_UV.y);
	vec3 color = tex.rgb;
	color += light_color.rgb * top_left * light_strength;
	color *= 1.0 - lower_right * edge_darkening;
	color *= 1.0 - edge * 0.075;
	color = mix(color, far_fog_color.rgb, depth * depth_strength);
	color = (color - 0.5) * 1.10 + 0.5;
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(gray), color, 1.08);
	COLOR = vec4(clamp(color, 0.0, 1.0), tex.a);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("light_color", tile_light_color)
	mat.set_shader_parameter("light_strength", tile_light_strength)
	mat.set_shader_parameter("light_direction", tile_light_direction)
	mat.set_shader_parameter("far_fog_color", tile_far_fog_color)
	mat.set_shader_parameter("depth_strength", tile_depth_strength)
	mat.set_shader_parameter("edge_darkening", tile_edge_darkening)
	return mat


func make_sway_lighting_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_mix;
uniform float sway_strength = 1.4;
uniform float sway_speed = 1.8;
uniform vec4 light_color : source_color = vec4(1.0, 0.84, 0.50, 1.0);
uniform float light_strength = 0.10;
void vertex() {
	float top_mask = smoothstep(0.20, 1.0, 1.0 - UV.y);
	float wave = sin(TIME * sway_speed + VERTEX.y * 0.08 + VERTEX.x * 0.035);
	VERTEX.x += wave * sway_strength * top_mask;
}
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float top_left = clamp((1.0 - UV.x) * (1.0 - UV.y), 0.0, 1.0);
	vec3 color = tex.rgb + light_color.rgb * top_left * light_strength;
	COLOR = vec4(color, tex.a);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("sway_strength", grass_sway_strength)
	mat.set_shader_parameter("sway_speed", grass_sway_speed)
	mat.set_shader_parameter("light_color", tile_light_color)
	return mat


func make_click_marker_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_mix;
uniform vec4 glow_color : source_color = vec4(1.0, 0.78, 0.16, 0.45);
uniform float pulse_speed = 2.2;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float d = distance(UV, vec2(0.5));
	float soft_ring = smoothstep(0.50, 0.30, d) - smoothstep(0.30, 0.16, d);
	float pulse = 0.84 + 0.16 * sin(TIME * pulse_speed);
	vec4 glow = glow_color * soft_ring * pulse * 0.35;
	COLOR = tex * vec4(1.0, 0.92, 0.68, 0.55) + glow;
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("glow_color", click_marker_glow_color)
	return mat


func make_background_depth_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 fog_color : source_color = vec4(0.42, 0.55, 0.68, 1.0);
uniform float haze = 0.28;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float depth = smoothstep(0.05, 0.85, UV.y);
	vec3 color = mix(tex.rgb, fog_color.rgb, haze + depth * 0.12);
	color *= 0.82;
	COLOR = vec4(color, tex.a);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("fog_color", Color(background_haze_color.r, background_haze_color.g, background_haze_color.b, 1.0))
	mat.set_shader_parameter("haze", clampf(background_haze_color.a + 0.14, 0.0, 0.9))
	return mat


func make_fog_material(fog_color: Color, drift: Vector2, scale: float, density: float) -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_mix;
uniform vec4 fog_color : source_color = vec4(0.7, 0.8, 0.9, 0.16);
uniform vec2 drift = vec2(0.01, 0.0);
uniform float fog_scale = 4.0;
uniform float density = 0.25;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
void fragment() {
	vec2 uv = SCREEN_UV * fog_scale + TIME * drift;
	float n = noise(uv) * 0.60 + noise(uv * 2.1) * 0.28 + noise(uv * 4.0) * 0.12;
	float vertical = smoothstep(0.02, 0.78, SCREEN_UV.y);
	float alpha = smoothstep(0.28, 0.92, n) * density * vertical;
	COLOR = vec4(fog_color.rgb, alpha * fog_color.a);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("fog_color", fog_color)
	mat.set_shader_parameter("drift", drift)
	mat.set_shader_parameter("fog_scale", scale)
	mat.set_shader_parameter("density", density)
	return mat


func make_vignette_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_mix;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 0.58);
uniform float radius = 0.52;
uniform float softness = 0.42;
void fragment() {
	float d = distance(SCREEN_UV, vec2(0.5));
	float alpha = smoothstep(radius, radius + softness, d) * vignette_color.a;
	COLOR = vec4(vignette_color.rgb, alpha);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("vignette_color", Color(vignette_color.r, vignette_color.g, vignette_color.b, vignette_strength))
	mat.set_shader_parameter("radius", vignette_radius)
	mat.set_shader_parameter("softness", vignette_softness)
	return mat


func show_home_screen() -> void:
	game_started = false
	is_dead = false
	intro_cutscene_active = false
	cursor_follow_active = false
	set_minimap_expanded(false, true)
	_set_gameplay_hud_visibility(false)
	if home_screen != null:
		home_screen.visible = true
		home_screen.move_to_front()
	if death_screen != null:
		death_screen.visible = false
	if click_marker != null:
		click_marker.visible = false
	if intro_cutscene_root != null:
		intro_cutscene_root.visible = false
	_play_music_track(menu_music, "Home")
	update_hud()


func start_game() -> void:
	print("START GAME PRESSED")

	var args: PackedStringArray = OS.get_cmdline_user_args()
	if enable_multiplayer_test_mode or _should_auto_connect_multiplayer(args):
		print("MULTIPLAYER TEST MODE ENABLED - connecting to room instead of starting a local random map.")
		enable_multiplayer_test_mode = true
		auto_start_for_testing = false
		quick_multiplayer_test()
		return

	if enable_intro_cutscene:
		_start_intro_cutscene()
		return
	world_complete = false
	start_level(unlocked_stage)


func _set_gameplay_hud_visibility(visible: bool) -> void:
	var hud_layer: CanvasLayer = get_node_or_null("HUDLayer") as CanvasLayer
	if hud_layer == null:
		hud_layer = get_node_or_null("HudLayer") as CanvasLayer
	if hud_layer == null:
		return
	var gameplay_ui_names: PackedStringArray = [
		"WeaponHUD",
		"WeaponChargeUI",
		"CharacterChargeUI",
		"CaraxesIconRoot",
		"PrinceStaminaRoot",
		"MiniMap",
		"TwinsModeHints"
	]
	for node_name in gameplay_ui_names:
		var node: CanvasItem = hud_layer.get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.visible = visible
	if haven_quick_button != null:
		haven_quick_button.visible = visible and not in_haven_mode
		_update_haven_button_position()


func _update_haven_button_position() -> void:
	if haven_quick_button == null or ui_layer == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var margin: Vector2 = Vector2(18.0, 18.0)
	var size: Vector2 = haven_quick_button.size
	if size == Vector2.ZERO:
		size = haven_quick_button.custom_minimum_size
	haven_quick_button.position = Vector2(
		viewport_size.x - size.x - margin.x,
		viewport_size.y - size.y - margin.y
	)


func start_level(stage_number: int, as_haven: bool = false) -> void:
	reset_debug_counters()
	in_haven_mode = as_haven
	game_started = true
	is_dead = false
	intro_cutscene_active = false
	cursor_follow_active = false
	door_unlocked = false
	current_stage = clampi(stage_number, 1, MAX_WORLD_STAGE)
	var campaign: Node = get_node_or_null("/root/CampaignManager")
	if not in_haven_mode and campaign != null and campaign.has_method("start_campaign_level"):
		var level_id: String = campaign.call("level_for_stage", current_stage, "world_1")
		campaign.call("start_campaign_level", level_id)
	current_health = max_health
	key_tiles.clear()
	collected_keys.clear()
	revealed_tiles.clear()
	visible_tiles.clear()
	last_reveal_tile = Vector2i(-9999, -9999)
	keys_collected_this_level = 0
	side_room_spawned.clear()
	cleared_main_rooms.clear()
	active_main_room = Vector2i(-9999, -9999)
	active_main_wave_index = -1
	active_main_wave_spawning = false
	active_main_room_locked = false
	active_main_blocked_tiles.clear()
	_clear_main_block_markers()
	room_slime_counts.clear()
	last_sent_pos = Vector2.INF
	last_sent_tile = Vector2i(-99999, -99999)
	last_sent_anim = ""
	last_sent_direction = ""
	net_idle_timer = 0.0
	net_force_state_send = false
	remote_velocities.clear()
	remote_state_received_at.clear()
	net_world_weapons.clear()
	set_minimap_expanded(false, true)
	if in_haven_mode:
		haven_shop_open = false

	if home_screen != null:
		home_screen.visible = false
	_set_gameplay_hud_visibility(true)
	_apply_haven_ui_state()
	if weapon_manager != null and weapon_manager.has_method("on_level_started"):
		weapon_manager.call("on_level_started")
	if death_screen != null:
		death_screen.visible = false
	if click_marker != null:
		click_marker.visible = false
	if intro_cutscene_root != null:
		intro_cutscene_root.visible = false
	if player_sprite != null:
		player_sprite.modulate = Color.WHITE

	apply_stage_lighting()
	generate_level()
	if in_haven_mode:
		key_tiles.clear()
		collected_keys.clear()
		keys_collected_this_level = 0
		goal_tile = Vector2i.ZERO
		door_unlocked = true
		if mob_root != null:
			for child in mob_root.get_children():
				child.queue_free()
	else:
		place_keys()
		create_goal_tile(false)
	player.global_position = tile_to_world(spawn_tile)
	current_tile = spawn_tile
	target_tile = spawn_tile
	target_world_position = player.global_position
	if not in_haven_mode:
		call_deferred("spawn_level_mobs")
	if camera != null:
		_reset_camera_to_player()
		camera.zoom = Vector2(_get_active_screen_zoom(), _get_active_screen_zoom())
	if in_haven_mode:
		_reveal_haven_minimap_without_fog()
	else:
		reveal_minimap_around_player()
	show_level_intro()
	show_level_banner()
	update_health_bar()
	update_hud()
	update_minimap()
	play_animation("idle_down")
	if in_haven_mode:
		show_floating_text(player.global_position + Vector2(0.0, -34.0), "You've now entered the Haven", Color(0.92, 0.96, 1.0, 0.95))
		show_floating_text(player.global_position + Vector2(0.0, -12.0), "Press Y to return to level", Color(0.84, 0.90, 1.0, 0.92))
		_play_music_track(menu_music, "Haven")
	else:
		print_level_result_debug()
		var stage_track: AudioStream = _get_stage_track(current_stage)
		_play_music_track(stage_track, "World 1-%d" % current_stage)


func apply_stage_lighting() -> void:
	var dark: float = 0.08 + float(current_stage) * 0.026
	var base: float = 1.0 - dark
	if canvas_modulate != null:
		canvas_modulate.color = Color(canvas_mood_color.r * base, canvas_mood_color.g * base, canvas_mood_color.b * base, 1.0)
	if darkness_rect != null:
		darkness_rect.color = Color(global_darkness_color.r, global_darkness_color.g, global_darkness_color.b, clampf(global_darkness_color.a + float(current_stage) * 0.018, 0.0, 0.85))
	if player_light != null:
		player_light.energy = player_glow_energy + float(current_stage) * 0.075
		player_light.texture_scale = player_glow_scale + float(current_stage) * 0.045


func generate_level() -> void:
	clear_level()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if in_haven_mode:
		rng.seed = 14052026
		_generate_haven_layout(rng)
		mark_borders()
		paint_ground(rng)
		create_world_depth_shadows()
		_build_haven_structures()
		_build_haven_shop_panel()
		current_tile = spawn_tile
		target_tile = spawn_tile
		target_world_position = tile_to_world(spawn_tile)
		click_path.clear()
		haven_click_target_queue.clear()
		is_moving_to_click = false
		_rebuild_room_combat_data()
		_update_camera_world_limits()
		return

	if multiplayer_enabled:
		rng.seed = int(multiplayer_map_seed + current_stage * 1000)
		print("Generating MULTIPLAYER map with seed: ", rng.seed)
	else:
		rng.randomize()
		print("Generating SINGLE PLAYER random map.")

	var stage_scale: float = get_stage_scale()
	spawn_tile = Vector2i(map_width / 2, map_height / 2)
	var previous_room: Vector2i = spawn_tile
	var direction: Vector2i = choose_direction(rng)
	var main_room_count: int = int(round(float(base_main_room_count + current_stage * 3) * stage_scale))

	for i in range(main_room_count):
		var center: Vector2i = previous_room
		if i > 0:
			if i % 2 == 0 or rng.randf() < 0.24:
				direction = rotate_direction(direction, rng)
			var side: Vector2i = rotate_direction(direction, rng)
			var min_distance: int = int(round(18.0 * stage_scale * playable_area_scale))
			var max_distance: int = int(round(31.0 * stage_scale * playable_area_scale))
			var distance: int = rng.randi_range(min_distance, max_distance)
			var drift: int = rng.randi_range(-int(round(5.0 * stage_scale)), int(round(5.0 * stage_scale)))
			center = clamp_to_map(previous_room + direction * distance + side * drift)
			carve_organic_corridor(previous_room, center, 1, rng)

		var room_size: Vector2i = random_room_size(i, main_room_count, rng)
		carve_coherent_room(center, room_size, rng)
		main_path_rooms.append(center)
		room_centers.append(center)

		if i % 2 == 1:
			carve_room_crossroads(center, room_size, rng)
		previous_room = center

	var side_room_count: int = int(round(float(base_side_room_count + current_stage * 2) * stage_scale))
	for i in range(side_room_count):
		var max_index: int = maxi(1, main_path_rooms.size() - 2)
		var start_index: int = rng.randi_range(1, max_index)
		var start_room: Vector2i = main_path_rooms[start_index]
		var branch_direction: Vector2i = choose_direction(rng)
		var branch_min_distance: int = int(round(16.0 * stage_scale * playable_area_scale))
		var branch_max_distance: int = int(round(36.0 * stage_scale * playable_area_scale))
		var branch_room: Vector2i = clamp_to_map(start_room + branch_direction * rng.randi_range(branch_min_distance, branch_max_distance))
		carve_organic_corridor(start_room, branch_room, 1, rng)

		var side_w: int = int(round(float(rng.randi_range(8, 13)) * clampf(stage_scale, 1.0, 1.8) * playable_area_scale))
		var side_h: int = int(round(float(rng.randi_range(8, 13)) * clampf(stage_scale, 1.0, 1.8) * playable_area_scale))
		carve_coherent_room(branch_room, Vector2i(side_w, side_h), rng)
		room_centers.append(branch_room)

	goal_tile = choose_far_room_from(spawn_tile, 0.96)
	mark_borders()
	paint_ground(rng)
	place_grassy_decorations(rng)
	spawn_world_trees(rng)
	_paint_world_edge_buffer(rng)
	create_world_depth_shadows()
	current_tile = spawn_tile
	target_tile = spawn_tile
	target_world_position = tile_to_world(spawn_tile)
	click_path.clear()
	haven_click_target_queue.clear()
	is_moving_to_click = false
	_rebuild_room_combat_data()
	boss_room_center = _get_room_center_for_tile(goal_tile)
	_update_camera_world_limits()


func _is_boss_room(room_center: Vector2i) -> bool:
	if boss_room_center == Vector2i(-9999, -9999):
		return false
	return room_center == boss_room_center


func _generate_haven_layout(_rng: RandomNumberGenerator) -> void:
	var center: Vector2i = Vector2i(map_width / 2, map_height / 2)
	var radius: int = clampi(haven_circle_radius, 24, mini(map_width, map_height) / 2 - world_edge_buffer_tiles - 2)
	var cross_len: int = clampi(haven_cross_half_length, 6, radius - 2)
	var cross_w: int = maxi(1, haven_cross_half_width)
	var gap_off: int = clampi(haven_gap_offset, cross_w + 2, radius - 4)
	var gap_r: int = clampi(haven_gap_radius, 4, maxi(4, radius / 2))
	haven_area_centers.clear()

	spawn_tile = center
	goal_tile = Vector2i.ZERO
	door_unlocked = true

	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var cell: Vector2i = Vector2i(x, y)
			if not is_inside_map(cell):
				continue
			var dx: int = cell.x - center.x
			var dy: int = cell.y - center.y
			if dx * dx + dy * dy > radius * radius:
				continue
			var on_vertical_cross: bool = abs(dx) <= cross_w and abs(dy) <= cross_len
			var on_horizontal_cross: bool = abs(dy) <= cross_w and abs(dx) <= cross_len
			var on_cross: bool = on_vertical_cross or on_horizontal_cross
			var inside_quadrant_gap: bool = false
			for sx in [-1, 1]:
				for sy in [-1, 1]:
					var gap_center: Vector2i = center + Vector2i(sx * gap_off, sy * gap_off)
					if cell.distance_to(gap_center) <= float(gap_r):
						inside_quadrant_gap = true
						break
				if inside_quadrant_gap:
					break
			if inside_quadrant_gap and not on_cross:
				continue

			walkable_tiles[cell] = true
			ground_biomes[cell] = "grass"
			if on_cross:
				road_tiles[cell] = true
				ground_biomes[cell] = "road"

	var north_center: Vector2i = center + Vector2i(0, -cross_len + 10)
	var east_center: Vector2i = center + Vector2i(cross_len - 10, 0)
	var west_center: Vector2i = center + Vector2i(-cross_len + 10, 0)
	var south_center: Vector2i = center + Vector2i(0, cross_len - 10)
	var ne_center: Vector2i = center + Vector2i(int(cross_len * 0.72), -int(cross_len * 0.72))
	var se_center: Vector2i = center + Vector2i(int(cross_len * 0.72), int(cross_len * 0.72))

	haven_area_centers["MainPlaza"] = center
	haven_area_centers["GoldenGardenGate"] = north_center
	haven_area_centers["RomanBazaar"] = east_center
	haven_area_centers["BloomsmithWorkshop"] = west_center
	haven_area_centers["TailorRow"] = south_center
	haven_area_centers["ApothecaryGarden"] = ne_center
	haven_area_centers["MaterialsExchange"] = se_center

	_carve_haven_plaza(center, Vector2i(11, 11), true)
	_carve_haven_plaza(north_center, Vector2i(10, 8), true)
	_carve_haven_plaza(east_center, Vector2i(10, 8), true)
	_carve_haven_plaza(west_center, Vector2i(10, 8), true)
	_carve_haven_plaza(south_center, Vector2i(10, 8), true)
	_carve_haven_plaza(ne_center, Vector2i(9, 7), true)
	_carve_haven_plaza(se_center, Vector2i(9, 7), true)

	_carve_haven_path(center, north_center, 2)
	_carve_haven_path(center, east_center, 2)
	_carve_haven_path(center, west_center, 2)
	_carve_haven_path(center, south_center, 2)
	_carve_haven_path(center, ne_center, 1)
	_carve_haven_path(center, se_center, 1)

	main_path_rooms.append(center)
	room_centers.append(center)
	room_centers.append(north_center)
	room_centers.append(east_center)
	room_centers.append(west_center)
	room_centers.append(south_center)
	room_centers.append(ne_center)
	room_centers.append(se_center)
	_setup_haven_transition_markers(center, cross_len)


func _carve_haven_plaza(center: Vector2i, half_extents: Vector2i, road_core: bool) -> void:
	for x in range(center.x - half_extents.x, center.x + half_extents.x + 1):
		for y in range(center.y - half_extents.y, center.y + half_extents.y + 1):
			var cell: Vector2i = Vector2i(x, y)
			if not is_inside_map(cell):
				continue
			var dx: float = absf(float(cell.x - center.x)) / float(maxi(1, half_extents.x))
			var dy: float = absf(float(cell.y - center.y)) / float(maxi(1, half_extents.y))
			if dx * dx + dy * dy > 1.10:
				continue
			walkable_tiles[cell] = true
			ground_biomes[cell] = "grass"
			if road_core and abs(cell.x - center.x) + abs(cell.y - center.y) <= int((half_extents.x + half_extents.y) * 0.72):
				road_tiles[cell] = true
				plaza_tiles[cell] = true
				ground_biomes[cell] = "road"


func _carve_haven_path(start: Vector2i, end: Vector2i, width: int) -> void:
	var current: Vector2i = start
	var guard: int = 0
	while current != end and guard < 1800:
		guard += 1
		mark_road_tile(current, width)
		var dx: int = end.x - current.x
		var dy: int = end.y - current.y
		if abs(dx) >= abs(dy) and dx != 0:
			current.x += signi(dx)
		elif dy != 0:
			current.y += signi(dy)
		else:
			break
	mark_road_tile(end, width)


func _decorate_haven_area(center: Vector2i, rng: RandomNumberGenerator, count: int) -> void:
	for i in range(count):
		var spread: Vector2i = Vector2i(rng.randi_range(-8, 8), rng.randi_range(-8, 8))
		var cell: Vector2i = center + spread
		if not walkable_tiles.has(cell):
			continue
		if occupied_deco_tiles.has(cell):
			continue
		if road_tiles.has(cell) and rng.randf() < 0.78:
			continue
		var use_utility: bool = rng.randf() < 0.33 and utility_deco_tiles.size() > 0
		var deco_tile: Vector2i = Vector2i.ZERO
		if use_utility:
			deco_tile = pick_existing_atlas(utility_deco_tiles, rng, ATLAS_PEDESTAL)
		else:
			deco_tile = pick_existing_atlas(plant_deco_tiles, rng, Vector2i(8, 1))
		set_atlas_cell_safe(deco_layer, cell, deco_tile)
		occupied_deco_tiles[cell] = true
		if rng.randf() < 0.45:
			create_shadow_at(tile_to_world(cell), Vector2(26.0, 7.0), 0.16)


func _setup_haven_transition_markers(center: Vector2i, cross_len: int) -> void:
	if haven_transition_root != null and is_instance_valid(haven_transition_root):
		haven_transition_root.queue_free()
	haven_transition_root = Node2D.new()
	haven_transition_root.name = "HavenTransitionMarkers"
	add_child(haven_transition_root)

	var marker_data: Array[Dictionary] = [
		{"name": "Exit_North_To_MissionGate", "tile": center + Vector2i(0, -cross_len + 2), "dir": Vector2i(0, -1)},
		{"name": "Exit_South_To_MainPlaza", "tile": center + Vector2i(0, 7), "dir": Vector2i(0, 1)},
		{"name": "Exit_East_To_RomanBazaar", "tile": center + Vector2i(cross_len - 2, 0), "dir": Vector2i(1, 0)},
		{"name": "Exit_West_To_BloomsmithWorkshop", "tile": center + Vector2i(-cross_len + 2, 0), "dir": Vector2i(-1, 0)},
		{"name": "Exit_South_To_TailorRow", "tile": center + Vector2i(0, cross_len - 2), "dir": Vector2i(0, 1)},
		{"name": "Exit_Northeast_To_ApothecaryGarden", "tile": center + Vector2i(int(cross_len * 0.72) - 1, -int(cross_len * 0.72) + 1), "dir": Vector2i(1, -1)},
		{"name": "Exit_Southeast_To_MaterialsExchange", "tile": center + Vector2i(int(cross_len * 0.72) - 1, int(cross_len * 0.72) - 1), "dir": Vector2i(1, 1)}
	]
	for entry in marker_data:
		var tile: Vector2i = entry.get("tile", center)
		var marker: Node2D = Node2D.new()
		marker.name = String(entry.get("name", "Exit"))
		marker.global_position = tile_to_world(tile)
		marker.visible = false
		marker.set_meta("tile", tile)
		marker.set_meta("direction", entry.get("dir", Vector2i.ZERO))
		haven_transition_root.add_child(marker)


func _paint_haven_transition_edge(origin_tile: Vector2i, direction: Vector2i) -> void:
	if direction == Vector2i.ZERO:
		return
	var dir: Vector2i = Vector2i(signi(direction.x), signi(direction.y))
	for i in range(0, 7):
		var cell: Vector2i = origin_tile + dir * i
		if not is_inside_map(cell):
			continue
		walkable_tiles[cell] = true
		road_tiles[cell] = true
		ground_biomes[cell] = "road"
		if i >= 4:
			border_tiles[cell] = true
		for side in [-1, 1]:
			var perp: Vector2i = Vector2i(-dir.y, dir.x) * side
			var shoulder: Vector2i = cell + perp
			if not is_inside_map(shoulder):
				continue
			border_tiles[shoulder] = true
			if i <= 4:
				walkable_tiles[shoulder] = true
				ground_biomes[shoulder] = "grass"
		if i >= 5:
			create_shadow_at(tile_to_world(cell), Vector2(36.0, 10.0), 0.24)
			if deco_layer != null and utility_deco_tiles.size() > 0:
				set_atlas_cell_safe(deco_layer, cell, pick_existing_atlas(utility_deco_tiles, RandomNumberGenerator.new(), ATLAS_PILLAR))


func _load_haven_tilesheet_texture() -> Texture2D:
	if haven_tilesheet_res_path.strip_edges() != "" and ResourceLoader.exists(haven_tilesheet_res_path):
		var res_tex: Resource = load(haven_tilesheet_res_path)
		if res_tex is Texture2D:
			return res_tex as Texture2D
	if haven_tilesheet_file_path.strip_edges() == "":
		return null
	if FileAccess.file_exists(haven_tilesheet_file_path):
		var image: Image = Image.new()
		if image.load(haven_tilesheet_file_path) == OK:
			return ImageTexture.create_from_image(image)
	return null


func _make_haven_atlas_texture(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	if sheet == null:
		return null
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return null
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	return atlas


func _build_haven_structures() -> void:
	if not in_haven_mode:
		return
	if haven_structures_root != null and is_instance_valid(haven_structures_root):
		haven_structures_root.queue_free()
	haven_structures_root = Node2D.new()
	haven_structures_root.name = "HavenStructures"
	add_child(haven_structures_root)

	var sheet: Texture2D = _load_haven_tilesheet_texture()
	if sheet == null:
		return

	var regions: Dictionary = {
		"platform": Rect2(8.0, 8.0, 260.0, 190.0),
		"portal": Rect2(252.0, 0.0, 300.0, 242.0),
		"shop": Rect2(552.0, 4.0, 316.0, 230.0),
		"stairs": Rect2(0.0, 248.0, 270.0, 205.0),
		"arch": Rect2(256.0, 232.0, 286.0, 228.0),
		"sigil": Rect2(540.0, 238.0, 328.0, 220.0)
	}

	var center_tile: Vector2i = haven_area_centers.get("MainPlaza", spawn_tile)
	haven_shop_stall_sprite = _add_haven_structure_sprite(
		"HavenShopStall",
		sheet,
		regions.get("shop", Rect2()),
		center_tile,
		Vector2(0.0, -64.0),
		haven_structure_scale * 3.0
	)


func _add_haven_structure_sprite(name: String, sheet: Texture2D, region: Rect2, tile: Vector2i, offset: Vector2, scale_value: float) -> Sprite2D:
	if haven_structures_root == null:
		return null
	var texture: AtlasTexture = _make_haven_atlas_texture(sheet, region)
	if texture == null:
		return null
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = name
	sprite.texture = texture
	sprite.centered = true
	sprite.global_position = tile_to_world(tile) + offset
	sprite.scale = Vector2.ONE * maxf(0.05, scale_value)
	sprite.z_index = 35 + int(sprite.global_position.y * 0.01)
	haven_structures_root.add_child(sprite)
	create_shadow_at(sprite.global_position + Vector2(0.0, 14.0), Vector2(42.0, 11.0), 0.20)
	return sprite


func _build_haven_shop_panel() -> void:
	if not in_haven_mode or ui_layer == null:
		return
	if haven_shop_panel != null and is_instance_valid(haven_shop_panel):
		haven_shop_panel.queue_free()
	haven_shop_panel = PanelContainer.new()
	haven_shop_panel.name = "HavenShopPanel"
	haven_shop_panel.visible = false
	haven_shop_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	haven_shop_panel.custom_minimum_size = Vector2(260.0, 170.0)
	haven_shop_panel.position = Vector2(get_viewport_rect().size.x - 278.0, 18.0)
	ui_layer.add_child(haven_shop_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	haven_shop_panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "HAVEN SHOP - CLASSES (%d coins each)" % _class_purchase_cost()
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)

	if weapon_manager == null or not weapon_manager.has_method("all_class_ids"):
		var warn: Label = Label.new()
		warn.text = "No classes available."
		vbox.add_child(warn)
		_refresh_haven_shop_panel_state()
		return

	# Only the classes the player does NOT already own appear in the shop.
	var unowned: Array = weapon_manager.call("get_unowned_class_ids")
	if unowned.is_empty():
		var done: Label = Label.new()
		done.text = "All classes owned!"
		vbox.add_child(done)
	for id_variant in unowned:
		var class_id: String = String(id_variant)
		var display_name: String = String(weapon_manager.call("get_class_display_name", class_id))
		var cost: int = _class_purchase_cost()
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = "%s - %d coins" % [display_name, cost]
		label.set_meta("base_name", display_name)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var buy: Button = Button.new()
		buy.text = "Buy"
		buy.set_meta("class_id", class_id)
		buy.pressed.connect(_buy_haven_class.bind(class_id, display_name, label, buy))
		row.add_child(buy)
		vbox.add_child(row)
		_refresh_haven_shop_item_ui(class_id, label, buy)
	_refresh_haven_shop_panel_state()


func _class_purchase_cost() -> int:
	if weapon_manager != null:
		var script: Script = weapon_manager.get_script()
		if script != null:
			var consts: Dictionary = script.get_script_constant_map()
			if consts.has("CLASS_COST"):
				return int(consts["CLASS_COST"])
	return 100


func _refresh_haven_shop_item_ui(class_id: String, label: Label, button: Button) -> void:
	var save: Node = get_node_or_null("/root/SaveManager")
	var coins: int = 0
	var cost: int = _class_purchase_cost()
	var base_name: String = String(label.get_meta("base_name", label.text))
	if save != null:
		coins = int(save.coins)
	var owned: bool = weapon_manager != null and bool(weapon_manager.call("is_class_owned", class_id))
	if owned:
		label.text = base_name + " - Owned"
		button.disabled = true
		button.text = "Owned"
		return
	label.text = "%s - %d coins" % [base_name, cost]
	button.disabled = coins < cost
	button.text = "Buy"


func _buy_haven_class(class_id: String, display_name: String, label: Label, button: Button) -> void:
	if weapon_manager == null or not weapon_manager.has_method("purchase_class"):
		return
	if bool(weapon_manager.call("is_class_owned", class_id)):
		return
	var save: Node = get_node_or_null("/root/SaveManager")
	if save != null and int(save.coins) < _class_purchase_cost():
		show_floating_text(player.global_position + Vector2(0.0, -24.0), "NOT ENOUGH COINS", Color(1.0, 0.35, 0.35, 0.95))
		return
	if not bool(weapon_manager.call("purchase_class", class_id)):
		show_floating_text(player.global_position + Vector2(0.0, -24.0), "PURCHASE FAILED", Color(1.0, 0.35, 0.35, 0.95))
		return
	show_floating_text(player.global_position + Vector2(0.0, -24.0), "UNLOCKED " + display_name, Color(0.75, 1.0, 0.82, 1.0))
	# Rebuild the shop so the just-bought class drops off the list.
	_build_haven_shop_panel()
	haven_shop_open = true
	_refresh_haven_shop_panel_state()
	update_hud()


func _refresh_haven_shop_panel_state() -> void:
	if haven_shop_panel == null or not is_instance_valid(haven_shop_panel):
		return
	haven_shop_panel.visible = game_started and not is_dead and in_haven_mode and haven_shop_open
	var viewport_size: Vector2 = get_viewport_rect().size
	haven_shop_panel.position = Vector2(viewport_size.x - haven_shop_panel.custom_minimum_size.x - 18.0, 18.0)
	for row_node in haven_shop_panel.find_children("*", "HBoxContainer", true, false):
		var row: HBoxContainer = row_node as HBoxContainer
		if row == null or row.get_child_count() < 2:
			continue
		var label: Label = row.get_child(0) as Label
		var button: Button = row.get_child(1) as Button
		if label == null or button == null:
			continue
		var class_id: String = String(button.get_meta("class_id", ""))
		if class_id == "":
			continue
		_refresh_haven_shop_item_ui(class_id, label, button)


func _try_toggle_haven_shop_from_click(world_pos: Vector2) -> bool:
	if not in_haven_mode:
		return false
	if haven_shop_stall_sprite == null or not is_instance_valid(haven_shop_stall_sprite):
		return false
	var distance: float = haven_shop_stall_sprite.global_position.distance_to(world_pos)
	if distance > 170.0:
		return false
	haven_shop_open = not haven_shop_open
	_refresh_haven_shop_panel_state()
	return true


func random_room_size(index: int, total: int, rng: RandomNumberGenerator) -> Vector2i:
	var stage_scale: float = clampf(get_stage_scale(), 1.0, 1.65)
	var result: Vector2i = Vector2i.ZERO

	if index == 0:
		result = Vector2i(15, 13)
	elif index == total - 1:
		result = Vector2i(rng.randi_range(17, 23), rng.randi_range(14, 20))
	elif index % 3 == 0:
		result = Vector2i(rng.randi_range(13, 20), rng.randi_range(11, 17))
	else:
		result = Vector2i(rng.randi_range(10, 15), rng.randi_range(9, 14))

	return Vector2i(
		int(round(float(result.x) * stage_scale * playable_area_scale)),
		int(round(float(result.y) * stage_scale * playable_area_scale))
	)


func carve_coherent_room(center: Vector2i, size: Vector2i, rng: RandomNumberGenerator) -> void:
	var half_w: int = size.x / 2
	var half_h: int = size.y / 2
	for x in range(center.x - half_w, center.x + half_w + 1):
		for y in range(center.y - half_h, center.y + half_h + 1):
			var cell: Vector2i = Vector2i(x, y)
			if not is_inside_map(cell):
				continue
			var dx: float = absf(float(cell.x - center.x)) / float(maxi(1, half_w))
			var dy: float = absf(float(cell.y - center.y)) / float(maxi(1, half_h))
			var edge_score: float = maxf(dx, dy)
			if edge_score > 0.91 and rng.randf() < 0.35:
				continue
			walkable_tiles[cell] = true
			room_tiles[cell] = true
			ground_biomes[cell] = "grass"

	for x in range(center.x - half_w + 2, center.x + half_w - 1):
		if rng.randf() < room_horizontal_road_chance:
			mark_road_tile(Vector2i(x, center.y), 0)
	for y in range(center.y - half_h + 2, center.y + half_h - 1):
		if rng.randf() < room_vertical_road_chance:
			mark_road_tile(Vector2i(center.x, y), 0)

	plaza_tiles[center] = true
	mark_road_tile(center, 1)


func carve_organic_corridor(a: Vector2i, b: Vector2i, width: int, rng: RandomNumberGenerator) -> void:
	var current: Vector2i = a
	var safety: int = 0
	var prefer_x: bool = abs(b.x - a.x) >= abs(b.y - a.y)
	mark_road_tile(current, width)
	while current != b and safety < 1800:
		safety += 1
		var dx: int = b.x - current.x
		var dy: int = b.y - current.y
		var step: Vector2i = Vector2i.ZERO
		if prefer_x and dx != 0:
			step = Vector2i(signi(dx), 0)
		elif dy != 0:
			step = Vector2i(0, signi(dy))
		elif dx != 0:
			step = Vector2i(signi(dx), 0)

		if rng.randf() < 0.15:
			prefer_x = not prefer_x
		if step == Vector2i.ZERO:
			break

		current = clamp_to_map(current + step)
		mark_road_tile(current, width)
		if rng.randf() < 0.11:
			var soft_edge: Vector2i = current + rotate_direction(step, rng)
			if is_inside_map(soft_edge):
				walkable_tiles[soft_edge] = true
				ground_biomes[soft_edge] = "grass"


func mark_road_tile(center: Vector2i, radius: int) -> void:
	var effective_radius: int = maxi(0, radius)
	for x in range(center.x - effective_radius, center.x + effective_radius + 1):
		for y in range(center.y - effective_radius, center.y + effective_radius + 1):
			var cell: Vector2i = Vector2i(x, y)
			if not is_inside_map(cell):
				continue
			if abs(cell.x - center.x) + abs(cell.y - center.y) <= effective_radius + 1:
				walkable_tiles[cell] = true
				road_tiles[cell] = true
				ground_biomes[cell] = "road"


func carve_room_crossroads(center: Vector2i, size: Vector2i, rng: RandomNumberGenerator) -> void:
	var split_count: int = rng.randi_range(1, 2)
	for i in range(split_count):
		var dir: Vector2i = choose_direction(rng)
		var end: Vector2i = clamp_to_map(center + dir * rng.randi_range(8, 16))
		carve_organic_corridor(center, end, 0, rng)


func mark_borders() -> void:
	border_tiles.clear()
	for cell_variant in walkable_tiles.keys():
		var cell: Vector2i = cell_variant
		if is_edge_cell(cell):
			border_tiles[cell] = true


func paint_ground(rng: RandomNumberGenerator) -> void:
	for cell_variant in walkable_tiles.keys():
		var cell: Vector2i = cell_variant
		var chosen: Vector2i = Vector2i(0, 0)
		if plaza_tiles.has(cell):
			chosen = pick_existing_atlas([Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)], rng, Vector2i(5, 0))
		elif road_tiles.has(cell):
			var neighbors: int = count_road_neighbors(cell)
			if neighbors >= 3:
				chosen = pick_existing_atlas(road_core_tiles, rng, Vector2i(4, 0))
			else:
				chosen = pick_existing_atlas([Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0)], rng, Vector2i(5, 0))
		elif border_tiles.has(cell):
			if current_stage >= 3 and rng.randf() < 0.34:
				chosen = pick_existing_atlas(ruin_border_tiles, rng, Vector2i(0, 1))
			else:
				chosen = pick_existing_atlas(stone_border_tiles, rng, Vector2i(8, 0))
		else:
			if rng.randf() < grass_floor_chance:
				chosen = pick_existing_atlas(grass_core_tiles, rng, Vector2i(0, 0))
			else:
				chosen = pick_existing_atlas(grass_detail_tiles, rng, Vector2i(1, 0))
		set_atlas_cell_safe(tilemap, cell, chosen)


func place_grassy_decorations(rng: RandomNumberGenerator) -> void:
	occupied_deco_tiles.clear()
	var cluster_count: int = int(round(float(26 + current_stage * 6) * decoration_density))
	for i in range(cluster_count):
		var center: Vector2i = get_random_walkable_cell(rng)
		if center.distance_to(spawn_tile) < 8.0 or center.distance_to(goal_tile) < 4.0:
			continue
		var cluster_radius: int = rng.randi_range(2, 5)
		var plant_count: int = rng.randi_range(3, 8)
		for j in range(plant_count):
			var offset: Vector2i = Vector2i(rng.randi_range(-cluster_radius, cluster_radius), rng.randi_range(-cluster_radius, cluster_radius))
			var cell: Vector2i = center + offset
			if not can_place_deco(cell):
				continue
			if road_tiles.has(cell) and rng.randf() < 0.98:
				continue
			var decor_tile: Vector2i = pick_existing_atlas(plant_deco_tiles, rng, Vector2i(8, 1))
			set_atlas_cell_safe(deco_layer, cell, decor_tile)
			occupied_deco_tiles[cell] = true
			if rng.randf() < 0.18:
				create_shadow_at(tile_to_world(cell), Vector2(26.0, 7.0), 0.16)

	for room_center in room_centers:
		if rng.randf() > landmark_density:
			continue
		var cell2: Vector2i = room_center + Vector2i(rng.randi_range(-4, 4), rng.randi_range(-4, 4))
		if not can_place_deco(cell2):
			continue
		var utility_tile: Vector2i = pick_existing_atlas(utility_deco_tiles, rng, ATLAS_PEDESTAL)
		set_atlas_cell_safe(deco_layer, cell2, utility_tile)
		occupied_deco_tiles[cell2] = true
		create_shadow_at(tile_to_world(cell2), Vector2(42.0, 12.0), 0.24)


func spawn_world_trees(rng: RandomNumberGenerator) -> void:
	clear_world_trees()
	if world_trees_root == null or world_tree_textures.is_empty():
		return
	var attempts: int = world_tree_count * 8
	var placed: int = 0
	while placed < world_tree_count and attempts > 0:
		attempts -= 1
		var cell: Vector2i = get_random_walkable_cell(rng)
		if cell.distance_to(spawn_tile) < 7.0 or cell.distance_to(goal_tile) < 5.0:
			continue
		if key_tiles.has(cell) or cell == spawn_tile or cell == goal_tile:
			continue
		if road_tiles.has(cell) and rng.randf() < 0.88:
			continue
		if occupied_deco_tiles.has(cell):
			continue
		var world_pos: Vector2 = tile_to_world(cell) + Vector2(rng.randf_range(-10.0, 10.0), rng.randf_range(-8.0, 6.0))
		var tree_texture: Texture2D = world_tree_textures[rng.randi_range(0, world_tree_textures.size() - 1)]
		var scale_jitter: float = rng.randf_range(0.88, 1.18) * world_tree_scale
		var tree_node: Node2D = _create_world_tree_node(placed, world_pos, cell, tree_texture, scale_jitter)
		world_trees_root.add_child(tree_node)
		world_tree_nodes.append(tree_node)
		occupied_deco_tiles[cell] = true
		placed += 1


func _create_world_tree_node(index: int, world_pos: Vector2, tile: Vector2i, tree_texture: Texture2D, scale_value: float) -> Node2D:
	var tree_node: Node2D = Node2D.new()
	tree_node.name = "WorldTree_%d" % index
	tree_node.global_position = world_pos
	tree_node.z_as_relative = false
	tree_node.set_meta("tree_tile", tile)

	var sprite_scale: Vector2 = Vector2(scale_value, scale_value)
	var sprite_offset: Vector2 = Vector2(0.0, -36.0)

	var outline_sprite: Sprite2D = Sprite2D.new()
	outline_sprite.name = "Outline"
	outline_sprite.texture = tree_texture
	outline_sprite.centered = true
	outline_sprite.offset = sprite_offset
	outline_sprite.scale = sprite_scale * world_tree_outline_scale
	outline_sprite.modulate = world_tree_outline_color
	outline_sprite.show_behind_parent = true
	outline_sprite.z_index = -1
	tree_node.add_child(outline_sprite)

	var tree_sprite: Sprite2D = Sprite2D.new()
	tree_sprite.name = "Foliage"
	tree_sprite.texture = tree_texture
	tree_sprite.centered = true
	tree_sprite.offset = sprite_offset
	tree_sprite.scale = sprite_scale
	tree_node.add_child(tree_sprite)

	var lighting: Node = get_node_or_null("/root/LightingManager")
	if lighting != null and lighting.has_method("attach_tree_lighting"):
		lighting.call("attach_tree_lighting", tree_node)

	return tree_node


func _is_player_near_tree_tile(player_tile: Vector2i, tree_tile: Vector2i) -> bool:
	var delta: Vector2i = player_tile - tree_tile
	return maxi(absi(delta.x), absi(delta.y)) <= world_tree_fade_tile_radius


func _set_world_tree_visual_alpha(tree_node: Node2D, alpha: float) -> void:
	var foliage: Sprite2D = tree_node.get_node_or_null("Foliage") as Sprite2D
	if foliage != null:
		foliage.modulate = Color(1.0, 1.0, 1.0, alpha)
	var outline: Sprite2D = tree_node.get_node_or_null("Outline") as Sprite2D
	if outline != null:
		var outline_alpha: float = alpha * world_tree_outline_color.a
		outline.modulate = Color(
			world_tree_outline_color.r,
			world_tree_outline_color.g,
			world_tree_outline_color.b,
			outline_alpha
		)


func clear_world_trees() -> void:
	for tree_node in world_tree_nodes:
		if is_instance_valid(tree_node):
			tree_node.queue_free()
	world_tree_nodes.clear()
	if world_trees_root != null:
		for child in world_trees_root.get_children():
			child.queue_free()


func can_place_deco(cell: Vector2i) -> bool:
	if not walkable_tiles.has(cell):
		return false
	if occupied_deco_tiles.has(cell):
		return false
	if cell == spawn_tile or cell == goal_tile:
		return false
	if key_tiles.has(cell):
		return false
	if count_walkable_neighbors(cell) < 3:
		return false
	return true


func create_world_depth_shadows() -> void:
	for shadow in shadow_nodes:
		if is_instance_valid(shadow):
			shadow.queue_free()
	shadow_nodes.clear()

	if island_shadow_layer != null:
		island_shadow_layer.clear()
		island_shadow_layer.position = island_shadow_offset
		island_shadow_layer.modulate = island_shadow_color
		island_shadow_layer.visible = enable_island_drop_shadow

	if enable_island_drop_shadow and island_shadow_layer != null:
		for cell_variant in border_tiles.keys():
			var cell: Vector2i = cell_variant
			if tile_exists_atlas(island_shadow_atlas_tile):
				set_atlas_cell_safe(island_shadow_layer, cell, island_shadow_atlas_tile)

	create_shadow_for_node(player, Vector2(38.0, 12.0), 0.30)


func create_shadow_for_node(target: Node2D, shadow_size: Vector2, alpha: float) -> void:
	if target == null:
		return
	var shadow: Polygon2D = Polygon2D.new()
	shadow.name = "SoftShadow"
	shadow.polygon = make_ellipse_polygon(shadow_size.x, shadow_size.y, 24)
	shadow.color = Color(0.0, 0.0, 0.0, alpha)
	shadow.position = Vector2(9.0, 18.0)
	shadow.z_index = -3
	target.add_child(shadow)
	shadow_nodes.append(shadow)


func create_shadow_at(world_position: Vector2, shadow_size: Vector2, alpha: float) -> void:
	var shadow: Polygon2D = Polygon2D.new()
	shadow.name = "GroundSoftShadow"
	shadow.polygon = make_ellipse_polygon(shadow_size.x, shadow_size.y, 24)
	shadow.color = Color(0.0, 0.0, 0.0, alpha)
	shadow.global_position = world_position + Vector2(8.0, 18.0)
	shadow.z_index = 8
	add_child(shadow)
	shadow_nodes.append(shadow)


func make_ellipse_polygon(width: float, height: float, points: int) -> PackedVector2Array:
	var arr: PackedVector2Array = PackedVector2Array()
	for i in range(points):
		var t: float = TAU * float(i) / float(points)
		arr.append(Vector2(cos(t) * width * 0.5, sin(t) * height * 0.5))
	return arr


func place_keys() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()

	if multiplayer_enabled:
		rng.seed = int(multiplayer_map_seed + current_stage * 1000 + 777)
		print("Placing MULTIPLAYER keys with seed: ", rng.seed)
	else:
		rng.randomize()
	key_tiles.clear()
	collected_keys.clear()
	var key_count: int = clampi(3 + int(round(float(current_stage - 1) * key_count_growth * get_stage_scale())) + current_stage, 3, 8)
	var used: Dictionary = {}
	for i in range(key_count):
		var percentile: float = 0.42 + float(i) * 0.11
		var key_cell: Vector2i = choose_far_room_from(spawn_tile, clampf(percentile, 0.42, 0.88))
		var tries: int = 0
		while used.has(key_cell) or key_cell == goal_tile or key_cell.distance_to(spawn_tile) < 10.0:
			key_cell = get_random_walkable_cell(rng)
			tries += 1
			if tries > 80:
				break
		used[key_cell] = true
		key_tiles.append(key_cell)
		if deco_layer != null:
			deco_layer.erase_cell(key_cell)
		set_atlas_cell_safe(deco_layer, key_cell, ATLAS_KEY)
		create_shadow_at(tile_to_world(key_cell), Vector2(24.0, 7.0), 0.22)


func spawn_level_mobs() -> void:
	if mob_root == null:
		return
	for child in mob_root.get_children():
		child.queue_free()
	room_slime_counts.clear()
	side_room_spawned.clear()
	cleared_main_rooms.clear()
	active_main_room = Vector2i(-9999, -9999)
	active_main_wave_index = -1
	active_main_wave_spawning = false
	active_main_room_locked = false
	active_main_blocked_tiles.clear()
	_clear_main_block_markers()
	if not mobs_enabled or not spawn_mobs_on_level_start:
		return

	var side_spawn_cap: int = clampi(slime_spawn_count, 0, global_mob_cap)
	if side_spawn_cap <= 0:
		return

	# Side rooms get immediate one-batch danger. Main rooms are wave encounters on entry.
	var spawned_total: int = 0
	for center_variant in room_centers:
		var center: Vector2i = center_variant
		if main_room_lookup.has(center):
			room_slime_counts[center] = 0
			continue
		if spawned_total >= side_spawn_cap:
			break
		var rng: RandomNumberGenerator = _make_room_rng(center, 31337)
		var batch_count: int = rng.randi_range(side_room_batch_min, side_room_batch_max)
		batch_count = mini(batch_count, side_spawn_cap - spawned_total)
		if batch_count <= 0:
			continue
		side_room_spawned[center] = true
		_spawn_slimes_for_room(center, batch_count, false)
		spawned_total += batch_count


func _update_room_encounter_flow(_delta: float) -> void:
	if not mobs_enabled or mob_root == null:
		return
	var room_center: Vector2i = _get_room_center_for_tile(current_tile)
	if room_center == Vector2i(-9999, -9999):
		return
	var room_cells: Array[Vector2i] = _get_room_cells(room_center)
	if room_cells.is_empty():
		return

	if main_room_lookup.has(room_center):
		if not cleared_main_rooms.has(room_center) and active_main_room != room_center and not active_main_wave_spawning:
			_start_main_room_encounter(room_center)
	else:
		if not side_room_spawned.has(room_center):
			side_room_spawned[room_center] = true
			var side_rng: RandomNumberGenerator = _make_room_rng(room_center, 991)
			var side_batch: int = side_rng.randi_range(side_room_batch_min, side_room_batch_max)
			_spawn_slimes_for_room(room_center, side_batch, false)

	if active_main_room != Vector2i(-9999, -9999) and not active_main_wave_spawning:
		var alive_count: int = int(room_slime_counts.get(active_main_room, 0))
		if alive_count <= 0:
			if active_main_wave_index + 1 < active_wave_counts.size():
				_queue_next_main_wave()
			else:
				_complete_main_room_encounter()


func _rebuild_room_combat_data() -> void:
	main_room_lookup.clear()
	room_tiles_by_center.clear()
	room_membership.clear()
	for center_variant in main_path_rooms:
		var center_main: Vector2i = center_variant
		main_room_lookup[center_main] = true
	for center_variant in room_centers:
		var center: Vector2i = center_variant
		var members: Array[Vector2i] = _collect_room_tiles_for_center(center)
		room_tiles_by_center[center] = members
		for tile in members:
			room_membership[tile] = center


func _collect_room_tiles_for_center(center: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var start: Vector2i = center
	if not room_tiles.has(start):
		for radius in range(1, 4):
			var found: bool = false
			for x in range(center.x - radius, center.x + radius + 1):
				for y in range(center.y - radius, center.y + radius + 1):
					var candidate: Vector2i = Vector2i(x, y)
					if room_tiles.has(candidate):
						start = candidate
						found = true
						break
				if found:
					break
			if found:
				break
	if not room_tiles.has(start):
		result.append(center)
		return result

	var queue: Array[Vector2i] = [start]
	var visited: Dictionary = {}
	visited[start] = true
	var head: int = 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		result.append(current)
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next_tile: Vector2i = current + dir
			if visited.has(next_tile):
				continue
			if not room_tiles.has(next_tile):
				continue
			visited[next_tile] = true
			queue.append(next_tile)
	return result


func _get_room_center_for_tile(tile: Vector2i) -> Vector2i:
	if room_membership.has(tile):
		return room_membership[tile]
	return Vector2i(-9999, -9999)


func _make_room_rng(room_center: Vector2i, salt: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if multiplayer_enabled:
		rng.seed = int(multiplayer_map_seed + current_stage * 1000 + salt + room_center.x * 97 + room_center.y * 131)
	else:
		rng.seed = int(Time.get_unix_time_from_system()) + salt + room_center.x * 97 + room_center.y * 131
	return rng


func _spawn_slimes_for_room(room_center: Vector2i, requested_count: int, _is_main_room: bool) -> void:
	if mob_root == null:
		return
	var cells: Array[Vector2i] = _get_room_cells(room_center)
	if cells.is_empty():
		return
	# Boss room is a tougher final encounter: allow a larger on-screen mob cap.
	var effective_cap: int = global_mob_cap
	if active_room_is_boss and room_center == active_main_room:
		effective_cap = maxi(global_mob_cap, 18)
	var remaining_global: int = maxi(0, effective_cap - _get_total_alive_slime_count())
	var spawn_count: int = mini(requested_count, remaining_global)
	if spawn_count <= 0:
		return
	var room_rng: RandomNumberGenerator = _make_room_rng(room_center, 1701 + spawn_count)
	for i in range(spawn_count):
		var spawn_tile_candidate: Vector2i = _pick_slime_spawn_tile_from_room(cells, room_rng)
		if spawn_tile_candidate == Vector2i(-9999, -9999):
			continue
		var mob: Node2D = _create_wave_mob(room_rng) as Node2D
		if mob == null:
			push_warning("World: skipped mob spawn in room %s (create failed)." % room_center)
			continue
		mob_root.add_child(mob)
		mob.global_position = tile_to_world(spawn_tile_candidate)
		var config: Dictionary = {"room_center": room_center, "world_ref": self}
		var enemy_id: String = String(mob.get_meta("enemy_id", "slime"))
		if mob is BaseEnemy:
			config["enemy_id"] = enemy_id
		elif enemy_id == "slime":
			var variation: Dictionary = _generate_slime_variation(room_rng)
			config.merge({
				"max_health": variation.get("max_health", slime_max_health),
				"max_hearts": variation.get("max_hearts", 2),
				"heart_value": variation.get("heart_value", slime_health_per_heart),
				"move_speed": variation.get("move_speed", slime_move_speed),
				"jump_interval": slime_jump_interval,
				"jump_distance": slime_jump_distance,
				"jump_height": slime_jump_height,
				"jump_duration": slime_jump_duration,
				"contact_damage": slime_contact_damage,
				"contact_damage_cooldown": slime_contact_damage_cooldown,
				"contact_range": slime_contact_range,
				"texture": slime_texture,
				"variant_scale": variation.get("scale", 1.0),
				"variant_tint": variation.get("tint", Color.WHITE),
				"speed_multiplier": variation.get("speed_multiplier", 1.0)
			}, true)
			enemy_id = String(variation.get("drop_id", "slime"))
		if mob.has_method("configure"):
			mob.call("configure", player, config)
		mob.set_meta("drop_id", enemy_id)
		if not is_world_position_on_walkable_tile(mob.global_position):
			mob.global_position = snap_world_position_to_walkable(mob.global_position)
		var death_cb: Callable = Callable(self, "_on_slime_died")
		if mob.has_signal("slime_died") and not mob.is_connected("slime_died", death_cb):
			mob.connect("slime_died", death_cb)
		room_slime_counts[room_center] = int(room_slime_counts.get(room_center, 0)) + 1
		_spawn_enemy_spawn_fx(mob.global_position)


func _create_slime_mob_node() -> Node2D:
	var slime: Node2D = SLIME_MOB_SCRIPT.new() as Node2D
	if slime != null:
		slime.set_meta("enemy_id", "slime")
	return slime


func _create_wave_mob(rng: RandomNumberGenerator) -> Node2D:
	if not enable_meadow_cult_mobs:
		return _create_slime_mob_node()
	var enemy_id: String = _pick_wave_enemy_id(rng)
	var script: Script = _script_for_enemy_id(enemy_id)
	if script == null:
		push_warning("World: missing mob script for '%s', using slime." % enemy_id)
		return _create_slime_mob_node()
	if not script.can_instantiate():
		push_warning("World: cannot instantiate '%s', using slime." % enemy_id)
		return _create_slime_mob_node()
	var mob: Node2D = script.new() as Node2D
	if mob == null:
		push_warning("World: mob.new() returned null for '%s', using slime." % enemy_id)
		return _create_slime_mob_node()
	mob.set_meta("enemy_id", enemy_id)
	return mob


func _pick_wave_enemy_id(rng: RandomNumberGenerator) -> String:
	var early: PackedStringArray = PackedStringArray(["slime", "shellcloak_oracle", "petalwretch_ooze", "lambent_idol"])
	var mid: PackedStringArray = PackedStringArray(["slime", "rootbound_acolyte", "bloommaw_lurker", "bellpilgrim_crawler"])
	var late: PackedStringArray = PackedStringArray(["mothcloak_priest", "multieye_cherub", "lambent_idol"])
	var symmetry_priority: PackedStringArray = PackedStringArray([
		"lambent_idol",
		"multieye_cherub",
		"bloommaw_lurker",
		"bellpilgrim_crawler",
		"petalwretch_ooze",
		"slime"
	])
	var full_cult: PackedStringArray = PackedStringArray([
		"bellpilgrim_crawler",
		"rootbound_acolyte", "rootbound_acolyte",
		"shellcloak_oracle", "shellcloak_oracle",
		"bloommaw_lurker",
		"slime"
	])
	if current_stage <= 1:
		if rng.randf() < 0.52:
			return symmetry_priority[rng.randi_range(0, symmetry_priority.size() - 1)]
		return early[rng.randi_range(0, early.size() - 1)]
	if current_stage == 2:
		if rng.randf() < 0.55:
			return symmetry_priority[rng.randi_range(0, symmetry_priority.size() - 1)]
		if rng.randf() < 0.78:
			return mid[rng.randi_range(0, mid.size() - 1)]
		return early[rng.randi_range(0, early.size() - 1)]
	if current_stage == 3 and rng.randf() < 0.46:
		return symmetry_priority[rng.randi_range(0, symmetry_priority.size() - 1)]
	if current_stage >= 4 and rng.randf() < 0.32:
		return full_cult[rng.randi_range(0, full_cult.size() - 1)]
	var merged: PackedStringArray = PackedStringArray()
	merged.append_array(early)
	merged.append_array(mid)
	merged.append_array(late)
	return merged[rng.randi_range(0, merged.size() - 1)]


func _script_for_enemy_id(enemy_id: String) -> Script:
	match enemy_id:
		"slime":
			return SLIME_MOB_SCRIPT
		"shellcloak_oracle":
			return SHELLCLOAK_ORACLE_SCRIPT
		"lambent_idol":
			return LAMBENT_IDOL_SCRIPT
		"bellpilgrim_crawler":
			return BELLPILGRIM_CRAWLER_SCRIPT
		"rootbound_acolyte":
			return ROOTBOUND_ACOLYTE_SCRIPT
		"mothcloak_priest":
			return MOTHCLOAK_PRIEST_SCRIPT
		"multieye_cherub":
			return MULTIEYE_CHERUB_SCRIPT
		"petalwretch_ooze":
			return PETALWRETCH_OOZE_SCRIPT
		"bloommaw_lurker":
			return BLOOMMAW_LURKER_SCRIPT
		_:
			return null


func _pick_slime_spawn_tile_from_room(room_cells: Array[Vector2i], rng: RandomNumberGenerator) -> Vector2i:
	var candidates: Array[Vector2i] = []
	var fallback_candidates: Array[Vector2i] = []
	for cell in room_cells:
		if key_tiles.has(cell):
			continue
		if cell == goal_tile:
			continue
		if not walkable_tiles.has(cell):
			continue
		fallback_candidates.append(cell)
		var dist: float = cell.distance_to(current_tile)
		if dist < slime_spawn_min_distance_from_player or dist > slime_spawn_max_distance_from_player:
			continue
		candidates.append(cell)
	if candidates.is_empty() and not fallback_candidates.is_empty():
		candidates = fallback_candidates
	if candidates.is_empty():
		return Vector2i(-9999, -9999)
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func is_walkable_tile(tile: Vector2i) -> bool:
	return walkable_tiles.has(tile)


func is_world_position_on_walkable_tile(world_pos: Vector2) -> bool:
	return walkable_tiles.has(world_to_tile(world_pos))


func snap_world_position_to_walkable(world_pos: Vector2, search_radius: int = 6) -> Vector2:
	var tile: Vector2i = world_to_tile(world_pos)
	if walkable_tiles.has(tile):
		return world_pos
	var nearest: Vector2i = find_nearest_walkable(tile, search_radius)
	if nearest == Vector2i(-9999, -9999):
		return world_pos
	return tile_to_world(nearest)


func _generate_slime_variation(rng: RandomNumberGenerator) -> Dictionary:
	var roll: float = rng.randf()
	var hearts: int = 2
	var scale_value: float = 1.0
	var speed_mult: float = 1.0
	var min_hearts: int = maxi(1, slime_min_hearts)
	var max_hearts: int = maxi(min_hearts, slime_max_hearts)
	if roll < 0.33:
		hearts = rng.randi_range(min_hearts, mini(2, max_hearts))
		scale_value = rng.randf_range(0.82, 0.96)
		speed_mult = rng.randf_range(1.05, 1.22)
	elif roll < 0.76:
		hearts = rng.randi_range(clampi(2, min_hearts, max_hearts), clampi(3, min_hearts, max_hearts))
		scale_value = rng.randf_range(0.96, 1.06)
		speed_mult = rng.randf_range(0.95, 1.05)
	else:
		hearts = rng.randi_range(clampi(4, min_hearts, max_hearts), max_hearts)
		scale_value = rng.randf_range(1.10, 1.26)
		speed_mult = rng.randf_range(0.74, 0.90)
	var drop_id: String = "slime"
	if hearts >= 4:
		drop_id = "elite_slime"
	elif hearts >= 3:
		drop_id = "strong_slime"
	return {
		"max_hearts": hearts,
		"heart_value": slime_health_per_heart,
		"max_health": float(hearts) * slime_health_per_heart,
		"scale": scale_value,
		"speed_multiplier": speed_mult,
		"move_speed": slime_move_speed * speed_mult,
		"drop_id": drop_id,
		"tint": Color(
			rng.randf_range(0.90, 1.08),
			rng.randf_range(0.90, 1.08),
			rng.randf_range(0.90, 1.10),
			1.0
		)
	}


func _on_slime_died(slime: Node2D, room_center: Vector2i) -> void:
	var death_pos: Vector2 = slime.global_position if slime != null else player.global_position
	_spawn_enemy_defeat_fx(death_pos)
	var drop_mgr: Node = get_node_or_null("/root/DropManager")
	if drop_mgr != null and drop_mgr.has_method("spawn_mob_drops"):
		var mob_id: String = "slime"
		if slime != null and slime.has_meta("drop_id"):
			mob_id = String(slime.get_meta("drop_id"))
		if mob_id != "":
			var bonus: int = 1 if mob_id == "elite_slime" or mob_id == "multieye_cherub" or mob_id == "bloommaw_lurker" else 0
			drop_mgr.call("spawn_mob_drops", death_pos, mob_id, bonus)
	var tutorial: Node = get_node_or_null("/root/TutorialManager")
	if tutorial != null and tutorial.has_method("notify_trigger"):
		tutorial.call("notify_trigger", "pickup")
	if room_center == Vector2i(-9999, -9999):
		return
	var remaining: int = int(room_slime_counts.get(room_center, 0)) - 1
	room_slime_counts[room_center] = maxi(0, remaining)


func _get_total_alive_slime_count() -> int:
	if mob_root == null:
		return 0
	var total: int = 0
	for child in mob_root.get_children():
		if child is Node2D and child.has_method("take_damage"):
			total += 1
	return total


func _start_main_room_encounter(room_center: Vector2i) -> void:
	active_main_room = room_center
	active_main_wave_index = -1
	active_main_wave_spawning = false
	active_room_is_boss = _is_boss_room(room_center)
	active_wave_counts = boss_room_wave_counts if active_room_is_boss else main_room_wave_counts
	room_slime_counts[room_center] = 0
	if active_room_is_boss:
		show_floating_text(tile_to_world(room_center), "BOSS ROOM", Color(1.0, 0.32, 0.30, 1.0))
	else:
		show_floating_text(tile_to_world(room_center), "ROOM LOCKED", Color(1.0, 0.58, 0.38, 1.0))
	if enable_main_room_lockdown:
		_lock_room_exits(room_center)
	start_screen_shake(lock_screen_shake_strength * (1.6 if active_room_is_boss else 1.0), 0.12)
	if wave_visual_controller != null and wave_visual_controller.has_method("on_room_locked"):
		wave_visual_controller.call("on_room_locked", room_center)
	var tutorial: Node = get_node_or_null("/root/TutorialManager")
	if tutorial != null and tutorial.has_method("notify_trigger"):
		tutorial.call("notify_trigger", "room_enter")
	_queue_next_main_wave()


func _queue_next_main_wave() -> void:
	if active_main_room == Vector2i(-9999, -9999):
		return
	if active_main_wave_spawning:
		return
	active_main_wave_spawning = true
	active_main_wave_index += 1
	if active_wave_counts.is_empty():
		active_wave_counts = boss_room_wave_counts if active_room_is_boss else main_room_wave_counts
	if active_main_wave_index >= active_wave_counts.size():
		active_main_wave_spawning = false
		_complete_main_room_encounter()
		return
	var total_waves: int = active_wave_counts.size()
	var wave_label: String = "WAVE %d / %d" % [active_main_wave_index + 1, total_waves]
	if active_room_is_boss:
		wave_label = "BOSS WAVE %d / %d" % [active_main_wave_index + 1, total_waves]
	show_floating_text(tile_to_world(active_main_room), wave_label, Color(1.0, 0.62, 0.40, 1.0) if active_room_is_boss else Color(1.0, 0.90, 0.52, 1.0))
	if wave_visual_controller != null and wave_visual_controller.has_method("on_wave_start"):
		wave_visual_controller.call("on_wave_start", active_main_wave_index, active_main_room)
	var timer: SceneTreeTimer = get_tree().create_timer(maxf(0.05, next_wave_delay))
	timer.timeout.connect(func() -> void:
		active_main_wave_spawning = false
		var wave_count: int = int(active_wave_counts[active_main_wave_index])
		_warn_slime_spawn_positions(active_main_room, wave_count)
		_spawn_slimes_for_room(active_main_room, wave_count, true)
	)


func _complete_main_room_encounter() -> void:
	if active_main_room == Vector2i(-9999, -9999):
		return
	cleared_main_rooms[active_main_room] = true
	show_floating_text(tile_to_world(active_main_room), "ROOM CLEARED", Color(0.50, 1.0, 0.58, 1.0))
	if wave_visual_controller != null and wave_visual_controller.has_method("on_room_cleared"):
		wave_visual_controller.call("on_room_cleared", active_main_room)
	var tutorial: Node = get_node_or_null("/root/TutorialManager")
	if tutorial != null and tutorial.has_method("notify_trigger"):
		tutorial.call("notify_trigger", "wave_clear")
	var blocked_snapshot: Dictionary = active_main_blocked_tiles.duplicate(true)
	active_main_blocked_tiles.clear()
	var room_to_clear: Vector2i = active_main_room
	active_main_room = Vector2i(-9999, -9999)
	active_main_wave_index = -1
	active_main_wave_spawning = false
	if active_main_room_locked:
		var timer: SceneTreeTimer = get_tree().create_timer(maxf(0.05, lock_regenerate_delay))
		timer.timeout.connect(func() -> void:
			_restore_blocked_tiles(blocked_snapshot)
			start_screen_shake(unlock_screen_shake_strength, 0.08)
			show_floating_text(tile_to_world(room_to_clear), "PATH OPEN", Color(0.62, 0.96, 1.0, 1.0))
		)
		active_main_room_locked = false


func _lock_room_exits(room_center: Vector2i) -> void:
	var room_cells: Array[Vector2i] = _get_room_cells(room_center)
	if room_cells.is_empty():
		return
	active_main_blocked_tiles.clear()
	_clear_main_block_markers()
	var room_lookup: Dictionary = {}
	for tile in room_cells:
		room_lookup[tile] = true
	for tile in room_cells:
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbor: Vector2i = tile + dir
			if not walkable_tiles.has(neighbor):
				continue
			if room_lookup.has(neighbor):
				continue
			_block_tile_with_fx(neighbor)
	active_main_room_locked = not active_main_blocked_tiles.is_empty()


func _block_tile_with_fx(tile: Vector2i) -> void:
	if active_main_blocked_tiles.has(tile):
		return
	var data: Dictionary = {
		"source_id": tilemap.get_cell_source_id(tile),
		"atlas": tilemap.get_cell_atlas_coords(tile),
		"alternative": tilemap.get_cell_alternative_tile(tile),
		"was_walkable": walkable_tiles.has(tile)
	}
	active_main_blocked_tiles[tile] = data
	walkable_tiles.erase(tile)
	var block_atlas: Vector2i = _pick_first_existing_atlas([
		Vector2i(11, 0), Vector2i(10, 0), Vector2i(9, 0), Vector2i(8, 0), Vector2i(0, 1)
	], Vector2i(8, 0))
	set_atlas_cell_safe(tilemap, tile, block_atlas)
	# Red iso-tile overlay sitting directly on the blocked tile (no ugly square/ring).
	var marker: Polygon2D = _make_tile_diamond(tile, Color(blocked_marker_color.r, blocked_marker_color.g, blocked_marker_color.b, clampf(blocked_marker_color.a, 0.6, 0.9)))
	marker.z_index = 95
	add_child(marker)
	active_main_block_markers[tile] = marker
	_emit_lock_tile_effect(tile)


func _restore_blocked_tiles(blocked_tiles: Dictionary) -> void:
	for tile_variant in blocked_tiles.keys():
		var tile: Vector2i = tile_variant
		var data: Dictionary = blocked_tiles[tile]
		if bool(data.get("was_walkable", true)):
			walkable_tiles[tile] = true
		var source_id: int = int(data.get("source_id", -1))
		if source_id >= 0:
			tilemap.set_cell(tile, source_id, data.get("atlas", Vector2i.ZERO), int(data.get("alternative", 0)))
		else:
			tilemap.erase_cell(tile)
		if active_main_block_markers.has(tile):
			var marker: Node2D = active_main_block_markers[tile] as Node2D
			if marker != null and is_instance_valid(marker):
				marker.queue_free()
			active_main_block_markers.erase(tile)
		_emit_unlock_tile_effect(tile)


func _clear_main_block_markers() -> void:
	for marker_variant in active_main_block_markers.values():
		var marker: Node2D = marker_variant as Node2D
		if marker != null and is_instance_valid(marker):
			marker.queue_free()
	active_main_block_markers.clear()


func _pick_first_existing_atlas(candidates: Array[Vector2i], fallback: Vector2i) -> Vector2i:
	for atlas in candidates:
		if tile_exists_atlas(atlas):
			return atlas
	if tile_exists_atlas(fallback):
		return fallback
	return Vector2i.ZERO


func _emit_lock_tile_effect(tile: Vector2i) -> void:
	var origin: Vector2 = tile_to_world(tile)
	var dust: ColorRect = ColorRect.new()
	dust.size = Vector2(18.0, 10.0)
	dust.position = origin - Vector2(9.0, 4.0)
	dust.color = Color(0.58, 0.52, 0.42, 0.58)
	dust.z_index = 94
	add_child(dust)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dust, "position", dust.position + Vector2(randf_range(-4.0, 4.0), randf_range(-2.0, 2.0)), lock_tile_shake_time)
	tween.tween_property(dust, "scale", Vector2(2.2, 1.6), lock_tile_shake_time)
	tween.tween_property(dust, "modulate:a", 0.0, lock_tile_shake_time)
	tween.chain().tween_callback(dust.queue_free)


func _emit_unlock_tile_effect(tile: Vector2i) -> void:
	var origin: Vector2 = tile_to_world(tile)
	var spark: ColorRect = ColorRect.new()
	spark.size = Vector2(16.0, 16.0)
	spark.position = origin - spark.size * 0.5
	spark.color = Color(0.52, 0.88, 1.0, 0.48)
	spark.z_index = 94
	add_child(spark)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(spark, "scale", Vector2(2.0, 2.0), 0.18)
	tween.tween_property(spark, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(spark.queue_free)


func _spawn_enemy_spawn_fx(world_pos: Vector2) -> void:
	var puff: ColorRect = ColorRect.new()
	puff.size = Vector2(18.0, 10.0)
	puff.position = world_pos - Vector2(9.0, 2.0)
	puff.color = Color(0.72, 0.68, 0.58, 0.42)
	puff.z_index = 9
	add_child(puff)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(puff, "scale", Vector2(1.8, 1.2), wave_spawn_delay)
	tween.tween_property(puff, "modulate:a", 0.0, wave_spawn_delay)
	tween.chain().tween_callback(puff.queue_free)


func _spawn_enemy_defeat_fx(world_pos: Vector2) -> void:
	var hit: ColorRect = ColorRect.new()
	hit.size = Vector2(20.0, 20.0)
	hit.position = world_pos - hit.size * 0.5
	hit.color = Color(0.42, 1.0, 0.72, 0.52)
	hit.z_index = 10
	add_child(hit)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(hit, "scale", Vector2(1.9, 1.9), 0.18)
	tween.tween_property(hit, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(hit.queue_free)


func create_goal_tile(unlocked: bool) -> void:
	if deco_layer == null:
		return
	deco_layer.erase_cell(goal_tile)
	if unlocked:
		set_atlas_cell_safe(deco_layer, goal_tile, ATLAS_OPEN_DOOR)
	else:
		set_atlas_cell_safe(deco_layer, goal_tile, ATLAS_LOCKED_DOOR)
	create_shadow_at(tile_to_world(goal_tile), Vector2(48.0, 14.0), 0.28)


func unlock_door() -> void:
	if door_unlocked:
		return
	door_unlocked = true
	if enable_goal_pulse:
		show_floating_text(tile_to_world(goal_tile), "DOOR OPEN", Color(1.0, 0.78, 0.22, 1.0))
		start_screen_shake(door_open_screen_shake_strength, door_open_screen_shake_duration)
	create_goal_tile(true)
	var marker: Node2D = Node2D.new()
	marker.global_position = tile_to_world(goal_tile)
	marker.z_index = 90
	add_child(marker)
	var flash: ColorRect = ColorRect.new()
	flash.size = Vector2(72.0, 72.0)
	flash.position = Vector2(-36.0, -58.0)
	flash.color = Color(1.0, 0.86, 0.18, 0.62)
	marker.add_child(flash)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(2.1, 2.1), 0.45)
	tween.tween_property(flash, "modulate:a", 0.0, 0.45)
	tween.tween_property(marker, "rotation", 0.22, 0.45)
	await tween.finished
	if is_instance_valid(marker):
		marker.queue_free()


func _start_intro_cutscene() -> void:
	if intro_cutscene_root == null:
		world_complete = false
		start_level(unlocked_stage)
		return
	if _get_intro_cutscene_slide_count() <= 0:
		world_complete = false
		start_level(unlocked_stage)
		return
	intro_cutscene_slide_index = 0
	intro_cutscene_active = true
	game_started = false
	is_dead = false
	cursor_follow_active = false
	if home_screen != null:
		home_screen.visible = false
	if death_screen != null:
		death_screen.visible = false
	if click_marker != null:
		click_marker.visible = false
	_set_gameplay_hud_visibility(false)
	if intro_cutscene_prompt != null:
		intro_cutscene_prompt.text = "Press SPACE"
		intro_cutscene_prompt.visible = false
	if intro_cutscene_prompt_icon != null:
		intro_cutscene_prompt_icon.texture = _resolve_intro_continue_icon_texture()
		intro_cutscene_prompt_icon.offset_left = -172.0
		intro_cutscene_prompt_icon.offset_top = -117.0
		intro_cutscene_prompt_icon.offset_right = -20.0
		intro_cutscene_prompt_icon.offset_bottom = -16.0
		intro_cutscene_prompt_icon.scale = Vector2(0.97, 0.97)
		intro_cutscene_prompt_icon.visible = intro_cutscene_prompt_icon.texture != null
		intro_cutscene_prompt_icon.move_to_front()
		if intro_cutscene_prompt != null and not intro_cutscene_prompt_icon.visible:
			intro_cutscene_prompt.visible = true
	intro_cutscene_root.visible = true
	_show_intro_cutscene_slide(intro_cutscene_slide_index)
	_play_music_track(menu_music, "Prologue")


func _show_intro_cutscene_slide(index: int) -> void:
	var slide_count: int = _get_intro_cutscene_slide_count()
	if slide_count <= 0:
		_finish_intro_cutscene()
		return
	var clamped_index: int = clampi(index, 0, slide_count - 1)
	intro_cutscene_slide_index = clamped_index
	if intro_cutscene_image != null:
		intro_cutscene_image.texture = _get_intro_cutscene_texture(clamped_index)
	if intro_cutscene_text != null:
		var line: String = ""
		if clamped_index < intro_cutscene_texts.size():
			line = intro_cutscene_texts[clamped_index]
		intro_cutscene_text.text = line
	if intro_cutscene_fade != null:
		intro_cutscene_fade.color = Color(0.0, 0.0, 0.0, 0.55)
		var tween: Tween = create_tween()
		tween.tween_property(intro_cutscene_fade, "color:a", 0.0, 0.2)


func _reset_intro_spacebar_visual() -> void:
	if intro_cutscene_prompt_icon == null:
		return
	if intro_spacebar_press_tween != null and intro_spacebar_press_tween.is_valid():
		intro_spacebar_press_tween.kill()
		intro_spacebar_press_tween = null
	intro_cutscene_prompt_icon.scale = intro_spacebar_rest_scale
	intro_cutscene_prompt_icon.offset_top = intro_spacebar_rest_offset_top
	intro_cutscene_prompt_icon.offset_bottom = intro_spacebar_rest_offset_bottom


func _play_intro_spacebar_press_anim() -> void:
	if intro_cutscene_prompt_icon == null:
		return
	if intro_spacebar_press_tween != null and intro_spacebar_press_tween.is_valid():
		intro_spacebar_press_tween.kill()
	intro_spacebar_press_tween = create_tween()
	intro_spacebar_press_tween.set_parallel(true)
	intro_spacebar_press_tween.tween_property(
		intro_cutscene_prompt_icon,
		"scale",
		intro_spacebar_rest_scale * Vector2(0.88, 0.68),
		0.08
	)
	intro_spacebar_press_tween.tween_property(
		intro_cutscene_prompt_icon,
		"offset_top",
		intro_spacebar_rest_offset_top + 11.0,
		0.08
	)
	intro_spacebar_press_tween.tween_property(
		intro_cutscene_prompt_icon,
		"offset_bottom",
		intro_spacebar_rest_offset_bottom + 11.0,
		0.08
	)


func _play_intro_spacebar_release_anim() -> void:
	if intro_cutscene_prompt_icon == null:
		return
	if intro_spacebar_press_tween != null and intro_spacebar_press_tween.is_valid():
		intro_spacebar_press_tween.kill()
	intro_spacebar_press_tween = create_tween()
	intro_spacebar_press_tween.set_parallel(true)
	intro_spacebar_press_tween.tween_property(intro_cutscene_prompt_icon, "scale", intro_spacebar_rest_scale, 0.12)
	intro_spacebar_press_tween.tween_property(
		intro_cutscene_prompt_icon,
		"offset_top",
		intro_spacebar_rest_offset_top,
		0.12
	)
	intro_spacebar_press_tween.tween_property(
		intro_cutscene_prompt_icon,
		"offset_bottom",
		intro_spacebar_rest_offset_bottom,
		0.12
	)


func _try_advance_intro_cutscene_on_release() -> void:
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - intro_spacebar_last_advance_ms < 120:
		return
	intro_spacebar_last_advance_ms = now_ms
	_advance_intro_cutscene()


func _advance_intro_cutscene() -> void:
	var next_index: int = intro_cutscene_slide_index + 1
	if next_index >= _get_intro_cutscene_slide_count():
		_finish_intro_cutscene()
		return
	_show_intro_cutscene_slide(next_index)
	_reset_intro_spacebar_visual()


func _finish_intro_cutscene() -> void:
	intro_cutscene_active = false
	intro_spacebar_is_down = false
	_reset_intro_spacebar_visual()
	if intro_cutscene_root != null:
		intro_cutscene_root.visible = false
	world_complete = false
	start_level(unlocked_stage)


func _get_intro_cutscene_slide_count() -> int:
	var textures: Array[Texture2D] = [
		intro_cutscene_slide_1,
		intro_cutscene_slide_2,
		intro_cutscene_slide_3,
		intro_cutscene_slide_4,
		intro_cutscene_slide_5
	]
	var highest_texture_index: int = -1
	for i in range(textures.size()):
		if textures[i] != null:
			highest_texture_index = i
	var texture_count: int = highest_texture_index + 1
	return maxi(texture_count, intro_cutscene_image_files.size())


func _get_intro_cutscene_texture(index: int) -> Texture2D:
	var textures: Array[Texture2D] = [
		intro_cutscene_slide_1,
		intro_cutscene_slide_2,
		intro_cutscene_slide_3,
		intro_cutscene_slide_4,
		intro_cutscene_slide_5
	]
	if index >= 0 and index < textures.size() and textures[index] != null:
		return textures[index]
	if index < 0 or index >= intro_cutscene_image_files.size():
		return null
	var path: String = intro_cutscene_image_files[index]
	if path.begins_with("res://"):
		var scene_res: Resource = load(path)
		if scene_res is Texture2D:
			return scene_res as Texture2D
	if FileAccess.file_exists(path):
		var image: Image = Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)
	return null


func _resolve_intro_continue_icon_texture() -> Texture2D:
	if intro_continue_icon_texture != null:
		return intro_continue_icon_texture
	if intro_continue_icon_file.strip_edges() == "":
		return null
	if intro_continue_icon_file.begins_with("res://"):
		var icon_res: Resource = load(intro_continue_icon_file)
		if icon_res is Texture2D:
			return icon_res as Texture2D
	if FileAccess.file_exists(intro_continue_icon_file):
		var icon_image: Image = Image.new()
		if icon_image.load(intro_continue_icon_file) == OK:
			return ImageTexture.create_from_image(icon_image)
	return null


func _update_aiming_cone_visual(_delta: float) -> void:
	if aim_cone_node == null or player == null:
		return
	aim_cone_node.visible = false
	return


func _input(event: InputEvent) -> void:
	if intro_cutscene_active:
		if event is InputEventKey:
			var slide_key_event: InputEventKey = event as InputEventKey
			if slide_key_event.keycode == KEY_SPACE and not slide_key_event.echo:
				if slide_key_event.pressed:
					if not intro_spacebar_is_down:
						intro_spacebar_is_down = true
						_play_intro_spacebar_press_anim()
					get_viewport().set_input_as_handled()
				else:
					if intro_spacebar_is_down:
						intro_spacebar_is_down = false
						_play_intro_spacebar_release_anim()
						_try_advance_intro_cutscene_on_release()
					get_viewport().set_input_as_handled()
				return
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if in_haven_mode and (key_event.keycode == KEY_Y or key_event.keycode == KEY_BRACKETRIGHT):
				_return_from_haven()
				return
			if not in_haven_mode and key_event.keycode == KEY_H:
				_go_to_haven()
				return
			if character_controller != null and character_controller.has_method("handle_world_key_input"):
				var consumed: bool = bool(character_controller.call("handle_world_key_input", key_event))
				if consumed:
					return
			# Let WeaponManager receive these in _unhandled_input:
			# P = inventory, E = pickup, Q = drop weapon.
			if key_event.keycode == KEY_P or key_event.keycode == KEY_E or key_event.keycode == KEY_Q:
				return

			if key_event.keycode == KEY_ESCAPE and close_expanded_map_with_escape and minimap_expanded:
				set_minimap_expanded(false, true)
				return

			if not game_started or is_dead:
				return

			if key_event.keycode == KEY_T:
				toggle_minimap_zoom()
				return

			if key_event.keycode == KEY_R:
				_cycle_music_track()
				return

			if key_event.keycode == KEY_G:
				ping_current_objective()
				return

			if key_event.keycode == KEY_Z:
				_toggle_controls_help()
				return

	if not game_started or is_dead:
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			if in_haven_mode:
				var world_pos: Vector2 = get_global_mouse_position()
				if _try_toggle_haven_shop_from_click(world_pos):
					get_viewport().set_input_as_handled()
					return
				if haven_shop_open:
					haven_shop_open = false
					_refresh_haven_shop_panel_state()
					get_viewport().set_input_as_handled()
					return

		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			cursor_follow_active = false

			var click_world_pos: Vector2 = get_global_mouse_position()
			request_click_move(click_world_pos)

			if multiplayer_enabled and net_node != null:
				var clicked_tile: Vector2i = world_to_tile(click_world_pos)
				net_node.call("send_clicked_tile", clicked_tile)

		# IMPORTANT:
		# Do not use right-click here. Right-click is reserved for WeaponManager firing/charging.

func _process(delta: float) -> void:
	elapsed_time += delta
	player_move_slow_timer = maxf(0.0, player_move_slow_timer - delta)
	if player_move_slow_timer <= 0.0:
		player_move_slow_multiplier = 1.0
	_update_aiming_cone_visual(delta)

	if shoot_anim_timer > 0.0:
		shoot_anim_timer = maxf(0.0, shoot_anim_timer - delta)
	_update_player_shoot_anim_lock()
	_update_player_charge_visual(delta)

	update_hud()
	_update_music_widget(delta)
	update_fullscreen_rects()
	update_particle_anchor()
	animate_atmosphere(delta)
	update_extra_polish(delta)
	update_screen_shake(delta)

	if not game_started or is_dead:
		update_objective_arrow()
		return

	current_tile = world_to_tile(player.global_position)
	if in_haven_mode:
		_reveal_haven_minimap_without_fog()
	else:
		reveal_minimap_around_player()
	process_click_tile_movement(delta)
	if not in_haven_mode:
		_update_tutorial_triggers(delta)
	_update_idle_facing_from_cursor()
	update_camera(delta)
	_update_remote_player_smoothing(delta)
	if not in_haven_mode:
		_update_room_encounter_flow(delta)
		check_key_and_goal()
	update_depth_sorting()
	update_objective_arrow()
	update_minimap()
	send_multiplayer_state_if_needed(delta)


func update_fullscreen_rects() -> void:
	var fog_near: ColorRect = null
	if atmosphere_layer != null:
		fog_near = atmosphere_layer.get_node_or_null("FogLayerNear") as ColorRect
	var rects: Array[ColorRect] = [darkness_rect, fog_rect_1, fog_rect_2, fog_rect_3, fog_near, vignette_rect, light_sweep_rect, film_grain_rect, god_rays_rect, cloud_shadow_rect, color_grade_rect, sun_glow_rect, void_shimmer_rect, edge_haze_rect, focus_spotlight_rect, chromatic_edge_rect, color_pop_rect, depth_shadow_rect, warm_corner_glow_rect, texture_lines_rect, sharpness_rect]
	for rect in rects:
		if rect == null:
			continue
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.size = get_viewport_rect().size

func update_particle_anchor() -> void:
	if particle_root == null:
		return
	var anchor: Vector2 = Vector2.ZERO
	if camera != null:
		anchor = camera.global_position
	else:
		anchor = player.global_position
	particle_root.global_position = anchor


func _update_music_widget(delta: float) -> void:
	if music_player != null:
		music_player.volume_db = linear_to_db(clampf(music_volume, 0.001, 1.0))
	if music_widget == null:
		return
	music_widget.visible = show_music_widget
	var viewport_size: Vector2 = get_viewport_rect().size
	var widget_size: Vector2 = Vector2(70.0, 70.0) * music_widget_scale
	var base_pos: Vector2 = Vector2(viewport_size.x - widget_size.x - 18.0, 16.0)
	var hover_x: float = sin(elapsed_time * cd_hover_speed) * cd_max_x_offset
	var hover_y: float = sin(elapsed_time * cd_hover_speed * 0.7) * cd_hover_strength
	music_widget.position = base_pos + Vector2(hover_x, hover_y)
	music_widget.size = Vector2(70.0, 70.0)
	music_widget.scale = Vector2.ONE * music_widget_scale
	if music_cd_icon != null and music_player != null and music_player.playing:
		var spin_t: float = elapsed_time * maxf(0.01, cd_spin_speed)
		var x_scale: float = absf(cos(spin_t))
		x_scale = clampf(x_scale, 0.12, 1.0)
		var y_scale: float = 0.96 + 0.04 * sin(spin_t * 0.4)
		music_cd_icon.scale = Vector2(x_scale, y_scale)
		if cd_enable_color_hue_shift:
			var glow_t: float = elapsed_time * 1.4
			var r: float = 0.62 + 0.38 * (0.5 + 0.5 * sin(glow_t))
			var g: float = 0.62 + 0.38 * (0.5 + 0.5 * sin(glow_t + TAU * 0.333))
			var b: float = 0.62 + 0.38 * (0.5 + 0.5 * sin(glow_t + TAU * 0.666))
			music_cd_icon.modulate = Color(r, g, b, 0.98)
		else:
			music_cd_icon.modulate = Color.WHITE
	if music_title_label != null:
		music_title_label.visible = false


func _update_remote_player_smoothing(delta: float) -> void:
	if remote_players.is_empty():
		return
	var now_sec: float = float(Time.get_ticks_msec()) * 0.001
	for id_variant in remote_players.keys():
		var player_id: int = int(id_variant)
		var ghost: Node2D = remote_players[player_id] as Node2D
		if not is_instance_valid(ghost):
			continue
		if not remote_target_positions.has(player_id):
			continue
		var target_pos: Vector2 = remote_target_positions[player_id]
		var velocity: Vector2 = Vector2.ZERO
		if remote_velocities.has(player_id):
			velocity = remote_velocities[player_id]
		var received_at: float = now_sec
		if remote_state_received_at.has(player_id):
			received_at = float(remote_state_received_at[player_id])
		var state_age: float = maxf(0.0, now_sec - received_at)
		var extrapolation_time: float = clampf(state_age + multiplayer_prediction_lead_seconds, 0.0, 0.35)
		var predicted_pos: Vector2 = target_pos + velocity * extrapolation_time
		var extrapolation_distance: float = target_pos.distance_to(predicted_pos)
		if extrapolation_distance > multiplayer_max_extrapolation_distance:
			var dir: Vector2 = (predicted_pos - target_pos).normalized()
			predicted_pos = target_pos + dir * multiplayer_max_extrapolation_distance
		var to_predicted: Vector2 = predicted_pos - ghost.global_position
		if to_predicted.length() >= multiplayer_snap_distance:
			ghost.global_position = predicted_pos
			continue
		var adaptive_blend: float = clampf(multiplayer_interpolation_amount * delta * (8.0 + minf(to_predicted.length() * 0.08, 16.0)), 0.04, 0.95)
		ghost.global_position = ghost.global_position.lerp(predicted_pos, adaptive_blend)


func animate_atmosphere(delta: float) -> void:
	if player_light != null:
		player_light.energy = 0.80 + sin(elapsed_time * 2.0) * 0.035 + float(current_stage) * 0.035


func update_extra_polish(delta: float) -> void:
	locked_hint_cooldown = maxf(0.0, locked_hint_cooldown - delta)
	if key_combo_timer > 0.0:
		key_combo_timer = maxf(0.0, key_combo_timer - delta)
		if key_combo_timer <= 0.0:
			key_combo_count = 0
	update_letterbox_rects()
	update_goal_pulse()
	update_premium_visuals(delta)
	update_ultra_visuals(delta)
	update_sharpness_postprocess()
	update_combo_label()


func update_letterbox_rects() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if letterbox_top != null:
		letterbox_top.visible = enable_cinematic_letterbox
		letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
		letterbox_top.position = Vector2.ZERO
		letterbox_top.size = Vector2(viewport_size.x, letterbox_height)
		letterbox_top.color = letterbox_color
	if letterbox_bottom != null:
		letterbox_bottom.visible = enable_cinematic_letterbox
		letterbox_bottom.set_anchors_preset(Control.PRESET_TOP_WIDE)
		letterbox_bottom.position = Vector2(0.0, viewport_size.y - letterbox_height)
		letterbox_bottom.size = Vector2(viewport_size.x, letterbox_height)
		letterbox_bottom.color = letterbox_color


func update_goal_pulse() -> void:
	if not enable_goal_pulse or deco_layer == null or goal_tile == Vector2i.ZERO:
		return
	var pulse: float = 0.82 + sin(elapsed_time * 2.8) * 0.08
	if door_unlocked:
		deco_layer.modulate = Color(1.0, 0.96 + pulse * 0.04, 0.82 + pulse * 0.08, 1.0)
	else:
		deco_layer.modulate = Color(0.94, 0.96, 1.0, 1.0)


func update_ultra_visuals(_delta: float) -> void:
	var active: bool = game_started and not is_dead
	if focus_spotlight_rect != null:
		focus_spotlight_rect.visible = enable_focus_spotlight and active
		if focus_spotlight_rect.material is ShaderMaterial:
			var focus_mat: ShaderMaterial = focus_spotlight_rect.material as ShaderMaterial
			focus_mat.set_shader_parameter("spotlight_color", focus_spotlight_color)
			focus_mat.set_shader_parameter("radius", focus_spotlight_radius)
			focus_mat.set_shader_parameter("softness", focus_spotlight_softness)
	if chromatic_edge_rect != null:
		chromatic_edge_rect.visible = enable_chromatic_edges and active
		if chromatic_edge_rect.material is ShaderMaterial:
			var chroma_mat: ShaderMaterial = chromatic_edge_rect.material as ShaderMaterial
			chroma_mat.set_shader_parameter("edge_strength", chromatic_edge_strength)
			chroma_mat.set_shader_parameter("edge_fade", chromatic_edge_fade)
	if color_pop_rect != null:
		color_pop_rect.visible = enable_color_pop and active
		if color_pop_rect.material is ShaderMaterial:
			var pop_mat: ShaderMaterial = color_pop_rect.material as ShaderMaterial
			pop_mat.set_shader_parameter("pop_strength", color_pop_strength)
			pop_mat.set_shader_parameter("pop_contrast", color_pop_contrast)
	if depth_shadow_rect != null:
		depth_shadow_rect.visible = enable_depth_shadow_gradient and active
		if depth_shadow_rect.material is ShaderMaterial:
			var depth_mat: ShaderMaterial = depth_shadow_rect.material as ShaderMaterial
			depth_mat.set_shader_parameter("shadow_color", depth_shadow_gradient_color)
	if warm_corner_glow_rect != null:
		warm_corner_glow_rect.visible = enable_warm_corner_glow and active
		if warm_corner_glow_rect.material is ShaderMaterial:
			var warm_mat: ShaderMaterial = warm_corner_glow_rect.material as ShaderMaterial
			warm_mat.set_shader_parameter("glow_color", warm_corner_glow_color)
	if texture_lines_rect != null:
		texture_lines_rect.visible = enable_texture_lines and active
		if texture_lines_rect.material is ShaderMaterial:
			var line_mat: ShaderMaterial = texture_lines_rect.material as ShaderMaterial
			line_mat.set_shader_parameter("line_color", texture_lines_color)
			line_mat.set_shader_parameter("frequency", texture_lines_frequency)
	if magic_sparkle_particles != null:
		magic_sparkle_particles.visible = enable_magic_sparkles and active
		magic_sparkle_particles.emitting = enable_magic_sparkles and active
		magic_sparkle_particles.amount = magic_sparkle_count
		magic_sparkle_particles.color = magic_sparkle_color
	if floating_pollen_particles != null:
		floating_pollen_particles.visible = enable_floating_pollen and active
		floating_pollen_particles.emitting = enable_floating_pollen and active
		floating_pollen_particles.amount = floating_pollen_count
		floating_pollen_particles.color = floating_pollen_color
	if foreground_mist_particles != null:
		foreground_mist_particles.visible = enable_foreground_mist and active
		foreground_mist_particles.emitting = enable_foreground_mist and active
		foreground_mist_particles.amount = foreground_mist_count
		foreground_mist_particles.color = foreground_mist_color
	if player_rim_light != null:
		player_rim_light.visible = enable_player_rim_light and active
		player_rim_light.energy = player_rim_light_energy + sin(elapsed_time * 2.6) * 0.025
		player_rim_light.texture_scale = player_rim_light_scale
		player_rim_light.color = player_rim_light_color
	if camera != null and enable_camera_pixel_snap and active and screen_shake_time <= 0.0:
		if camera.get_parent() == player:
			camera.position = Vector2.ZERO
		else:
			camera.global_position = camera.global_position.round()

func update_sharpness_postprocess() -> void:
	if sharpness_rect == null:
		return
	sharpness_rect.visible = enable_sharpness_postprocess and game_started and not is_dead
	if sharpness_rect.material is ShaderMaterial:
		var mat: ShaderMaterial = sharpness_rect.material as ShaderMaterial
		mat.set_shader_parameter("sharpen_strength", screen_sharpen_strength)
		mat.set_shader_parameter("contrast", screen_contrast)
		mat.set_shader_parameter("saturation", screen_saturation)
		mat.set_shader_parameter("brightness", screen_brightness)
		mat.set_shader_parameter("contrast", screen_contrast)
		mat.set_shader_parameter("saturation", screen_saturation)
		mat.set_shader_parameter("brightness", screen_brightness)

func update_combo_label() -> void:
	if combo_label == null:
		return
	if not enable_combo_feedback or key_combo_count < 2 or key_combo_timer <= 0.0:
		combo_label.modulate.a = lerpf(combo_label.modulate.a, 0.0, 0.12)
		return
	combo_label.text = "KEY STREAK x" + str(key_combo_count)
	combo_label.modulate = Color(1.0, 0.86, 0.28, 0.95)


func _get_active_screen_zoom() -> float:
	return haven_camera_zoom if in_haven_mode else screen_zoom


func update_camera(delta: float) -> void:
	if camera == null or player == null:
		return
	if camera.get_parent() == player:
		camera.position = Vector2.ZERO
		return
	var desired: Vector2 = player.global_position
	camera.global_position = camera.global_position.lerp(desired, clampf(delta * camera_smooth_speed, 0.0, 1.0))


func _reset_camera_to_player() -> void:
	if camera == null or player == null:
		return
	camera.offset = Vector2.ZERO
	if camera.get_parent() == player:
		camera.position = Vector2.ZERO
		camera.limit_enabled = false
	else:
		camera.global_position = player.global_position


func _update_camera_world_limits() -> void:
	if camera == null or tilemap == null:
		return
	if camera.get_parent() == player:
		camera.limit_enabled = false
		return
	var half: Vector2 = get_viewport_rect().size * 0.5 / camera.zoom
	var min_world: Vector2 = tilemap.to_global(tilemap.map_to_local(Vector2i(world_edge_buffer_tiles, world_edge_buffer_tiles))) - half
	var max_world: Vector2 = tilemap.to_global(tilemap.map_to_local(Vector2i(map_width - world_edge_buffer_tiles, map_height - world_edge_buffer_tiles))) + half
	if min_world.x >= max_world.x or min_world.y >= max_world.y:
		camera.limit_enabled = false
		return
	camera.limit_enabled = true
	camera.limit_left = int(min_world.x)
	camera.limit_top = int(min_world.y)
	camera.limit_right = int(max_world.x)
	camera.limit_bottom = int(max_world.y)


func update_depth_sorting() -> void:
	player.z_index = 50 + int(player.global_position.y * 0.01)
	_update_world_tree_depth_sorting()


func _update_world_tree_depth_sorting() -> void:
	if player == null:
		return
	var player_sort_y: float = player.global_position.y
	var player_tile: Vector2i = world_to_tile(player.global_position)
	for tree_node in world_tree_nodes:
		if tree_node == null or not is_instance_valid(tree_node):
			continue
		var tree_tile: Vector2i = tree_node.get_meta("tree_tile", Vector2i.ZERO)
		var trunk_sort_y: float = tree_node.global_position.y + world_tree_sort_foot_offset
		tree_node.z_index = 40 + int(tree_node.global_position.y * 0.01)
		var in_tile_range: bool = _is_player_near_tree_tile(player_tile, tree_tile)
		var player_behind: bool = player_sort_y < trunk_sort_y
		if in_tile_range and player_behind:
			_set_world_tree_visual_alpha(tree_node, world_tree_behind_alpha)
		else:
			_set_world_tree_visual_alpha(tree_node, 1.0)


func request_click_move(world_position: Vector2) -> void:
	var clicked_tile: Vector2i = world_to_tile(world_position)
	if _is_tile_blocked_by_main_lock(clicked_tile):
		show_blocked_click_marker(clicked_tile, world_position)
		if locked_hint_cooldown <= 0.0:
			show_floating_text(world_position, "BLOCKED", blocked_marker_color)
			locked_hint_cooldown = 0.25
		return
	if not walkable_tiles.has(clicked_tile):
		var nearest: Vector2i = find_nearest_walkable(clicked_tile, 7)
		if nearest == Vector2i(-9999, -9999):
			show_blocked_click_marker(clicked_tile, world_position)
			return
		if _is_tile_blocked_by_main_lock(nearest):
			show_blocked_click_marker(nearest, world_position)
			return
		clicked_tile = nearest

	if clicked_tile == target_tile and is_moving_to_click:
		return

	if in_haven_mode:
		_queue_haven_click_target(clicked_tile)
		if weapon_manager != null and weapon_manager.has_method("reveal_hotbar"):
			weapon_manager.call("reveal_hotbar")
		show_click_marker(clicked_tile)
		return

	var path: Array[Vector2i] = find_tile_path(current_tile, clicked_tile)
	if path.is_empty():
		return
	target_tile = clicked_tile
	target_world_position = tile_to_world(target_tile)
	click_path = path
	is_moving_to_click = true
	if weapon_manager != null and weapon_manager.has_method("reveal_hotbar"):
		weapon_manager.call("reveal_hotbar")
	show_click_marker(target_tile)


func cancel_click_move() -> void:
	cursor_follow_active = false
	is_moving_to_click = false
	click_path.clear()
	haven_click_target_queue.clear()
	if click_marker != null:
		click_marker.visible = false
	play_idle()


func process_click_tile_movement(delta: float) -> void:
	if not is_moving_to_click:
		play_idle()
		return
	if click_path.is_empty():
		if in_haven_mode and not haven_click_target_queue.is_empty():
			_start_next_haven_click_target()
			return
		is_moving_to_click = false
		if not cursor_follow_active and click_marker != null:
			click_marker.visible = false
		play_idle()
		return

	var next_tile: Vector2i = click_path[0]
	var next_world: Vector2 = tile_to_world(next_tile)
	var to_next: Vector2 = next_world - player.global_position
	if to_next.length() <= 4.0:
		player.global_position = next_world
		click_path.remove_at(0)
		if click_path.is_empty():
			is_moving_to_click = false
			if not cursor_follow_active and click_marker != null:
				click_marker.visible = false
			play_idle()
		return

	var direction: Vector2 = to_next.normalized()
	player.global_position += direction * _get_active_move_speed() * delta
	spawn_step_dust()
	spawn_breadcrumb()
	set_animation_from_vector(direction, "walking")


func _get_active_move_speed() -> float:
	var base_speed: float = move_speed
	if in_haven_mode:
		base_speed = move_speed * haven_click_speed_multiplier
	return base_speed * maxf(0.2, player_move_slow_multiplier)


func apply_player_slow(multiplier: float, duration: float) -> void:
	player_move_slow_multiplier = mini(player_move_slow_multiplier, clampf(multiplier, 0.2, 1.0))
	player_move_slow_timer = maxf(player_move_slow_timer, duration)


func _queue_haven_click_target(target: Vector2i) -> void:
	var from_tile: Vector2i = current_tile
	if not haven_click_target_queue.is_empty():
		from_tile = haven_click_target_queue[haven_click_target_queue.size() - 1]
	elif is_moving_to_click:
		from_tile = target_tile

	if from_tile == target:
		return
	var chain_path: Array[Vector2i] = find_tile_path(from_tile, target)
	if chain_path.is_empty():
		return
	if not is_moving_to_click or click_path.is_empty():
		target_tile = target
		target_world_position = tile_to_world(target_tile)
		click_path = find_tile_path(current_tile, target)
		if click_path.is_empty():
			return
		is_moving_to_click = true
		return
	haven_click_target_queue.append(target)


func _start_next_haven_click_target() -> void:
	while not haven_click_target_queue.is_empty():
		var next_target: Vector2i = haven_click_target_queue.pop_front()
		var path: Array[Vector2i] = find_tile_path(current_tile, next_target)
		if path.is_empty():
			continue
		target_tile = next_target
		target_world_position = tile_to_world(target_tile)
		click_path = path
		is_moving_to_click = true
		return
	is_moving_to_click = false


func _is_tile_blocked_by_main_lock(tile: Vector2i) -> bool:
	if not active_main_room_locked:
		return false
	if active_main_room == Vector2i(-9999, -9999):
		return false
	if active_main_blocked_tiles.has(tile):
		return true
	var active_room_tiles: Array[Vector2i] = _get_room_cells(active_main_room)
	if active_room_tiles.is_empty():
		return false
	return not active_room_tiles.has(tile)


func show_blocked_click_marker(tile: Vector2i, raw_world_position: Vector2 = Vector2.INF) -> void:
	if click_marker == null:
		return
	click_marker.visible = true
	click_marker.global_position = raw_world_position if raw_world_position != Vector2.INF else tile_to_world(tile)
	click_marker.scale = Vector2(click_marker_start_scale * 0.9, click_marker_start_scale * 0.9)
	click_marker.modulate = Color(blocked_marker_color.r, blocked_marker_color.g, blocked_marker_color.b, blocked_marker_color.a)
	if click_marker.material is ShaderMaterial:
		var mat: ShaderMaterial = click_marker.material as ShaderMaterial
		mat.set_shader_parameter("glow_color", blocked_marker_glow_color)
	if click_marker_light != null:
		click_marker_light.energy = click_marker_light_energy * 1.35
		click_marker_light.texture_scale = click_marker_light_scale * 1.1
		click_marker_light.color = blocked_marker_glow_color
	if marker_tween != null and marker_tween.is_running():
		marker_tween.kill()
	if marker_pulse_tween != null and marker_pulse_tween.is_running():
		marker_pulse_tween.kill()
	marker_tween = create_tween()
	marker_tween.set_parallel(true)
	marker_tween.tween_property(click_marker, "scale", Vector2(click_marker_end_scale * 1.1, click_marker_end_scale * 1.1), blocked_marker_fade_time)
	marker_tween.tween_property(click_marker, "modulate:a", 0.0, blocked_marker_fade_time)
	marker_tween.chain().tween_callback(func() -> void:
		if click_marker != null:
			click_marker.visible = false
	)


## Builds a red-tinted overlay shaped exactly like the tile footprint (derived from the
## actual projection of neighbor tile centers, so it matches the isometric perspective).
func _make_tile_diamond(tile: Vector2i, fill: Color) -> Polygon2D:
	var center_pos: Vector2 = tile_to_world(tile)
	var right_off: Vector2 = tile_to_world(tile + Vector2i(1, 0)) - center_pos
	var down_off: Vector2 = tile_to_world(tile + Vector2i(0, 1)) - center_pos
	var top_p: Vector2 = -(right_off + down_off) * 0.5
	var right_p: Vector2 = (right_off - down_off) * 0.5
	var bottom_p: Vector2 = (right_off + down_off) * 0.5
	var left_p: Vector2 = (down_off - right_off) * 0.5
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = PackedVector2Array([top_p, right_p, bottom_p, left_p])
	poly.color = fill
	poly.global_position = center_pos
	return poly


func spawn_combat_tile_marker(world_pos: Vector2, duration: float = 0.85, loop_pulse: bool = false) -> Node2D:
	if tilemap == null:
		return null
	var tile: Vector2i = world_to_tile(world_pos)
	var base_alpha: float = clampf(blocked_marker_color.a, 0.55, 0.82)
	var marker: Polygon2D = _make_tile_diamond(tile, Color(blocked_marker_color.r, blocked_marker_color.g, blocked_marker_color.b, base_alpha))
	marker.z_index = 94
	add_child(marker)
	var life: float = maxf(0.12, duration)
	var tween: Tween = create_tween()
	if loop_pulse:
		var pulse_loops: int = maxi(1, int(life / maxf(0.08, click_marker_pulse_time)))
		for _i in range(pulse_loops):
			tween.tween_property(marker, "color:a", base_alpha * 0.4, click_marker_pulse_time * 0.5).set_trans(Tween.TRANS_SINE)
			tween.tween_property(marker, "color:a", base_alpha, click_marker_pulse_time * 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(marker, "color:a", 0.0, 0.16)
	tween.tween_callback(func() -> void:
		if is_instance_valid(marker):
			marker.queue_free()
	)
	return marker


func spawn_combat_tile_markers_box(
	center_world_pos: Vector2,
	box_tiles: Vector2i = Vector2i(2, 2),
	duration: float = 0.85,
	loop_pulse: bool = false
) -> Array[Node2D]:
	var markers: Array[Node2D] = []
	if tilemap == null:
		return markers
	var anchor: Vector2i = world_to_tile(center_world_pos)
	for x in range(maxi(1, box_tiles.x)):
		for y in range(maxi(1, box_tiles.y)):
			var marker: Node2D = spawn_combat_tile_marker(tile_to_world(anchor + Vector2i(x, y)), duration, loop_pulse)
			if marker != null:
				markers.append(marker)
	return markers


func spawn_combat_tile_markers_line(
	from_world_pos: Vector2,
	to_world_pos: Vector2,
	duration: float = 0.85,
	loop_pulse: bool = false
) -> Array[Node2D]:
	var markers: Array[Node2D] = []
	if tilemap == null:
		return markers
	var seen: Dictionary = {}
	var span: float = maxf(1.0, from_world_pos.distance_to(to_world_pos))
	var steps: int = maxi(2, int(ceil(span / 28.0)))
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var sample: Vector2 = from_world_pos.lerp(to_world_pos, t)
		var tile: Vector2i = world_to_tile(sample)
		if seen.has(tile):
			continue
		seen[tile] = true
		var marker: Node2D = spawn_combat_tile_marker(tile_to_world(tile), duration, loop_pulse)
		if marker != null:
			markers.append(marker)
	return markers


func show_click_marker(tile: Vector2i) -> void:
	if click_marker == null:
		return

	click_marker.visible = true
	click_marker.global_position = tile_to_world(tile)
	click_marker.scale = Vector2(click_marker_start_scale, click_marker_start_scale)
	click_marker.modulate = Color(click_marker_color.r, click_marker_color.g, click_marker_color.b, click_marker_alpha * 0.65)

	if click_marker.material is ShaderMaterial:
		var mat: ShaderMaterial = click_marker.material as ShaderMaterial
		mat.set_shader_parameter("glow_color", click_marker_glow_color)

	if click_marker_light != null:
		click_marker_light.energy = click_marker_light_energy
		click_marker_light.texture_scale = click_marker_light_scale
		click_marker_light.color = click_marker_glow_color

	if marker_tween != null and marker_tween.is_running():
		marker_tween.kill()
	if marker_pulse_tween != null and marker_pulse_tween.is_running():
		marker_pulse_tween.kill()

	marker_tween = create_tween()
	marker_tween.set_parallel(true)
	marker_tween.tween_property(click_marker, "scale", Vector2(click_marker_end_scale, click_marker_end_scale), click_marker_fade_in_time).set_trans(Tween.TRANS_SINE)
	marker_tween.tween_property(click_marker, "modulate:a", click_marker_alpha, click_marker_fade_in_time)

	marker_pulse_tween = create_tween()
	marker_pulse_tween.set_loops()
	marker_pulse_tween.tween_property(click_marker, "scale", Vector2(click_marker_pulse_big_scale, click_marker_pulse_big_scale), click_marker_pulse_time).set_trans(Tween.TRANS_SINE)
	marker_pulse_tween.tween_property(click_marker, "scale", Vector2(click_marker_pulse_small_scale, click_marker_pulse_small_scale), click_marker_pulse_time).set_trans(Tween.TRANS_SINE)


func find_tile_path(start_tile: Vector2i, end_tile: Vector2i) -> Array[Vector2i]:
	if start_tile == end_tile:
		return [end_tile]
	var frontier: Array[Vector2i] = [start_tile]
	var came_from: Dictionary = {}
	var visited: Dictionary = {}
	visited[start_tile] = true
	came_from[start_tile] = start_tile
	var head: int = 0
	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1
		if current == end_tile:
			break
		var neighbors: Array[Vector2i] = get_sorted_path_neighbors(current, end_tile)
		for next_tile in neighbors:
			if visited.has(next_tile):
				continue
			if not walkable_tiles.has(next_tile):
				continue
			visited[next_tile] = true
			came_from[next_tile] = current
			frontier.append(next_tile)
	if not came_from.has(end_tile):
		return []
	var path: Array[Vector2i] = []
	var step: Vector2i = end_tile
	while step != start_tile:
		path.insert(0, step)
		step = came_from[step]
	return path


func get_sorted_path_neighbors(cell: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = [cell + Vector2i(1, 0), cell + Vector2i(-1, 0), cell + Vector2i(0, 1), cell + Vector2i(0, -1)]
	neighbors.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_score: int = abs(a.x - goal.x) + abs(a.y - goal.y)
		var b_score: int = abs(b.x - goal.x) + abs(b.y - goal.y)
		return a_score < b_score
	)
	return neighbors


func find_nearest_walkable(center: Vector2i, radius: int) -> Vector2i:
	var best_cell: Vector2i = Vector2i(-9999, -9999)
	var best_distance: int = 999999
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var cell: Vector2i = Vector2i(x, y)
			if not walkable_tiles.has(cell):
				continue
			var distance: int = abs(cell.x - center.x) + abs(cell.y - center.y)
			if distance < best_distance:
				best_distance = distance
				best_cell = cell
	return best_cell


func check_key_and_goal() -> void:
	for key_cell in key_tiles:
		if current_tile == key_cell and not collected_keys.has(key_cell):
			collect_key_shared(key_cell, false)

			if multiplayer_enabled and net_node != null:
				net_node.call("send_key_collected", key_cell)

	if current_tile == goal_tile:
		if door_unlocked:
			win_game()
		else:
			if locked_hint_cooldown <= 0.0:
				show_floating_text(tile_to_world(goal_tile), "LOCKED - NEED KEYS", Color(0.85, 0.55, 1.0, 1.0))
				locked_hint_cooldown = 1.2
			print("Door locked. Collect all keys first.")


func win_game() -> void:
	cursor_follow_active = false
	var campaign: Node = get_node_or_null("/root/CampaignManager")
	if campaign != null and bool(campaign.get("use_campaign_flow")):
		var level_id: String = campaign.call("level_for_stage", current_stage, "world_1")
		campaign.call("complete_level", level_id)
		var tutorial: Node = get_node_or_null("/root/TutorialManager")
		if tutorial != null and tutorial.has_method("notify_trigger"):
			tutorial.call("notify_trigger", "level_win")
		var next_level: String = campaign.call("get_next_level_after", level_id)
		if next_level == "haven":
			_go_to_haven()
			return
		if next_level != "":
			var next_stage: int = campaign.call("stage_for_level", next_level)
			if multiplayer_enabled and net_node != null and net_node.has_method("send_level_started"):
				net_node.call("send_level_started", next_stage, multiplayer_map_seed)
			start_level(next_stage)
			return
	if current_stage < MAX_WORLD_STAGE:
		current_stage += 1
		unlocked_stage = maxi(unlocked_stage, current_stage)
		if multiplayer_enabled and net_node != null and net_node.has_method("send_level_started"):
			net_node.call("send_level_started", current_stage, multiplayer_map_seed)
		start_level(current_stage)
		return
	world_complete = true
	game_started = false
	clear_level()
	show_home_screen()
	play_animation("idle_down")


func retry_game() -> void:
	start_level(current_stage)


func return_home() -> void:
	game_started = false
	is_dead = false
	cursor_follow_active = false
	clear_level()
	show_home_screen()
	play_animation("idle_down")


func quit_game() -> void:
	get_tree().quit()


func clear_level() -> void:
	tilemap.clear()
	if deco_layer != null:
		deco_layer.clear()
	if island_shadow_layer != null:
		island_shadow_layer.clear()
	clear_world_trees()
	if haven_transition_root != null and is_instance_valid(haven_transition_root):
		haven_transition_root.queue_free()
	haven_transition_root = null
	if haven_structures_root != null and is_instance_valid(haven_structures_root):
		haven_structures_root.queue_free()
	haven_structures_root = null
	if haven_shop_panel != null and is_instance_valid(haven_shop_panel):
		haven_shop_panel.queue_free()
	haven_shop_panel = null
	haven_shop_stall_sprite = null
	haven_shop_open = false
	for shadow in shadow_nodes:
		if is_instance_valid(shadow):
			shadow.queue_free()
	shadow_nodes.clear()
	walkable_tiles.clear()
	room_centers.clear()
	main_path_rooms.clear()
	main_room_lookup.clear()
	room_tiles_by_center.clear()
	room_membership.clear()
	side_room_spawned.clear()
	cleared_main_rooms.clear()
	active_main_room = Vector2i(-9999, -9999)
	active_main_wave_index = -1
	active_main_wave_spawning = false
	active_main_room_locked = false
	active_main_blocked_tiles.clear()
	_clear_main_block_markers()
	room_slime_counts.clear()
	ground_biomes.clear()
	occupied_deco_tiles.clear()
	road_tiles.clear()
	room_tiles.clear()
	plaza_tiles.clear()
	border_tiles.clear()
	revealed_tiles.clear()
	visible_tiles.clear()
	last_reveal_tile = Vector2i(-9999, -9999)
	click_path.clear()
	is_moving_to_click = false
	key_tiles.clear()
	collected_keys.clear()
	if breadcrumb_root != null:
		for child in breadcrumb_root.get_children():
			child.queue_free()
	if mob_root != null:
		for child in mob_root.get_children():
			child.queue_free()
	if minimap != null:
		minimap.queue_redraw()


func take_damage(amount: float) -> void:
	if is_dead:
		return
	if weapon_manager != null and weapon_manager.has_method("cancel_active_charge"):
		weapon_manager.call("cancel_active_charge")
	if character_controller != null and character_controller.has_method("cancel_active_charge"):
		character_controller.call("cancel_active_charge")
	current_health = clampf(current_health - amount, 0.0, max_health)
	spawn_damage_tick(player.global_position, amount, Color(1.0, 0.28, 0.24, 1.0))
	_flash_player_hit()
	start_screen_shake(2.2, 0.1)
	update_health_bar()
	if current_health <= 0.0:
		die()


func _flash_player_hit() -> void:
	var hit_color: Color = Color(1.55, 0.18, 0.18, 1.0)
	if player_hit_tween != null and player_hit_tween.is_running():
		player_hit_tween.kill()
	if player_sprite != null and player_sprite.visible:
		player_sprite.modulate = hit_color
	if character_controller != null and character_controller.has_method("flash_twins_hit"):
		character_controller.call("flash_twins_hit", hit_color)
	player_hit_tween = create_tween()
	if player_sprite != null and player_sprite.visible:
		player_hit_tween.tween_property(player_sprite, "modulate", Color.WHITE, 0.22)


func update_health_bar() -> void:
	var ratio: float = clampf(current_health / max_health, 0.0, 1.0)
	var filled_hearts: int = int(ceil(ratio * 3.0))
	if health_bar_root != null:
		health_bar_root.visible = true
	_layout_health_hearts()
	_apply_health_fill_to_hearts(health_hearts, filled_hearts)
	if local_health_ui_root != null:
		local_health_ui_root.visible = false


func _layout_health_hearts() -> void:
	if health_hearts.is_empty():
		return
	var heart_scale: float = 3.0
	var heart_spacing: float = 30.0
	var heart_y: float = -60.0
	var right_shift: float = 10.0
	var start_x: float = -heart_spacing + right_shift
	for index in range(health_hearts.size()):
		var heart: Sprite2D = health_hearts[index]
		if heart == null:
			continue
		heart.scale = Vector2.ONE * heart_scale
		heart.position = Vector2(start_x + float(index) * heart_spacing, heart_y)
		heart.z_index = 82


func _layout_health_hearts_for_root(root: Node2D) -> void:
	if root == null:
		return
	var hearts: Array[Sprite2D] = []
	for index in range(3):
		var heart: Sprite2D = root.get_node_or_null("Heart%d" % (index + 1)) as Sprite2D
		if heart != null:
			hearts.append(heart)
	if hearts.is_empty():
		return
	var heart_scale: float = 3.0
	var heart_spacing: float = 30.0
	var heart_y: float = -60.0
	var right_shift: float = 10.0
	var start_x: float = -heart_spacing + right_shift
	for index in range(hearts.size()):
		var heart_sprite: Sprite2D = hearts[index]
		if heart_sprite == null:
			continue
		heart_sprite.scale = Vector2.ONE * heart_scale
		heart_sprite.position = Vector2(start_x + float(index) * heart_spacing, heart_y)
		heart_sprite.z_index = 82


func _ensure_local_health_ui() -> void:
	if ui_layer == null:
		return
	if local_health_ui_root == null:
		local_health_ui_root = ui_layer.get_node_or_null("PlayerHealthUI") as Node2D
	if local_health_ui_root == null:
		local_health_ui_root = Node2D.new()
		local_health_ui_root.name = "PlayerHealthUI"
		ui_layer.add_child(local_health_ui_root)

	if local_health_ui_hearts.size() < 3:
		local_health_ui_hearts.clear()
		for index in range(3):
			var heart_name: String = "HUDHeart%d" % (index + 1)
			var heart: Sprite2D = local_health_ui_root.get_node_or_null(heart_name) as Sprite2D
			if heart == null:
				heart = Sprite2D.new()
				heart.name = heart_name
				local_health_ui_root.add_child(heart)
			heart.texture = heart_full_texture
			heart.z_index = 200
			local_health_ui_hearts.append(heart)


func _layout_local_health_ui_hearts() -> void:
	if local_health_ui_root == null or local_health_ui_hearts.is_empty():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var heart_scale: float = 2.9
	var heart_spacing: float = 28.0
	var total_width: float = heart_spacing * float(local_health_ui_hearts.size() - 1)
	var base_x: float = viewport_size.x - local_health_ui_top_right_margin.x - total_width
	var base_y: float = local_health_ui_top_right_margin.y
	for index in range(local_health_ui_hearts.size()):
		var heart: Sprite2D = local_health_ui_hearts[index]
		if heart == null:
			continue
		heart.visible = true
		heart.scale = Vector2.ONE * heart_scale
		heart.position = Vector2(base_x + float(index) * heart_spacing, base_y)
		heart.z_index = 200


func _apply_health_fill_to_hearts(hearts: Array[Sprite2D], filled_hearts: int) -> void:
	for index in range(hearts.size()):
		var heart: Sprite2D = hearts[index]
		if heart == null:
			continue
		var is_filled: bool = index < filled_hearts
		heart.texture = heart_full_texture if is_filled else heart_empty_texture
		heart.modulate = Color.WHITE if is_filled else Color(0.72, 0.72, 0.78, 1.0)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	cursor_follow_active = false
	if weapon_manager != null and weapon_manager.has_method("cancel_active_charge"):
		weapon_manager.call("cancel_active_charge")
	if character_controller != null and character_controller.has_method("cancel_active_charge"):
		character_controller.call("cancel_active_charge")
	if click_marker != null:
		click_marker.visible = false
	if death_screen != null:
		death_screen.visible = false
	start_screen_shake(5.0, 0.28)
	start_level(current_stage)


func update_hud() -> void:
	var show_game_ui: bool = false
	if level_label != null:
		level_label.visible = false
		level_label.text = ""
	if key_label != null:
		key_label.visible = false
		key_label.text = ""
	if map_button != null:
		map_button.position = map_button_position
		map_button.size = map_button_size
		map_button.visible = false
	if minimap != null:
		minimap.visible = game_started and not is_dead
	if objective_arrow != null:
		objective_arrow.visible = false
	if objective_text != null:
		objective_text.visible = false
	if combo_label != null:
		combo_label.visible = false
	if level_banner != null:
		level_banner.visible = false
	if music_widget != null:
		music_widget.visible = show_music_widget
	if haven_quick_button != null:
		haven_quick_button.visible = game_started and not is_dead and not in_haven_mode
		_update_haven_button_position()
	_update_haven_hint()
	_ensure_key_hint_bar()
	_position_controls_help_panel()
	_apply_haven_ui_state()
	_refresh_haven_shop_panel_state()


func _update_haven_hint() -> void:
	if ui_layer == null:
		return
	if haven_hint_label == null:
		haven_hint_label = ui_layer.get_node_or_null("HavenReturnHint") as Label
	if haven_hint_label == null:
		haven_hint_label = Label.new()
		haven_hint_label.name = "HavenReturnHint"
		haven_hint_label.text = "Press Y to return to your level"
		haven_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		haven_hint_label.add_theme_font_size_override("font_size", 20)
		haven_hint_label.add_theme_color_override("font_color", Color(0.86, 0.92, 1.0, 0.96))
		haven_hint_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
		haven_hint_label.add_theme_constant_override("outline_size", 6)
		haven_hint_label.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.10, 0.9))
		ui_layer.add_child(haven_hint_label)
	var viewport_w: float = get_viewport_rect().size.x
	haven_hint_label.position = Vector2(viewport_w * 0.5 - 150.0, 24.0)
	haven_hint_label.custom_minimum_size = Vector2(300.0, 24.0)
	haven_hint_label.visible = game_started and not is_dead and in_haven_mode


## All gameplay controls, used by both the Z help overlay and the key-hint flexbox.
func _controls_list() -> Array:
	return [
		["LMB", "Move"],
		["RMB", "Attack / Hold to charge"],
		["1-9", "Switch class"],
		["E", "Pick up weapon"],
		["Q", "Drop weapon"],
		["H", "Enter Haven"],
		["Y", "Return to level"],
		["R", "Switch music"],
		["G", "Ping objective"],
		["T", "Toggle map"],
		["Z", "Toggle controls"],
	]


func _ensure_controls_help_panel() -> void:
	if ui_layer == null:
		return
	if controls_help_panel != null and is_instance_valid(controls_help_panel):
		return
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ControlsHelpPanel"
	panel.visible = false
	panel.custom_minimum_size = Vector2(250.0, 0.0)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)
	var title: Label = Label.new()
	title.text = "CONTROLS"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	for entry in _controls_list():
		var row: Label = Label.new()
		row.text = "[%s]  %s" % [String(entry[0]), String(entry[1])]
		row.add_theme_font_size_override("font_size", 13)
		vbox.add_child(row)
	ui_layer.add_child(panel)
	controls_help_panel = panel


func _toggle_controls_help() -> void:
	_ensure_controls_help_panel()
	controls_help_visible = not controls_help_visible
	_position_controls_help_panel()


func _position_controls_help_panel() -> void:
	if controls_help_panel == null or not is_instance_valid(controls_help_panel):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = controls_help_panel.get_combined_minimum_size()
	controls_help_panel.position = Vector2(
		viewport_size.x - maxf(250.0, panel_size.x) - 18.0,
		viewport_size.y - maxf(220.0, panel_size.y) - 18.0
	)
	controls_help_panel.visible = controls_help_visible and game_started and not is_dead


## Compact key-chip flexbox shown just left of the hotbar.
func _ensure_key_hint_bar() -> void:
	if ui_layer == null:
		return
	if key_hint_bar == null or not is_instance_valid(key_hint_bar):
		var bar: HBoxContainer = HBoxContainer.new()
		bar.name = "KeyHintBar"
		bar.add_theme_constant_override("separation", 4)
		var compact: Array = [["H", "Haven"], ["Y", "Back"], ["R", "Music"], ["T", "Map"], ["Z", "Help"]]
		for entry in compact:
			var chip: PanelContainer = PanelContainer.new()
			var chip_label: Label = Label.new()
			chip_label.text = "%s %s" % [String(entry[0]), String(entry[1])]
			chip_label.add_theme_font_size_override("font_size", 11)
			chip.add_child(chip_label)
			bar.add_child(chip)
		ui_layer.add_child(bar)
		key_hint_bar = bar
	var viewport_size: Vector2 = get_viewport_rect().size
	var bar_size: Vector2 = key_hint_bar.get_combined_minimum_size()
	# Sit to the left of the bottom-center hotbar (hotbar is ~560 wide, centered).
	key_hint_bar.position = Vector2(
		maxf(12.0, viewport_size.x * 0.5 - 280.0 - bar_size.x - 12.0),
		viewport_size.y - bar_size.y - 24.0
	)
	key_hint_bar.visible = game_started and not is_dead


func update_minimap() -> void:
	if minimap != null:
		minimap.visible = game_started and not is_dead
		minimap.queue_redraw()


func _apply_haven_ui_state() -> void:
	var hud_layer: CanvasLayer = get_node_or_null("HUDLayer") as CanvasLayer
	if hud_layer == null:
		hud_layer = get_node_or_null("HudLayer") as CanvasLayer
	if hud_layer == null:
		return
	var hide_in_haven: PackedStringArray = [
		"WeaponHUD",
		"WeaponChargeUI",
		"CharacterChargeUI",
		"CaraxesIconRoot",
		"PrinceStaminaRoot",
		"TwinsModeHints"
	]
	for node_name in hide_in_haven:
		var node: CanvasItem = hud_layer.get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.visible = not in_haven_mode


func _reveal_haven_minimap_without_fog() -> void:
	revealed_tiles.clear()
	visible_tiles.clear()
	for cell_variant in walkable_tiles.keys():
		var cell: Vector2i = cell_variant
		revealed_tiles[cell] = true
		visible_tiles[cell] = true
	if minimap != null:
		minimap.queue_redraw()


func set_player_has_weapon(value: bool) -> void:
	player_has_weapon = value
	_apply_player_animation_frames()
	play_idle()


func set_equipped_weapon(value: Node) -> void:
	equipped_weapon = value
	player_has_weapon = equipped_weapon != null
	_apply_player_animation_frames()


func set_character_animation_overrides(character_id: String, walk_frames: SpriteFrames, shoot_frames: SpriteFrames, walk_scale: Vector2, shoot_scale: Vector2) -> void:
	current_character_id = character_id
	character_walk_frames_override = walk_frames
	character_shoot_frames_override = shoot_frames
	character_walk_scale_override = walk_scale
	character_shoot_scale_override = shoot_scale
	_apply_player_animation_frames()


func get_flower_gun_settings() -> Dictionary:
	return {
		"weapon_name": "Flower Gun",
		"weapon_icon_texture": flower_weapon_icon_texture,
		"weapon_floor_texture": flower_weapon_floor_texture,
		"ui_icon": flower_weapon_icon_texture,
		"floor_pickup_sprite": flower_weapon_floor_texture,
		"floor_weapon_scale_override": flower_floor_weapon_scale,
		"player_shoot_frames": player_flower_shoot_frames,
		"base_damage": flower_base_damage,
		"base_fire_rate": flower_base_fire_rate,
		"base_charge_time": flower_base_charge_time,
		"base_charge_damage_multiplier": flower_base_charge_damage_multiplier,
		"base_projectile_speed": flower_base_projectile_speed,
		"base_spawn_distance": flower_base_spawn_distance,
		"base_spawn_y_offset": flower_base_spawn_y_offset,
		"small_petal_projectile_frames": flower_small_projectile_frames,
		"small_petal_speed": flower_small_petal_speed,
		"small_petal_size": flower_small_petal_size,
		"small_petal_damage": flower_small_petal_damage,
		"small_petal_lifetime": flower_small_petal_lifetime,
		"small_petal_hit_radius": flower_small_petal_hit_radius,
		"big_petal_projectile_frames": flower_charged_projectile_frames,
		"charged_projectile_frames": flower_charged_projectile_frames,
		"big_petal_speed": flower_big_petal_speed,
		"charged_projectile_speed": flower_big_petal_speed,
		"big_petal_size": flower_big_petal_size,
		"charged_projectile_size": flower_big_petal_size,
		"big_petal_damage": flower_big_petal_damage,
		"charged_projectile_damage": flower_big_petal_damage,
		"big_petal_lifetime": flower_big_petal_lifetime,
		"charged_projectile_lifetime": flower_big_petal_lifetime,
		"big_petal_hit_radius": flower_big_petal_hit_radius,
		"charged_projectile_hit_radius": flower_big_petal_hit_radius,
		"flower_explosion_animation_frames": flower_explosion_animation_frames,
		"explosion_animation_frames": flower_explosion_animation_frames,
		"explosion_radius": flower_explosion_radius,
		"explosion_damage": flower_explosion_damage,
		"explosion_duration": flower_explosion_duration,
		"explosion_scale": flower_explosion_scale,
		"explosion_damage_once": true
	}


func get_michael_gun_settings() -> Dictionary:
	return {
		"player_walk_frames_override": player_michael_jackson_walk_frames,
		"player_shoot_frames_override": player_michael_jackson_shoot_frames,
		"player_walk_scale_override": michael_jackson_walk_scale,
		"player_shoot_scale_override": michael_jackson_shoot_scale,
		"base_damage": 7.0,
		"charged_projectile_damage": 18.0,
		"explosion_damage": 22.0
	}


func get_visual_quality_settings() -> Dictionary:
	return {
		"enable_screen_shake": enable_screen_shake_on_key,
		"screen_shake_strength": key_screen_shake_strength,
		"screen_shake_duration": key_screen_shake_duration,
		"enable_projectile_flash": enable_player_halo or enable_light_sweep,
		"enable_projectile_shadow": true,
		"enable_projectile_trail": enable_magic_sparkles or enable_floating_pollen,
		"projectile_sharpness": 1.0,
		"premium_visuals_enabled": enable_film_grain or enable_god_rays or enable_premium_color_grade,
		"ultra_premium_visuals_enabled": enable_focus_spotlight or enable_chromatic_edges or enable_color_pop
	}


func play_weapon_shoot_animation(direction_name: String) -> void:
	if not player_has_weapon:
		return

	var clean_direction: String = normalize_direction_name(direction_name)
	if not player_shoot_anim_locked:
		shoot_anim_timer = SHOOT_ANIM_DURATION
	net_force_state_send = true

	if player_sprite != null:
		_apply_player_sprite_scale(_resolve_weapon_shoot_scale())
		var shoot_frames: SpriteFrames = _resolve_weapon_shoot_frames()
		if shoot_frames == null:
			shoot_frames = player_with_gun_shoot_frames
		if shoot_frames != null:
			player_sprite.sprite_frames = shoot_frames
		if player_shoot_anim_locked and player_shoot_anim_freeze_frame < 0:
			player_sprite.speed_scale = 0.0

	play_animation("shoot_" + clean_direction)


func _update_player_shoot_anim_lock() -> void:
	if not player_shoot_anim_locked or player_shoot_anim_freeze_frame < 0 or player_sprite == null:
		return
	if not str(player_sprite.animation).begins_with("shoot_"):
		return
	var frame_count: int = 0
	if player_sprite.sprite_frames != null and player_sprite.sprite_frames.has_animation(player_sprite.animation):
		frame_count = player_sprite.sprite_frames.get_frame_count(player_sprite.animation)
	var target_frame: int = clampi(BIG_LASER_SHOOT_FREEZE_FRAME, 0, maxi(0, frame_count - 1))
	if player_sprite.frame >= target_frame:
		player_sprite.frame = target_frame
		player_sprite.speed_scale = 0.0
		player_shoot_anim_freeze_frame = -1


func lock_player_shoot_animation(direction_name: String) -> void:
	player_shoot_anim_locked = true
	player_shoot_anim_freeze_frame = BIG_LASER_SHOOT_FREEZE_FRAME
	shoot_anim_timer = 0.0
	play_weapon_shoot_animation(direction_name)
	if player_sprite != null:
		player_sprite.speed_scale = 1.0


func unlock_player_shoot_animation() -> void:
	if not player_shoot_anim_locked:
		return
	player_shoot_anim_locked = false
	player_shoot_anim_freeze_frame = -1
	if player_sprite != null:
		player_sprite.speed_scale = 1.0
	play_idle()


func _apply_player_animation_frames() -> void:
	if player_sprite == null:
		return

	var walk_frames: SpriteFrames = _resolve_weapon_walk_frames()
	if walk_frames != null:
		player_sprite.sprite_frames = walk_frames
	_apply_player_sprite_scale(_resolve_weapon_walk_scale())


func _resolve_weapon_walk_frames() -> SpriteFrames:
	if character_walk_frames_override != null:
		return character_walk_frames_override
	if equipped_weapon == null:
		return player_default_walk_frames
	var weapon_walk_frames: Variant = equipped_weapon.get("player_walk_frames")
	if weapon_walk_frames is SpriteFrames:
		return weapon_walk_frames as SpriteFrames
	var weapon_script: Script = equipped_weapon.get_script()
	if weapon_script == MICHAEL_GUN_SCRIPT and player_michael_jackson_walk_frames != null:
		return player_michael_jackson_walk_frames
	return player_default_walk_frames


func _resolve_weapon_walk_scale() -> Vector2:
	if character_walk_frames_override != null:
		return character_walk_scale_override
	if equipped_weapon == null:
		return player_sprite_base_scale
	var walk_scale: Variant = equipped_weapon.get("player_walk_scale_override")
	if walk_scale is Vector2:
		return walk_scale as Vector2
	return player_sprite_base_scale


func _resolve_weapon_shoot_scale() -> Vector2:
	if character_shoot_frames_override != null:
		return character_shoot_scale_override
	if equipped_weapon == null:
		return player_sprite_base_scale
	var shoot_scale: Variant = equipped_weapon.get("player_shoot_scale_override")
	if shoot_scale is Vector2:
		return shoot_scale as Vector2
	var weapon_script: Script = equipped_weapon.get_script()
	if weapon_script == MICHAEL_GUN_SCRIPT:
		return michael_jackson_shoot_scale
	return player_sprite_base_scale


func _apply_player_sprite_scale(target_scale: Vector2) -> void:
	if player_sprite == null:
		return
	var safe_scale: Vector2 = Vector2(maxf(0.01, target_scale.x), maxf(0.01, target_scale.y))
	player_sprite.scale = safe_scale
	var anchor_height: float = 0.0
	var frame_tex: Texture2D = player_sprite.sprite_frames.get_frame_texture(player_sprite.animation, player_sprite.frame) if player_sprite.sprite_frames != null and player_sprite.sprite_frames.has_animation(player_sprite.animation) and player_sprite.sprite_frames.get_frame_count(player_sprite.animation) > 0 else null
	if frame_tex != null:
		anchor_height = float(frame_tex.get_height())
	player_sprite_scale_compensation = Vector2(0.0, -anchor_height * maxf(0.0, safe_scale.y - 1.0) * 0.5)


func _resolve_weapon_shoot_frames() -> SpriteFrames:
	if character_shoot_frames_override != null:
		return character_shoot_frames_override
	if equipped_weapon == null:
		return null
	var weapon_shoot_frames: Variant = equipped_weapon.get("player_shoot_frames")
	if weapon_shoot_frames is SpriteFrames:
		return weapon_shoot_frames as SpriteFrames
	var weapon_script: Script = equipped_weapon.get_script()
	if weapon_script == FLOWER_GUN_SCRIPT and player_flower_shoot_frames != null:
		return player_flower_shoot_frames
	if weapon_script == MICHAEL_GUN_SCRIPT and player_michael_jackson_shoot_frames != null:
		return player_michael_jackson_shoot_frames
	return null


func _resolve_remote_shoot_frames() -> SpriteFrames:
	if player_with_gun_shoot_frames != null:
		return player_with_gun_shoot_frames
	if player_flower_shoot_frames != null:
		return player_flower_shoot_frames
	if player_michael_jackson_shoot_frames != null:
		return player_michael_jackson_shoot_frames
	return player_default_walk_frames


func _resolve_remote_base_frames() -> SpriteFrames:
	return player_default_walk_frames


func _optimize_remote_player_node(root: Node) -> void:
	if root == null:
		return

	var animated_sprite: AnimatedSprite2D = root as AnimatedSprite2D
	if animated_sprite != null:
		animated_sprite.speed_scale = 1.0
	else:
		var node_2d: Node2D = root as Node2D
		if node_2d != null:
			node_2d.set_process(false)
			node_2d.set_physics_process(false)
			node_2d.set_process_input(false)
			node_2d.set_process_unhandled_input(false)
			node_2d.set_process_shortcut_input(false)
			node_2d.set_process_unhandled_key_input(false)

	if root is CollisionObject2D:
		var collision: CollisionObject2D = root as CollisionObject2D
		collision.collision_layer = 0
		collision.collision_mask = 0

	for child in root.get_children():
		_optimize_remote_player_node(child)


func normalize_direction_name(direction_name: String) -> String:
	match direction_name:
		"forward":
			return "down"
		"back":
			return "up"
		"down":
			return "down"
		"up":
			return "up"
		"left":
			return "left"
		"right":
			return "right"
		_:
			return "down"


func set_animation_from_vector(direction: Vector2, prefix: String) -> void:
	if shoot_anim_timer > 0.0 or player_charge_visual_active or player_shoot_anim_locked:
		return

	_apply_player_animation_frames()

	var actual_prefix: String = prefix
	if actual_prefix == "walking":
		actual_prefix = "walk"

	var direction_name: String = "down"

	if absf(direction.x) > absf(direction.y):
		if direction.x >= 0.0:
			direction_name = "right"
		else:
			direction_name = "left"
	else:
		if direction.y >= 0.0:
			direction_name = "down"
		else:
			direction_name = "up"

	last_direction = direction_name
	play_animation(actual_prefix + "_" + direction_name)


func play_idle() -> void:
	if shoot_anim_timer > 0.0 or player_charge_visual_active or player_shoot_anim_locked:
		return

	_update_idle_facing_from_cursor()
	_apply_player_animation_frames()
	play_animation("idle_" + normalize_direction_name(last_direction))


func _update_idle_facing_from_cursor() -> void:
	if not game_started or is_dead:
		return
	if in_haven_mode:
		return
	if player_charge_visual_active or player_shoot_anim_locked:
		return
	if player == null or player_sprite == null:
		return
	if is_moving_to_click or not click_path.is_empty():
		return
	if shoot_anim_timer > 0.0:
		return
	var aim_delta: Vector2 = get_global_mouse_position() - player.global_position
	if aim_delta.length() <= 0.001:
		return
	var next_direction: String = "down"
	if absf(aim_delta.x) > absf(aim_delta.y):
		next_direction = "right" if aim_delta.x >= 0.0 else "left"
	else:
		next_direction = "down" if aim_delta.y >= 0.0 else "up"
	if normalize_direction_name(last_direction) == next_direction:
		return
	last_direction = next_direction


func set_player_charge_visual(active: bool, direction_name: String = "down") -> void:
	player_charge_visual_active = active
	player_charge_direction = normalize_direction_name(direction_name)
	if not active:
		player_charge_fully_charged = false
		player_charge_shake_time = 0.0
		if player_sprite != null:
			player_sprite.position = player_sprite_base_position + player_sprite_scale_compensation
			player_sprite.speed_scale = 1.0
		return
	if player_sprite != null:
		player_sprite.speed_scale = 0.2
	net_force_state_send = true
	play_weapon_shoot_animation(player_charge_direction)


func set_player_charge_progress(progress: float) -> void:
	player_charge_fully_charged = player_charge_visual_active and progress >= 0.995


func _update_player_charge_visual(delta: float) -> void:
	if player_sprite == null:
		return
	if not player_charge_visual_active:
		var base_pos: Vector2 = player_sprite_base_position + player_sprite_scale_compensation
		player_sprite.position = player_sprite.position.lerp(base_pos, clampf(delta * 14.0, 0.0, 1.0))
		if not player_shoot_anim_locked:
			player_sprite.speed_scale = 1.0
		return

	player_charge_shake_time += delta
	player_sprite.speed_scale = 0.0 if player_charge_fully_charged else 0.2
	var aim_delta: Vector2 = get_global_mouse_position() - player.global_position
	if aim_delta.length() > 0.001:
		player_charge_direction = _direction_name_from_vector(aim_delta)
	last_direction = player_charge_direction

	var shoot_frames: SpriteFrames = _resolve_weapon_shoot_frames()
	if shoot_frames == null:
		shoot_frames = player_with_gun_shoot_frames
	if shoot_frames != null:
		player_sprite.sprite_frames = shoot_frames
	_apply_player_sprite_scale(_resolve_weapon_shoot_scale())

	var shoot_animation: String = "shoot_" + normalize_direction_name(player_charge_direction)
	var resolved: String = resolve_animation(shoot_animation)
	if player_sprite.sprite_frames != null and player_sprite.sprite_frames.has_animation(resolved):
		if current_anim != resolved:
			play_animation(shoot_animation)

	var shake_offset: Vector2 = Vector2(
		sin(player_charge_shake_time * 18.0) * 0.8,
		cos(player_charge_shake_time * 14.0) * 0.6
	)
	player_sprite.position = player_sprite_base_position + player_sprite_scale_compensation + shake_offset


func _direction_name_from_vector(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x >= 0.0 else "left"
	return "down" if direction.y >= 0.0 else "up"


func resolve_animation(anim_name: String) -> String:
	# New required animation names:
	# idle_down, idle_left, idle_right, idle_up
	# walk_down, walk_left, walk_right, walk_up
	# shoot_down, shoot_left, shoot_right, shoot_up
	#
	# Backward compatibility for older names:
	if anim_name == "idle":
		return "idle_down"
	if anim_name == "walking_forward":
		return "walk_down"
	if anim_name == "walking_back":
		return "walk_up"
	if anim_name == "walking_left":
		return "walk_left"
	if anim_name == "walking_right":
		return "walk_right"
	if anim_name == "forward":
		return "down"
	if anim_name == "back":
		return "up"
	return anim_name


func play_animation(anim_name: String) -> void:
	if player_sprite == null or player_sprite.sprite_frames == null:
		return

	var actual_anim: String = resolve_animation(anim_name)
	var mirror_result: Dictionary = MIRROR_ANIMATION_HELPER_SCRIPT.resolve_with_mirror(player_sprite.sprite_frames, actual_anim)
	if not bool(mirror_result.get("found", false)) and actual_anim.begins_with("shoot_"):
		var fallback_walk: String = "walk_" + actual_anim.trim_prefix("shoot_")
		mirror_result = MIRROR_ANIMATION_HELPER_SCRIPT.resolve_with_mirror(player_sprite.sprite_frames, fallback_walk)

	if not bool(mirror_result.get("found", false)):
		print("Missing player animation: ", actual_anim)
		return

	actual_anim = str(mirror_result.get("animation", actual_anim))
	player_sprite.flip_h = bool(mirror_result.get("flip_h", false))

	current_anim = actual_anim
	player_sprite.play(actual_anim)

func choose_far_room_from(from_tile: Vector2i, percentile: float) -> Vector2i:
	var scored: Array[Dictionary] = []
	for room_center in room_centers:
		var room: Vector2i = room_center
		var dist: int = abs(room.x - from_tile.x) + abs(room.y - from_tile.y)
		scored.append({"room": room, "dist": dist})
	if scored.is_empty():
		return spawn_tile
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["dist"]) < int(b["dist"])
	)
	var index: int = clampi(roundi(float(scored.size() - 1) * percentile), 0, scored.size() - 1)
	var chosen: Dictionary = scored[index]
	var chosen_room: Vector2i = chosen["room"]
	return chosen_room


func get_random_walkable_cell(rng: RandomNumberGenerator) -> Vector2i:
	var keys: Array = walkable_tiles.keys()
	if keys.is_empty():
		return spawn_tile
	var selected: Vector2i = keys[rng.randi_range(0, keys.size() - 1)]
	return selected


func choose_direction(rng: RandomNumberGenerator) -> Vector2i:
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	return dirs[rng.randi_range(0, dirs.size() - 1)]


func rotate_direction(direction: Vector2i, rng: RandomNumberGenerator) -> Vector2i:
	if direction == Vector2i.ZERO:
		return choose_direction(rng)
	if rng.randf() < 0.5:
		return Vector2i(-direction.y, direction.x)
	return Vector2i(direction.y, -direction.x)



func make_ring_texture(size: int, tint: Color) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(float(size) * 0.5, float(size) * 0.5)
	var radius: float = float(size) * 0.5
	for x in range(size):
		for y in range(size):
			var p: Vector2 = Vector2(float(x), float(y))
			var d: float = p.distance_to(center) / radius
			var ring: float = smoothstep(0.82, 0.68, d) - smoothstep(0.55, 0.42, d)
			var soft: float = smoothstep(1.0, 0.35, d) * 0.18
			var alpha: float = clampf(ring + soft, 0.0, 1.0) * tint.a
			img.set_pixel(x, y, Color(tint.r, tint.g, tint.b, alpha))
	return ImageTexture.create_from_image(img)


func make_focus_spotlight_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_mix;
uniform vec4 spotlight_color : source_color = vec4(0.0, 0.0, 0.0, 0.22);
uniform float radius = 0.34;
uniform float softness = 0.42;
void fragment() {
	float d = distance(SCREEN_UV, vec2(0.5, 0.52));
	float mask = smoothstep(radius, radius + softness, d);
	COLOR = vec4(spotlight_color.rgb, spotlight_color.a * mask);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("spotlight_color", focus_spotlight_color)
	mat.set_shader_parameter("radius", focus_spotlight_radius)
	mat.set_shader_parameter("softness", focus_spotlight_softness)
	return mat


func make_chromatic_edge_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float edge_strength = 0.85;
uniform float edge_fade = 0.58;
void fragment() {
	vec2 from_center = SCREEN_UV - vec2(0.5);
	float edge = smoothstep(edge_fade, 1.0, length(from_center) * 1.45);
	vec2 offset = normalize(from_center + vec2(0.0001)) * SCREEN_PIXEL_SIZE * edge_strength * edge;
	float r = texture(screen_texture, SCREEN_UV + offset).r;
	float g = texture(screen_texture, SCREEN_UV).g;
	float b = texture(screen_texture, SCREEN_UV - offset).b;
	COLOR = vec4(r, g, b, 1.0);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("edge_strength", chromatic_edge_strength)
	mat.set_shader_parameter("edge_fade", chromatic_edge_fade)
	return mat


func make_color_pop_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pop_strength = 0.12;
uniform float pop_contrast = 1.08;
void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 contrasted = (color - 0.5) * pop_contrast + 0.5;
	vec3 saturated = mix(vec3(luma), contrasted, 1.0 + pop_strength);
	COLOR = vec4(clamp(mix(color, saturated, pop_strength), 0.0, 1.0), 1.0);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("pop_strength", color_pop_strength)
	mat.set_shader_parameter("pop_contrast", color_pop_contrast)
	return mat


func make_depth_shadow_gradient_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_mix;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.22);
void fragment() {
	float bottom = smoothstep(0.52, 1.0, SCREEN_UV.y);
	float side = max(1.0 - smoothstep(0.0, 0.16, SCREEN_UV.x), smoothstep(0.84, 1.0, SCREEN_UV.x));
	float mask = max(bottom * 0.82, side * 0.38);
	COLOR = vec4(shadow_color.rgb, shadow_color.a * mask);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("shadow_color", depth_shadow_gradient_color)
	return mat


func make_warm_corner_glow_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_add;
uniform vec4 glow_color : source_color = vec4(1.0, 0.70, 0.28, 0.10);
void fragment() {
	float d1 = distance(SCREEN_UV, vec2(0.18, 0.16));
	float d2 = distance(SCREEN_UV, vec2(0.78, 0.18));
	float glow = pow(smoothstep(0.72, 0.0, min(d1, d2)), 2.2);
	COLOR = vec4(glow_color.rgb, glow_color.a * glow);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("glow_color", warm_corner_glow_color)
	return mat


func make_texture_lines_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_add;
uniform vec4 line_color : source_color = vec4(1.0, 0.94, 0.72, 0.055);
uniform float frequency = 120.0;
void fragment() {
	float line = sin((SCREEN_UV.y + TIME * 0.006) * frequency);
	line = smoothstep(0.94, 1.0, line);
	COLOR = vec4(line_color.rgb, line_color.a * line);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("line_color", texture_lines_color)
	mat.set_shader_parameter("frequency", texture_lines_frequency)
	return mat

func make_film_grain_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_mix;
uniform vec4 grain_color : source_color = vec4(1.0, 0.95, 0.80, 1.0);
uniform float grain_strength = 0.035;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}
void fragment() {
	float n = hash(SCREEN_UV * vec2(1920.0, 1080.0) + TIME * 43.0);
	float grain = (n - 0.5) * grain_strength;
	COLOR = vec4(grain_color.rgb, abs(grain));
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("grain_color", film_grain_color)
	mat.set_shader_parameter("grain_strength", film_grain_strength)
	return mat


func make_god_rays_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_add;
uniform vec4 ray_color : source_color = vec4(1.0, 0.86, 0.42, 0.105);
uniform float ray_strength = 0.26;
void fragment() {
	vec2 sun = vec2(0.18, 0.06);
	vec2 dir = SCREEN_UV - sun;
	float angle = atan(dir.y, dir.x);
	float rays = sin(angle * 18.0 + TIME * 0.45) * 0.5 + 0.5;
	rays = pow(rays, 5.0);
	float fade = 1.0 - smoothstep(0.0, 1.05, length(dir));
	float vertical = 1.0 - smoothstep(0.22, 0.92, SCREEN_UV.y);
	COLOR = vec4(ray_color.rgb, ray_color.a * rays * fade * vertical * ray_strength);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("ray_color", god_rays_color)
	mat.set_shader_parameter("ray_strength", god_rays_strength)
	return mat


func make_cloud_shadow_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_mix;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.155);
uniform float shadow_strength = 0.22;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float a = hash(i); float b = hash(i + vec2(1.0, 0.0)); float c = hash(i + vec2(0.0, 1.0)); float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
void fragment() {
	vec2 uv = SCREEN_UV * 2.2 + vec2(TIME * 0.018, TIME * 0.006);
	float n = noise(uv) * 0.7 + noise(uv * 2.2) * 0.3;
	float mask = smoothstep(0.48, 0.80, n);
	COLOR = vec4(shadow_color.rgb, shadow_color.a * mask * shadow_strength);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("shadow_color", cloud_shadow_color)
	mat.set_shader_parameter("shadow_strength", cloud_shadow_strength)
	return mat


func make_color_grade_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 shadow_tint : source_color = vec4(0.52, 0.64, 0.76, 1.0);
uniform vec4 highlight_tint : source_color = vec4(1.0, 0.88, 0.58, 1.0);
uniform float grade_strength = 0.18;
void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float lum = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 graded = mix(color * shadow_tint.rgb, color * highlight_tint.rgb, smoothstep(0.20, 0.88, lum));
	color = mix(color, graded, grade_strength);
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("shadow_tint", color_grade_shadow_tint)
	mat.set_shader_parameter("highlight_tint", color_grade_highlight_tint)
	mat.set_shader_parameter("grade_strength", color_grade_strength)
	return mat


func make_sun_glow_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_add;
uniform vec4 sun_color : source_color = vec4(1.0, 0.78, 0.32, 0.16);
void fragment() {
	float d = distance(SCREEN_UV, vec2(0.12, 0.08));
	float glow = smoothstep(0.82, 0.0, d);
	glow = pow(glow, 2.1);
	COLOR = vec4(sun_color.rgb, sun_color.a * glow);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("sun_color", sun_glow_color)
	return mat


func make_void_shimmer_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_add;
uniform vec4 shimmer_color : source_color = vec4(0.38, 0.76, 1.0, 0.095);
void fragment() {
	float lower = smoothstep(0.48, 1.0, SCREEN_UV.y);
	float wave = sin((SCREEN_UV.x * 22.0 + SCREEN_UV.y * 10.0) + TIME * 0.9) * 0.5 + 0.5;
	wave *= sin((SCREEN_UV.x * -13.0 + SCREEN_UV.y * 17.0) + TIME * 0.55) * 0.5 + 0.5;
	wave = pow(wave, 3.4);
	COLOR = vec4(shimmer_color.rgb, shimmer_color.a * wave * lower);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("shimmer_color", void_shimmer_color)
	return mat


func make_edge_haze_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_add;
uniform vec4 haze_color : source_color = vec4(0.56, 0.76, 0.88, 0.11);
void fragment() {
	float left = 1.0 - smoothstep(0.0, 0.22, SCREEN_UV.x);
	float right = smoothstep(0.78, 1.0, SCREEN_UV.x);
	float bottom = smoothstep(0.62, 1.0, SCREEN_UV.y);
	float haze = max(max(left, right), bottom * 0.72);
	COLOR = vec4(haze_color.rgb, haze_color.a * haze);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("haze_color", edge_haze_color)
	return mat

func make_sharpness_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float sharpen_strength = 0.44;
uniform float contrast = 1.16;
uniform float saturation = 1.12;
uniform float brightness = 0.025;
void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec3 center = texture(screen_texture, SCREEN_UV).rgb;
	vec3 up = texture(screen_texture, SCREEN_UV + vec2(0.0, -px.y)).rgb;
	vec3 down = texture(screen_texture, SCREEN_UV + vec2(0.0, px.y)).rgb;
	vec3 left = texture(screen_texture, SCREEN_UV + vec2(-px.x, 0.0)).rgb;
	vec3 right = texture(screen_texture, SCREEN_UV + vec2(px.x, 0.0)).rgb;
	vec3 sharp = center * (1.0 + 4.0 * sharpen_strength) - (up + down + left + right) * sharpen_strength;
	vec3 color = mix(center, sharp, sharpen_strength);
	color = (color - 0.5) * contrast + 0.5;
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(gray), color, saturation);
	color += brightness;
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("sharpen_strength", screen_sharpen_strength)
	mat.set_shader_parameter("contrast", screen_contrast)
	mat.set_shader_parameter("saturation", screen_saturation)
	mat.set_shader_parameter("brightness", screen_brightness)
	return mat


func make_light_sweep_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_add;
uniform vec4 sweep_color : source_color = vec4(1.0, 0.86, 0.42, 0.08);
void fragment() {
	float band = smoothstep(0.0, 0.18, SCREEN_UV.x + SCREEN_UV.y + sin(TIME * 0.28) * 0.35 - 0.76);
	band *= 1.0 - smoothstep(0.18, 0.42, SCREEN_UV.x + SCREEN_UV.y + sin(TIME * 0.28) * 0.35 - 0.76);
	COLOR = vec4(sweep_color.rgb, sweep_color.a * band);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("sweep_color", light_sweep_color)
	return mat


func spawn_key_wisp_burst(world_position: Vector2) -> void:
	if not enable_key_wisps:
		return
	var burst: CPUParticles2D = CPUParticles2D.new()
	burst.name = "KeyWispBurst"
	burst.amount = 20
	burst.one_shot = true
	burst.lifetime = 0.9
	burst.explosiveness = 0.92
	burst.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 7.0
	burst.gravity = Vector2(0.0, -34.0)
	burst.initial_velocity_min = 16.0
	burst.initial_velocity_max = 52.0
	burst.angular_velocity_min = -120.0
	burst.angular_velocity_max = 120.0
	burst.scale_amount_min = 1.0
	burst.scale_amount_max = 2.8
	burst.color = key_wisp_color
	burst.texture = make_particle_texture(9, key_wisp_color)
	burst.global_position = world_position + Vector2(0.0, -24.0)
	burst.z_index = 120
	add_child(burst)
	burst.emitting = true
	var tween: Tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_callback(burst.queue_free)


func spawn_breadcrumb() -> void:
	if not enable_breadcrumb_trail or breadcrumb_root == null:
		return
	if elapsed_time - last_breadcrumb_time < breadcrumb_interval:
		return
	last_breadcrumb_time = elapsed_time
	var dot: Polygon2D = Polygon2D.new()
	dot.name = "BreadcrumbDot"
	dot.polygon = make_ellipse_polygon(18.0, 7.0, 16)
	dot.color = breadcrumb_color
	dot.global_position = player.global_position + Vector2(0.0, 15.0)
	dot.z_index = 44
	breadcrumb_root.add_child(dot)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dot, "scale", Vector2(0.25, 0.25), 1.2)
	tween.tween_property(dot, "color:a", 0.0, 1.2)
	tween.chain().tween_callback(dot.queue_free)


func register_key_combo() -> void:
	if not enable_combo_feedback:
		return
	key_combo_count += 1
	key_combo_timer = combo_reset_time
	if combo_label != null:
		combo_label.text = "KEY STREAK x" + str(key_combo_count)
		combo_label.scale = Vector2(1.18, 1.18)
		var tween: Tween = create_tween()
		tween.tween_property(combo_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)


func show_level_banner() -> void:
	if not enable_level_banner or level_banner == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	level_banner.text = level_banner_prefix + " 1-" + str(current_stage)
	level_banner.position = Vector2(0.0, viewport_size.y * 0.18)
	level_banner.size = Vector2(viewport_size.x, 58.0)
	level_banner.modulate = Color(1.0, 0.92, 0.60, 0.0)
	level_banner.scale = Vector2(0.92, 0.92)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(level_banner, "modulate:a", 0.95, 0.35)
	tween.tween_property(level_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_interval(1.15)
	tween.chain().tween_property(level_banner, "modulate:a", 0.0, 0.45)


func ping_objective() -> void:
	ping_current_objective()


func ping_current_objective() -> void:
	if not game_started or is_dead:
		return
	var objective_tile: Vector2i = get_current_objective_tile()
	if objective_tile == Vector2i.ZERO:
		return
	var pos: Vector2 = tile_to_world(objective_tile)
	show_floating_text(pos, "OBJECTIVE", Color(1.0, 0.88, 0.28, 1.0))
	spawn_key_wisp_burst(pos)
	if objective_arrow != null:
		objective_arrow.scale = Vector2(1.45, 1.45)
		if objective_ping_tween != null and objective_ping_tween.is_running():
			objective_ping_tween.kill()
		objective_ping_tween = create_tween()
		objective_ping_tween.tween_property(objective_arrow, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func count_road_neighbors(cell: Vector2i) -> int:
	var count: int = 0
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if road_tiles.has(cell + d):
			count += 1
	return count


func count_walkable_neighbors(cell: Vector2i) -> int:
	var count: int = 0
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if walkable_tiles.has(cell + d):
			count += 1
	return count


func is_edge_cell(cell: Vector2i) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if not walkable_tiles.has(cell + d):
			return true
	return false


func pick_existing_atlas(atlas_list: Array[Vector2i], rng: RandomNumberGenerator, fallback: Vector2i) -> Vector2i:
	var existing: Array[Vector2i] = []
	for atlas_coord in atlas_list:
		if tile_exists_atlas(atlas_coord):
			existing.append(atlas_coord)
	if existing.is_empty():
		return fallback
	return existing[rng.randi_range(0, existing.size() - 1)]


func tile_exists_atlas(atlas_coord: Vector2i) -> bool:
	if tilemap == null or tilemap.tile_set == null:
		return false
	if not tilemap.tile_set.has_source(GROUND_SOURCE_ID):
		return false
	var source: TileSetSource = tilemap.tile_set.get_source(GROUND_SOURCE_ID)
	if source == null or not source is TileSetAtlasSource:
		return false
	var atlas_source: TileSetAtlasSource = source as TileSetAtlasSource
	return atlas_source.has_tile(atlas_coord)


func set_atlas_cell_safe(layer: TileMapLayer, cell: Vector2i, atlas_coord: Vector2i) -> void:
	tile_place_attempts += 1
	if layer == null:
		tile_place_failures += 1
		return
	if not tile_exists_atlas(atlas_coord):
		tile_place_failures += 1
		missing_tiles[atlas_coord] = true
		return
	layer.set_cell(cell, GROUND_SOURCE_ID, atlas_coord, TILE_ALTERNATIVE)
	tile_place_successes += 1


func world_to_tile(world_pos: Vector2) -> Vector2i:
	return tilemap.local_to_map(tilemap.to_local(world_pos))


func tile_to_world(tile_pos: Vector2i) -> Vector2:
	# Original tile-click anchor: the player stands exactly at the TileMap cell center.
	# Keep this at zero so the character does not float above the isometric tile.
	return tilemap.to_global(tilemap.map_to_local(tile_pos))


func get_duo_partner_world_position(partner_tile_offset: Vector2i) -> Vector2:
	if player == null:
		return Vector2.ZERO
	if not is_moving_to_click or click_path.is_empty():
		var stack_tile: Vector2i = world_to_tile(player.global_position)
		return tile_to_world(stack_tile + partner_tile_offset)
	var step_to_tile: Vector2i = click_path[0]
	var step_from_tile: Vector2i = _infer_move_from_tile(step_to_tile)
	var from_world: Vector2 = tile_to_world(step_from_tile)
	var to_world: Vector2 = tile_to_world(step_to_tile)
	var segment_length: float = from_world.distance_to(to_world)
	var travel_t: float = 0.0
	if segment_length > 0.001:
		travel_t = clampf((player.global_position - from_world).length() / segment_length, 0.0, 1.0)
	var partner_from_world: Vector2 = tile_to_world(step_from_tile + partner_tile_offset)
	var partner_to_world: Vector2 = tile_to_world(step_to_tile + partner_tile_offset)
	return partner_from_world.lerp(partner_to_world, travel_t)


func _infer_move_from_tile(to_tile: Vector2i) -> Vector2i:
	if player == null:
		return to_tile
	var to_world: Vector2 = tile_to_world(to_tile)
	var best_from_tile: Vector2i = to_tile
	var best_progress: float = -INF
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var candidate_tile: Vector2i = to_tile - dir
		if not walkable_tiles.has(candidate_tile):
			continue
		var candidate_world: Vector2 = tile_to_world(candidate_tile)
		var segment: Vector2 = to_world - candidate_world
		if segment.length_squared() <= 0.001:
			continue
		var progress: float = (player.global_position - candidate_world).dot(segment.normalized())
		if progress > best_progress:
			best_progress = progress
			best_from_tile = candidate_tile
	return best_from_tile


func is_inside_map(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < map_width and cell.y >= 0 and cell.y < map_height


func clamp_to_map(cell: Vector2i) -> Vector2i:
	var edge: int = world_edge_buffer_tiles
	return Vector2i(int(clamp(cell.x, edge, map_width - edge - 1)), int(clamp(cell.y, edge, map_height - edge - 1)))


func signi(value: int) -> int:
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0


func reset_debug_counters() -> void:
	tile_place_attempts = 0
	tile_place_successes = 0
	tile_place_failures = 0
	missing_tiles.clear()


func print_debug_header() -> void:
	if not debug_tiles:
		return
	print("-----------------------------------")
	print("ATMOSPHERIC WORLD SCRIPT LOADED")
	print("Attach this script to the root World Node2D.")
	print("Required nodes: TileMapLayer, Player/AnimatedSprite2D, ClickMarker.")
	print("Optional nodes are created automatically: DecoLayer, Camera2D, HUDLayer, MiniMapLayer, AtmosphereLayer, CanvasModulate, WorldBackground.")
	print("Using tile sheet path: ", NEW_TILE_SHEET_PATH)
	print("Left click sets/follows target. Right click cancels movement.")
	print("-----------------------------------")


func print_level_result_debug() -> void:
	if not debug_tiles:
		return
	print("-----------------------------------")
	print("LEVEL RESULT DEBUG")
	print("Stage: ", current_stage)
	print("Walkable tiles: ", walkable_tiles.size())
	print("Rooms: ", room_centers.size())
	print("Keys: ", key_tiles)
	print("Goal tile: ", goal_tile)
	print("Tile placement attempts: ", tile_place_attempts)
	print("Tile placement successes: ", tile_place_successes)
	print("Tile placement failures: ", tile_place_failures)
	print("Missing atlas tiles: ", missing_tiles.keys())
	print("-----------------------------------")


func _should_auto_connect_multiplayer(args: PackedStringArray) -> bool:
	if args.has("--multiplayer"):
		return true
	if _extract_player_index_arg(args) > 0:
		return true
	return false


func _extract_player_index_arg(args: PackedStringArray) -> int:
	for arg in args:
		if not arg.begins_with("--p"):
			continue
		var raw_index: String = arg.substr(3)
		if raw_index.is_valid_int():
			var parsed: int = int(raw_index)
			if parsed > 0:
				return parsed
	return 0


func _read_cmdline_option(args: PackedStringArray, key: String) -> String:
	for index in range(args.size()):
		if args[index] != key:
			continue
		var next_index: int = index + 1
		if next_index >= args.size():
			return ""
		return str(args[next_index])
	return ""


func on_drop_collected(drop: DropItem) -> void:
	var drop_mgr: Node = get_node_or_null("/root/DropManager")
	if drop_mgr != null and drop_mgr.has_method("handle_collected"):
		drop_mgr.call("handle_collected", drop)


func show_pickup_text(world_position: Vector2, text: String, color: Color = Color(1.0, 0.92, 0.45, 1.0)) -> void:
	show_floating_text(world_position + Vector2(0.0, -18.0), text, color)


func heal_player(amount: float) -> void:
	current_health = clampf(current_health + amount, 0.0, max_health)
	update_health_bar()
	show_pickup_text(player.global_position, "+%d HP" % int(round(amount)), Color(1.0, 0.45, 0.55, 1.0))


func spawn_room_clear_rewards(room_center: Vector2i) -> void:
	var drop_mgr: Node = get_node_or_null("/root/DropManager")
	if drop_mgr == null:
		return
	var origin: Vector2 = tile_to_world(room_center)
	for i in range(3):
		var offset: Vector2 = Vector2(randf_range(-20.0, 20.0), randf_range(-12.0, 12.0))
		drop_mgr.call("spawn_drop", MobDropTables.DROP_SILVER, origin + offset)


func _go_to_haven() -> void:
	_prepare_haven_return_state()
	if multiplayer_enabled and net_node != null:
		if net_node.has_method("send_level_started"):
			net_node.call("send_level_started", 0, multiplayer_map_seed)
		start_level(1, true)
		return
	game_started = false
	clear_level()
	var loading: Node = get_node_or_null("/root/LoadingScreen")
	if loading != null and loading.has_method("transition_to"):
		loading.call("transition_to", "haven", "Haven", "Preparing sanctuary...", "res://world.tscn")
	else:
		get_tree().change_scene_to_file("res://world.tscn")


func _prepare_haven_return_state() -> void:
	var campaign: Node = get_node_or_null("/root/CampaignManager")
	if campaign == null:
		return
	var return_level_id: String = "world_1_1"
	var return_stage: int = maxi(1, current_stage)
	if campaign.has_method("level_for_stage"):
		return_level_id = String(campaign.call("level_for_stage", return_stage, "world_1"))
	var current_level_id: String = String(campaign.get("current_level_id"))
	if current_level_id.begins_with("world_"):
		return_level_id = current_level_id
		if campaign.has_method("stage_for_level"):
			return_stage = int(campaign.call("stage_for_level", current_level_id))
	var resolved: Dictionary = _resolve_haven_return_target(campaign, return_level_id, return_stage)
	return_level_id = String(resolved.get("level_id", return_level_id))
	return_stage = int(resolved.get("stage", return_stage))
	if campaign.has_method("start_campaign_level"):
		campaign.call("start_campaign_level", "haven")
	if campaign.has_method("queue_enter_haven"):
		campaign.call("queue_enter_haven", return_level_id, return_stage)
	else:
		campaign.set("pending_scene_mode", "haven")
		campaign.set("pending_haven_level_id", return_level_id)
		campaign.set("pending_haven_start_stage", return_stage)


func _resolve_haven_return_target(campaign: Node, level_id: String, stage: int) -> Dictionary:
	var resolved_level: String = level_id
	var resolved_stage: int = maxi(1, stage)
	if campaign == null:
		return {"level_id": resolved_level, "stage": resolved_stage}
	var guard: int = 0
	while guard < 10 and campaign.has_method("is_level_completed"):
		if not bool(campaign.call("is_level_completed", resolved_level)):
			break
		if not campaign.has_method("get_next_level_after"):
			break
		var next_level: String = String(campaign.call("get_next_level_after", resolved_level))
		if next_level == "" or next_level == "haven":
			break
		resolved_level = next_level
		if campaign.has_method("stage_for_level"):
			resolved_stage = int(campaign.call("stage_for_level", resolved_level))
		guard += 1
	return {"level_id": resolved_level, "stage": resolved_stage}


func _return_from_haven() -> void:
	if not in_haven_mode:
		return
	var target_level_id: String = "world_1_1"
	var target_stage: int = 1
	var campaign: Node = get_node_or_null("/root/CampaignManager")
	if campaign != null:
		var pending_id: String = String(campaign.get("pending_haven_level_id"))
		var pending_stage: int = int(campaign.get("pending_haven_start_stage"))
		if pending_id.begins_with("world_"):
			target_level_id = pending_id
		if pending_stage > 0:
			target_stage = pending_stage
		var resolved: Dictionary = _resolve_haven_return_target(campaign, target_level_id, target_stage)
		target_level_id = String(resolved.get("level_id", target_level_id))
		target_stage = int(resolved.get("stage", target_stage))
		if campaign.has_method("queue_start_from_haven"):
			campaign.call("queue_start_from_haven", target_level_id, target_stage)
		else:
			campaign.set("pending_haven_level_id", target_level_id)
			campaign.set("pending_haven_start_stage", target_stage)
	if multiplayer_enabled and net_node != null:
		if net_node.has_method("send_level_started"):
			net_node.call("send_level_started", target_stage, multiplayer_map_seed)
		start_level(target_stage)
		return
	game_started = false
	clear_level()
	var loading: Node = get_node_or_null("/root/LoadingScreen")
	if loading != null and loading.has_method("transition_to"):
		loading.call("transition_to", target_level_id, "Back to Level", "Returning from Haven...", "res://world.tscn")
	else:
		get_tree().change_scene_to_file("res://world.tscn")


func start_campaign_from_haven(level_id: String, stage_number: int) -> void:
	start_level(stage_number)


func _try_start_pending_haven_campaign() -> void:
	var campaign: Node = get_node_or_null("/root/CampaignManager")
	if campaign == null:
		return
	var pending_mode: String = String(campaign.get("pending_scene_mode"))
	if pending_mode == "haven":
		campaign.set("pending_scene_mode", "")
		call_deferred("start_level", 1, true)
		return
	var pending_id: String = String(campaign.get("pending_haven_level_id"))
	if pending_id == "":
		return
	var stage: int = int(campaign.get("pending_haven_start_stage"))
	campaign.set("pending_haven_level_id", "")
	campaign.set("pending_haven_start_stage", 0)
	call_deferred("start_campaign_from_haven", pending_id, stage)


func _paint_world_edge_buffer(rng: RandomNumberGenerator) -> void:
	var edge: int = world_edge_buffer_tiles
	for x in range(map_width):
		for y in range(map_height):
			var cell: Vector2i = Vector2i(x, y)
			var near_edge: bool = x < edge or y < edge or x >= map_width - edge or y >= map_height - edge
			if not near_edge:
				continue
			if walkable_tiles.has(cell) and rng.randf() < 0.35:
				if deco_layer != null and plant_deco_tiles.size() > 0:
					var deco_tile: Vector2i = plant_deco_tiles[rng.randi_range(0, plant_deco_tiles.size() - 1)]
					set_atlas_cell_safe(deco_layer, cell, deco_tile)
				walkable_tiles.erase(cell)


func _warn_slime_spawn_positions(room_center: Vector2i, count: int) -> void:
	if wave_visual_controller == null:
		return
	var cells: Array[Vector2i] = _get_room_cells(room_center)
	if cells.is_empty():
		return
	var rng: RandomNumberGenerator = _make_room_rng(room_center, 9090 + count)
	var positions: Array[Vector2] = []
	for i in range(mini(count, 6)):
		var cell: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
		positions.append(tile_to_world(cell))
	if wave_visual_controller.has_method("on_spawn_warning"):
		wave_visual_controller.call("on_spawn_warning", positions)


func _get_room_cells(room_center: Vector2i) -> Array[Vector2i]:
	var raw_cells: Variant = room_tiles_by_center.get(room_center, null)
	if raw_cells is Array:
		var typed_cells: Array[Vector2i] = []
		for cell_variant in raw_cells:
			if cell_variant is Vector2i:
				typed_cells.append(cell_variant)
		return typed_cells
	return []


func _update_tutorial_triggers(_delta: float) -> void:
	var tutorial: Node = get_node_or_null("/root/TutorialManager")
	if tutorial == null or not tutorial.get("tutorial_enabled"):
		return
	if player == null:
		return
	var motion_dir: Vector2 = Vector2.ZERO
	if character_controller != null:
		motion_dir = character_controller.get("player_motion_dir")
	if is_moving_to_click or motion_dir.length() > 0.05:
		if not _player_moved_for_tutorial:
			_player_moved_for_tutorial = true
			tutorial.call("notify_trigger", "moved")
	var mouse_dir: Vector2 = get_global_mouse_position() - player.global_position
	if mouse_dir.length() > 24.0:
		tutorial.call("notify_trigger", "aimed")
	if weapon_manager != null:
		var weapon: Node = weapon_manager.get("equipped_weapon")
		if weapon != null and bool(weapon.get("is_charging")):
			tutorial.call("notify_trigger", "charged")
	if not _player_shot_for_tutorial and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_player_shot_for_tutorial = true
		tutorial.call("notify_trigger", "shot")
	var trail: Node = get_node_or_null("/root/ObjectiveTrailManager")
	if trail != null and bool(trail.get("objective_trail_enabled")):
		tutorial.call("notify_trigger", "trail_seen")
