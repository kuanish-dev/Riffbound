class_name BendView
extends RefCounted

const WOBBLE_KICK := 0.4
const WOBBLE_FADE := 1.5
const FOLLOW := 30.0

var amount := 0.0
var wobble := 0.0
var _target := 0.0
var _direction := 0.0


func update(target: float, delta: float) -> void:
	var direction := signf(target - _target)
	if target > 0.0 and direction != 0.0 and direction != _direction:
		if _direction != 0.0:
			wobble = minf(1.0, wobble + WOBBLE_KICK)
		_direction = direction
	if target == 0.0:
		_direction = 0.0
	wobble = maxf(0.0, wobble - delta * WOBBLE_FADE)
	_target = target
	amount = lerpf(amount, target, 1.0 - exp(-delta * FOLLOW))
