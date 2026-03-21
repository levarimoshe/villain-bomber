extends Node2D

var parent_bomb: Area2D


func _ready() -> void:
	parent_bomb = get_parent() as Area2D


func _draw() -> void:
	# === TRAIL ===
	if parent_bomb and parent_bomb.trail_points.size() > 1:
		for i in range(parent_bomb.trail_points.size() - 1):
			var from_world: Vector2 = parent_bomb.trail_points[i]
			var to_world: Vector2 = parent_bomb.trail_points[i + 1]
			# Convert to local space (undo rotation)
			var from_local: Vector2 = (from_world - parent_bomb.global_position).rotated(-parent_bomb.rotation)
			var to_local: Vector2 = (to_world - parent_bomb.global_position).rotated(-parent_bomb.rotation)
			var t: float = float(i) / float(parent_bomb.trail_points.size())
			var alpha: float = t * 0.5
			var width: float = 1.0 + t * 2.0
			draw_line(from_local, to_local, Color(1.0, 0.6, 0.1, alpha), width)

	# === BOMB BODY ===
	var body_color := Color(0.2, 0.2, 0.25)

	# Main body
	_draw_ellipse(Vector2.ZERO, 5.0, 7.0, body_color)

	# Highlight
	_draw_ellipse(Vector2(-1.5, -1), 2.0, 3.0, Color(0.5, 0.5, 0.55, 0.4))

	# Nose cone
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3.5, 5), Vector2(3.5, 5), Vector2(0, 13)
	]), body_color.lightened(0.05))

	# Tail fins
	draw_colored_polygon(PackedVector2Array([
		Vector2(-2, -6), Vector2(0, -6), Vector2(-7, -13), Vector2(-4, -7)
	]), Color(0.35, 0.35, 0.38))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -6), Vector2(2, -6), Vector2(7, -13), Vector2(4, -7)
	]), Color(0.35, 0.35, 0.38))
	# Center fin
	draw_colored_polygon(PackedVector2Array([
		Vector2(-1, -6), Vector2(1, -6), Vector2(0, -11)
	]), Color(0.3, 0.3, 0.35))

	# Fuse spark with flicker
	var spark_pos := Vector2(0, -7)
	var flicker: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
	# Glow
	_draw_ellipse(spark_pos, 4.0, 4.0, Color(1.0, 0.5, 0.0, flicker * 0.3))
	_draw_ellipse(spark_pos, 2.5, 2.5, Color(1.0, 0.7, 0.1, flicker * 0.6))
	_draw_ellipse(spark_pos, 1.2, 1.2, Color(1.0, 1.0, 0.5, flicker))

	# Red stripe on body
	draw_line(Vector2(-4, 1), Vector2(4, 1), Color(0.7, 0.1, 0.1, 0.6), 1.5)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	if rx < 0.5 or ry < 0.5:
		return
	var points := PackedVector2Array()
	for i in range(17):
		var angle: float = float(i) / 16.0 * TAU
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)
