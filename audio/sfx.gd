class_name Sfx
## Звуки стиля, собранные кодом: взлёт ранга — шумовой «вжух» вверх и звонкий удар, тем выше, чем выше ранг;
## падение — глухой удар вниз.

const RATE := 44100
const UP := {"seconds": 0.5, "sweep_from": 300.0, "sweep_to": 1400.0, "ping": 1600.0, "per_rank": 0.08, "gain": 0.55}
const DOWN := {"seconds": 0.35, "from": 180.0, "to": 55.0, "gain": 0.7}


## Взлёт на ранг rank (0…): частоты растут на per_rank за ранг.
static func rank_up(rank: int) -> AudioStreamWAV:
	var lift := 1.0 + float(UP["per_rank"]) * rank
	var out := PackedFloat32Array()
	out.resize(int(float(UP["seconds"]) * RATE))
	var phase := 0.0
	var ping := 0.0
	var prev := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = rank
	for i in out.size():
		var t := float(i) / RATE
		var k := t / float(UP["seconds"])
		phase += TAU * lerpf(float(UP["sweep_from"]), float(UP["sweep_to"]), k * k) * lift / RATE
		ping += TAU * float(UP["ping"]) * lift / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		var air := (noise - prev) * 0.5 * sin(PI * minf(k * 1.6, 1.0)) * (1.0 - k)
		prev = noise
		var sweep := sin(phase) * 0.35 * minf(t * 30.0, 1.0) * (1.0 - k)
		var hit := (sin(ping) + 0.5 * sin(ping * 1.5)) * exp(-maxf(0.0, t - 0.12) * 14.0) * (1.0 if t > 0.12 else 0.0)
		out[i] = (air * 0.6 + sweep + hit * 0.45) * float(UP["gain"])
	return Backing.to_wav(out)


static func rank_down() -> AudioStreamWAV:
	var out := PackedFloat32Array()
	out.resize(int(float(DOWN["seconds"]) * RATE))
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var k := t / float(DOWN["seconds"])
		phase += TAU * lerpf(float(DOWN["from"]), float(DOWN["to"]), k) / RATE
		out[i] = tanh(sin(phase) * 2.5) * exp(-t * 9.0) * float(DOWN["gain"])
	return Backing.to_wav(out)
