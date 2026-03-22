extends Node2D
## Cluster bomb — falls, then splits into 5 mini bombs at altitude

const GRAVITY: float = 350.0

var velocity: Vector2 = Vector2.ZERO
var split_altitude: float = 400.0  # Y position to split at
var has_split: bool = false
var lifetime: float = 5.0


func _ready() -> void:
	add_to_group(&"projectile")


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	velocity.y += GRAVITY * delta
	position += velocity * delta
	lifetime -= delta

	# Split into mini bombs when reaching altitude
	if not has_split and global_position.y > split_altitude:
		has_split = true
		_split()
		queue_free()
		return

	queue_redraw()

	if lifetime <= 0 or position.y > 800:
		queue_free()


func _split() -> void:
	for i in range(5):
		var mini := Node2D.new()
		mini.set_script(load("res://scenes/weapons/mini_bomb.gd"))
		mini.global_position = global_position + Vector2(float(i - 2) * 20, 0)
		mini.velocity = Vector2(velocity.x + float(i - 2) * 40, velocity.y * 0.5)
		get_tree().current_scene.add_child(mini)
	SoundManager.play_explosion()


func _draw() -> void:
	# Orange bomb with cluster marks
	var points := PackedVector2Array()
	for seg in range(13):
		var a: float = float(seg) / 12.0 * TAU
		points.append(Vector2(cos(a) * 7, sin(a) * 9))
	draw_colored_polygon(points, Color(0.8, 0.4, 0.1))
	# Cluster dots
	for d in range(3):
		var dx: float = float(d - 1) * 4
		draw_circle(Vector2(dx, 0), 2.0, Color(1, 0.7, 0.2))
