extends Node2D

const TILE_WIDTH: int = 2560
const GROUND_BASE_Y: float = 580.0
const HILL_AMPLITUDE: float = 45.0
const HILL_AMPLITUDE2: float = 20.0


static func get_ground_y(world_x: float) -> float:
	return GROUND_BASE_Y - (sin(world_x * 0.005) * HILL_AMPLITUDE + sin(world_x * 0.013) * HILL_AMPLITUDE2)


func _draw() -> void:
	# Far background hills (misty, dark)
	_draw_hill_layer(TILE_WIDTH, GROUND_BASE_Y - 80.0, 70.0, 30.0, 0.003, 0.008,
		Color(0.18, 0.35, 0.15, 0.5))

	# Mid hills
	_draw_hill_layer(TILE_WIDTH, GROUND_BASE_Y - 30.0, 55.0, 22.0, 0.004, 0.011,
		Color(0.15, 0.42, 0.12))

	# Main ground hills
	_draw_hill_layer(TILE_WIDTH, GROUND_BASE_Y, HILL_AMPLITUDE, HILL_AMPLITUDE2, 0.005, 0.013,
		Color(0.22, 0.55, 0.15))

	# Lighter grass highlights on top
	_draw_hill_edge(TILE_WIDTH, GROUND_BASE_Y, HILL_AMPLITUDE, HILL_AMPLITUDE2, 0.005, 0.013,
		Color(0.3, 0.65, 0.2), 3.0)

	# Earth/dirt layer
	_draw_hill_layer(TILE_WIDTH, GROUND_BASE_Y + 15.0, HILL_AMPLITUDE * 0.7, HILL_AMPLITUDE2 * 0.7, 0.005, 0.013,
		Color(0.4, 0.28, 0.12))

	# Dark earth bottom
	draw_rect(Rect2(0, GROUND_BASE_Y + 50, TILE_WIDTH, 200), Color(0.25, 0.15, 0.07))

	# Grass blades
	_draw_grass_blades()

	# Small flowers/details
	_draw_flowers()


func _draw_hill_layer(w: int, base_y: float, amp1: float, amp2: float, freq1: float, freq2: float, color: Color) -> void:
	var points := PackedVector2Array()
	for x in range(0, w + 1, 4):
		var fx := float(x)
		var y: float = base_y - (sin(fx * freq1) * amp1 + sin(fx * freq2) * amp2)
		points.append(Vector2(fx, y))
	points.append(Vector2(float(w), 900.0))
	points.append(Vector2(0.0, 900.0))
	draw_colored_polygon(points, color)


func _draw_hill_edge(w: int, base_y: float, amp1: float, amp2: float, freq1: float, freq2: float, color: Color, thickness: float) -> void:
	var prev := Vector2.ZERO
	for x in range(0, w + 1, 6):
		var fx := float(x)
		var y: float = base_y - (sin(fx * freq1) * amp1 + sin(fx * freq2) * amp2)
		var current := Vector2(fx, y)
		if x > 0:
			draw_line(prev, current, color, thickness)
		prev = current


func _draw_grass_blades() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(0, TILE_WIDTH, 6):
		var x: float = float(i) + rng.randf_range(-2.0, 2.0)
		var y: float = get_ground_y(x)
		var blade_h: float = rng.randf_range(6.0, 14.0)
		var sway: float = rng.randf_range(-4.0, 4.0)
		var brightness: float = rng.randf_range(-0.08, 0.12)
		var green := Color(0.22 + brightness, 0.55 + brightness, 0.15 + brightness * 0.5)
		draw_line(Vector2(x, y), Vector2(x + sway, y - blade_h), green, 1.5)


func _draw_flowers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99999
	for i in range(30):
		var x: float = rng.randf_range(0, TILE_WIDTH)
		var y: float = get_ground_y(x) - 2.0
		var flower_color: Color = [
			Color(1, 0.3, 0.3),
			Color(1, 0.8, 0.2),
			Color(0.8, 0.3, 0.8),
			Color(1, 1, 0.4),
		][rng.randi() % 4]
		# Small flower dot
		draw_rect(Rect2(x - 1.5, y - 3, 3, 3), flower_color)
		draw_line(Vector2(x, y), Vector2(x, y - 2), Color(0.2, 0.45, 0.15), 1.0)
