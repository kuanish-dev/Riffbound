class_name SceneBuilder
extends RefCounted


static func build(main: Main) -> void:
	_build_guitar(main)
	_build_views(main)
	_build_touch(main)
	main.music = MusicLoader.new(main.hud)
	main.jam = JamSession.new(main)
	main.shop = ShopScreen.new(main)
	main.common = CommonCommands.new(main)
	main.router = GuitarRouter.new(main.fretboard, main.hud)


static func _build_guitar(main: Main) -> void:
	var bank := SampleBank.new()
	bank.build()
	main.conductor = _add(main, Conductor.new())
	main.conductor.setup()
	main.fretboard = _add(main, Fretboard.new())
	main.fretboard.conductor = main.conductor
	main.voices = _add(main, GuitarVoices.new())
	main.voices.setup(bank)
	main.layers = _add(main, LayerVoices.new())
	main.layers.setup(bank)
	main.looper = Looper.new()
	main.performance = SongJudge.new()
	main.style = StyleMeter.new()
	_share_services(main)


static func _share_services(main: Main) -> void:
	Game.conductor = main.conductor
	Game.fretboard = main.fretboard
	Game.looper = main.looper
	Game.voices = main.voices
	Game.performance = main.performance
	Game.style = main.style
	Game.tuning = Tuning.song()


static func _build_views(main: Main) -> void:
	main.stage = _add(main, StageView.new())
	main.stage_fx = _add(main, FxLayer.new("stage"))
	main.style_view = _add(main, StyleView.new())
	main.hud = _add(main, Hud.new())
	main.fx = _add(main, FxLayer.new("top"))
	_add(main, CrtOverlay.new())
	main.shaker = _add(main, Shaker.new())
	main.feedback = _add(main, Feedback.new())
	main.feedback.setup(main.hud)


static func _build_touch(main: Main) -> void:
	if DevArgs.has("touch"):
		Input.emulate_touch_from_mouse = true
	Game.touch = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	main.touch_pad = _add(main, TouchPad.new())
	main.touch_pad.active = Game.touch
	Game.pad = main.touch_pad


static func _add(main: Main, node: Node) -> Node:
	main.add_child(node)
	return node
