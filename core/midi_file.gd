class_name MidiFile
## Стандартный MIDI-файл (SMF, формат 1) из слоёв лупера: дорожка темпа и по дорожке на слой.
## Струна — свой канал (порядок Notes.STRINGS), чтобы бенд одной струны не тянул остальные;
## в начале каждого канала диапазон бенда ставится в Tuning.BEND_SEMITONES.

const PPQ := 480
const VELOCITY := 96


static func save(path: String, layers: Array) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(build(layers))
	return OK


static func build(layers: Array) -> PackedByteArray:
	var out := PackedByteArray()
	out.append_array("MThd".to_ascii_buffer())
	out.append_array(_u32(6))
	out.append_array(_u16(1))
	out.append_array(_u16(layers.size() + 1))
	out.append_array(_u16(PPQ))
	out.append_array(_track(_tempo_events()))
	for layer: Array in layers:
		out.append_array(_track(_layer_events(layer)))
	return out


## Число переменной длины (VLQ): по 7 бит, старший бит — «дальше есть ещё».
static func vlq(value: int) -> PackedByteArray:
	var bytes := PackedByteArray([value & 0x7F])
	value >>= 7
	while value > 0:
		bytes.insert(0, (value & 0x7F) | 0x80)
		value >>= 7
	return bytes


static func ticks(seconds: float) -> int:
	return roundi(seconds / Timing.BEAT_LEN * PPQ)


## Темп и размер 4/4.
static func _tempo_events() -> Array:
	var tempo := roundi(Timing.BEAT_LEN * 1000000.0)
	return [
		[0, 0, PackedByteArray([0xFF, 0x51, 0x03, (tempo >> 16) & 0xFF, (tempo >> 8) & 0xFF, tempo & 0xFF])],
		[0, 0, PackedByteArray([0xFF, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08])],
	]


## События слоя → [тик, порядок, байты]. Порядок в одном тике: настройки, снятие нот, бенд, новые ноты.
static func _layer_events(layer: Array) -> Array:
	var events: Array = []
	var sounding := {}                      ## канал → звучащие ноты
	for channel in Notes.STRINGS.size():
		for cc: Array in [[101, 0], [100, 0], [6, int(Tuning.BEND_SEMITONES)], [38, 0]]:
			events.append([0, 0, PackedByteArray([0xB0 | channel, cc[0], cc[1]])])
		sounding[channel] = []
	for event: Dictionary in layer:
		var channel := Notes.STRINGS.find(String(event["string"]))
		var at := ticks(float(event["t"]))
		var kind := String(event["kind"])
		if kind == "bend":
			var value := clampi(8192 + roundi(float(event["amount"]) * 8191.0), 0, 16383)
			events.append([at, 2, PackedByteArray([0xE0 | channel, value & 0x7F, (value >> 7) & 0x7F])])
			continue
		for midi: int in sounding[channel]:
			events.append([at, 1, PackedByteArray([0x80 | channel, midi, 0])])
		sounding[channel] = []
		for midi: int in event.get("midis", []):
			if kind != "mute":
				events.append([at, 3, PackedByteArray([0x90 | channel, midi, VELOCITY])])
				sounding[channel].append(midi)
	var end := ticks(Synth.loop_seconds())
	for channel: int in sounding:
		for midi: int in sounding[channel]:
			events.append([end, 1, PackedByteArray([0x80 | channel, midi, 0])])
	return events


static func _track(events: Array) -> PackedByteArray:
	events.sort_custom(_earlier)
	var body := PackedByteArray()
	var last := 0
	for event: Array in events:
		body.append_array(vlq(int(event[0]) - last))
		body.append_array(event[2])
		last = int(event[0])
	body.append_array(vlq(0))
	body.append_array(PackedByteArray([0xFF, 0x2F, 0x00]))
	var out := "MTrk".to_ascii_buffer()
	out.append_array(_u32(body.size()))
	out.append_array(body)
	return out


static func _earlier(a: Array, b: Array) -> bool:
	return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1])


static func _u32(value: int) -> PackedByteArray:
	return PackedByteArray([(value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF])


static func _u16(value: int) -> PackedByteArray:
	return PackedByteArray([(value >> 8) & 0xFF, value & 0xFF])
