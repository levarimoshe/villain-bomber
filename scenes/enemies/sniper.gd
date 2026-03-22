extends Node2D
## Sniper — stands still, shoots very accurate single shots

var is_dying: bool = false
var health: int = 1
var camera_ref: Camera2D = null
var shoot_timer: float = 2.0
var anim_time: float = 0.0
var death_timer: float = 0.0
var points_value: int = 200

const BulletScript = preload("res://scenes/villain/bullet.gd")


func _ready() -> void:
	add_to_group(&"villains")
	shoot_timer = randf_range(1.0, 3.0)


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return
	if is_dying:
		death_timer -= delta
		modulate.a = clampf(death_timer / 0.5, 0.0, 1.0)
		rotation += delta * 12.0
		position.y -= 60 * delta
		if death_timer <= 0:
			queue_free()
		queue_redraw()
		return

	anim_time += delta
	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_timer = randf_range(2.5, 4.0)
		_shoot_accurate()

	if camera_ref and global_position.x < camera_ref.global_position.x - 900:
		queue_free()
	queue_redraw()


func _shoot_accurate() -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if not player:
		return
	var bullet := Node2D.new()
	bullet.set_script(BulletScript)
	bullet.global_position = global_position + Vector2(0, -25)
	# Very accurate — small spread
	var dir: Vector2 = (player.global_position - global_position).normalized()
	dir = dir.rotated(randf_range(-0.08, 0.08))
	bullet.velocity = dir * 350.0
	get_tree().current_scene.add_child(bullet)
	SoundManager.play_shoot()


func hit_by_bomb() -> void:
	if is_dying:
		return
	is_dying = true
	death_timer = 0.5
	Events.villain_killed.emit(global_position, points_value)


func _draw() -> void:
	var sc: float = 1.5
	# Prone position (lying down)
	draw_rect(Rect2(-12 * sc, -4 * sc, 24 * sc, 8 * sc), Color(0.2, 0.25, 0.15))
	# Head
	draw_circle(Vector2(-10 * sc, -6 * sc), 5 * sc, Color(0.85, 0.7, 0.55))
	# Scope glint
	var glint: float = 0.5 + 0.5 * sin(anim_time * 4.0)
	draw_circle(Vector2(14 * sc, -4 * sc), 2 * sc, Color(1, 0.2, 0.2, glint))
	# Rifle
	draw_line(Vector2(-2 * sc, -2 * sc), Vector2(16 * sc, -4 * sc), Color(0.3, 0.28, 0.2), 2.5 * sc)
	# Helmet
	draw_circle(Vector2(-10 * sc, -9 * sc), 4 * sc, Color(0.3, 0.35, 0.2))
