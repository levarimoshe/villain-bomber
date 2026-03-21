extends Node2D

var elapsed: float = 0.0
var duration: float = 1.2
var max_radius: float = 60.0
var particles: Array = []
var smoke_puffs: Array = []
var sparks: Array = []


func _ready() -> void:
	# Debris particles
	for i in range(20):
		var angle: float = randf() * TAU
		var speed: float = randf_range(100.0, 300.0)
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed - 80.0),
			"life": randf_range(0.4, 0.9),
			"max_life": 0.9,
			"size": randf_range(2.0, 6.0),
			"color": [Color(1.0, 0.7, 0.1), Color(1.0, 0.5, 0.0), Color(1.0, 0.3, 0.0), Color(0.9, 0.9, 0.2)][randi() % 4],
		})

	# Smoke puffs (slower, bigger, darker)
	for i in range(8):
		var angle: float = randf() * TAU
		var speed: float = randf_range(20.0, 60.0)
		smoke_puffs.append({
			"pos": Vector2(randf_range(-10, 10), randf_range(-10, 5)),
			"vel": Vector2(cos(angle) * speed, -randf_range(30, 80)),
			"life": randf_range(0.6, 1.1),
			"max_life": 1.1,
			"size": randf_range(15.0, 35.0),
		})

	# Bright sparks
	for i in range(12):
		var angle: float = randf() * TAU
		var speed: float = randf_range(150.0, 400.0)
		sparks.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed - 100.0),
			"life": randf_range(0.15, 0.4),
			"max_life": 0.4,
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
		p["vel"].y += 350.0 * delta
		p["pos"] += p["vel"] * delta
		p["life"] -= delta

	for s in smoke_puffs:
		s["vel"] *= 0.97
		s["pos"] += s["vel"] * delta
		s["life"] -= delta
		s["size"] += 20.0 * delta

	for sp in sparks:
		sp["vel"].y += 500.0 * delta
		sp["pos"] += sp["vel"] * delta
		sp["life"] -= delta

	queue_redraw()


func _draw() -> void:
	var t: float = elapsed / duration

	# === SHOCKWAVE RING (first 15%) ===
	if t < 0.15:
		var ring_t: float = t / 0.15
		var ring_radius: float = max_radius * 2.0 * ring_t
		var ring_width: float = 4.0 * (1.0 - ring_t)
		var ring_alpha: float = (1.0 - ring_t) * 0.6
		draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 32, Color(1, 1, 0.8, ring_alpha), ring_width)

	# === BRIGHT FLASH (first 10%) ===
	if t < 0.1:
		var flash_t: float = t / 0.1
		var flash_radius: float = max_radius * 1.8 * flash_t
		var flash_alpha: float = (1.0 - flash_t) * 0.9
		_draw_glow(Vector2.ZERO, flash_radius, Color(1, 1, 0.9, flash_alpha))

	# === FIREBALL (0% to 50%) ===
	if t < 0.5:
		var fire_t: float = t / 0.5
		var radius: float = max_radius * ease(fire_t, 0.4)
		var alpha: float = (1.0 - fire_t) * 0.8

		# Multiple overlapping fire circles for organic look
		for i in range(5):
			var offset := Vector2(
				sin(float(i) * 1.3 + elapsed * 5.0) * radius * 0.2,
				cos(float(i) * 1.7 + elapsed * 4.0) * radius * 0.15
			)
			var r: float = radius * (0.5 + float(i) * 0.1)
			# Outer red
			_draw_glow(offset, r, Color(0.9, 0.15, 0.0, alpha * 0.4))
			# Inner orange
			_draw_glow(offset, r * 0.6, Color(1.0, 0.5, 0.0, alpha * 0.6))

		# Core yellow
		_draw_glow(Vector2.ZERO, radius * 0.35, Color(1.0, 0.95, 0.4, alpha))

	# === SMOKE (20% to 100%) ===
	for s in smoke_puffs:
		if s["life"] > 0:
			var life_ratio: float = clampf(s["life"] / s["max_life"], 0.0, 1.0)
			var smoke_alpha: float = life_ratio * 0.35
			var sz: float = s["size"]
			_draw_glow(s["pos"], sz, Color(0.25, 0.22, 0.2, smoke_alpha))

	# === DEBRIS PARTICLES ===
	for p in particles:
		if p["life"] > 0:
			var life_ratio: float = clampf(p["life"] / p["max_life"], 0.0, 1.0)
			var c: Color = p["color"]
			c.a = life_ratio
			var sz: float = p["size"] * life_ratio
			draw_rect(Rect2(p["pos"] - Vector2(sz, sz) / 2.0, Vector2(sz, sz)), c)
			# Glow on particles
			if life_ratio > 0.5:
				_draw_glow(p["pos"], sz * 2.0, Color(c.r, c.g, c.b, 0.15))

	# === SPARKS (bright streaks) ===
	for sp in sparks:
		if sp["life"] > 0:
			var life_ratio: float = clampf(sp["life"] / sp["max_life"], 0.0, 1.0)
			var vel: Vector2 = sp["vel"]
			var trail: Vector2 = vel.normalized() * 6.0
			draw_line(sp["pos"], sp["pos"] - trail, Color(1, 1, 0.8, life_ratio), 1.5)
			draw_line(sp["pos"], sp["pos"] - trail * 0.5, Color(1, 1, 1, life_ratio * 0.8), 2.5)


func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	if radius < 1.0:
		return
	var points := PackedVector2Array()
	var segs := 16
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
