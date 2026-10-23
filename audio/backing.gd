class_name Backing
## Подложка из настоящих сэмплов (assets/drums, assets/bass — CC0, см. CREDITS.md): игра сама сводит
## барабаны и бас в луп на Looper.BARS тактов в темпе Timing.bpm и тональности строя.
## Стиль (STYLES) — какие такты в каком порядке («order»), такт — партии инструментов (PARTS) строкой
## из восьми восьмых: «.» — тишина, буква — удар, заглавная — с акцентом. У баса буква — нота аккорда
## (BASS_NOTES); аккорд такта — ступень PROGRESSIONS (минор: i–i–VI–VII, как E–E–C–D; мажор: I–I–IV–V),
## поэтому ноты гаммы гитары ложатся в гармонию. swing — на сколько восьмой сдвинуть слабые восьмые (шаффл).
## Метроном (metronome) — отдельный луп в такт из щелчков, собранных кодом: Conductor играет его поверх
## любой подложки.

const RATE := 44100
const DRUM_DIR := "res://assets/drums/"
const BASS_DIR := "res://assets/bass/"
## Инструмент: сэмплы (по кругу, чтобы удары не звучали одинаково) или высота (бас) и громкость.
const PARTS := {
	"kick": {"samples": ["kick_1", "kick_2"], "gain": 1.0},
	"snare": {"samples": ["snare_1", "snare_2"], "gain": 0.8},
	"hat": {"samples": ["hat_1", "hat_2"], "gain": 0.32},
	"open": {"samples": ["hat_open"], "gain": 0.3},
	"crash": {"samples": ["crash"], "gain": 0.42},
	"bass": {"gain": 0.75},
}
const SOFT := 0.6                    ## строчная буква — тише заглавной
const BASS_NOTES := {"x": 0, "o": 12, "f": 7}
const BASS_SAMPLES := [33, 36, 39, 42, 45, 48, 51, 54, 57]   ## A1…A3 через малую терцию
const BASS_BASE_MIDI := 36           ## C2: бас тоники — BASS_BASE_MIDI + тональность
const PROGRESSIONS := {"minor": [0, 0, 8, 10], "major": [0, 0, 5, 7]}
const PEAK := 0.85
const LOOP_PAD := 64
## Щелчок метронома: высота первой доли и остальных, затухание, громкость, длина.
const CLICK := {"accent_hz": 2000.0, "beat_hz": 1300.0, "decay": 160.0, "gain": 0.8, "seconds": 0.03}
const STYLES := [
	{"id": "rock", "name": "рок", "swing": 0.0, "order": ["a", "b", "b", "fill"], "bars": {
		"a": {"crash": "X.......", "kick": "X...X.x.", "snare": "..X...X.", "hat": ".xXxXxXx", "bass": "xxxxxxxx"},
		"b": {"kick": "X...X.x.", "snare": "..X...X.", "hat": "XxXxXxXx", "bass": "xxxxxxxx"},
		"fill": {"kick": "X...X...", "snare": "..X.XxXX", "hat": "XxXx....", "bass": "xxxxx.o."},
	}},
	{"id": "slow", "name": "медленный", "swing": 0.0, "order": ["a", "b", "b", "fill"], "bars": {
		"a": {"crash": "X.......", "kick": "X..x....", "snare": "....X...", "hat": "..x.X.x.", "bass": "x.....f."},
		"b": {"kick": "X..x....", "snare": "....X...", "hat": "X.x.X.x.", "bass": "x.....f."},
		"fill": {"kick": "X..x....", "snare": "....X.xX", "hat": "X.x.X...", "bass": "x...o.f."},
	}},
	{"id": "shuffle", "name": "шаффл", "swing": 0.33, "order": ["a", "b", "b", "fill"], "bars": {
		"a": {"crash": "X.......", "kick": "X...X...", "snare": "..X...X.", "hat": ".xXxXxXx", "bass": "x.x.f.o."},
		"b": {"kick": "X...X...", "snare": "..X...X.", "hat": "XxXxXxXx", "bass": "x.x.f.o."},
		"fill": {"kick": "X...X...", "snare": "..X.XxXx", "hat": "XxXx....", "bass": "x.x.f.f."},
	}},
	{"id": "metal", "name": "метал", "swing": 0.0, "order": ["a", "b", "b", "fill"], "bars": {
		"a": {"crash": "X...X...", "kick": "XxxxXxxx", "snare": "..X...X.", "open": "..x...x.", "bass": "XxxxXxxx"},
		"b": {"kick": "XxxxXxxx", "snare": "..X...X.", "open": "x.x.x.x.", "bass": "XxxxXxxx"},
		"fill": {"kick": "XxxxXxxx", "snare": "..X.XXXX", "bass": "XxxxXxoo"},
	}},
	{"id": "none", "name": "тишина", "swing": 0.0, "order": ["a", "a", "a", "a"], "bars": {}},
]

## Звук → PCM: барабаны по имени, бас по MIDI сэмпла (читаются при первой подложке).
static var _pcm := {}


static func style_of(id: String) -> Dictionary:
	for style: Dictionary in STYLES:
		if style["id"] == id:
			return style
	return {}


