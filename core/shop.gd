class_name Shop

const FILE := "user://shop.json"
const COINS_PER_STAR := 10
const SCORE_PER_COIN := 1000
const FIRST := "classic"
const SKINS := [
	{"id": "classic", "name": "Классика", "price": 0, "shape": "strat", "pickups": "sss",
		"body": Color(0.95, 0.62, 0.18), "edge": Color(0.12, 0.05, 0.03), "rings": 7, "guard": Color(0.96, 0.94, 0.88),
		"hardware": Color(0.85, 0.86, 0.9), "cover": Color(0.95, 0.93, 0.86), "board": Color(0.24, 0.13, 0.08),
		"neck": Color(0.83, 0.62, 0.36), "inlay": Color(0.95, 0.93, 0.86),
		"tone": {"name": "кранч", "fx": []}},
	{"id": "midnight", "name": "Полночь", "price": 60, "shape": "strat", "pickups": "sss",
		"body": Color(0.07, 0.07, 0.09), "stripes": 2, "guard": Color(0.95, 0.95, 0.95),
		"hardware": Color(0.85, 0.86, 0.9), "cover": Color(0.95, 0.95, 0.93), "board": Color(0.9, 0.76, 0.5),
		"neck": Color(0.9, 0.76, 0.5), "inlay": Color(0.1, 0.1, 0.1),
		"tone": {"name": "блюз", "fx": [
			{"type": "AudioEffectLowPassFilter", "cutoff_hz": 3800.0, "resonance": 0.6},
			{"type": "AudioEffectReverb", "room_size": 0.35, "damping": 0.6, "wet": 0.16, "dry": 1.0}]}},
	{"id": "cherry", "name": "Вишня", "price": 100, "shape": "sg", "pickups": "hh",
		"body": Color(0.62, 0.05, 0.08), "stripes": 2, "guard": Color(0.08, 0.08, 0.08),
		"hardware": Color(0.85, 0.86, 0.9), "cover": Color(0.85, 0.86, 0.9), "board": Color(0.2, 0.11, 0.07),
		"neck": Color(0.5, 0.05, 0.07), "inlay": Color(0.95, 0.93, 0.86),
		"tone": {"name": "хард-рок", "fx": [
			{"type": "AudioEffectDistortion", "mode": 3, "drive": 0.35, "post_gain": -2.5},
			{"type": "AudioEffectEQ6", "band_db/100_hz": -2.0, "band_db/1000_hz": 3.0},
			{"type": "AudioEffectDelay", "tap1_delay_ms": 110.0, "tap1_level_db": -12.0, "tap2_active": false,
				"feedback_active": false}]}},
	{"id": "goldtop", "name": "Голдтоп", "price": 150, "shape": "lp", "pickups": "hh",
		"body": Color(0.86, 0.7, 0.32), "stripes": 3, "guard": Color(0.95, 0.88, 0.7),
		"hardware": Color(0.95, 0.8, 0.4), "cover": Color(0.95, 0.88, 0.7), "board": Color(0.2, 0.11, 0.07),
		"neck": Color(0.45, 0.25, 0.12), "inlay": Color(0.95, 0.9, 0.75), "head": Color(0.1, 0.08, 0.08),
		"tone": {"name": "жирный лид", "fx": [
			{"type": "AudioEffectDistortion", "mode": 1, "drive": 0.3, "post_gain": 9.0},
			{"type": "AudioEffectLowPassFilter", "cutoff_hz": 3200.0, "resonance": 0.5},
			{"type": "AudioEffectDelay", "tap1_delay_ms": 380.0, "tap1_level_db": -14.0, "tap2_active": false,
				"feedback_active": true, "feedback_delay_ms": 380.0, "feedback_level_db": -18.0},
			{"type": "AudioEffectReverb", "room_size": 0.5, "wet": 0.12, "dry": 1.0}]}},
	{"id": "ocean", "name": "Океан", "price": 200, "shape": "super", "pickups": "hsh",
		"body": Color(0.08, 0.35, 0.75), "stripes": 3,
		"hardware": Color(0.12, 0.12, 0.14), "cover": Color(0.1, 0.1, 0.12), "board": Color(0.16, 0.1, 0.07),
		"neck": Color(0.8, 0.6, 0.38), "inlay": Color(0.4, 0.85, 1.0), "head": Color(0.08, 0.35, 0.75),
		"tone": {"name": "шред", "fx": [
			{"type": "AudioEffectDistortion", "mode": 3, "drive": 0.55, "post_gain": -1.0},
			{"type": "AudioEffectEQ6", "band_db/320_hz": -3.0, "band_db/3200_hz": 2.0},
			{"type": "AudioEffectDelay", "tap1_delay_ms": 300.0, "tap1_level_db": -12.0, "tap1_pan": -0.4,
				"tap2_delay_ms": 600.0, "tap2_level_db": -16.0, "tap2_pan": 0.4, "feedback_active": false},
			{"type": "AudioEffectReverb", "room_size": 0.45, "wet": 0.14, "dry": 1.0}]}},
	{"id": "arrow", "name": "Стрела", "price": 250, "shape": "v", "pickups": "hh",
		"body": Color(0.94, 0.94, 0.93), "guard": Color(0.08, 0.08, 0.08),
		"hardware": Color(0.85, 0.86, 0.9), "cover": Color(0.85, 0.86, 0.9), "board": Color(0.2, 0.11, 0.07),
		"neck": Color(0.93, 0.93, 0.92), "inlay": Color(0.95, 0.93, 0.86),
		"tone": {"name": "метал", "fx": [
			{"type": "AudioEffectHighPassFilter", "cutoff_hz": 140.0},
			{"type": "AudioEffectDistortion", "mode": 4, "drive": 0.65, "post_gain": -8.0},
			{"type": "AudioEffectEQ6", "band_db/320_hz": -4.0, "band_db/3200_hz": 3.0},
			{"type": "AudioEffectCompressor", "threshold": -18.0, "ratio": 4.0},
			{"type": "AudioEffectAmplify", "volume_db": 11.0}]}},
	{"id": "lava", "name": "Лава", "price": 300, "shape": "explorer", "pickups": "hh",
		"body": Color(1.0, 0.72, 0.1), "edge": Color(0.45, 0.02, 0.0), "rings": 6, "guard": Color(0.08, 0.08, 0.08),
		"hardware": Color(0.12, 0.12, 0.14), "cover": Color(0.1, 0.1, 0.12), "board": Color(0.16, 0.1, 0.07),
		"neck": Color(0.45, 0.06, 0.02), "inlay": Color(1.0, 0.6, 0.1),
		"tone": {"name": "фузз", "fx": [
			{"type": "AudioEffectDistortion", "mode": 0, "pre_gain": 12.0, "drive": 0.7, "post_gain": -14.0},
			{"type": "AudioEffectLowPassFilter", "cutoff_hz": 2600.0, "resonance": 0.8}]}},
	{"id": "neon", "name": "Неон", "price": 400, "shape": "super", "pickups": "hh",
		"body": Color(0.05, 0.05, 0.08), "edge": Color(0.2, 1.0, 0.95), "neon": true,
		"hardware": Color(0.12, 0.12, 0.14), "cover": Color(0.08, 0.08, 0.1), "board": Color(0.08, 0.06, 0.06),
		"neck": Color(0.06, 0.06, 0.08), "inlay": Color(0.2, 1.0, 0.95), "head": Color(0.05, 0.05, 0.08),
		"tone": {"name": "синтвейв", "fx": [
			{"type": "AudioEffectChorus", "voice_count": 2, "wet": 0.6, "dry": 1.0},
			{"type": "AudioEffectDelay", "tap1_delay_ms": 330.0, "tap1_level_db": -10.0, "tap2_active": false,
				"feedback_active": true, "feedback_delay_ms": 330.0, "feedback_level_db": -10.0, "feedback_lowpass": 3000.0},
			{"type": "AudioEffectReverb", "room_size": 0.8, "damping": 0.4, "wet": 0.25, "dry": 1.0},
			{"type": "AudioEffectAmplify", "volume_db": -4.5}]}},
	{"id": "galaxy", "name": "Галактика", "price": 500, "shape": "lp", "pickups": "hh",
		"body": Color(0.32, 0.1, 0.55), "edge": Color(0.06, 0.02, 0.14), "rings": 5, "sparkle": 90,
		"guard": Color(0.08, 0.08, 0.08), "hardware": Color(0.85, 0.86, 0.9), "cover": Color(0.85, 0.86, 0.9),
		"board": Color(0.1, 0.07, 0.07), "neck": Color(0.2, 0.06, 0.32), "inlay": Color(0.8, 0.7, 1.0),
		"head": Color(0.2, 0.06, 0.32),
		"tone": {"name": "космос", "fx": [
			{"type": "AudioEffectPhaser", "rate_hz": 0.4, "depth": 0.8, "feedback": 0.6},
			{"type": "AudioEffectDelay", "tap1_delay_ms": 500.0, "tap1_level_db": -10.0, "tap2_active": false,
				"feedback_active": true, "feedback_delay_ms": 500.0, "feedback_level_db": -8.0},
			{"type": "AudioEffectReverb", "room_size": 0.95, "wet": 0.35, "dry": 0.9},
			{"type": "AudioEffectAmplify", "volume_db": -10.0}]}},
	{"id": "chrome", "name": "Хром", "price": 700, "shape": "v", "pickups": "hh",
		"body": Color(0.72, 0.75, 0.8), "edge": Color(0.32, 0.34, 0.4), "rings": 4, "stripes": 4,
		"hardware": Color(0.12, 0.12, 0.14), "cover": Color(0.1, 0.1, 0.12), "board": Color(0.1, 0.07, 0.07),
		"neck": Color(0.6, 0.62, 0.68), "inlay": Color(0.95, 0.95, 1.0),
		"tone": {"name": "индастриал", "fx": [
			{"type": "AudioEffectDistortion", "mode": 2, "pre_gain": 6.0, "drive": 0.5, "post_gain": 1.0},
			{"type": "AudioEffectBandPassFilter", "cutoff_hz": 1400.0, "resonance": 1.2},
			{"type": "AudioEffectDelay", "tap1_delay_ms": 40.0, "tap1_level_db": -8.0, "tap2_active": false,
				"feedback_active": false}]}},
]

