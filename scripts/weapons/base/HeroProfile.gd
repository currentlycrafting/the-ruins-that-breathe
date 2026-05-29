class_name HeroProfile
extends RefCounted

var character_id: String = "hero"
var display_name: String = "Hero"

var normal_damage: float = 1.0
var charged_damage: float = 3.0
var normal_cooldown: float = 0.05
var charged_cooldown: float = 3.0
var normal_width: float = 5.0
var charged_width: float = 26.0
var range_value: float = 290.0
var charge_max_time: float = 3.0
var charge_hold_time_multiplier: float = 0.5
var full_charge_hold_limit: float = 3.0
var auto_release_enabled: bool = true

var charge_icon_texture: Texture2D = null
var charge_fill_color: Color = Color(1.0, 0.25, 0.22, 1.0)
var charge_glow_color: Color = Color(1.0, 0.14, 0.14, 1.0)
