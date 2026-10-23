class_name Shaker
extends Camera2D
## Камера над всем показом, как в Hotline Miami: экран всё время чуть качается (SWAY, сильнее на высоком
## стиле) — чуть приближенный (ZOOM), чтобы при наклоне не открывались углы — и трясётся от толчков.
## Толчки KICKS копятся в «травму» (до 1), она гаснет за секунды; смещение — квадрат травмы, поэтому слабые
## толчки едва заметны, а взлёт ранга бьёт сильно. Толкают факты песни (on_fact) и смена ранга (on_ranked).

const KICKS := {"rank_up": 0.55, "rank_down": 0.5, "tech": 0.22, "miss": 0.32, "wrong": 0.22}
const MAX_OFFSET := 14.0
const MAX_ROLL := 0.012
const DECAY := 2.2
const SWAY := {"angle": 0.006, "hot": 0.006, "speed": 0.23}   ## наклон, прибавка на стиле, качаний в секунду
const ZOOM := 1.015

var trauma := 0.0


func _ready() -> void:
	position = Layout.SCREEN * 0.5
	ignore_rotation = false
	zoom = Vector2(ZOOM, ZOOM)


func kick(kind: String) -> void:
	trauma = minf(1.0, trauma + float(KICKS.get(kind, 0.0)))


func on_fact(kind: String, _data: Dictionary) -> void:
	kick(kind)


func on_ranked(_rank: int, up: bool) -> void:
	kick("rank_up" if up else "rank_down")


func _process(delta: float) -> void:
	trauma = maxf(0.0, trauma - DECAY * delta)
	var shake := trauma * trauma
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * MAX_OFFSET * shake
	var sway := (float(SWAY["angle"]) + float(SWAY["hot"]) * StageView.heat()) \
		* sin(Time.get_ticks_msec() / 1000.0 * TAU * float(SWAY["speed"]))
	rotation = sway + randf_range(-1.0, 1.0) * MAX_ROLL * shake
