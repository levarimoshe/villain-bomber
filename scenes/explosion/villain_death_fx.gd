extends Node2D
## Dramatic death effect when a villain is killed

var elapsed: float = 0.0
var duration: float = 0.8
var particles: Array = []
var stars: Array = []
var flash_radius: float = 0.0


func _ready() -> void:
	# Blood/debris burst
	for i in range(16):
		var angle: float = randf() * TAU
		var speed: float = randf_range(80.0, 250.0)
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed - 60.0),
			"life": randf_range(0.3, 0.7),
			"max_life": 0.7,
			"size": randf_range(2.5, 6.0),
			"color": [
				Color(1.0, 0.3, 0.0),
				Color(1.0, 0.6, 0.0),
				Color(0.9, 0.15, 0.0),
				Color(1.0, 0.9, 0.2),
				Color(0.4, 0.35, 0.25),
			][randi() % 5],
		})

	# Star/sparkle effects
	for i in range(6):
		var angle: float = randf() * TAU
		var dist: float = randf_range(15.0, 40.0)
		stars.append({
			"pos": Vector2(cos(angle) * dist, sin(angle) * dist - 10),
			"size": randf_range(4.0, 8.0),
			"life": randf_range(0.2, 0.5),
			"max_life": 0.5,
			"rotation": randf() * TAU,
		})

	var timer := Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()


func _process(delta: float) -> void:
	elapsed += delta

	for p in particles:
		p["vel"].y += 300.0 * delta
		p["pos"] += p["vel"] * delta
		p["life"] -= delta

	for s in stars:
		s["life"] -= delta
		s["rotation"] += delta * 5.0

	queue_redraw()


func _draw() -> void:
	var t: float = elapsed / duration

	# === BRIGHT FLASH ===
	if t < 0.15:
		var flash_t: float = t / 0.15
		var radius: float = 40.0 * flash_t
		var alpha: float = (1.0 - flash_t) * 0.9
		_draw_glow(Vector2.ZERO, radius, Color(1, 0.9, 0.3, alpha))
		_draw_glow(Vector2.ZERO, radius * 0.5, Color(1, 1, 0.8, alpha))

	# === EXPANDING RED RING ===
	if t < 0.3:
		var ring_t: float = t / 0.3
		var ring_r: float = 50.0 * ring_t
		var ring_alpha: float = (1.0 - ring_t) * 0.6
		draw_arc(Vector2.ZERO, ring_r, 0, TAU, 20, Color(1, 0.3, 0.0, ring_alpha), 3.0)

	# === PARTICLES ===
	for p in particles:
		if p["life"] > 0:
			var life_ratio: float = clampf(p["life"] / p["max_life"], 0.0, 1.0)
			var c: Color = p["color"]
			c.a = life_ratio
			var sz: float = p["size"] * life_ratio
			# Glowing particle
			_draw_glow(p["pos"], sz * 1.5, Color(c.r, c.g, c.b, c.a * 0.3))
			draw_rect(Rect2(p["pos"] - Vector2(sz, sz) / 2.0, Vector2(sz, sz)), c)

	# === STARS / SPARKLES ===
	for s in stars:
		if s["life"] > 0:
			var life_ratio: float = clampf(s["life"] / s["max_life"], 0.0, 1.0)
			var sz: float = s["size"] * life_ratio
			var rot: float = s["rotation"]
			_draw_star(s["pos"], sz, rot, Color(1, 1, 0.5, life_ratio))

	# === IMPACT TEXT EFFECT ===
	if t < 0.4:
		var text_alpha: float = (1.0 - t / 0.4)
		var font: Font = ThemeDB.fallback_font
		var impact_y: float = -20 - t * 30
		draw_string(font, Vector2(-15, impact_y), "BOOM!", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(1, 0.6, 0.1, text_alpha))


func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var points := PackedVector2Array()
	var segs: int = 12
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)


func _draw_star(center: Vector2, sz: float, rot: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(8):
		var angle: float = float(i) / 8.0 * TAU + rot
		var r: float = sz if i % 2 == 0 else sz * 0.3
		points.append(center + Vector2(cos(angle) * r, sin(angle) * r))
	draw_colored_polygon(points, color)
