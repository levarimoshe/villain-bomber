extends Node2D
## Mini bomb from cluster split — small explosion on ground contact

const GRAVITY: float = 500.0

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 3.0


func _ready() -> void:
	add_to_group(&"projectile")


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	velocity.y += GRAVITY * delta
	position += velocity * delta
	lifetime -= delta

	# Ground check
	if global_position.y > 570:
		Events.bomb_hit_ground.emit(global_position, 0.6, false)
		queue_free()
		return

	# Hit enemies directly
	for villain in get_tree().get_nodes_in_group(&"villains"):
		if is_instance_valid(villain) and villain.has_method("hit_by_bomb"):
			if villain.get("is_dying") == true:
				continue
			if global_position.distance_to(villain.global_position) < 30:
				villain.hit_by_bomb()
				queue_free()
				return

	queue_redraw()
	if lifetime <= 0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color(0.7, 0.35, 0.1))
	draw_circle(Vector2.ZERO, 1.5, Color(1, 0.6, 0.2))
