class_name Backing
## Подложка из настоящих сэмплов (assets/drums, assets/bass — CC0, см. CREDITS.md): игра сама сводит
## барабаны, бас и клавиши по аккордам (Harmony) в темпе песни или джема — столько тактов, сколько аккордов:
## у песни — вся песня по её аккордам, в джеме — круг Harmony.progression тональности строя.
## Стиль (STYLES) — какие такты в каком порядке («order», по кругу), такт — партии инструментов (PARTS) строкой
## из восьми восьмых: «.» — тишина, буква — удар, заглавная — с акцентом. У баса буква — ступень аккорда
## (BASS_NOTES), клавиши играют аккорд (KEYS — в каком регистре), поэтому гармония подложки та же, что у
## мелодии. swing — на сколько восьмой сдвинуть слабые восьмые (шаффл).
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
	"keys": {"keys": true, "gain": 0.2},
}
const SOFT := 0.6                    ## строчная буква — тише заглавной
const BASS_NOTES := {"x": "root", "o": "octave", "f": "fifth"}
## Клавиши: аккорд в регистре от low (каждая нота — ближайшая выше), нота звенит seconds, гаснет с decay.
const KEYS := {"low": 55, "seconds": 1.0, "decay": 2.6, "overtone": 0.35}
const BASS_SAMPLES := [33, 36, 39, 42, 45, 48, 51, 54, 57]   ## A1…A3 через малую терцию
const BASS_BASE_MIDI := 36           ## C2: бас тоники — BASS_BASE_MIDI + тональность
const PEAK := 0.85
const LOOP_PAD := 64
## Щелчок метронома: высота первой доли и остальных, затухание, громкость, длина.
const CLICK := {"accent_hz": 2000.0, "beat_hz": 1300.0, "decay": 160.0, "gain": 0.8, "seconds": 0.03}
const STYLES := [
	{"id": "rock", "name": "рок", "swing": 0.0, "order": ["a", "b", "b", "fill"], "bars": {
		"a": {"crash": "X.......", "kick": "X...X.x.", "snare": "..X...X.", "hat": ".xXxXxXx", "bass": "xxxxxxxx", "keys": "x...x..."},
		"b": {"kick": "X...X.x.", "snare": "..X...X.", "hat": "XxXxXxXx", "bass": "xxxxxxxx", "keys": "x...x..."},
		"fill": {"kick": "X...X...", "snare": "..X.XxXX", "hat": "XxXx....", "bass": "xxxxx.o.", "keys": "x......."},
	}},
	{"id": "slow", "name": "медленный", "swing": 0.0, "order": ["a", "b", "b", "fill"], "bars": {
		"a": {"crash": "X.......", "kick": "X..x....", "snare": "....X...", "hat": "..x.X.x.", "bass": "x.....f.", "keys": "x...x..."},
		"b": {"kick": "X..x....", "snare": "....X...", "hat": "X.x.X.x.", "bass": "x.....f.", "keys": "x...x..."},
		"fill": {"kick": "X..x....", "snare": "....X.xX", "hat": "X.x.X...", "bass": "x...o.f.", "keys": "x...x..."},
	}},
	{"id": "shuffle", "name": "шаффл", "swing": 0.33, "order": ["a", "b", "b", "fill"], "bars": {
		"a": {"crash": "X.......", "kick": "X...X...", "snare": "..X...X.", "hat": ".xXxXxXx", "bass": "x.x.f.o.", "keys": "..x...x."},
		"b": {"kick": "X...X...", "snare": "..X...X.", "hat": "XxXxXxXx", "bass": "x.x.f.o.", "keys": "..x...x."},
		"fill": {"kick": "X...X...", "snare": "..X.XxXx", "hat": "XxXx....", "bass": "x.x.f.f.", "keys": "..x....."},
	}},
	{"id": "metal", "name": "метал", "swing": 0.0, "order": ["a", "b", "b", "fill"], "bars": {
		"a": {"crash": "X...X...", "kick": "XxxxXxxx", "snare": "..X...X.", "open": "..x...x.", "bass": "XxxxXxxx"},
		"b": {"kick": "XxxxXxxx", "snare": "..X...X.", "open": "x.x.x.x.", "bass": "XxxxXxxx"},
		"fill": {"kick": "XxxxXxxx", "snare": "..X.XXXX", "bass": "XxxxXxoo"},
	}},
	{"id": "none", "name": "тишина", "swing": 0.0, "order": ["a", "a", "a", "a"], "bars": {}},
]

## Звук → PCM: барабаны по имени, бас по MIDI сэмпла, аккорды клавиш (готовятся при первой подложке).
## Это кэш основного потока; фоновая сборка (Main) передаёт в render свой — словари не делятся между потоками.
static var _pcm := {}


static func style_of(id: String) -> Dictionary:
	for style: Dictionary in STYLES:
		if style["id"] == id:
			return style
	return {}


## Играет ли стиль гармонию (бас или клавиши) — тогда его аккорды можно подсвечивать.
static func has_harmony(id: String) -> bool:
	for parts: Dictionary in (style_of(id)["bars"] as Dictionary).values():
		for part: String in parts:
			if not (PARTS[part] as Dictionary).has("samples"):
				return true
	return false


