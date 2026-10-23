class_name Layout

const SCREEN := Vector2(1280, 720)
const TOP_H := 54.0
const STAGE := Rect2(0, 54, 1280, 198)
const GUITAR_POSES := {
	"song": {"at": Vector2(250, 160), "angle": -0.2, "size": 1.15},
	"jam": {"at": Vector2(110, 168), "angle": -0.28, "size": 0.62},
	"*": {"at": Vector2(380, 156), "angle": -0.14, "size": 1.25},
}
const SHOP_LIST := Rect2(20, 262, 600, 236)
const SHOP_PREVIEW := Rect2(640, 262, 620, 236)
const LISTS := {
	"menu": {"keys": {"rect": Rect2(20, 262, 1240, 236), "rows": 6, "row_h": 30.0, "gap": 3.0, "top": 32.0},
		"touch": {"rect": Rect2(20, 262, 1240, 270), "rows": 3, "row_h": 84.0, "gap": 9.0, "top": 0.0}},
	"shop": {"keys": {"rect": Rect2(20, 262, 600, 236), "rows": 6, "row_h": 30.0, "gap": 3.0, "top": 32.0},
		"touch": {"rect": Rect2(20, 262, 600, 236), "rows": 3, "row_h": 72.0, "gap": 10.0, "top": 0.0}},
}
const HIGHWAY := Rect2(20, 262, 1240, 236)
const HIGHWAY_TOUCH := Rect2(20, 262, 960, 236)
const LANE_GAP := 70.0
const HIT_X := 230.0
const SLOT_PX := 46.0
const CONTROLS_Y := 528.0
const MAP := Rect2(700, 62, 560, 182)
const LOOP_BAR := Rect2(700, 8, 380, 38)
const HINT_Y := 690.0
