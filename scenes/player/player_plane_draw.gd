extends Node2D

@export var plane_color: Color = Color(0.28, 0.38, 0.28)
@export var accent_color: Color = Color(0.22, 0.32, 0.22)

var parent_plane: CharacterBody2D


func _ready() -> void:
	parent_plane = get_parent() as CharacterBody2D


func _draw() -> void:
	# === EXHAUST TRAIL ===
	if parent_plane and parent_plane.exhaust_particles.size() > 0:
		for p in parent_plane.exhaust_particles:
			var local_pos: Vector2 = p["pos"] - parent_plane.global_position
			var alpha: float = p["life"] / p["max_life"] * 0.4
			var s: float = p["size"] * (1.0 - p["life"] / p["max_life"])
			_draw_circle_safe(local_pos, s, Color(0.6, 0.6, 0.6, alpha))

	# === CROSSHAIR (bomb landing prediction) ===
	if parent_plane:
		var ch: Vector2 = parent_plane.crosshair_pos - parent_plane.global_position
		# Rotate crosshair to counter plane rotation
		ch = ch.rotated(-rotation)
		var ch_alpha: float = 0.4 + sin(Time.get_ticks_msec() * 0.005) * 0.15
		# Dotted circle
		for i in range(12):
			var a: float = float(i) / 12.0 * TAU
			var dot_pos: Vector2 = ch + Vector2(cos(a) * 12, sin(a) * 12)
			draw_rect(Rect2(dot_pos.x - 1, dot_pos.y - 1, 2, 2), Color(1, 0.3, 0.1, ch_alpha))
		# Cross
		draw_line(ch + Vector2(-6, 0), ch + Vector2(6, 0), Color(1, 0.3, 0.1, ch_alpha), 1.0)
		draw_line(ch + Vector2(0, -6), ch + Vector2(0, 6), Color(1, 0.3, 0.1, ch_alpha), 1.0)

	# === CONTRAILS (wing tips) ===
	if parent_plane:
		var speed_factor: float = absf(parent_plane.velocity.x) / 400.0
		if speed_factor > 0.3:
			var trail_alpha: float = minf(speed_factor * 0.2, 0.3)
			for i in range(5):
				var offset: float = float(i) * 8
				# Left wing trail
				_draw_circle_safe(Vector2(-15 - offset, -25 + i * 1), 2.0 + float(i) * 0.5, Color(1, 1, 1, trail_alpha * (1.0 - float(i) / 5.0)))
				# Right wing trail
				_draw_circle_safe(Vector2(-15 - offset, 25 - i * 1), 2.0 + float(i) * 0.5, Color(1, 1, 1, trail_alpha * (1.0 - float(i) / 5.0)))

	# === TAIL FIN ===
	draw_colored_polygon(PackedVector2Array([
		Vector2(-35, -2), Vector2(-42, -20), Vector2(-28, -2),
	]), accent_color.darkened(0.1))
	# Tail stabilizers
	draw_colored_polygon(PackedVector2Array([
		Vector2(-33, 0), Vector2(-40, 4), Vector2(-28, 0)
	]), accent_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-33, 0), Vector2(-40, -4), Vector2(-28, 0)
	]), accent_color)

	# === FUSELAGE ===
	_draw_ellipse(Vector2.ZERO, 38.0, 10.0, plane_color)
	_draw_ellipse(Vector2(0, 2), 32.0, 5.0, plane_color.lightened(0.15))

	# === WINGS ===
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -3), Vector2(5, -3), Vector2(-15, -28), Vector2(-20, -28),
	]), accent_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, 3), Vector2(5, 3), Vector2(-15, 28), Vector2(-20, 28),
	]), accent_color.darkened(0.05))
	draw_line(Vector2(-8, -15), Vector2(2, -15), Color(0.7, 0.7, 0.7), 1.0)
	draw_line(Vector2(-8, 15), Vector2(2, 15), Color(0.6, 0.6, 0.6), 1.0)

	# === COCKPIT ===
	_draw_ellipse(Vector2(12, -5), 10.0, 7.0, Color(0.4, 0.6, 0.85, 0.9))
	draw_arc(Vector2(14, -7), 5.0, PI * 0.8, PI * 1.6, 8, Color(1, 1, 1, 0.4), 1.5)
	# Pilot silhouette
	_draw_circle_safe(Vector2(10, -6), 3.5, Color(0.2, 0.25, 0.2, 0.5))
	_draw_circle_safe(Vector2(10, -3), 2.5, Color(0.2, 0.25, 0.2, 0.4))

	# === ENGINE + GLOW ===
	_draw_ellipse(Vector2(34, 0), 8.0, 8.0, Color(0.35, 0.35, 0.35))
	# Engine heat glow
	_draw_circle_safe(Vector2(36, 0), 10.0, Color(1.0, 0.5, 0.1, 0.08))
	_draw_circle_safe(Vector2(36, 0), 6.0, Color(1.0, 0.6, 0.2, 0.12))

	# === PROPELLER ===
	if parent_plane:
		var angle: float = parent_plane.propeller_angle
		var prop_center := Vector2(40, 0)
		_draw_circle_safe(prop_center, 12.0, Color(0.7, 0.7, 0.7, 0.15))
		var b1_end: Vector2 = prop_center + Vector2(cos(angle) * 2, sin(angle) * 14)
		draw_line(prop_center, b1_end, Color(0.3, 0.3, 0.3), 3.0)
		var b2_end: Vector2 = prop_center + Vector2(cos(angle + PI) * 2, sin(angle + PI) * 14)
		draw_line(prop_center, b2_end, Color(0.3, 0.3, 0.3), 3.0)
		_draw_circle_safe(prop_center, 3.0, Color(0.4, 0.4, 0.4))

	# === STAR MARKING ===
	_draw_star(Vector2(-5, 0), 5.0, Color(1, 1, 1, 0.5))

	# === NOSE ===
	_draw_ellipse(Vector2(36, 0), 4.0, 7.0, Color(0.3, 0.3, 0.3))

	# === SHIELD EFFECT ===
	if GameState.has_shield:
		var shield_alpha: float = 0.2 + sin(Time.get_ticks_msec() * 0.008) * 0.1
		_draw_circle_safe(Vector2.ZERO, 45.0, Color(0.2, 0.5, 1.0, shield_alpha))
		# Shield border
		draw_arc(Vector2.ZERO, 45.0, 0, TAU, 24, Color(0.3, 0.6, 1.0, shield_alpha + 0.15), 2.0)

	# === POWER-UP INDICATORS ===
	if GameState.has_rapid_fire:
		_draw_circle_safe(Vector2(0, 15), 3.0, Color(1, 0.8, 0.1, 0.6))
	if GameState.has_mega_bomb:
		_draw_circle_safe(Vector2(0, -15), 3.0, Color(1, 0.2, 0.1, 0.6))


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	var segments := 20
	for i in range(segments + 1):
		var angle: float = float(i) / float(segments) * TAU
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)


func _draw_star(center: Vector2, sz: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var angle: float = float(i) / 10.0 * TAU - PI / 2.0
		var r: float = sz if i % 2 == 0 else sz * 0.4
		points.append(center + Vector2(cos(angle) * r, sin(angle) * r))
	draw_colored_polygon(points, color)


func _draw_circle_safe(pos: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var points := PackedVector2Array()
	var segs: int = 16
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(pos + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
