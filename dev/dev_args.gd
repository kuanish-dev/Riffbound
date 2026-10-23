class_name DevArgs

static var values: Dictionary = {}


static func parse() -> void:
	values.clear()
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var kv := arg.substr(2).split("=", true, 1)
		values[kv[0]] = kv[1] if kv.size() > 1 else "true"


static func has(key: String) -> bool:
	return values.has(key)


static func get_str(key: String, fallback := "") -> String:
	return values.get(key, fallback)


static func get_int(key: String, fallback := 0) -> int:
	return int(values[key]) if values.has(key) else fallback
