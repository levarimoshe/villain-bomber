extends Node2D

const WIDTH: float = 1280.0
const HEIGHT: float = 720.0


func _draw() -> void:
	# Draw sky as smooth gradient using thick rectangles instead of lines
	var steps := 80
	var band_h := HEIGHT / float(steps)
	for i in range(steps):
		var t := float(i) / float(steps)
		var color: Color
		if t < 0.3:
			# Deep blue to mid blue
			var lt: float = t / 0.3
			color = Color(0.1, 0.15, 0.45).lerp(Color(0.3, 0.5, 0.78), lt)
		elif t < 0.65:
			# Mid blue to light blue
			var lt: float = (t - 0.3) / 0.35
			color = Color(0.3, 0.5, 0.78).lerp(Color(0.55, 0.78, 0.92), lt)
		else:
			# Light blue to warm horizon
			var lt: float = (t - 0.65) / 0.35
			color = Color(0.55, 0.78, 0.92).lerp(Color(0.9, 0.8, 0.6), lt)
		draw_rect(Rect2(0, i * band_h, WIDTH, band_h + 1), color)

	# Sun with glow layers
	var sun_pos := Vector2(WIDTH * 0.82, HEIGHT * 0.18)
	# Outer glow
	for r in range(80, 0, -3):
		var alpha: float = 0.015 * (1.0 - float(r) / 80.0)
		_draw_circle_safe(sun_pos, float(r), Color(1.0, 0.9, 0.4, alpha))
	# Sun body
	_draw_circle_safe(sun_pos, 25.0, Color(1.0, 0.98, 0.85, 0.9))
	_draw_circle_safe(sun_pos, 18.0, Color(1.0, 1.0, 0.95, 0.95))

	# Sun rays
	for i in range(12):
		var angle: float = float(i) / 12.0 * TAU
		var ray_start: Vector2 = sun_pos + Vector2(cos(angle), sin(angle)) * 28.0
		var ray_end: Vector2 = sun_pos + Vector2(cos(angle), sin(angle)) * (45.0 + sin(angle * 3.0) * 10.0)
		draw_line(ray_start, ray_end, Color(1.0, 0.95, 0.6, 0.15), 2.0)


func _draw_circle_safe(pos: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var points := PackedVector2Array()
	var segs := 24
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(pos + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
