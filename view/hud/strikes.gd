class_name Strikes
extends RefCounted

const SHAKE_TIME := 0.9
const FLASH_TIME := 0.15
const LONG_AGO := 9.0

var _ages := {}


func strike(string: String) -> void:
	_ages[string] = 0.0


func advance(delta: float) -> void:
	for string: String in _ages:
		_ages[string] = float(_ages[string]) + delta


func age(string: String) -> float:
	return float(_ages.get(string, LONG_AGO))


func shake(string: String) -> float:
	return maxf(0.0, 1.0 - age(string) / SHAKE_TIME)


func flash(string: String) -> float:
	return clampf(1.0 - age(string) / FLASH_TIME, 0.0, 1.0)
