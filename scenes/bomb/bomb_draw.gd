extends Node2D

var parent_bomb: Area2D


func _ready() -> void:
	parent_bomb = get_parent() as Area2D


func _draw() -> void:
	var is_nuke: bool = false
	if parent_bomb:
		is_nuke = parent_bomb.is_nuke

	# === NUKE GLOW (pulsing aura around the bomb) ===
	if is_nuke:
		var pulse: float = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.012)
		_draw_ellipse(Vector2.ZERO, 18.0 * pulse, 18.0 * pulse, Color(1.0, 0.2, 0.0, 0.15))
		_draw_ellipse(Vector2.ZERO, 12.0 * pulse, 12.0 * pulse, Color(1.0, 0.4, 0.0, 0.25))
		_draw_ellipse(Vector2.ZERO, 7.0 * pulse, 7.0 * pulse, Color(1.0, 0.7, 0.1, 0.35))

	# === TRAIL ===
	if parent_bomb and parent_bomb.trail_points.size() > 1:
		for i in range(parent_bomb.trail_points.size() - 1):
			var from_world: Vector2 = parent_bomb.trail_points[i]
			var to_world: Vector2 = parent_bomb.trail_points[i + 1]
			var from_local: Vector2 = (from_world - parent_bomb.global_position).rotated(-parent_bomb.rotation)
			var to_local: Vector2 = (to_world - parent_bomb.global_position).rotated(-parent_bomb.rotation)
			var t: float = float(i) / float(parent_bomb.trail_points.size())
			var alpha: float = t * 0.5
			var width: float = 1.0 + t * 2.0
			var trail_color := Color(1.0, 0.6, 0.1, alpha) if not is_nuke else Color(1.0, 0.2, 0.0, alpha * 1.3)
			draw_line(from_local, to_local, trail_color, width * (1.5 if is_nuke else 1.0))

	# === BOMB BODY ===
	var body_color := Color(0.2, 0.2, 0.25) if not is_nuke else Color(0.4, 0.12, 0.08)
	var sc: float = 1.0 if not is_nuke else 1.5

	_draw_ellipse(Vector2.ZERO, 5.0 * sc, 7.0 * sc, body_color)
	_draw_ellipse(Vector2(-1.5 * sc, -1 * sc), 2.0 * sc, 3.0 * sc, Color(0.5, 0.5, 0.55, 0.4))

	# Nose cone
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3.5 * sc, 5 * sc), Vector2(3.5 * sc, 5 * sc), Vector2(0, 13 * sc)
	]), body_color.lightened(0.05))

	# Tail fins
	draw_colored_polygon(PackedVector2Array([
		Vector2(-2 * sc, -6 * sc), Vector2(0, -6 * sc), Vector2(-7 * sc, -13 * sc), Vector2(-4 * sc, -7 * sc)
	]), Color(0.35, 0.35, 0.38))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -6 * sc), Vector2(2 * sc, -6 * sc), Vector2(7 * sc, -13 * sc), Vector2(4 * sc, -7 * sc)
	]), Color(0.35, 0.35, 0.38))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-1 * sc, -6 * sc), Vector2(1 * sc, -6 * sc), Vector2(0, -11 * sc)
	]), Color(0.3, 0.3, 0.35))

	# Fuse spark
	var spark_pos := Vector2(0, -7 * sc)
	var flicker: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
	_draw_ellipse(spark_pos, 4.0 * sc, 4.0 * sc, Color(1.0, 0.5, 0.0, flicker * 0.3))
	_draw_ellipse(spark_pos, 2.5 * sc, 2.5 * sc, Color(1.0, 0.7, 0.1, flicker * 0.6))
	_draw_ellipse(spark_pos, 1.2 * sc, 1.2 * sc, Color(1.0, 1.0, 0.5, flicker))

	# Stripe
	var stripe_color := Color(0.7, 0.1, 0.1, 0.6) if not is_nuke else Color(1.0, 0.8, 0.0, 0.8)
	draw_line(Vector2(-4 * sc, 1 * sc), Vector2(4 * sc, 1 * sc), stripe_color, 1.5 * sc)

	# Nuke symbol on body
	if is_nuke:
		# Radiation symbol (simplified)
		draw_line(Vector2(-3, -2), Vector2(3, -2), Color(1, 0.9, 0, 0.8), 1.5)
		draw_line(Vector2(0, -4), Vector2(0, 0), Color(1, 0.9, 0, 0.8), 1.5)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	if rx < 0.5 or ry < 0.5:
		return
	var points := PackedVector2Array()
	for i in range(17):
		var angle: float = float(i) / 16.0 * TAU
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)
