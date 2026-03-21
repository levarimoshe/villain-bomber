extends Node2D

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 4.0
var trail_points: Array = []
var hit_radius: float = 18.0


func _ready() -> void:
	add_to_group(&"bullet")


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	position += velocity * delta
	velocity.y += 50.0 * delta  # slight gravity on bullets
	lifetime -= delta

	# Trail
	trail_points.append(Vector2(global_position.x, global_position.y))
	if trail_points.size() > 10:
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

	if lifetime <= 0 or global_position.y < -100 or global_position.y > 800:
		queue_free()


func _draw() -> void:
	# Bullet glow
	_draw_glow(Vector2.ZERO, 6.0, Color(1.0, 0.2, 0.05, 0.25))
	_draw_glow(Vector2.ZERO, 3.5, Color(1.0, 0.5, 0.1, 0.6))
	_draw_glow(Vector2.ZERO, 1.8, Color(1.0, 1.0, 0.5, 1.0))

	# Trail
	for i in range(trail_points.size() - 1):
		var from_local: Vector2 = trail_points[i] - global_position
		var to_local: Vector2 = trail_points[i + 1] - global_position
		var t: float = float(i) / float(trail_points.size())
		draw_line(from_local, to_local, Color(1.0, 0.3, 0.05, t * 0.5), 1.5 + t)


func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	var segs := 10
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
