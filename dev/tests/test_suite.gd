class_name TestSuite
extends RefCounted

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


func eq(got: Variant, want: Variant, what := "") -> void:
	if str(got) != str(want):
		_errors.append("%s: ожидали %s, получили %s" % [what, str(want), str(got)])
