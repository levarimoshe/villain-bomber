extends Node2D
## Napalm canister — creates massive fire area on impact

const GRAVITY: float = 300.0

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 5.0


func _ready() -> void:
	add_to_group(&"projectile")


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	velocity.y += GRAVITY * delta
	position += velocity * delta
	lifetime -= delta

	# Ground impact — create wide fire
	if global_position.y > 560:
		_ignite()
		queue_free()
		return

	queue_redraw()
	if lifetime <= 0:
		queue_free()


func _ignite() -> void:
	# Create 5 fires spread across a wide area
	for i in range(7):
		var fire_x: float = global_position.x + float(i - 3) * 50
		var fire_pos := Vector2(fire_x, global_position.y)
		Events.bomb_hit_ground.emit(fire_pos, 1.5, false)

	# Kill everything in a WIDE area
	for villain in get_tree().get_nodes_in_group(&"villains"):
		if is_instance_valid(villain) and villain.has_method("hit_by_bomb"):
			if villain.get("is_dying") == true:
				continue
			if absf(villain.global_position.x - global_position.x) < 200:
				villain.hit_by_bomb()

	SoundManager.play_explosion()


func _draw() -> void:
	# Red napalm canister
	draw_rect(Rect2(-5, -8, 10, 16), Color(0.8, 0.15, 0.05))
	draw_rect(Rect2(-6, -6, 12, 2), Color(0.6, 0.6, 0.6))
	draw_rect(Rect2(-6, 4, 12, 2), Color(0.6, 0.6, 0.6))
	# Flame symbol
	draw_circle(Vector2(0, -1), 3, Color(1, 0.5, 0, 0.7))
