class_name SwordWeapon
extends RefCounted

var slash_damage: float = 2.0
var slash_range: float = 72.0
var slash_arc: float = 90.0
var slash_cooldown: float = 0.25
var slash_stamina_cost: float = 18.0
var max_stamina: float = 100.0
var stamina_regen_rate: float = 22.0
var can_combo: bool = true
var combo_step: int = 0

func swing(origin: Vector2, direction: Vector2, mobs: Array[Node2D]) -> Array[Node2D]:
	var hit_map: Dictionary = {}
	var aim: Vector2 = direction.normalized() if direction.length() > 0.001 else Vector2.RIGHT
	var half_arc: float = deg_to_rad(slash_arc * 0.5)
	var sweep_samples: int = 9
	var sample_spread: float = deg_to_rad(14.0)
	for sample_index in range(sweep_samples):
		var sweep_t: float = 0.0 if sweep_samples <= 1 else float(sample_index) / float(sweep_samples - 1)
		var sample_angle: float = lerpf(-half_arc, half_arc, sweep_t)
		var sample_dir: Vector2 = aim.rotated(sample_angle)
		for mob in mobs:
			if mob == null or not is_instance_valid(mob):
				continue
			var to_mob: Vector2 = mob.global_position - origin
			var distance: float = to_mob.length()
			if distance <= 0.001 or distance > slash_range:
				continue
			var mob_dir: Vector2 = to_mob.normalized()
			var angle_delta: float = absf(wrapf(sample_dir.angle_to(mob_dir), -PI, PI))
			if angle_delta > sample_spread:
				continue
			var forward: float = to_mob.dot(aim)
			if forward < -slash_range * 0.12:
				continue
			var lateral: float = absf(to_mob.cross(aim))
			if lateral > slash_range * 1.12 and forward < slash_range * 0.34:
				continue
			hit_map[mob.get_instance_id()] = mob
	var hit_mobs: Array[Node2D] = []
	for mob_id in hit_map.keys():
		hit_mobs.append(hit_map[mob_id])
	if can_combo:
		combo_step = (combo_step + 1) % 3
	return hit_mobs
