extends Node2D
## Enemy bullet — bright red/orange tracer with thick glowing trail

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 5.0
var trail_points: Array = []
var hit_radius: float = 20.0
var glow_time: float = 0.0


func _ready() -> void:
	add_to_group(&"bullet")


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	position += velocity * delta
	velocity.y += 40.0 * delta
	lifetime -= delta
	glow_time += delta

	# Store trail
	trail_points.append(Vector2(global_position.x, global_position.y))
	if trail_points.size() > 18:
		trail_points.remove_at(0)

	# Check distance to player
	var player_node: Node = get_tree().get_first_node_in_group(&"player")
	if player_node:
		var dist: float = global_position.distance_to(player_node.global_position)
		if dist < hit_radius:
			Events.player_hit.emit()
			SoundManager.play_hit()
			queue_free()
			return

	queue_redraw()

	if lifetime <= 0 or global_position.y < -200 or global_position.y > 900:
		queue_free()


func _draw() -> void:
	var pulse: float = 0.7 + 0.3 * sin(glow_time * 15.0)

	# === THICK GLOWING TRAIL ===
	if trail_points.size() > 1:
		for i in range(trail_points.size() - 1):
			var from_local: Vector2 = trail_points[i] - global_position
			var to_local: Vector2 = trail_points[i + 1] - global_position
			var t: float = float(i) / float(trail_points.size())
			# Outer glow trail (wide, faint)
			draw_line(from_local, to_local, Color(1.0, 0.2, 0.0, t * 0.25), 6.0 * t)
			# Inner bright trail
			draw_line(from_local, to_local, Color(1.0, 0.5, 0.1, t * 0.6), 3.0 * t)
			# Core white trail
			draw_line(from_local, to_local, Color(1.0, 0.9, 0.5, t * 0.4), 1.5 * t)

	# === BULLET HEAD — large glowing ball ===
	# Outer red glow
	_draw_glow(Vector2.ZERO, 14.0 * pulse, Color(1.0, 0.15, 0.0, 0.2))
	# Mid orange glow
	_draw_glow(Vector2.ZERO, 9.0 * pulse, Color(1.0, 0.35, 0.05, 0.45))
	# Inner bright
	_draw_glow(Vector2.ZERO, 5.0, Color(1.0, 0.6, 0.15, 0.85))
	# Hot core
	_draw_glow(Vector2.ZERO, 2.5, Color(1.0, 1.0, 0.7, 1.0))


func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var points := PackedVector2Array()
	var segs: int = 12
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
