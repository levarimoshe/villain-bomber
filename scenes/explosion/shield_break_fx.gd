extends Node2D

var elapsed: float = 0.0
var duration: float = 0.6
var shards: Array = []


func _ready() -> void:
	for i in range(12):
		var angle: float = float(i) / 12.0 * TAU
		var speed: float = randf_range(100.0, 200.0)
		shards.append({
			"pos": Vector2(cos(angle) * 20, sin(angle) * 20),
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed),
			"size": randf_range(4.0, 10.0),
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
	for s in shards:
		s["pos"] += s["vel"] * delta
		s["vel"] *= 0.95
		s["rotation"] += delta * 8.0
	queue_redraw()


func _draw() -> void:
	var t: float = elapsed / duration
	var alpha: float = 1.0 - t

	# Blue expanding ring
	if t < 0.4:
		var ring_r: float = 60.0 * (t / 0.4)
		draw_arc(Vector2.ZERO, ring_r, 0, TAU, 24, Color(0.3, 0.6, 1.0, alpha * 0.6), 3.0)

	# Blue flash
	if t < 0.15:
		_draw_glow(Vector2.ZERO, 50.0 * (t / 0.15), Color(0.3, 0.6, 1.0, (1.0 - t / 0.15) * 0.5))

	# Flying shards
	for s in shards:
		var shard_alpha: float = alpha * 0.8
		var sz: float = s["size"] * alpha
		var rot: float = s["rotation"]
		var pts := PackedVector2Array()
		for i in range(4):
			var a: float = rot + float(i) * PI / 2.0
			pts.append(s["pos"] + Vector2(cos(a) * sz, sin(a) * sz * 0.5))
		draw_colored_polygon(pts, Color(0.4, 0.7, 1.0, shard_alpha))


func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var points := PackedVector2Array()
	var segs: int = 16
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
