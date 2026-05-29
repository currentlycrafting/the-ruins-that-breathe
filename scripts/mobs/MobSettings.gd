class_name MobSettings
extends Resource

@export var mobs_enabled: bool = true
@export var spawn_on_level_start: bool = true
@export_range(0, 64, 1) var global_mob_cap: int = 8
@export_range(0, 24, 1) var slime_spawn_count: int = 3
@export_range(2.0, 80.0, 0.5) var slime_spawn_min_distance_from_player: float = 14.0
@export_range(8.0, 120.0, 0.5) var slime_spawn_max_distance_from_player: float = 36.0
