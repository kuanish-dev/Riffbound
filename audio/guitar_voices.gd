class_name GuitarVoices
extends Node
## Голос гитары: по StringVoice на струну. Свой у живого игрока и у каждого слоя лупера.
## Событие гитары {kind, string, midis, amount} уходит голосу струны методом kind
## (pluck, slur, mute, dead, bend). Все голоса звучат через шину LEAD_BUS; её эффекты — звук гитары
## из магазина (set_tone, «fx» скина Shop.SKINS), после них всегда TAIL_FX.

const LEAD_BUS := "Lead"
## Эффект — {type: класс эффекта, остальное — его свойства}, например {"type": "AudioEffectDelay",
## "tap1_delay_ms": 450.0}. TAIL_FX — после звука любой гитары: лимитер, чтобы громкие звуки не хрипели.
const TAIL_FX := [{"type": "AudioEffectHardLimiter", "ceiling_db": -1.0}]

var strings := {}         ## струна → StringVoice


func setup(bank: SampleBank) -> void:
	var silent := DisplayServer.get_name() == "headless"
	if not silent:
		_make_lead_bus()
	for string: String in Notes.STRINGS:
		var voice := StringVoice.new()
		voice.bank = bank
		voice.silent = silent
		add_child(voice)
		strings[string] = voice


func play(event: Dictionary) -> void:
	strings[event["string"]].call(String(event["kind"]), event)


func silence() -> void:
	for string: String in strings:
		(strings[string] as StringVoice).silence()


## Звук гитары: эффекты шины заново — fx по порядку, затем TAIL_FX. Без шины (headless) — ничего.
static func set_tone(fx: Array) -> void:
	var bus := AudioServer.get_bus_index(LEAD_BUS)
	if bus == -1:
		return
	while AudioServer.get_bus_effect_count(bus) > 0:
		AudioServer.remove_bus_effect(bus, 0)
	for spec: Dictionary in fx + TAIL_FX:
		AudioServer.add_bus_effect(bus, make_effect(spec))


static func make_effect(spec: Dictionary) -> AudioEffect:
	var effect: AudioEffect = ClassDB.instantiate(String(spec["type"]))
	for property: String in spec:
		if property != "type":
			effect.set(property, spec[property])
	return effect


static func _make_lead_bus() -> void:
	if AudioServer.get_bus_index(LEAD_BUS) != -1:
		return
	AudioServer.add_bus()
	var bus := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus, LEAD_BUS)
	AudioServer.set_bus_send(bus, "Master")
