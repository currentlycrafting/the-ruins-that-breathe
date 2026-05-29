class_name TwinsProfile
extends RefCounted

var character_id: String = "stack"
var display_name: String = "Stack"

var smoke_damage: float = 1.0
var smoke_interval: float = 0.35
var smoke_range: float = 390.0
var smoke_charged_range: float = 495.0
var stack_damage: float = 3.0
var stack_windup: float = 0.45
var stack_interval: float = 1.1
var stack_spread_angle: float = 45.0
var stack_range: float = 420.0

var charged_duration: float = 3.0
var charged_cooldown: float = 6.0
var charged_smoke_interval: float = 0.15
var charged_stack_interval: float = 0.55

var charge_max_time: float = 0.8
var full_charge_hold_limit: float = 3.0
var auto_release_enabled: bool = true

var charge_icon_texture: Texture2D = null
var charge_fill_color: Color = Color(0.92, 0.78, 0.36, 1.0)
var charge_glow_color: Color = Color(1.0, 0.66, 0.26, 1.0)
