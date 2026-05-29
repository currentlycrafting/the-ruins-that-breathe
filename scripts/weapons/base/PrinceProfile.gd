class_name PrinceProfile
extends RefCounted

var character_id: String = "prince"
var display_name: String = "Prince"

var slash_damage: float = 65.0
var slash_range: float = 115.0
var slash_arc: float = 165.0
var slash_cooldown: float = 0.52

var summon_cooldown: float = 45.0
var summon_max_targets: int = 5
var summon_grab_frame: int = 5

var charge_max_time: float = 1.0
var full_charge_hold_limit: float = 3.0
var auto_release_enabled: bool = true

var charge_icon_texture: Texture2D = null
var charge_fill_color: Color = Color(0.82, 0.16, 0.18, 1.0)
var charge_glow_color: Color = Color(1.0, 0.22, 0.22, 1.0)
