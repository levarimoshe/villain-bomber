extends Node2D
## Enemy jeep — drives fast, soldiers inside shoot

var speed: float = 150.0
var direction: int = -1
var is_dying: bool = false
var health: int = 2
var camera_ref: Camera2D = null
var anim_time: float = 0.0
var death_timer: float = 0.0
var shoot_timer: float = 1.5
var points_value: int = 350
var wheel_angle: float = 0.0

const BulletScript = preload("res://scenes/villain/bullet.gd")


func _ready() -> void:
	add_to_group(&"villains")
	shoot_timer = randf_range(0.8, 2.0)


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	if is_dying:
		death_timer -= delta
		modulate.a = clampf(death_timer / 0.8, 0.0, 1.0)
		if death_timer <= 0:
			queue_free()
		queue_redraw()
		return

	anim_time += delta
	wheel_angle += speed * delta * 0.1
	position.x += direction * speed * delta

	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_timer = randf_range(1.0, 2.0)
		_shoot()

	if camera_ref and global_position.x < camera_ref.global_position.x - 900:
		Events.villain_escaped.emit()
		queue_free()
	queue_redraw()


func _shoot() -> void:
	for s in range(2):  # Two soldiers shoot
		var bullet := Node2D.new()
		bullet.set_script(BulletScript)
		bullet.global_position = global_position + Vector2(float(s - 1) * 10, -20)
		var player: Node = get_tree().get_first_node_in_group(&"player")
		if player:
			var dir: Vector2 = (player.global_position - global_position).normalized()
			dir = dir.rotated(randf_range(-0.25, 0.25))
			bullet.velocity = dir * 250.0
		else:
			bullet.velocity = Vector2(0, -250)
		get_tree().current_scene.add_child(bullet)
	SoundManager.play_shoot()


func hit_by_bomb() -> void:
	if is_dying:
		return
	health -= 1
	if health <= 0:
		is_dying = true
		death_timer = 0.8
		Events.villain_killed.emit(global_position, points_value)


func _draw() -> void:
	var sc: float = 1.3
	# Jeep body
	draw_rect(Rect2(-16 * sc, -10 * sc, 32 * sc, 14 * sc), Color(0.3, 0.35, 0.2))
	# Hood
	draw_rect(Rect2(direction * 10 * sc, -8 * sc, direction * 8 * sc, 10 * sc), Color(0.28, 0.32, 0.18))
	# Windshield
	draw_rect(Rect2(direction * 4 * sc, -12 * sc, 4 * sc, 4 * sc), Color(0.4, 0.55, 0.7, 0.7))
	# Wheels (spinning)
	var w1x: float = -10 * sc
	var w2x: float = 10 * sc
	draw_circle(Vector2(w1x, 4 * sc), 5 * sc, Color(0.15, 0.15, 0.15))
	draw_circle(Vector2(w2x, 4 * sc), 5 * sc, Color(0.15, 0.15, 0.15))
	# Wheel spokes
	for w_pos in [Vector2(w1x, 4 * sc), Vector2(w2x, 4 * sc)]:
		for spoke in range(4):
			var a: float = wheel_angle + float(spoke) * PI / 2.0
			draw_line(w_pos, w_pos + Vector2(cos(a), sin(a)) * 3 * sc, Color(0.3, 0.3, 0.3), 1.0)
	# Soldiers (2 stick figures)
	for s in range(2):
		var sx: float = float(s * 2 - 1) * 5 * sc
		draw_circle(Vector2(sx, -16 * sc), 3 * sc, Color(0.85, 0.7, 0.55))
		draw_circle(Vector2(sx, -20 * sc), 4 * sc, Color(0.3, 0.35, 0.2))
