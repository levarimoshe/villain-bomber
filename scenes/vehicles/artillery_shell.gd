extends Node2D
## Artillery shell — arcs through the air, big explosion on impact

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 5.0
var trail_points: Array = []


func _ready() -> void:
	add_to_group(&"bullet")  # Damages player on contact


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	velocity.y += 250 * delta  # Gravity arc
	position += velocity * delta
	rotation = velocity.angle()
	lifetime -= delta

	trail_points.append(Vector2(global_position.x, global_position.y))
	if trail_points.size() > 12:
		trail_points.remove_at(0)

	# Check player hit
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player and global_position.distance_to(player.global_position) < 30:
		Events.player_hit.emit()
		SoundManager.play_hit()
		Events.bomb_hit_ground.emit(global_position, 1.5, false)
		queue_free()
		return

	# Ground impact
	if global_position.y > 570:
		Events.bomb_hit_ground.emit(global_position, 1.5, false)
		queue_free()
		return

	queue_redraw()
	if lifetime <= 0:
		queue_free()


func _draw() -> void:
	# Trail
	for i in range(trail_points.size() - 1):
		var from_l: Vector2 = trail_points[i] - global_position
		var to_l: Vector2 = trail_points[i + 1] - global_position
		var t: float = float(i) / float(trail_points.size())
		draw_line(from_l, to_l, Color(0.5, 0.4, 0.2, t * 0.4), 2.0)

	# Shell body
	draw_rect(Rect2(-3, -6, 6, 12), Color(0.4, 0.35, 0.2))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3, 6), Vector2(3, 6), Vector2(0, 10)
	]), Color(0.5, 0.4, 0.25))
	# Glow
	draw_circle(Vector2(0, -5), 4, Color(1, 0.5, 0.1, 0.3))
