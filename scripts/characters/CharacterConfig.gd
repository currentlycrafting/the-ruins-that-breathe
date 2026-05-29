class_name CharacterConfig
extends Resource

@export var character_id: String = "classic"
@export var display_name: String = "Classic"
@export var walking_animation_resource: SpriteFrames = null
@export var shooting_animation_resource: SpriteFrames = null
@export var attack_type: String = "weapon"
@export var basic_cooldown: float = 0.25
@export var charged_cooldown: float = 1.0
@export var charge_attack_enabled: bool = true
@export var special_ability_enabled: bool = false
