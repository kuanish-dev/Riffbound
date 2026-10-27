class_name BendGesture
extends RefCounted

const DEAD := 6.0
const RANGE := 110.0
const STEP := 0.02
const SIDEWAYS := 1.5

var from := Vector2.ZERO
var pos := Vector2.ZERO
var on := false
var amount := 0.0


func _init(at: Vector2) -> void:
	from = at
	pos = at


func follow(to: Vector2) -> bool:
	pos = to
	var shift := to - from
	if not on:
		on = absf(shift.x) >= DEAD and absf(shift.x) >= absf(shift.y) * SIDEWAYS
	if not on:
		return false
	var next := clampf((absf(shift.x) - DEAD) / RANGE, 0.0, Tuning.BEND_MAX)
	var changed := absf(next - amount) >= STEP or (next == 0.0) != (amount == 0.0)
	if changed:
		amount = next
	if next == 0.0:
		on = false
	return changed
