extends Node2D
## Lingering fire/flames on the ground after bomb explosion

var elapsed: float = 0.0
var duration: float = 3.5
var flames: Array = []
var embers: Array = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	# Create flame sources
	for i in range(8):
		flames.append({
			"x": rng.randf_range(-30, 30),
			"base_h": rng.randf_range(15, 35),
			"speed": rng.randf_range(3.0, 6.0),
			"phase": rng.randf() * TAU,
			"width": rng.randf_range(8, 16),
		})
	# Create floating embers
	for i in range(12):
		embers.append({
			"pos": Vector2(rng.randf_range(-25, 25), rng.randf_range(-5, 5)),
			"vel": Vector2(rng.randf_range(-15, 15), rng.randf_range(-40, -80)),
			"life": rng.randf_range(0.5, 1.5),
			"max_life": 1.5,
			"size": rng.randf_range(1.0, 3.0),
		})

	var timer := Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()


func _process(delta: float) -> void:
	elapsed += delta
	# Update embers
	for e in embers:
		e["vel"].x += randf_range(-20, 20) * delta
		e["pos"] += e["vel"] * delta
		e["life"] -= delta
	queue_redraw()


func _draw() -> void:
	var life_ratio: float = 1.0 - elapsed / duration
	if life_ratio <= 0:
		return

	# === GROUND SCORCH MARK ===
	_draw_ellipse_safe(Vector2.ZERO, 35.0, 8.0, Color(0.1, 0.08, 0.05, 0.5 * life_ratio))

	# === FLAMES ===
	for f in flames:
		var h: float = f["base_h"] * life_ratio
		var flicker: float = sin(elapsed * f["speed"] + f["phase"])
		var flame_h: float = h * (0.7 + flicker * 0.3)
		var w: float = f["width"] * life_ratio
		var fx: float = f["x"]

		if flame_h < 2.0:
			continue

		# Outer flame (red-orange)
		var outer_alpha: float = 0.5 * life_ratio
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx - w / 2, 0),
			Vector2(fx - w / 4 + flicker * 2, -flame_h * 0.6),
			Vector2(fx + flicker * 3, -flame_h),
			Vector2(fx + w / 4 + flicker * 2, -flame_h * 0.6),
			Vector2(fx + w / 2, 0),
		]), Color(0.9, 0.25, 0.0, outer_alpha))

		# Inner flame (yellow-white)
		var inner_h: float = flame_h * 0.6
		var inner_w: float = w * 0.5
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx - inner_w / 2, 0),
			Vector2(fx + flicker * 2, -inner_h),
			Vector2(fx + inner_w / 2, 0),
		]), Color(1.0, 0.8, 0.2, outer_alpha * 0.8))

		# Core (bright white)
		if flame_h > 8:
			draw_colored_polygon(PackedVector2Array([
				Vector2(fx - 2, 0),
				Vector2(fx + flicker, -inner_h * 0.5),
				Vector2(fx + 2, 0),
			]), Color(1.0, 1.0, 0.7, outer_alpha * 0.6))

	# === HEAT SHIMMER (glow above flames) ===
	var shimmer_alpha: float = 0.08 * life_ratio
	_draw_ellipse_safe(Vector2(0, -20 * life_ratio), 25.0 * life_ratio, 15.0 * life_ratio, Color(1, 0.5, 0, shimmer_alpha))

	# === FLOATING EMBERS ===
	for e in embers:
		if e["life"] > 0:
			var ea: float = clampf(e["life"] / e["max_life"], 0.0, 1.0) * life_ratio
			var es: float = e["size"] * ea
			draw_rect(Rect2(e["pos"].x - es / 2, e["pos"].y - es / 2, es, es), Color(1, 0.6, 0.1, ea))

	# === SMOKE WISPS ===
	for i in range(3):
		var smoke_t: float = fmod(elapsed * 0.6 + float(i) * 0.4, 2.0)
		var smoke_y: float = -10 - smoke_t * 30.0
		var smoke_x: float = sin(elapsed * 1.5 + float(i) * 2.0) * 10.0
		var smoke_a: float = (1.0 - smoke_t / 2.0) * 0.15 * life_ratio
		var smoke_r: float = 5.0 + smoke_t * 10.0
		_draw_ellipse_safe(Vector2(smoke_x, smoke_y), smoke_r, smoke_r * 0.7, Color(0.3, 0.3, 0.3, smoke_a))


func _draw_ellipse_safe(center: Vector2, rx: float, ry: float, color: Color) -> void:
	if rx < 0.5 or ry < 0.5:
		return
	var points := PackedVector2Array()
	var segs: int = 12
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(points, color)
