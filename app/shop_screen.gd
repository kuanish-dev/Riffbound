class_name ShopScreen
extends RefCounted

const LICK := [
	{"t": 0.0, "kind": "pluck", "string": "low", "midis": [52]},
	{"t": 0.2, "kind": "pluck", "string": "low", "midis": [55]},
	{"t": 0.4, "kind": "slur", "string": "low", "midis": [57]},
	{"t": 0.65, "kind": "pluck", "string": "mid", "midis": [59]},
	{"t": 0.85, "kind": "pluck", "string": "mid", "midis": [62]},
	{"t": 1.05, "kind": "bend", "string": "mid", "amount": 1.0},
	{"t": 1.55, "kind": "bend", "string": "mid", "amount": 0.0},
	{"t": 1.75, "kind": "pluck", "string": "high", "midis": [64]},
	{"t": 2.4, "kind": "mute", "string": "high"},
	{"t": 2.55, "kind": "pluck", "string": "low", "midis": [40, 47]},
	{"t": 3.4, "kind": "mute", "string": "low"},
]

var _main: Main
var _tone := ""
var _lick_from := -1.0
var _lick_next := 0


func _init(main: Main) -> void:
	_main = main


func open() -> void:
	Game.state = "shop"
	Game.shop_index = _equipped_index()
	TouchLists.reveal("shop")


func up() -> void:
	Game.shop_index = posmod(Game.shop_index - 1, Shop.SKINS.size())


func down() -> void:
	Game.shop_index = posmod(Game.shop_index + 1, Shop.SKINS.size())


func take() -> void:
	var skin: Dictionary = Shop.SKINS[Game.shop_index]
	var id := String(skin["id"])
	if Shop.owned.has(id):
		Shop.equip(id)
		_main.feedback.say("equip", "Надета «%s»" % skin["name"])
	elif Shop.buy(id):
		Shop.equip(id)
		_main.feedback.say("buy", "Куплена «%s» за %d монет — уже в руках" % [skin["name"], skin["price"]])
	else:
		var missing := int(skin["price"]) - Shop.coins
		_main.feedback.say("deny", "Не хватает %d монет — сыграй песню: %d за звезду" % [missing, Shop.COINS_PER_STAR])


func listen() -> void:
	Game.voices.silence()
	_lick_from = _clock()
	_lick_next = 0


func stop_listening() -> void:
	_lick_from = -1.0


func tick() -> void:
	_sync_tone()
	_play_lick()


func _sync_tone() -> void:
	var skin: Dictionary = Shop.SKINS[Game.shop_index] if Game.state == "shop" else Shop.current()
	if skin["id"] != _tone:
		_tone = String(skin["id"])
		GuitarVoices.set_tone(skin["tone"]["fx"])


func _play_lick() -> void:
	if _lick_from < 0.0:
		return
	var elapsed := _clock() - _lick_from
	while _lick_next < LICK.size() and elapsed >= float(LICK[_lick_next]["t"]):
		Game.voices.play(LICK[_lick_next])
		_lick_next += 1
	if _lick_next >= LICK.size():
		stop_listening()


static func _equipped_index() -> int:
	for i in Shop.SKINS.size():
		if Shop.SKINS[i]["id"] == Shop.equipped:
			return i
	return 0


static func _clock() -> float:
	return Time.get_ticks_msec() / 1000.0
