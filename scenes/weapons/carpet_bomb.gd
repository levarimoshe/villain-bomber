extends Node2D
## Carpet bomb — drops 10 bombs in a sequence over time

var velocity: Vector2 = Vector2.ZERO
var bombs_remaining: int = 10
var drop_interval: float = 0.08
var drop_timer: float = 0.0
var lifetime: float = 3.0

const BombScene: PackedScene = preload("res://scenes/bomb/bomb.tscn")


func _ready() -> void:
	add_to_group(&"projectile")


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	position += velocity * delta
	lifetime -= delta
	drop_timer -= delta

	if drop_timer <= 0 and bombs_remaining > 0:
		drop_timer = drop_interval
		bombs_remaining -= 1
		_drop_one()

	if bombs_remaining <= 0 or lifetime <= 0:
		queue_free()


func _drop_one() -> void:
	var bomb := BombScene.instantiate()
	bomb.global_position = global_position + Vector2(randf_range(-10, 10), 0)
	bomb.initial_velocity = Vector2(velocity.x * 0.3, 30)
	bomb.speed_scale = 0.7
	Events.bomb_dropped.emit(bomb)
