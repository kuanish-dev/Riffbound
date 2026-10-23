class_name Screenshot
extends RefCounted

const MENU_FRAMES := 30


static func take(main: Main) -> void:
	_quiet_and_fast()
	if DevArgs.has("autoplay"):
		main.add_child(Autoplay.new())
	_open_scene(main)
	var started := Time.get_ticks_msec()
	var frames: int = await _wait(main, float(DevArgs.get_str("at", "8")))
	await RenderingServer.frame_post_draw
	var path := DevArgs.get_str("screenshot")
	main.get_viewport().get_texture().get_image().save_png(path)
	print("[shot] %s (%s, %.1f с, счёт %d, %.0f fps)" % [path, Game.state, main.conductor.now(), main.performance.score,
		frames * 1000.0 / maxf(1.0, Time.get_ticks_msec() - started)])
	if Game.metronome:
		_report_metronome(main.conductor)
	main.quit()


static func _quiet_and_fast() -> void:
	Songs.persist = false
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 120


static func _open_scene(main: Main) -> void:
	if DevArgs.has("jam"):
		main.start_jam()
	elif DevArgs.has("shop"):
		main.open_shop()
		Game.shop_index = DevArgs.get_int("skin", Game.shop_index)
	elif DevArgs.has("menu"):
		TouchLists.reveal("menu")
	else:
		main.start_song()


static func _wait(main: Main, at: float) -> int:
	var gestures := Gestures.new(DevArgs.get_str("gesture", ""))
	var frames := 0
	while _waiting(main, at, frames):
		frames += 1
		gestures.tick(main.touch_pad, main.conductor.now())
		await main.get_tree().process_frame
	return frames


static func _waiting(main: Main, at: float, frames: int) -> bool:
	if Game.state in ["song", "jam"]:
		return main.conductor.now() < at
	return Game.state in ["menu", "shop"] and frames < MENU_FRAMES


static func _report_metronome(clock: Conductor) -> void:
	var drift := fposmod(clock.player.get_playback_position() - clock.loop_start, Timing.bar_len()) \
		- clock.click.get_playback_position()
	print("[shot] метроном: %s, расхождение с музыкой %.1f мс" % ["играет" if clock.click.playing else "молчит", drift * 1000.0])
