extends Node2D
## Guided missile — aggressively homes on nearest enemy

const SPEED: float = 350.0
const TURN_RATE: float = 5.0

var velocity: Vector2 = Vector2(0, 200)
var lifetime: float = 4.0
var trail_points: Array = []


func _ready() -> void:
	add_to_group(&"projectile")


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	# Find nearest target
	var target: Node2D = _find_target()
	if target:
		var to_target: Vector2 = (target.global_position - global_position).normalized()
		var current_dir: Vector2 = velocity.normalized()
		var new_dir: Vector2 = current_dir.lerp(to_target, TURN_RATE * delta).normalized()
		velocity = new_dir * SPEED
	else:
		velocity.y += 200 * delta  # Fall if no target

	position += velocity * delta
	rotation = velocity.angle() + PI / 2.0
	lifetime -= delta

	# Trail
	trail_points.append(Vector2(global_position.x, global_position.y))
	if trail_points.size() > 15:
		trail_points.remove_at(0)

	# Hit check
	for villain in get_tree().get_nodes_in_group(&"villains"):
		if is_instance_valid(villain) and villain.has_method("hit_by_bomb"):
			if villain.get("is_dying") == true:
				continue
			if global_position.distance_to(villain.global_position) < 25:
				villain.hit_by_bomb()
				Events.bomb_hit_ground.emit(global_position, 0.8, false)
				queue_free()
				return

	# Ground hit
	if global_position.y > 580:
		Events.bomb_hit_ground.emit(global_position, 1.0, false)
		queue_free()
		return

	queue_redraw()
	if lifetime <= 0:
		queue_free()


func _find_target() -> Node2D:
	var best: Node2D = null
	var best_dist: float = 500.0
	for v in get_tree().get_nodes_in_group(&"villains"):
		if not is_instance_valid(v) or v.get("is_dying") == true:
			continue
		var d: float = global_position.distance_to(v.global_position)
		if d < best_dist:
			best_dist = d
			best = v
	return best


func _draw() -> void:
	# Trail
	for i in range(trail_points.size() - 1):
		var from_l: Vector2 = (trail_points[i] - global_position).rotated(-rotation)
		var to_l: Vector2 = (trail_points[i + 1] - global_position).rotated(-rotation)
		var t: float = float(i) / float(trail_points.size())
		draw_line(from_l, to_l, Color(0.3, 0.8, 0.3, t * 0.5), 2.0 * t)

	# Missile body
	draw_rect(Rect2(-2.5, -8, 5, 16), Color(0.35, 0.6, 0.35))
	# Nose
	draw_colored_polygon(PackedVector2Array([
		Vector2(-2.5, 8), Vector2(2.5, 8), Vector2(0, 14)
	]), Color(0.5, 0.5, 0.5))
	# Fins
	draw_colored_polygon(PackedVector2Array([
		Vector2(-2, -8), Vector2(-6, -12), Vector2(-1, -6)
	]), Color(0.3, 0.5, 0.3))
	draw_colored_polygon(PackedVector2Array([
		Vector2(2, -8), Vector2(6, -12), Vector2(1, -6)
	]), Color(0.3, 0.5, 0.3))
	# Engine glow
	draw_circle(Vector2(0, -8), 3, Color(1, 0.6, 0.1, 0.5))
	draw_circle(Vector2(0, -8), 1.5, Color(1, 0.9, 0.3, 0.8))
