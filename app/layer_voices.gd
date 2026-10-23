class_name LayerVoices
extends Node

var _bank: SampleBank
var _voices: Array[GuitarVoices] = []


func setup(bank: SampleBank) -> void:
	_bank = bank


func sync(count: int) -> void:
	while _voices.size() < count:
		_add_voice()
	while _voices.size() > count:
		_remove_voice()


func play(due: Array[Dictionary]) -> void:
	for item: Dictionary in due:
		_voices[int(item["layer"])].play(item["event"])


func _add_voice() -> void:
	var voice := GuitarVoices.new()
	add_child(voice)
	voice.setup(_bank)
	_voices.append(voice)


func _remove_voice() -> void:
	var voice: GuitarVoices = _voices.pop_back()
	voice.silence()
	voice.queue_free()
