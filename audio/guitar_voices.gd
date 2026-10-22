class_name GuitarVoices
extends Node
## Голос гитары: по StringVoice на струну. Свой у живого игрока и у каждого слоя лупера.
## Событие гитары {kind, string, midis, amount} уходит голосу струны методом kind
## (pluck, slur, mute, dead, bend). Звучит через шину LEAD_BUS; эффекты шины — LEAD_FX.

const LEAD_BUS := "Lead"
## Эффекты шины по порядку: type — класс эффекта, остальное — его свойства,
## например {"type": "AudioEffectDelay", "tap1_delay_ms": 450.0}.
const LEAD_FX := []

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


static func _make_lead_bus() -> void:
	if AudioServer.get_bus_index(LEAD_BUS) != -1:
		return
	AudioServer.add_bus()
	var bus := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus, LEAD_BUS)
	AudioServer.set_bus_send(bus, "Master")
	for fx: Dictionary in LEAD_FX:
		var effect: AudioEffect = ClassDB.instantiate(String(fx["type"]))
		for property: String in fx:
			if property != "type":
				effect.set(property, fx[property])
		AudioServer.add_bus_effect(bus, effect)
