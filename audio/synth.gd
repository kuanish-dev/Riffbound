class_name Synth
## Все звуки собираются кодом при запуске — без файлов.
## Гитара: Karplus-Strong (щипок струны) + перегруз, одна нота на сэмпл (SampleBank режет по полутонам).
## Подложки (BACKINGS) — луп на BARS тактов в любой тональности: бас ходит по ступеням PROGRESSIONS
## (минор: i–i–VI–VII, как E–E–C–D; мажор: I–I–IV–V), поэтому ноты гаммы гитары ложатся в гармонию.

const RATE := 44100
const DRIVE := 4.5
const SUSTAIN := 3.0         ## секунд звенит струна, если её не заглушить
const DECAY_DB := 5.0        ## на сколько дБ в секунду тихнет струна — одинаково для любой высоты
const MUTED_DECAY_DB := 80.0 ## глушёная струна гаснет почти сразу
const LEVEL := 0.3           ## громкость начала ноты (RMS первых 0.3 с) — все ноты равны
const BRIGHT_HZ := 165.0     ## у нот выше этой частоты струна меньше сглаживается и не тускнеет быстрее низких
const BARS := 4
## Барабаны по восьмым, строка на такт: x — удар.
const KICK := ["x...x.x.", "x...x...", "x...x.x.", "x.x.x..."]
const SNARE := ["..x...x.", "..x...x.", "..x...x.", "..x...xx"]
## Что звучит в подложке.
const BACKINGS := [
	{"id": "rock", "name": "рок", "drums": true, "bass": true, "click": false},
	{"id": "click", "name": "метроном", "drums": false, "bass": false, "click": true},
	{"id": "none", "name": "тишина", "drums": false, "bass": false, "click": false},
]
## Бас по тактам — полутоны от тоники.
const PROGRESSIONS := {"minor": [0, 0, 8, 10], "major": [0, 0, 5, 7]}
const BASS_BASE_MIDI := 36   ## C2: бас тоники — BASS_BASE_MIDI + тональность


static func loop_seconds() -> float:
	return BARS * Timing.BEATS_PER_BAR * Timing.BEAT_LEN


