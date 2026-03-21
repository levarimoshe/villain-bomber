extends Area2D

const GRAVITY: float = 420.0

var initial_velocity: Vector2 = Vector2.ZERO
var current_velocity: Vector2 = Vector2.ZERO
var trail_points: Array = []


func _ready() -> void:
	current_velocity = initial_velocity
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return
	current_velocity.y += GRAVITY * delta
	position += current_velocity * delta
	rotation = current_velocity.angle() + PI / 2.0

	# Store trail positions
	trail_points.append(Vector2(global_position.x, global_position.y))
	if trail_points.size() > 12:
		trail_points.remove_at(0)

	$BombVisual.queue_redraw()

	if position.y > 1000:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"ground"):
		Events.bomb_hit_ground.emit(global_position)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"villains") and area.has_method("hit_by_bomb"):
		area.hit_by_bomb()
		queue_free()
