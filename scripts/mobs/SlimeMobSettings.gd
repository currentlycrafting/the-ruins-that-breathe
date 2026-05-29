class_name SlimeMobSettings
extends Resource

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
