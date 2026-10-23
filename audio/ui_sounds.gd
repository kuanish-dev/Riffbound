class_name UiSounds
extends Node
## Звуки отклика на действия игрока, собранные кодом: SOUNDS — имя → рецепт. Рецепт — ноты (at — когда, hz → to —
## высота с глиссандо, len — длина, wave — sine / square / triangle / saw) и шум (len, from → to — срез фильтра)
## с общей громкостью gain. Играет пул из POOL плееров по кругу, чтобы быстрые звуки не обрывали друг друга.
## Звуки собираются при первом вызове; без звука (headless) — молчит.

const RATE := 44100
const POOL := 6
const VOLUME_DB := -3.0
const ATTACK := 0.003
const SOUNDS := {
	"move": {"gain": 0.22, "notes": [{"hz": 1250.0, "len": 0.035, "wave": "square"}]},
	"select": {"gain": 0.26, "notes": [{"hz": 880.0, "len": 0.06, "wave": "square"},
		{"at": 0.06, "hz": 1320.0, "len": 0.1, "wave": "square"}]},
	"back": {"gain": 0.26, "notes": [{"hz": 990.0, "len": 0.06, "wave": "square"},
		{"at": 0.06, "hz": 660.0, "len": 0.1, "wave": "square"}]},
	"start": {"gain": 0.3, "notes": [{"hz": 660.0, "len": 0.06, "wave": "square"}, {"at": 0.06, "hz": 990.0, "len": 0.06, "wave": "square"},
		{"at": 0.12, "hz": 1320.0, "to": 1760.0, "len": 0.16, "wave": "square"}], "noise": {"len": 0.25, "from": 800.0, "to": 6000.0, "gain": 0.35}},
	"toggle_on": {"gain": 0.3, "notes": [{"hz": 700.0, "to": 1400.0, "len": 0.09, "wave": "sine"}]},
	"toggle_off": {"gain": 0.3, "notes": [{"hz": 1400.0, "to": 700.0, "len": 0.09, "wave": "sine"}]},
	"shift": {"gain": 0.3, "noise": {"len": 0.11, "from": 1500.0, "to": 5000.0, "gain": 0.5},
		"notes": [{"hz": 520.0, "to": 780.0, "len": 0.08, "wave": "triangle"}]},
	"tick": {"gain": 0.3, "notes": [{"hz": 2200.0, "len": 0.018, "wave": "sine"}]},
	"deny": {"gain": 0.28, "notes": [{"hz": 150.0, "len": 0.08, "wave": "square"}, {"at": 0.11, "hz": 150.0, "len": 0.12, "wave": "square"}]},
	"buy": {"gain": 0.3, "notes": [{"hz": 1568.0, "len": 0.08, "wave": "triangle"}, {"at": 0.08, "hz": 2093.0, "len": 0.3, "wave": "triangle"},
		{"at": 0.08, "hz": 2637.0, "len": 0.3, "wave": "sine"}], "noise": {"len": 0.18, "from": 5000.0, "to": 9000.0, "gain": 0.25}},
	"equip": {"gain": 0.3, "notes": [{"hz": 523.0, "len": 0.07, "wave": "triangle"}, {"at": 0.07, "hz": 784.0, "len": 0.14, "wave": "triangle"}]},
	"record": {"gain": 0.28, "notes": [{"hz": 1000.0, "len": 0.05, "wave": "sine"}, {"at": 0.1, "hz": 1000.0, "len": 0.05, "wave": "sine"}]},
	"layer": {"gain": 0.28, "notes": [{"hz": 660.0, "len": 0.07, "wave": "triangle"}, {"at": 0.07, "hz": 880.0, "len": 0.07, "wave": "triangle"},
		{"at": 0.14, "hz": 1320.0, "len": 0.16, "wave": "triangle"}]},
	"undo": {"gain": 0.28, "notes": [{"hz": 600.0, "to": 280.0, "len": 0.12, "wave": "square"}]},
	"save": {"gain": 0.28, "notes": [{"hz": 784.0, "len": 0.06, "wave": "triangle"}, {"at": 0.06, "hz": 988.0, "len": 0.06, "wave": "triangle"},
		{"at": 0.12, "hz": 1175.0, "len": 0.06, "wave": "triangle"}, {"at": 0.18, "hz": 1568.0, "len": 0.2, "wave": "triangle"}]},
	"delete": {"gain": 0.28, "notes": [{"hz": 320.0, "to": 140.0, "len": 0.16, "wave": "saw"}],
		"noise": {"len": 0.12, "from": 3000.0, "to": 400.0, "gain": 0.4}},
	"tap": {"gain": 0.35, "notes": [{"hz": 1800.0, "to": 1500.0, "len": 0.03, "wave": "sine"}],
		"noise": {"len": 0.012, "from": 4000.0, "to": 4000.0, "gain": 0.4}},
	"miss": {"gain": 0.32, "notes": [{"hz": 150.0, "to": 70.0, "len": 0.13, "wave": "sine"}],
		"noise": {"len": 0.05, "from": 900.0, "to": 300.0, "gain": 0.3}},
	"tech": {"gain": 0.16, "notes": [{"hz": 2637.0, "len": 0.06, "wave": "sine"}, {"at": 0.045, "hz": 3136.0, "len": 0.1, "wave": "sine"}]},
	"mult": {"gain": 0.22, "notes": [{"hz": 523.0, "len": 0.05, "wave": "square"}, {"at": 0.05, "hz": 659.0, "len": 0.05, "wave": "square"},
		{"at": 0.1, "hz": 784.0, "len": 0.05, "wave": "square"}, {"at": 0.15, "hz": 1047.0, "len": 0.14, "wave": "square"}]},
	"finish": {"gain": 0.3, "notes": [{"hz": 523.0, "len": 0.12, "wave": "square"}, {"at": 0.12, "hz": 659.0, "len": 0.12, "wave": "square"},
		{"at": 0.24, "hz": 784.0, "len": 0.12, "wave": "square"}, {"at": 0.36, "hz": 1047.0, "len": 0.45, "wave": "square"},
		{"at": 0.36, "hz": 784.0, "len": 0.45, "wave": "triangle"}]},
	"record_new": {"gain": 0.26, "notes": [{"hz": 2093.0, "len": 0.1, "wave": "sine"}, {"at": 0.09, "hz": 2637.0, "len": 0.1, "wave": "sine"},
		{"at": 0.18, "hz": 3136.0, "len": 0.25, "wave": "sine"}], "noise": {"len": 0.3, "from": 6000.0, "to": 9000.0, "gain": 0.2}},
}

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _streams := {}
var _silent := false


