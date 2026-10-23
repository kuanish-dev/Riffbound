class_name ShopTests
extends TestSuite
## Магазин гитар: монеты за песни, покупка и выбор скина; скины рисуемы — контуры правильные многоугольники,
## железо стоит на корпусе. Файлы не пишутся.


func before_each() -> void:
	Songs.persist = false
	Shop.reset()


func after_all() -> void:
	Shop.reset()
	Songs.persist = true


func test_reward_for_song() -> void:
	eq(Shop.reward({"stars": 5, "score": 9400}), 5 * Shop.COINS_PER_STAR + 9, "звёзды и тысячи очков")
	eq(Shop.reward({"stars": 0, "score": 300}), 0, "ни звезды, меньше тысячи — ничего")
	eq(Shop.coins, 59, "монеты копятся")


func test_first_start_pays_for_records() -> void:
	Songs.record("warmup", {"score": 4200, "stars": 3, "accuracy": 0.8}, false)
	Shop.load_data(null)
	check(Shop.coins >= 3 * Shop.COINS_PER_STAR + 4, "за рекорд «Разминки» — монеты (%d)" % Shop.coins)


func test_buy_and_equip() -> void:
	check(not Shop.buy("midnight"), "без монет не купить")
	Shop.coins = 100
	check(Shop.buy("midnight"), "хватает — купили")
	eq(Shop.coins, 100 - int(Shop.skin("midnight")["price"]), "цена списана")
	check(not Shop.buy("midnight"), "купленную второй раз не продают")
	check(not Shop.equip("cherry"), "некупленную не надеть")
	check(Shop.equip("midnight"), "купленную надеть")
	eq(Shop.current()["id"], "midnight", "надета")


func test_skins_table() -> void:
	var ids := {}
	for skin: Dictionary in Shop.SKINS:
		check(not ids.has(skin["id"]), "%s: id один" % skin["id"])
		ids[skin["id"]] = true
		check(GuitarArt.SHAPES.has(skin["shape"]), "%s: форма есть" % skin["id"])
		check(GuitarArt.PICKUPS.has(skin["pickups"]), "%s: звукосниматели есть" % skin["id"])
		check(skin.has_all(["body", "hardware", "cover", "board", "neck", "inlay"]), "%s: все цвета" % skin["id"])
		check(skin.has("edge") or not (skin.get("rings", 0) > 0 or skin.get("neon", false)), "%s: санбёрсту и неону нужен edge" % skin["id"])
	eq(Shop.SKINS[0]["price"], 0, "первая гитара бесплатная")
	eq(Shop.SKINS[0]["id"], Shop.FIRST, "она и надета сначала")


## Звук каждой гитары собирается: классы эффектов есть, свойства у них такие и есть.
func test_tones_are_valid() -> void:
	for skin: Dictionary in Shop.SKINS:
		check(skin.has("tone") and not String(skin["tone"]["name"]).is_empty(), "%s: у звука есть имя" % skin["id"])
		for spec: Dictionary in skin["tone"]["fx"] + GuitarVoices.TAIL_FX:
			check(ClassDB.class_exists(spec["type"]), "%s: эффект %s есть" % [skin["id"], spec["type"]])
			var effect := GuitarVoices.make_effect(spec)
			var names := effect.get_property_list().map(func(p: Dictionary) -> String: return p["name"])
			for property: String in spec:
				check(property == "type" or names.has(property), "%s: у %s есть свойство %s" % [skin["id"], spec["type"], property])
				if property != "type" and names.has(property):
					check(str(effect.get(property)) == str(spec[property]) or typeof(spec[property]) == TYPE_FLOAT
						and is_equal_approx(float(effect.get(property)), float(spec[property])),
						"%s: %s.%s = %s" % [skin["id"], spec["type"], property, spec[property]])


func test_shapes_are_drawable() -> void:
	for id: String in GuitarArt.SHAPES:
		var shape: Dictionary = GuitarArt.SHAPES[id]
		var body := GuitarArt.outline(id, "body")
		check(not Geometry2D.triangulate_polygon(body).is_empty(), "%s: корпус — правильный многоугольник" % id)
		if not (shape["guard"] as Array).is_empty():
			var guard := GuitarArt.outline(id, "guard")
			check(not Geometry2D.triangulate_polygon(guard).is_empty(), "%s: накладка рисуется" % id)
		for knob: Vector2 in shape["knobs"] + [shape["switch"]]:
			check(Geometry2D.is_point_in_polygon(knob, body), "%s: ручка %s на корпусе" % [id, knob])
	for skin: Dictionary in Shop.SKINS:
		var body := GuitarArt.outline(String(skin["shape"]), "body")
		for pickup: Dictionary in GuitarArt.PICKUPS[skin["pickups"]]:
			var half: Vector2 = GuitarArt.PICKUP_KINDS[pickup["kind"]]["size"] * 0.5
			for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var p := Vector2(float(pickup["x"]), 0) + half * corner
				check(Geometry2D.is_point_in_polygon(p, body), "%s: звукосниматели на корпусе" % skin["id"])
	for head: String in GuitarArt.HEADS:
		check(not Geometry2D.triangulate_polygon(GuitarArt.head_outline(head)).is_empty(), "голова %s рисуется" % head)
