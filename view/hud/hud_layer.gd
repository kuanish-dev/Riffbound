class_name HudLayer
extends Node2D

var strikes: Strikes
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
