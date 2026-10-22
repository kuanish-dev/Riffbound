class_name SampleBank
extends RefCounted
## Сэмплы гитары: щипок на каждый полутон диапазона Tuning и глухой «чк» каждой струны.
## Голос берёт сэмпл своей ноты и тянет высоту только для бенда и легато.

var notes := {}           ## MIDI → AudioStreamWAV
var dead := {}            ## струна → AudioStreamWAV


func build(rng: RandomNumberGenerator) -> void:
	for midi in range(Tuning.MIDI_MIN, Tuning.MIDI_MAX + 1):
		notes[midi] = Synth.to_wav(Synth.pluck_note(Tuning.hz(midi), rng))
	for string: String in Notes.STRINGS:
		dead[string] = Synth.to_wav(Synth.muted_strum(float(Notes.MUTED_HZ[string]), rng))
