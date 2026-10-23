class_name Looper
extends RefCounted

const MAX_LAYERS := 4
const BARS := 4

var length := 0.0
var layers: Array[Array] = []
var recording := false
var _rec_start := 0.0
var _rec: Array[Dictionary] = []
var _last := -1.0


func reset() -> void:
	layers.clear()
	cancel_recording()
	_last = -1.0


func start_recording(now: float) -> bool:
	if recording or layers.size() >= MAX_LAYERS:
		return false
	recording = true
	_rec_start = now
	_rec.clear()
	return true


func cancel_recording() -> void:
	recording = false
	_rec.clear()


func progress(now: float) -> float:
	return clampf((now - _rec_start) / length, 0.0, 1.0) if recording else 0.0


func undo() -> bool:
	if layers.is_empty():
		return false
	layers.pop_back()
	return true


func capture(event: Dictionary, now: float) -> void:
	if recording and now >= _rec_start:
		var item := event.duplicate()
		item["t"] = fposmod(now, length)
		_rec.append(item)


func tick(now: float) -> Array[Dictionary]:
	if recording and now >= _rec_start + length:
		recording = false
		var events := _rec.duplicate()
		events.sort_custom(_earlier)
		layers.append(events)
		_rec.clear()
	var due: Array[Dictionary] = []
	if _last >= 0.0 and now > _last and length > 0.0:
		var from := fposmod(_last, length)
		var to := fposmod(now, length)
		for i in layers.size():
			for event: Dictionary in layers[i]:
				if _between(float(event["t"]), from, to):
					due.append({"layer": i, "event": event})
	_last = now
	return due


static func _between(t: float, from: float, to: float) -> bool:
	if from <= to:
		return t > from and t <= to
	return t > from or t <= to


static func _earlier(a: Dictionary, b: Dictionary) -> bool:
	return float(a["t"]) < float(b["t"])
