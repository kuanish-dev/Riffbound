class_name TestSuite
extends RefCounted
## Основа набора тестов: DevTools вызывает методы test_* по очереди, перед каждым — before_each().

var _errors: Array[String] = []


func before_each() -> void:
	pass


func after_all() -> void:
	pass


func begin() -> void:
	_errors.clear()


func end() -> Array[String]:
	return _errors.duplicate()


func check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)


## Сравнение по строковому виду: типизированные и обычные массивы с одинаковым содержимым равны.
func eq(got: Variant, want: Variant, what := "") -> void:
	if str(got) != str(want):
		_errors.append("%s: ожидали %s, получили %s" % [what, str(want), str(got)])