## Подложка стиля id по аккордам bars (такт — «Am» или «Am E») в темпе bpm: столько тактов, сколько аккордов.
## Хвосты звуков заворачиваются в начало — это петля. Глобального не трогает (темп — параметром, кэш сэмплов —
## pcm, по умолчанию кэш основного потока), поэтому может собираться в фоновом потоке.
static func render(id: String, bars: Array, bpm: float, pcm: Variant = null) -> AudioStreamWAV:
	var cache: Dictionary = _pcm if pcm == null else pcm
	var style := style_of(id)
	var slot := 60.0 / bpm / Timing.SLOTS_PER_BEAT * RATE
	var out := PackedFloat32Array()
	out.resize(roundi(bars.size() * Timing.SLOTS_PER_BAR * slot))
	var order: Array = style["order"]
	var round_robin := 0
	for bar in bars.size():
		var parts: Dictionary = (style["bars"] as Dictionary).get(order[bar % order.size()], {})
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
					_mix(out, at, _drum(String(names[round_robin % names.size()]), cache), gain)
					round_robin += 1
					continue
				var chord := Harmony.parse(Harmony.in_bar(String(bars[bar]), s))
				if chord.is_empty():
					continue
				if spec.has("keys"):
					_mix(out, at, _key_chord(chord, cache), gain, roundi(_ring(cells, s) * slot))
				else:
					var midi := BASS_BASE_MIDI + int(chord["root"]) + Harmony.degree(chord, String(BASS_NOTES[cell.to_lower()]))
					_mix_bass(out, at, midi, roundi(_ring(cells, s) * slot), gain, cache)
	var peak := 0.0
	for v in out:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		for i in out.size():
			out[i] *= PEAK / peak
	return to_wav(out, true)


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


## Петля: после конца — ещё LOOP_PAD сэмплов её начала. Микшер Godot на стыке читает за конец петли,
## и на Android чтение за конец буфера роняет игру (защитная страница памяти).
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


## Звук в петлю с места at; length — сколько ему звенеть (дальше обрывается с коротким затуханием).
static func _mix(out: PackedFloat32Array, at: int, sample: PackedFloat32Array, gain: float, length := -1) -> void:
	var size := out.size()
	var n := sample.size() if length < 0 else mini(length, sample.size())
	var fade := 0 if length < 0 else maxi(1, mini(n, int(0.01 * RATE)))
	for i in n - fade:
		out[(at + i) % size] += sample[i] * gain
	for i in range(n - fade, n):
		out[(at + i) % size] += sample[i] * gain * (n - i) / fade


## Бас: ближайший сэмпл, подтянутый по высоте (линейная интерполяция), с коротким затуханием в конце.
static func _mix_bass(out: PackedFloat32Array, at: int, midi: int, length: int, gain: float, cache: Dictionary) -> void:
	var base: int = BASS_SAMPLES[0]
	for m: int in BASS_SAMPLES:
		if absi(m - midi) < absi(base - midi):
			base = m
	var src := _bass(base, cache)
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


## Звук аккорда на клавишах (электропиано кодом): у каждой ноты основной тон с гаснущим обертоном,
## мягкая атака, затухание; каждая нота — ближайшая выше KEYS.low. Звенит до следующего удара партии.
static func _key_chord(chord: Dictionary, cache: Dictionary) -> PackedFloat32Array:
	var key := "keys:%s" % [chord["tones"]]
	if not cache.has(key):
		var buf := PackedFloat32Array()
		buf.resize(int(float(KEYS["seconds"]) * RATE))
		var low := int(KEYS["low"])
		for pc: int in chord["tones"]:
			var hz := Tuning.hz(low + posmod(pc - low, 12))
			for i in buf.size():
				var t := float(i) / RATE
				var tone := sin(TAU * hz * t) + float(KEYS["overtone"]) * sin(TAU * 2.0 * hz * t) * exp(-t * 3.0)
				buf[i] += tone * exp(-t * float(KEYS["decay"])) * minf(t / 0.005, 1.0) * 0.5
		cache[key] = buf
	return cache[key]


## PCM сэмплов: 16 бит моно, импорт без сжатия (compress/mode=0 в *.wav.import).
static func _drum(name: String, cache: Dictionary) -> PackedFloat32Array:
	if not cache.has(name):
		cache[name] = _decode(load(DRUM_DIR + name + ".wav") as AudioStreamWAV)
	return cache[name]


static func _bass(midi: int, cache: Dictionary) -> PackedFloat32Array:
	if not cache.has(midi):
		cache[midi] = _decode(load(BASS_DIR + "%d.wav" % midi) as AudioStreamWAV)
	return cache[midi]


static func _decode(wav: AudioStreamWAV) -> PackedFloat32Array:
	var data := wav.data
	var out := PackedFloat32Array()
	out.resize(data.size() / 2)
	for i in out.size():
		out[i] = data.decode_s16(i * 2) / 32768.0
	return out
