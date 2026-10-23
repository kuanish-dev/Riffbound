class_name TestRunner
extends RefCounted


static func run(main: Node) -> void:
	var suites: Array[TestSuite] = [CoreTests.new(), InstrumentTests.new(), SongTests.new(), JamTests.new(), TouchTests.new(),
		MusicTests.new(), HarmonyTests.new(), ShopTests.new(), StyleTests.new(), SoundTests.new()]
	var total := 0
	var failed := 0
	for suite in suites:
		var counts := _run_suite(suite)
		total += counts.x
		failed += counts.y
	print("[test] %s — %d/%d" % ["PASS" if failed == 0 else "FAIL", total - failed, total])
	main.get_tree().quit(1 if failed > 0 else 0)


static func _run_suite(suite: TestSuite) -> Vector2i:
	var counts := Vector2i.ZERO
	for method in suite.get_method_list():
		var test_name: String = method["name"]
		if test_name.begins_with("test_"):
			counts.x += 1
			counts.y += 0 if _run_test(suite, test_name) else 1
	suite.after_all()
	return counts


static func _run_test(suite: TestSuite, test_name: String) -> bool:
	suite.before_each()
	suite.begin()
	suite.call(test_name)
	var errors := suite.end()
	if errors.is_empty():
		print("[test] ok    %s" % test_name)
	for error in errors:
		print("[test] FAIL  %s: %s" % [test_name, error])
	return errors.is_empty()
