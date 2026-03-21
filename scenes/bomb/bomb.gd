extends Area2D

const GRAVITY: float = 420.0
const HOMING_STRENGTH: float = 4.5

var initial_velocity: Vector2 = Vector2.ZERO
var current_velocity: Vector2 = Vector2.ZERO
var trail_points: Array = []
var speed_scale: float = 1.0
var is_nuke: bool = false


func _ready() -> void:
	current_velocity = initial_velocity
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	current_velocity.y += GRAVITY * delta

	# Homing — aggressively steer toward nearest villain
	var nearest_villain: Node2D = _find_nearest_villain()
	if nearest_villain and current_velocity.y > 50:
		var to_villain: Vector2 = nearest_villain.global_position - global_position
		var desired_dir: Vector2 = to_villain.normalized()
		var current_dir: Vector2 = current_velocity.normalized()
		var steer: Vector2 = (desired_dir - current_dir) * HOMING_STRENGTH
		current_velocity += steer * current_velocity.length() * delta
		var horizontal_pull: float = (nearest_villain.global_position.x - global_position.x) * 2.0 * delta
		current_velocity.x += horizontal_pull

	position += current_velocity * delta
	rotation = current_velocity.angle() + PI / 2.0

	var max_trail: int = 12 if not is_nuke else 20
	trail_points.append(Vector2(global_position.x, global_position.y))
	if trail_points.size() > max_trail:
		trail_points.remove_at(0)

	$BombVisual.queue_redraw()

	if position.y > 1000:
		queue_free()


func _find_nearest_villain() -> Node2D:
	var best: Node2D = null
	var best_dist: float = 400.0
	for villain in get_tree().get_nodes_in_group(&"villains"):
		if not is_instance_valid(villain):
			continue
		if villain.get("is_dying") == true:
			continue
		if villain.global_position.y < global_position.y:
			continue
		var dist: float = global_position.distance_to(villain.global_position)
		if dist < best_dist:
			best_dist = dist
			best = villain
	return best


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"ground"):
		# Pass scale and nuke flag directly through the signal — no meta needed
		Events.bomb_hit_ground.emit(global_position, speed_scale, is_nuke)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"villains") and area.has_method("hit_by_bomb"):
		area.hit_by_bomb()
		# Still trigger ground explosion for area damage
		Events.bomb_hit_ground.emit(global_position, speed_scale, is_nuke)
		queue_free()
