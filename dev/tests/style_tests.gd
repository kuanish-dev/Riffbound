class_name StyleTests
extends TestSuite
## Шкала стиля: растёт от попаданий и техники, разнообразие ценится, тает со временем, ошибки роняют ранг.

var meter: StyleMeter
var log: Array[String] = []


func before_each() -> void:
	meter = StyleMeter.new()
	log.clear()
	meter.ranked.connect(func(rank: int, up: bool) -> void:
		log.append("%s%s" % ["↑" if up else "↓", StyleMeter.RANKS[rank]["id"]]))


## Лямбда сигнала держит набор тестов, а он — шкалу: без этого цикл не освободится.
func after_all() -> void:
	meter = null


func test_first_hit_shows_meter() -> void:
	check(not meter.visible(), "до первой ноты шкалы нет")
	_hit("low", "1", "perfect")
	check(meter.visible(), "после — есть")
	eq(log, ["↑D"], "появление — как взлёт на D")


func test_variety_pays_more() -> void:
	for i in 4:
		_hit("low", "1", "perfect")
	var same := meter.level
	before_each()
	for fret: String in ["1", "2", "3", "4"]:
		_hit("low", fret, "perfect")
	check(meter.level > same * 1.5, "разные ноты дают больше, чем одна и та же (%.2f против %.2f)" % [meter.level, same])


func test_rank_climbs_and_caps() -> void:
	for i in 200:
		_hit(Notes.STRINGS[i % 3], Notes.FRETS[i % 4], "perfect")
		meter.on_fact("tech", {})
	eq(meter.rank(), StyleMeter.RANKS.size() - 1, "выше SSS некуда")
	check(meter.fill() < 1.0, "шкала SSS не переполняется")
	eq(log.slice(0, 7), ["↑D", "↑C", "↑B", "↑A", "↑S", "↑SS", "↑SSS"], "ранги по порядку")
	eq(meter.result(), {"style": "SSS", "style_coins": StyleMeter.RANKS.back()["coins"]}, "лучший стиль в итоге")


func test_drain_over_time() -> void:
	meter.update(0.0)
	for fret: String in Notes.FRETS:
		_hit("mid", fret, "perfect")
		meter.on_fact("tech", {})
	var top := meter.rank()
	check(top >= 1, "набрали ранг")
	meter.update(30.0)
	eq(meter.level, 0.0, "за полминуты тишины стиль растаял")
	check(log.back() == "↓D" or log.back().begins_with("↓"), "растаял — сигнал падения")
	eq(meter.result()["style"], StyleMeter.RANKS[top]["id"], "лучший ранг помнится")


func test_mistakes_drop_rank() -> void:
	for fret: String in Notes.FRETS:
		_hit("high", fret, "perfect")
		meter.on_fact("tech", {})
	var before := meter.level
	meter.on_fact("miss", {})
	check(is_equal_approx(meter.level, maxf(0.0, before - StyleMeter.DROP["miss"])), "промах — минус ранг")
	before = meter.level
	meter.on_fact("wrong", {})
	check(is_equal_approx(meter.level, maxf(0.0, before - StyleMeter.DROP["wrong"])), "не та нота — минус полранга")


func _hit(string: String, fret: String, judgement: String) -> void:
	meter.on_fact("hit", {"note": {"string": string, "fret": fret, "tech": ""}, "judgement": {"id": judgement}})
