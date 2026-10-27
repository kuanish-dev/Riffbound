class_name KeyControls
extends HudLayer

const HINTS := {
	"menu": "↑ ↓  выбрать      ← →  сложность      Enter  играть      Tab  джем      G  магазин",
	"song": "Esc  выйти",
	"results": "Enter  ещё раз      Esc  к песням",
	"jam": "R  запись      V  музыка      Tab  ещё      Esc  выйти",
	"jam+": "Backspace стереть   Enter в песню   M MIDI   Z/X тон   C гамма   N метроном   T тап   Q/E позиция",
	"shop": "↑ ↓  выбрать      Enter  взять      P  послушать      Esc  назад",
}
const KEY_SIZE := Vector2(62, 58)
const KEY_GAP := 8.0
const GROUP_GAP := 44.0
const KEY_FILL := Color(0.16, 0.15, 0.22)
const KEY_ON := Color(0.85, 0.85, 0.92)
const KEY_EDGE := Color(0.6, 0.58, 0.7)
const KEY_INK_ON := Color(0.05, 0.05, 0.08)


func _draw() -> void:
	if Game.state in ["song", "jam"]:
		_draw_groups(_groups(Cue.next()))
	_draw_hint()


func _groups(cue: Dictionary) -> Array[Dictionary]:
	var held := Game.fretboard.held
	var frets: Array[Dictionary] = []
	for fret: String in Notes.FRETS:
		var key := _key(InputConfig.key_label(InputConfig.fret_action(fret)), held.has(fret), cue.get("frets", []).has(fret))
		key["edge"] = Ink.of_position(Game.tuning.position)
		frets.append(key)
	var strike := _key(InputConfig.key_label("strike"), _struck(), not cue.get("strings", []).is_empty())
	var groups: Array[Dictionary] = [{"caption": "держи", "keys": frets}, {"caption": "бей", "keys": [strike]}]
	if Game.needs.get("bend", true):
		var bend := _key("Пробел", Game.fretboard.bending, cue.get("bend", false))
		bend["w"] = KEY_SIZE.x * 2.2
		groups.append({"caption": "тяни", "keys": [bend]})
	if Game.needs.get("positions", true):
		groups.append(_hand_group())
	return groups


func _struck() -> bool:
	return Notes.STRINGS.any(func(string: String) -> bool: return strikes.flash(string) > 0.0)


func _hand_group() -> Dictionary:
	var shift := Cue.shift()
	var keys: Array[Dictionary] = []
	for dir: int in [-1, 1]:
		var cued: bool = shift.get("dir", 0) == dir
		var key := _key(InputConfig.key_label("position_up" if dir > 0 else "position_down"), false, cued)
		key["times"] = int(shift.get("steps", 0)) if cued else 0
		keys.append(key)
	return {"caption": "рука · поз %d" % (Game.tuning.position + 1), "keys": keys, "ink": Ink.of_position(Game.tuning.position)}


static func _key(label: String, on: bool, cued: bool) -> Dictionary:
	return {"label": label, "on": on, "cued": cued, "w": KEY_SIZE.x}


func _draw_groups(groups: Array[Dictionary]) -> void:
	var widths: Array[float] = []
	var total := GROUP_GAP * (groups.size() - 1)
	for group: Dictionary in groups:
		widths.append(_group_width(group))
		total += widths.back()
	var x := (Layout.SCREEN.x - total) * 0.5
	var pulse := Cue.glow(Cue.next(), t)
	for g in groups.size():
		var start := x
		for key: Dictionary in groups[g]["keys"]:
			_draw_key(key, Rect2(x, Layout.CONTROLS_Y, float(key["w"]), KEY_SIZE.y), pulse)
			x += float(key["w"]) + KEY_GAP
		var caption_y := Layout.CONTROLS_Y + KEY_SIZE.y + 24
		Glyph.text_center(self, start + widths[g] * 0.5, caption_y, String(groups[g]["caption"]), 16, groups[g].get("ink", Ink.DIM))
		x += GROUP_GAP - KEY_GAP


static func _group_width(group: Dictionary) -> float:
	var width := -KEY_GAP
	for key: Dictionary in group["keys"]:
		width += float(key["w"]) + KEY_GAP
	return width


func _draw_key(key: Dictionary, cell: Rect2, pulse: float) -> void:
	var glow := Cue.blink(t) if int(key.get("times", 0)) > 0 else pulse
	var fill := KEY_FILL.lerp(Ink.GOLD.darkened(0.35), glow) if key["cued"] else KEY_FILL
	draw_rect(cell, KEY_ON if key["on"] else fill)
	draw_rect(cell, Ink.GOLD if key["cued"] else key.get("edge", KEY_EDGE), false, 4.0 if key["cued"] else 2.0)
	var label := String(key["label"])
	Glyph.title_center(self, cell.get_center().x, cell.get_center().y + 10, label, 26 if label.length() == 1 else 18,
		KEY_INK_ON if key["on"] else Color.WHITE)
	if int(key.get("times", 0)) > 1:
		Glyph.title_center(self, cell.get_center().x, cell.position.y - 8, "×%d" % int(key["times"]), 20, Ink.GOLD)


func _draw_hint() -> void:
	var key := Game.state + ("+" if Game.more and HINTS.has(Game.state + "+") else "")
	Glyph.text_center(self, 640, Layout.HINT_Y, String(HINTS.get(key, "")), 17, Ink.DIM)