static func to_wav(buf: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
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


## Нота гитары: щипок струны через перегруз.
static func pluck_note(hz: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(SUSTAIN * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	_pluck(out, hz, DECAY_DB, rng)
	var norm := tanh(DRIVE)
	for i in n:
		out[i] = tanh(out[i] * DRIVE) / norm
	var gain := LEVEL / maxf(_rms(out, 0, int(0.3 * RATE)), 0.0001)
	for i in n:
		out[i] *= gain * minf(1.0, (n - i) / 3000.0)
	return out


static func backing_index(id: String) -> int:
	for i in BACKINGS.size():
		if BACKINGS[i]["id"] == id:
			return i
	return 0


## Подложка на BARS тактов (BACKINGS) в тональности key. Хвосты звуков заворачиваются в начало лупа.
static func backing(id: String, key: int, minor: bool, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var kind: Dictionary = BACKINGS[backing_index(id)]
	var roots: Array = PROGRESSIONS["minor" if minor else "major"]
	var out := PackedFloat32Array()
	out.resize(roundi(loop_seconds() * RATE))
	for bar in BARS:
		for s in Timing.SLOTS_PER_BAR:
			var at := roundi((bar * Timing.SLOTS_PER_BAR + s) * Timing.SLOT_LEN * RATE)
			var strong := s % Timing.SLOTS_PER_BEAT == 0
			if kind["drums"]:
				if KICK[bar][s] == "x":
					_kick(out, at)
				if SNARE[bar][s] == "x":
					_snare(out, at, rng)
				_hat(out, at, 0.2 if strong else 0.12, rng)
			if kind["bass"]:
				_bass(out, at, Tuning.hz(BASS_BASE_MIDI + key + int(roots[bar])), 0.42 if strong else 0.32, rng)
			if kind["click"] and strong:
				_click(out, at, s == 0)
	var peak := 0.0
	for v in out:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		for i in out.size():
			out[i] = out[i] / peak * 0.85
	return out


## Струна: кольцевой буфер шума, усредняемый с затуханием (Karplus-Strong). Добавляет в out.
## Затухание задаётся в дБ за секунду и пересчитывается на период: иначе высокая струна, у которой
## периодов в секунду больше, гаснет заметно быстрее низкой. По той же причине у высоких нот
## сглаживание соседних отсчётов слабее (smooth), чтобы они не тускнели раньше.
static func _pluck(out: PackedFloat32Array, hz: float, decay_db: float, rng: RandomNumberGenerator) -> void:
	var period := maxi(2, int(RATE / hz))
	var decay := pow(10.0, -decay_db / 20.0 / hz)
	var smooth := clampf(0.5 * BRIGHT_HZ / hz, 0.15, 0.5)
	var ring := PackedFloat32Array()
	ring.resize(period)
	var pick := 0.0
	for i in period:
		pick += (rng.randf_range(-1.0, 1.0) - pick) * 0.6
		ring[i] = pick
	var idx := 0
	for i in out.size():
		var a := ring[idx]
		var next := (idx + 1) % period
		ring[idx] = (a * (1.0 - smooth) + ring[next] * smooth) * decay
		out[i] += a * 0.6
		idx = next


static func _rms(buf: PackedFloat32Array, from: int, to: int) -> float:
	var sum := 0.0
	for i in range(from, mini(to, buf.size())):
		sum += buf[i] * buf[i]
	return sqrt(sum / maxi(1, mini(to, buf.size()) - from))


## Глушняк: короткий шумный «чк» и тут же заглохшая низкая струна.
static func muted_strum(hz: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(0.12 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var low := 0.0
	for i in n:
		low += (rng.randf_range(-1.0, 1.0) - low) * 0.3
		out[i] = low * exp(-float(i) / RATE * 50.0) * 1.6
	_pluck(out, hz, MUTED_DECAY_DB, rng)
	var norm := tanh(DRIVE)
	for i in n:
		var tail := minf(1.0, (n - i) / 400.0)
		out[i] = tanh(out[i] * DRIVE) / norm * 0.4 * tail
	return out


static func _add(out: PackedFloat32Array, i: int, v: float) -> void:
	out[i % out.size()] += v


## Метроном: короткий щелчок, на первую долю такта — выше.
static func _click(out: PackedFloat32Array, at: int, accent: bool) -> void:
	var hz := 1800.0 if accent else 1200.0
	for i in int(0.03 * RATE):
		var t := float(i) / RATE
		_add(out, at + i, sin(TAU * hz * t) * exp(-t * 160.0) * 0.6)


static func _kick(out: PackedFloat32Array, at: int) -> void:
	var phase := 0.0
	for i in int(0.32 * RATE):
		var t := float(i) / RATE
		phase += TAU * (48.0 + 90.0 * exp(-t * 28.0)) / RATE
		_add(out, at + i, sin(phase) * exp(-t * 8.0) * 0.95)


static func _snare(out: PackedFloat32Array, at: int, rng: RandomNumberGenerator) -> void:
	for i in int(0.2 * RATE):
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0) * exp(-t * 22.0) * 0.45
		var body := sin(TAU * 185.0 * t) * exp(-t * 30.0) * 0.35
		_add(out, at + i, noise + body)


static func _hat(out: PackedFloat32Array, at: int, gain: float, rng: RandomNumberGenerator) -> void:
	var prev := 0.0
	for i in int(0.05 * RATE):
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		_add(out, at + i, (noise - prev) * 0.5 * exp(-t * 90.0) * gain)
		prev = noise


## Бас: тёмный щипок, заглушённый к следующей восьмой.
static func _bass(out: PackedFloat32Array, at: int, hz: float, gain: float, rng: RandomNumberGenerator) -> void:
	var period := maxi(2, int(RATE / hz))
	var ring := PackedFloat32Array()
	ring.resize(period)
	var smooth := 0.0
	for i in period:
		smooth = smooth * 0.6 + rng.randf_range(-1.0, 1.0) * 0.4
		ring[i] = smooth
	var n := int(0.27 * RATE)
	var idx := 0
	for i in n:
		var a := ring[idx]
		var next := (idx + 1) % period
		ring[idx] = (a + ring[next]) * 0.5 * 0.995
		idx = next
		_add(out, at + i, tanh(a * 2.2) * gain * minf(1.0, (n - i) / 600.0))
