extends Node2D

const WIDTH: float = 2560.0
const HEIGHT: float = 720.0

var rain_drops: Array = []
var lightning_timer: float = 0.0
var lightning_flash: float = 0.0
var time: float = 0.0


func _process(delta: float) -> void:
	time += delta
	var level: int = GameState.current_level

	# Rain (level 7+)
	if level >= 7:
		var rain_count: int = 8 if level < 10 else 15
		for i in range(rain_count):
			rain_drops.append({
				"x": randf_range(0, WIDTH),
				"y": randf_range(-20, 0),
				"speed": randf_range(400, 600),
				"length": randf_range(8, 18),
			})
		# Update existing drops
		var idx: int = 0
		while idx < rain_drops.size():
			rain_drops[idx]["y"] += rain_drops[idx]["speed"] * delta
			if rain_drops[idx]["y"] > HEIGHT:
				rain_drops.remove_at(idx)
			else:
				idx += 1
		while rain_drops.size() > 200:
			rain_drops.remove_at(0)

	# Lightning (level 10+)
	if level >= 10:
		lightning_timer -= delta
		if lightning_timer <= 0:
			lightning_timer = randf_range(2.0, 6.0)
			lightning_flash = 0.3

	if lightning_flash > 0:
		lightning_flash -= delta

	queue_redraw()


func _draw() -> void:
	var level: int = GameState.current_level

	# Darkness factor based on level
	var dark: float = 0.0
	if level >= 4:
		dark = minf(float(level - 3) * 0.08, 0.45)

	# Sky gradient using biome colors
	var sky_top: Color = BiomeManager.get_sky_top()
	var sky_mid: Color = BiomeManager.get_sky_mid()
	var sky_bottom: Color = BiomeManager.get_sky_bottom()

	var steps := 100
	var band_h := HEIGHT / float(steps)
	for i in range(steps):
		var t := float(i) / float(steps)
		var color: Color
		if t < 0.4:
			color = sky_top.lerp(sky_mid, t / 0.4)
		else:
			color = sky_mid.lerp(sky_bottom, (t - 0.4) / 0.6)
		# Darken for weather
		color = color.darkened(dark)
		draw_rect(Rect2(0, i * band_h, WIDTH, band_h + 1), color)

	# Lightning flash overlay
	if lightning_flash > 0:
		var flash_alpha: float = lightning_flash / 0.3 * 0.4
		draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color(1, 1, 0.95, flash_alpha))

	# Sun (hidden in storm)
	if level < 7:
		var sun_alpha: float = 1.0 - dark * 1.5
		var sun_pos := Vector2(WIDTH * 0.82, HEIGHT * 0.18)
		for r in range(80, 0, -3):
			var alpha: float = 0.015 * (1.0 - float(r) / 80.0) * sun_alpha
			_draw_circle_safe(sun_pos, float(r), Color(1.0, 0.9, 0.4, alpha))
		_draw_circle_safe(sun_pos, 25.0, Color(1.0, 0.98, 0.85, 0.9 * sun_alpha))
		_draw_circle_safe(sun_pos, 18.0, Color(1.0, 1.0, 0.95, 0.95 * sun_alpha))
		for ray_i in range(12):
			var angle: float = float(ray_i) / 12.0 * TAU
			var ray_start: Vector2 = sun_pos + Vector2(cos(angle), sin(angle)) * 28.0
			var ray_end: Vector2 = sun_pos + Vector2(cos(angle), sin(angle)) * 45.0
			draw_line(ray_start, ray_end, Color(1.0, 0.95, 0.6, 0.15 * sun_alpha), 2.0)

	# Rain drops
	if level >= 7:
		var rain_alpha: float = 0.3 if level < 10 else 0.5
		for drop in rain_drops:
			var dx: float = drop["x"]
			var dy: float = drop["y"]
			var dl: float = drop["length"]
			draw_line(Vector2(dx, dy), Vector2(dx - 2, dy + dl), Color(0.7, 0.75, 0.85, rain_alpha), 1.0)

	# Lightning bolt (level 10+)
	if lightning_flash > 0.15 and level >= 10:
		var lx: float = randf_range(WIDTH * 0.2, WIDTH * 0.8)
		var points: Array = [Vector2(lx, 0)]
		var ly: float = 0.0
		while ly < HEIGHT * 0.7:
			ly += randf_range(30, 60)
			lx += randf_range(-30, 30)
			points.append(Vector2(lx, ly))
		for p_i in range(points.size() - 1):
			draw_line(points[p_i], points[p_i + 1], Color(1, 1, 0.9, 0.9), 3.0)
			draw_line(points[p_i], points[p_i + 1], Color(0.7, 0.8, 1.0, 0.4), 8.0)


func _draw_circle_safe(pos: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var points := PackedVector2Array()
	var segs := 24
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(pos + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
