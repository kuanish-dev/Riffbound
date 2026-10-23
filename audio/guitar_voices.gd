class_name GuitarVoices
extends Node

const LEAD_BUS := "Lead"
const TAIL_FX := [{"type": "AudioEffectHardLimiter", "ceiling_db": -1.0}]

var strings := {}


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
