class_name ToneMeter
extends RefCounted

const LISTEN_MS := 3800


static func run(main: Main) -> void:
	Songs.persist = false
	AudioServer.set_bus_volume_db(0, -80.0)
	main.open_shop()
	for i in Shop.SKINS.size():
		Game.shop_index = i
		for frame in 3:
			await main.get_tree().process_frame
		var level: Vector2 = await _measure(main)
		var skin: Dictionary = Shop.SKINS[i]
		print("[tone] %-10s %-12s громкость %6.1f дБ, пик %6.1f дБ" % [skin["id"], skin["tone"]["name"], level.x, level.y])
	main.quit()


static func _measure(main: Main) -> Vector2:
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index(GuitarVoices.LEAD_BUS), capture)
	main.listen()
	var sum := 0.0
	var count := 0
	var peak := 0.0
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < LISTEN_MS:
		await main.get_tree().process_frame
		for frame: Vector2 in capture.get_buffer(capture.get_frames_available()):
			sum += frame.x * frame.x + frame.y * frame.y
			count += 2
			peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
	return Vector2(linear_to_db(sqrt(sum / maxi(count, 1))), linear_to_db(peak))