static var coins := 0
static var owned: Array[String] = [FIRST]
static var equipped := FIRST


static func skin(id: String) -> Dictionary:
	for item: Dictionary in SKINS:
		if item["id"] == id:
			return item
	return SKINS[0]


static func current() -> Dictionary:
	return skin(equipped)


static func reward(result: Dictionary, scale := 1.0) -> int:
	var earned := roundi(coins_for(result) * scale)
	coins += earned
	_save()
	return earned


static func coins_for(result: Dictionary) -> int:
	@warning_ignore("integer_division")
	return int(result.get("stars", 0)) * COINS_PER_STAR + int(result.get("score", 0)) / SCORE_PER_COIN \
		+ int(result.get("style_coins", 0))


static func buy(id: String) -> bool:
	var price := int(skin(id)["price"])
	if owned.has(id) or coins < price:
		return false
	coins -= price
	owned.append(id)
	_save()
	return true


static func equip(id: String) -> bool:
	if not owned.has(id):
		return false
	equipped = id
	_save()
	return true


static func reset() -> void:
	coins = 0
	owned.assign([FIRST])
	equipped = FIRST


static func load_saved() -> void:
	load_data(Songs.load_json(FILE))


static func load_data(data: Variant) -> void:
	reset()
	if not data is Dictionary:
		for song: Dictionary in Songs.all():
			coins += coins_for(Songs.best(String(song["id"])))
		return
	coins = int(data.get("coins", 0))
	for id: Variant in data.get("owned", []):
		if String(id) != FIRST and skin(String(id))["id"] == String(id):
			owned.append(String(id))
	var wanted := String(data.get("equipped", FIRST))
	equipped = wanted if owned.has(wanted) else FIRST


static func _save() -> void:
	Songs.save_json(FILE, {"coins": coins, "owned": owned, "equipped": equipped})