## Луп стиля id в тональности key (minor — гармония минорная). Хвосты звуков заворачиваются в начало.
static func render(id: String, key: int, minor: bool) -> AudioStreamWAV:
	var style := style_of(id)
	var slot := Timing.slot_len() * RATE
	var out := PackedFloat32Array()
	out.resize(roundi(Looper.BARS * Timing.bar_len() * RATE))
	var roots: Array = PROGRESSIONS["minor" if minor else "major"]
	var round_robin := 0
	for bar in Looper.BARS:
		var parts: Dictionary = (style["bars"] as Dictionary).get(style["order"][bar], {})
		for part: String in parts:
			var spec: Dictionary = PARTS[part]
			var cells := String(parts[part])
			for s in cells.length():
				var cell := cells[s]
				if cell == ".":
					continue
				var swing := float(style["swing"]) if s % Timing.SLOTS_PER_BEAT == 1 else 0.0
				var at := roundi((bar * Timing.SLOTS_PER_BAR + s + swing) * slot)
				var gain := float(spec["gain"]) * (1.0 if cell == cell.to_upper() else SOFT)
				if spec.has("samples"):
					var names: Array = spec["samples"]
					_mix(out, at, _drum(String(names[round_robin % names.size()])), gain)
					round_robin += 1
				else:
					var midi := BASS_BASE_MIDI + key + int(roots[bar]) + int(BASS_NOTES[cell.to_lower()])
					_mix_bass(out, at, midi, roundi(_ring(cells, s) * slot), gain)
	var peak := 0.0
	for v in out:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		for i in out.size():
			out[i] *= PEAK / peak
	return to_wav(out, true)


## Петля: после конца — ещё LOOP_PAD сэмплов её начала. Микшер Godot на стыке читает за конец петли,
## и на Android чтение за конец буфера роняет игру (защитная страница памяти).
## Метроном: такт щелчков в темпе Timing.bpm, первая доля выше. offset — где в такте сильная доля музыки
## (пре-ролл трека), чтобы щелчок совпал с ней.
static func metronome(offset: float) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	out.resize(roundi(Timing.bar_len() * RATE))
	for beat in Timing.BEATS_PER_BAR:
		var hz := float(CLICK["accent_hz"] if beat == 0 else CLICK["beat_hz"])
		var at := roundi((offset + beat * Timing.beat_len()) * RATE)
		for i in int(float(CLICK["seconds"]) * RATE):
			var t := float(i) / RATE
			out[(at + i) % out.size()] += sin(TAU * hz * t) * exp(-t * float(CLICK["decay"])) * float(CLICK["gain"])
	return to_wav(out, true)


static func to_wav(buf: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	var pad := LOOP_PAD if loop else 0
	bytes.resize((buf.size() + pad) * 2)
	for i in buf.size() + pad:
		bytes.encode_s16(i * 2, int(clampf(buf[i % buf.size()], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = buf.size()
	return wav


## Сколько восьмых звенит нота баса: до следующей ноты партии или конца такта.
static func _ring(cells: String, s: int) -> int:
	var n := 1
	while s + n < cells.length() and cells[s + n] == ".":
		n += 1
	return n


static func _mix(out: PackedFloat32Array, at: int, sample: PackedFloat32Array, gain: float) -> void:
	var size := out.size()
	for i in sample.size():
		out[(at + i) % size] += sample[i] * gain


## Бас: ближайший сэмпл, подтянутый по высоте (линейная интерполяция), с коротким затуханием в конце.
static func _mix_bass(out: PackedFloat32Array, at: int, midi: int, length: int, gain: float) -> void:
	var base: int = BASS_SAMPLES[0]
	for m: int in BASS_SAMPLES:
		if absi(m - midi) < absi(base - midi):
			base = m
	var src := _bass(base)
	var ratio := pow(2.0, (midi - base) / 12.0)
	var n := mini(length, int((src.size() - 2) / ratio))
	var fade := maxi(1, mini(n, int(0.012 * RATE)))
	var size := out.size()
	for i in n:
		var p := i * ratio
		var j := int(p)
		var v := lerpf(src[j], src[j + 1], p - j)
		if i > n - fade:
			v *= float(n - i) / fade
		out[(at + i) % size] += v * gain


## PCM сэмплов: 16 бит моно, импорт без сжатия (compress/mode=0 в *.wav.import).
static func _drum(name: String) -> PackedFloat32Array:
	if not _pcm.has(name):
		_pcm[name] = _decode(load(DRUM_DIR + name + ".wav") as AudioStreamWAV)
	return _pcm[name]


static func _bass(midi: int) -> PackedFloat32Array:
	if not _pcm.has(midi):
		_pcm[midi] = _decode(load(BASS_DIR + "%d.wav" % midi) as AudioStreamWAV)
	return _pcm[midi]


static func _decode(wav: AudioStreamWAV) -> PackedFloat32Array:
	var data := wav.data
	var out := PackedFloat32Array()
	out.resize(data.size() / 2)
	for i in out.size():
		out[i] = data.decode_s16(i * 2) / 32768.0
	return out
