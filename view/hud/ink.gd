class_name Ink
extends RefCounted

const GOLD := Color(1.0, 0.82, 0.3)
const RED := Color(1.0, 0.38, 0.35)
const PANEL := Color(0.075, 0.065, 0.11)
const DIM := Color(0.68, 0.66, 0.76)
const ROW := Color(0.12, 0.11, 0.17)
const ROW_SELECTED := Color(0.24, 0.22, 0.36)
const CHORD_TONE := Color(0.45, 0.85, 1.0)
const STAR_OFF := Color(0.3, 0.28, 0.36)
const POSITIONS := [Color(0.35, 0.9, 1.0), Color(0.75, 0.55, 1.0), Color(0.55, 1.0, 0.45), Color(1.0, 0.45, 0.8),
	Color(0.45, 0.6, 1.0), Color(0.4, 1.0, 0.8)]


static func of_position(position: int) -> Color:
	return POSITIONS[posmod(position, POSITIONS.size())]
