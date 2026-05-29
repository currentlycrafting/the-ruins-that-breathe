class_name ChargeIconIndicator
extends Control

enum ChargeIconState {
	HIDDEN,
	READY,
	COOLDOWN,
	CHARGING,
	FULLY_CHARGED,
	AUTO_RELEASING
}

var state: ChargeIconState = ChargeIconState.HIDDEN
var icon_texture: Texture2D = null
var charge_percent: float = 0.0
var cooldown_percent: float = 0.0
var shake_amount: float = 3.0
var pulse_scale: float = 1.12
var pulse_speed: float = 5.0
var glow_strength: float = 1.5
var hold_urgency: float = 0.0
var fill_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var glow_color: Color = Color(1.0, 0.2, 0.2, 1.0)

var icon_rect: TextureRect = null
var glow_icon: TextureRect = null
var cooldown_overlay: ColorRect = null
var cooldown_text: Label = null
var anchor_position: Vector2 = Vector2.ZERO
var shake_offset: Vector2 = Vector2.ZERO
var time_accum: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(72.0, 72.0)
	_build()
	visible = false
	set_process(true)


func _build() -> void:
	glow_icon = TextureRect.new()
	glow_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow_icon.modulate = Color(glow_color.r, glow_color.g, glow_color.b, 0.0)
	add_child(glow_icon)

	icon_rect = TextureRect.new()
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.material = _make_fill_shader_material()
	add_child(icon_rect)

	cooldown_overlay = ColorRect.new()
	cooldown_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	cooldown_overlay.color = Color(0.04, 0.04, 0.04, 0.66)
	cooldown_overlay.visible = false
	add_child(cooldown_overlay)

	cooldown_text = Label.new()
	cooldown_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	cooldown_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_text.add_theme_font_size_override("font_size", 18)
	cooldown_text.visible = false
	add_child(cooldown_text)


func set_icon(texture: Texture2D) -> void:
	icon_texture = texture
	if icon_rect != null:
		icon_rect.texture = icon_texture
	if glow_icon != null:
		glow_icon.texture = icon_texture


func set_charge_percent(percent: float) -> void:
	charge_percent = clampf(percent, 0.0, 1.0)
	if icon_rect != null and icon_rect.material is ShaderMaterial:
		(icon_rect.material as ShaderMaterial).set_shader_parameter("fill_ratio", charge_percent)
		(icon_rect.material as ShaderMaterial).set_shader_parameter("crack_strength", 0.0)


func set_fully_charged(is_ready: bool) -> void:
	state = ChargeIconState.FULLY_CHARGED if is_ready else ChargeIconState.CHARGING
	if is_ready:
		hold_urgency = 1.0


func set_screen_anchor(screen_pos: Vector2) -> void:
	anchor_position = screen_pos
	position = anchor_position + shake_offset


func set_fill_and_glow_colors(new_fill: Color, new_glow: Color) -> void:
	fill_color = new_fill
	glow_color = new_glow


func start_charge() -> void:
	state = ChargeIconState.CHARGING
	visible = true
	hold_urgency = 0.0
	set_charge_percent(0.0)


func show_ready() -> void:
	state = ChargeIconState.READY
	visible = true
	set_charge_percent(0.0)
	hold_urgency = 0.0


func show_cooldown(cooldown_left_seconds: float, cooldown_ratio: float) -> void:
	state = ChargeIconState.COOLDOWN
	visible = true
	cooldown_percent = clampf(cooldown_ratio, 0.0, 1.0)
	if cooldown_overlay != null:
		cooldown_overlay.visible = true
		cooldown_overlay.color.a = lerpf(0.75, 0.35, cooldown_percent)
	if cooldown_text != null:
		cooldown_text.visible = true
		cooldown_text.text = str(ceili(cooldown_left_seconds))
	set_charge_percent(0.0)


func set_auto_releasing() -> void:
	state = ChargeIconState.AUTO_RELEASING


func set_hold_urgency(urgency: float) -> void:
	hold_urgency = clampf(urgency, 0.0, 1.0)


func cancel_charge() -> void:
	state = ChargeIconState.HIDDEN
	visible = false
	set_charge_percent(0.0)
	hold_urgency = 0.0


func release_charge() -> void:
	state = ChargeIconState.READY
	visible = true
	set_charge_percent(0.0)
	hold_urgency = 0.0


func _process(delta: float) -> void:
	time_accum += delta
	if not visible:
		return
	if cooldown_overlay != null:
		cooldown_overlay.visible = state == ChargeIconState.COOLDOWN
	if cooldown_text != null:
		cooldown_text.visible = state == ChargeIconState.COOLDOWN
	if state == ChargeIconState.COOLDOWN:
		_apply_scale_and_shake(Vector2.ONE, 0.0)
		_apply_glow(0.0)
		_apply_crack(0.0)
		return

	var is_charged_state: bool = state == ChargeIconState.FULLY_CHARGED or state == ChargeIconState.AUTO_RELEASING
	if not is_charged_state:
		_apply_scale_and_shake(Vector2.ONE, 0.0)
		_apply_glow(0.0)
		_apply_crack(0.0)
		return

	var pulse: float = 1.0 + (pulse_scale - 1.0) * (0.5 + 0.5 * sin(time_accum * pulse_speed * (1.0 + hold_urgency * 1.75)))
	var shake: float = shake_amount * (0.85 + hold_urgency * 2.2)
	_apply_scale_and_shake(Vector2.ONE * pulse, shake)
	_apply_glow(glow_strength * (0.65 + hold_urgency * 0.9))
	if state == ChargeIconState.AUTO_RELEASING:
		_apply_crack(clampf(hold_urgency * 1.2, 0.0, 1.0))
	else:
		_apply_crack(0.0)


func _apply_scale_and_shake(scale_value: Vector2, shake_strength: float) -> void:
	scale = scale_value
	if shake_strength <= 0.01:
		shake_offset = Vector2.ZERO
	else:
		shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	position = anchor_position + shake_offset


func _apply_glow(alpha_scale: float) -> void:
	if glow_icon == null:
		return
	glow_icon.modulate = Color(glow_color.r, glow_color.g, glow_color.b, clampf(alpha_scale * 0.6, 0.0, 1.0))


func _apply_crack(strength: float) -> void:
	if icon_rect == null or not (icon_rect.material is ShaderMaterial):
		return
	(icon_rect.material as ShaderMaterial).set_shader_parameter("crack_strength", clampf(strength, 0.0, 1.0))


func _make_fill_shader_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float fill_ratio : hint_range(0.0, 1.0) = 0.0;
uniform vec4 dark_color : source_color = vec4(0.02, 0.02, 0.02, 0.96);
uniform float crack_strength : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a <= 0.001) {
		COLOR = vec4(0.0);
		return;
	}
	float threshold = 1.0 - fill_ratio;
	float crack_noise = fract(sin(dot(UV * 123.7, vec2(12.9898, 78.233)) + TIME * 8.0) * 43758.5453);
	float crack_cut = step(1.0 - crack_strength * 0.55, crack_noise);
	if (UV.y >= threshold) {
		COLOR = vec4(tex.rgb, tex.a * (1.0 - crack_cut * 0.55));
	} else {
		COLOR = vec4(dark_color.rgb, tex.a * dark_color.a * (1.0 - crack_cut * 0.65));
	}
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("fill_ratio", 0.0)
	mat.set_shader_parameter("crack_strength", 0.0)
	return mat
