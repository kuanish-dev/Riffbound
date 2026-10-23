class_name StyleMeter
extends RefCounted

signal ranked(rank: int, up: bool)

const RANKS := [
	{"id": "D", "name": "Разогрев", "size": 300.0, "drain": 30.0, "coins": 0, "tint": Color(0.62, 0.62, 0.72)},
	{"id": "C", "name": "Неплохо", "size": 380.0, "drain": 45.0, "coins": 1, "tint": Color(0.45, 0.75, 1.0)},
	{"id": "B", "name": "Бодро", "size": 460.0, "drain": 60.0, "coins": 2, "tint": Color(0.35, 1.0, 0.6)},
	{"id": "A", "name": "Агрессивно", "size": 560.0, "drain": 80.0, "coins": 4, "tint": Color(1.0, 0.86, 0.3)},
	{"id": "S", "name": "Свирепо", "size": 680.0, "drain": 100.0, "coins": 6, "tint": Color(1.0, 0.56, 0.18)},
	{"id": "SS", "name": "Сокрушительно", "size": 820.0, "drain": 125.0, "coins": 10, "tint": Color(1.0, 0.27, 0.27)},
	{"id": "SSS", "name": "Сногсшибательный стиль!", "size": 1000.0, "drain": 150.0, "coins": 15,
		"tint": Color(1.0, 0.25, 0.8)},
]
const GAIN := {"perfect": 120.0, "good": 55.0}
const TECH := 100.0
const SUSTAIN := 60.0
const DROP := {"miss": 1.0, "wrong": 0.5}
const VARIETY := 4
const REPEAT := 0.4

var level := 0.0
var best := -1
var _recent: Array[String] = []
var _time := -1.0



static func rank_of(id: String) -> Dictionary:
	for rank: Dictionary in RANKS:
		if rank["id"] == id:
			return rank
	return RANKS[0]

func reset() -> void:
	level = 0.0
	best = -1
	_recent.clear()
	_time = -1.0


func rank() -> int:
	return mini(floori(level), RANKS.size() - 1)


func fill() -> float:
	return clampf(level - rank(), 0.0, 1.0)


func heat() -> float:
	return clampf(level / RANKS.size(), 0.0, 1.0)


func visible() -> bool:
	return best >= 0


func on_fact(kind: String, data: Dictionary) -> void:
	var method := "_on_" + kind
	if has_method(method):
		call(method, data)


func update(time: float) -> void:
	if _time >= 0.0 and time > _time:
		var before := rank()
		var drain := (time - _time) * float(RANKS[before]["drain"])
		while drain > 0.0 and level > 0.0:
			var r := rank()
			var size := float(RANKS[r]["size"])
			var room := (level - r) * size
			if drain > room and r > 0:
				level = r - 0.0001
				drain -= room
			else:
				level = maxf(0.0, level - drain / size)
				drain = 0.0
		if rank() < before:
			ranked.emit(rank(), false)
	_time = time


func result() -> Dictionary:
	if best < 0:
		return {"style": "", "style_coins": 0}
	return {"style": RANKS[best]["id"], "style_coins": RANKS[best]["coins"]}


func _on_hit(data: Dictionary) -> void:
	var note: Dictionary = data["note"]
	var move := "%s:%s:%s" % [note["string"], note["fret"], note.get("tech", "")]
	var gain := float(GAIN.get(data["judgement"]["id"], 0.0)) * (REPEAT if _recent.has(move) else 1.0)
	_recent.append(move)
	if _recent.size() > VARIETY:
		_recent.pop_front()
	_add(gain)


func _on_tech(_data: Dictionary) -> void:
	_add(TECH)


func _on_sustain(data: Dictionary) -> void:
	_add(SUSTAIN * float(data["ratio"]))


func _on_miss(_data: Dictionary) -> void:
	_drop(float(DROP["miss"]))


func _on_wrong(_data: Dictionary) -> void:
	_drop(float(DROP["wrong"]))


func _add(points: float) -> void:
	var before := rank() if best >= 0 else -1
	var top := RANKS.size() - 1
	while points > 0.0:
		var r := rank()
		var size := float(RANKS[r]["size"])
		var room := (r + 1 - level) * size
		if points >= room and r < top:
			level = r + 1
			points -= room
		else:
			level = minf(level + points / size, top + 0.9999)
			points = 0.0
	best = maxi(best, rank())
	if rank() > before:
		ranked.emit(rank(), true)


func _drop(ranks: float) -> void:
	var before := rank()
	level = maxf(0.0, level - ranks)
	_recent.clear()
	if rank() < before:
		ranked.emit(rank(), false)
