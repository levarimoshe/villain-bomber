extends Node2D

var clouds: Array = []
var birds: Array = []
var bird_time: float = 0.0
const TILE_WIDTH: int = 2560


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777
	for i in range(12):
		var cloud: Dictionary = {
			"x": rng.randf_range(0, TILE_WIDTH),
			"y": rng.randf_range(40, 250),
			"puffs": [] as Array,
		}
		var num_puffs: int = rng.randi_range(3, 6)
		for p in range(num_puffs):
			cloud["puffs"].append({
				"ox": rng.randf_range(-30, 30),
				"oy": rng.randf_range(-10, 8),
				"rx": rng.randf_range(20, 45),
				"ry": rng.randf_range(14, 25),
			})
		clouds.append(cloud)

	# Create bird flocks
	for i in range(6):
		var flock: Dictionary = {
			"x": rng.randf_range(0, TILE_WIDTH),
			"y": rng.randf_range(60, 200),
			"count": rng.randi_range(3, 6),
			"speed": rng.randf_range(15, 35),
			"offsets": [] as Array,
		}
		for b in range(flock["count"]):
			flock["offsets"].append({
				"dx": rng.randf_range(-25, 25),
				"dy": rng.randf_range(-12, 12),
			})
		birds.append(flock)


func _process(delta: float) -> void:
	bird_time += delta
	# Move bird flocks
	for flock in birds:
		flock["x"] = fmod(flock["x"] + flock["speed"] * delta, float(TILE_WIDTH))
	queue_redraw()


func _draw() -> void:
	# Clouds
	for cloud in clouds:
		var cx: float = cloud["x"]
		var cy: float = cloud["y"]
		for puff in cloud["puffs"]:
			var pos := Vector2(cx + puff["ox"], cy + puff["oy"] + 5)
			_draw_ellipse(pos, puff["rx"], puff["ry"], Color(0, 0, 0, 0.05))
		for puff in cloud["puffs"]:
			var pos := Vector2(cx + puff["ox"], cy + puff["oy"])
			_draw_ellipse(pos, puff["rx"], puff["ry"], Color(1, 1, 1, 0.85))

	# Birds
	for flock in birds:
		var fx: float = flock["x"]
		var fy: float = flock["y"]
		for bird_data in flock["offsets"]:
			var bx: float = fx + bird_data["dx"]
			var by: float = fy + bird_data["dy"]
			var wing_flap: float = sin(bird_time * 6.0 + bx * 0.1) * 3.0
			# Draw bird as V shape
			draw_line(Vector2(bx - 4, by + wing_flap), Vector2(bx, by), Color(0.15, 0.15, 0.15, 0.7), 1.5)
			draw_line(Vector2(bx, by), Vector2(bx + 4, by + wing_flap), Color(0.15, 0.15, 0.15, 0.7), 1.5)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	var segments: int = 16
	for i in range(segments + 1):
		var angle: float = float(i) / float(segments) * TAU
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)