func _ready() -> void:
	_silent = DisplayServer.get_name() == "headless"
	for i in POOL:
		var player := AudioStreamPlayer.new()
		player.volume_db = VOLUME_DB
		add_child(player)
		_players.append(player)


func play(id: String) -> void:
	if _silent or id.is_empty():
		return
	if not _streams.has(id):
		_streams[id] = render(SOUNDS[id])
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[id]
	player.play()


func stop() -> void:
	for player in _players:
		player.stop()


## Звук по рецепту.
static func render(spec: Dictionary) -> AudioStreamWAV:
	var noise: Dictionary = spec.get("noise", {})
	var total := float(noise.get("len", 0.0))
	for note: Dictionary in spec.get("notes", []):
		total = maxf(total, float(note.get("at", 0.0)) + float(note["len"]))
	var out := PackedFloat32Array()
	out.resize(int((total + 0.01) * RATE))
	for note: Dictionary in spec.get("notes", []):
		_add_note(out, note)
	if not noise.is_empty():
		_add_noise(out, noise)
	var gain := float(spec["gain"])
	for i in out.size():
		out[i] *= gain
	return Backing.to_wav(out)


static func _add_note(out: PackedFloat32Array, note: Dictionary) -> void:
	var start := int(float(note.get("at", 0.0)) * RATE)
	var length := float(note["len"])
	var from := float(note["hz"])
	var to := float(note.get("to", from))
	var phase := 0.0
	for i in int(length * RATE):
		var t := float(i) / RATE
		var k := t / length
		phase = fposmod(phase + lerpf(from, to, k) / RATE, 1.0)
		var env := minf(t / ATTACK, 1.0) * (1.0 - k) * (1.0 - k)
		if start + i < out.size():
			out[start + i] += _wave(String(note["wave"]), phase) * env


static func _wave(kind: String, phase: float) -> float:
	match kind:
		"square":
			return 0.6 if phase < 0.5 else -0.6
		"triangle":
			return 4.0 * absf(phase - 0.5) - 1.0
		"saw":
			return (2.0 * phase - 1.0) * 0.7
	return sin(TAU * phase)


## Шум через однополюсный фильтр, срез которого едет from → to.
static func _add_noise(out: PackedFloat32Array, noise: Dictionary) -> void:
	var length := float(noise["len"])
	var gain := float(noise["gain"])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(length * 1000.0)
	var low := 0.0
	for i in mini(int(length * RATE), out.size()):
		var k := float(i) / (length * RATE)
		var cutoff := lerpf(float(noise["from"]), float(noise["to"]), k)
		var a := 1.0 - exp(-TAU * cutoff / RATE)
		low += (rng.randf_range(-1.0, 1.0) - low) * a
		out[i] += low * gain * (1.0 - k) * minf(float(i) / (ATTACK * RATE), 1.0)
