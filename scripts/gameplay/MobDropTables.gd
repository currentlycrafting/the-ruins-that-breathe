class_name MobDropTables
extends RefCounted
## Weighted drop tables per mob type. Expand by adding new mob_id entries.

const DROP_SILVER: String = "silver_coin"
const DROP_GOLD: String = "gold_coin"
const DROP_HEART: String = "heart"
const DROP_SLIME: String = "slime_drop"
const DROP_CHARGE: String = "charge_orb"
const DROP_XP: String = "xp_orb"

static func get_entries(mob_id: String) -> Array:
	match mob_id:
		"slime":
			return [
				{"id": DROP_SILVER, "weight": 70},
				{"id": DROP_GOLD, "weight": 15},
				{"id": DROP_HEART, "weight": 10},
				{"id": DROP_SLIME, "weight": 5},
			]
		"strong_slime":
			return [
				{"id": DROP_SILVER, "weight": 60, "count_min": 1, "count_max": 2},
				{"id": DROP_GOLD, "weight": 25},
				{"id": DROP_HEART, "weight": 10},
				{"id": DROP_SLIME, "weight": 5},
			]
		"elite_slime":
			return [
				{"id": DROP_SILVER, "weight": 50, "count_min": 2, "count_max": 4},
				{"id": DROP_GOLD, "weight": 35, "count_min": 1, "count_max": 2},
				{"id": DROP_HEART, "weight": 8},
				{"id": DROP_SLIME, "weight": 7},
			]
		"shellcloak_oracle":
			return [
				{"id": DROP_XP, "weight": 42},
				{"id": DROP_SILVER, "weight": 30},
				{"id": DROP_GOLD, "weight": 10},
				{"id": DROP_HEART, "weight": 8},
				{"id": DROP_SLIME, "weight": 10},
			]
		"petalwretch_ooze":
			return [
				{"id": DROP_XP, "weight": 40},
				{"id": DROP_SILVER, "weight": 28},
				{"id": DROP_GOLD, "weight": 10},
				{"id": DROP_HEART, "weight": 8},
				{"id": DROP_SLIME, "weight": 14},
			]
		"lambent_idol":
			return [
				{"id": DROP_XP, "weight": 40},
				{"id": DROP_SILVER, "weight": 25},
				{"id": DROP_GOLD, "weight": 14},
				{"id": DROP_HEART, "weight": 9},
				{"id": DROP_SLIME, "weight": 12},
			]
		"bellpilgrim_crawler":
			return [
				{"id": DROP_XP, "weight": 42},
				{"id": DROP_SILVER, "weight": 24},
				{"id": DROP_GOLD, "weight": 12},
				{"id": DROP_HEART, "weight": 8},
				{"id": DROP_SLIME, "weight": 14},
			]
		"rootbound_acolyte":
			return [
				{"id": DROP_XP, "weight": 44},
				{"id": DROP_SILVER, "weight": 23},
				{"id": DROP_GOLD, "weight": 12},
				{"id": DROP_HEART, "weight": 8},
				{"id": DROP_SLIME, "weight": 13},
			]
		"bloommaw_lurker":
			return [
				{"id": DROP_XP, "weight": 36, "count_min": 1, "count_max": 2},
				{"id": DROP_SILVER, "weight": 24, "count_min": 1, "count_max": 2},
				{"id": DROP_GOLD, "weight": 18, "count_min": 1, "count_max": 2},
				{"id": DROP_HEART, "weight": 10},
				{"id": DROP_SLIME, "weight": 12},
			]
		"mothcloak_priest":
			return [
				{"id": DROP_XP, "weight": 46},
				{"id": DROP_SILVER, "weight": 22},
				{"id": DROP_GOLD, "weight": 14},
				{"id": DROP_HEART, "weight": 7},
				{"id": DROP_SLIME, "weight": 11},
			]
		"multieye_cherub":
			return [
				{"id": DROP_XP, "weight": 34, "count_min": 1, "count_max": 3},
				{"id": DROP_SILVER, "weight": 22, "count_min": 2, "count_max": 3},
				{"id": DROP_GOLD, "weight": 22, "count_min": 1, "count_max": 2},
				{"id": DROP_HEART, "weight": 10},
				{"id": DROP_SLIME, "weight": 12},
			]
		_:
			return [{"id": DROP_SILVER, "weight": 80}]


static func roll_drop(mob_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var entries: Array = get_entries(mob_id)
	if entries.is_empty():
		return {}
	var total: int = 0
	for entry in entries:
		total += int(entry.get("weight", 0))
	if total <= 0:
		return {}
	var roll: int = rng.randi_range(1, total)
	var acc: int = 0
	for entry in entries:
		acc += int(entry.get("weight", 0))
		if roll <= acc:
			var count_min: int = int(entry.get("count_min", 1))
			var count_max: int = int(entry.get("count_max", count_min))
			var count: int = rng.randi_range(count_min, maxi(count_min, count_max))
			return {"id": String(entry.get("id", DROP_SILVER)), "count": count}
	return {}
