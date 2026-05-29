class_name MirrorAnimationHelper
extends RefCounted

static func resolve_with_mirror(frames: SpriteFrames, requested_animation: String) -> Dictionary:
	var result: Dictionary = {
		"found": false,
		"animation": requested_animation,
		"flip_h": false,
		"mirrored_from": ""
	}
	if frames == null:
		return result
	if frames.has_animation(requested_animation):
		result["found"] = true
		return result

	var mirror_candidate: String = _mirror_name(requested_animation)
	if mirror_candidate != requested_animation and frames.has_animation(mirror_candidate):
		result["found"] = true
		result["animation"] = mirror_candidate
		result["flip_h"] = true
		result["mirrored_from"] = mirror_candidate
		return result

	return result


static func _mirror_name(anim_name: String) -> String:
	if anim_name.ends_with("_right"):
		return anim_name.trim_suffix("_right") + "_left"
	if anim_name.ends_with("_left"):
		return anim_name.trim_suffix("_left") + "_right"
	return anim_name
