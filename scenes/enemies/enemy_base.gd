extends Area2D
## Base class for all enemy types

@export var speed: float = 80.0
var direction: int = -1
var is_dying: bool = false
var anim_time: float = 0.0
var health: int = 1
var max_health: int = 1
var camera_ref: Camera2D = null
var points_value: int = 100
var death_timer: float = 0.0
var death_velocity: Vector2 = Vector2.ZERO
var can_shoot: bool = false
var shoot_timer: float = 3.0
var shoot_interval: float = 3.0

const BulletScript = preload("res://scenes/villain/bullet.gd")


func _ready() -> void:
	add_to_group(&"villains")
	anim_time = randf() * TAU


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	if is_dying:
		_process_death(delta)
		return

	anim_time += delta * 8.0
	_move(delta)
	_try_shoot(delta)
	_check_offscreen()
	queue_redraw()


func _move(delta: float) -> void:
	position.x += direction * speed * delta


func _try_shoot(delta: float) -> void:
	if not can_shoot:
		return
	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_timer = shoot_interval
		_shoot()


func _shoot() -> void:
	var bullet := Node2D.new()
	bullet.set_script(BulletScript)
	bullet.global_position = global_position + Vector2(0, -20)
	var player_node: Node = get_tree().get_first_node_in_group(&"player")
	if player_node:
		var dir: Vector2 = (player_node.global_position - global_position).normalized()
		dir = dir.rotated(randf_range(-0.3, 0.3))
		bullet.velocity = dir * randf_range(200, 300)
	else:
		bullet.velocity = Vector2(0, -250)
	get_tree().current_scene.add_child(bullet)
	SoundManager.play_shoot()


func _check_offscreen() -> void:
	if camera_ref:
		var cam_x := camera_ref.global_position.x
		if global_position.x < cam_x - 900 or global_position.x > cam_x + 1200:
			Events.villain_escaped.emit()
			queue_free()


func _process_death(delta: float) -> void:
	death_timer -= delta
	death_velocity.y -= 80.0 * delta
	position += death_velocity * delta
	modulate.a = clampf(death_timer / 0.5, 0.0, 1.0)
	rotation += delta * 10.0
	if death_timer <= 0:
		queue_free()


func hit_by_bomb() -> void:
	if is_dying:
		return
	health -= 1
	if health <= 0:
		is_dying = true
		death_timer = 0.5
		death_velocity = Vector2(randf_range(-40, 40), -120)
		if has_node("CollisionShape2D"):
			$CollisionShape2D.set_deferred("disabled", true)
		Events.villain_killed.emit(global_position, points_value)
