extends Node2D
## Anti-air turret — stationary, rapid fire, must be bombed

var is_dying: bool = false
var health: int = 3
var max_health: int = 3
var camera_ref: Camera2D = null
var anim_time: float = 0.0
var death_timer: float = 0.0
var shoot_timer: float = 0.5
var flash_timer: float = 0.0
var points_value: int = 400
var turret_angle: float = -PI / 2.0

const BulletScript = preload("res://scenes/villain/bullet.gd")


func _ready() -> void:
	add_to_group(&"villains")
	shoot_timer = randf_range(0.5, 1.5)


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
	if flash_timer > 0:
		flash_timer -= delta

	# Track player with turret
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player:
		var to_player: Vector2 = player.global_position - global_position
		var target_angle: float = to_player.angle()
		turret_angle = lerp_angle(turret_angle, target_angle, 3.0 * delta)

	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_timer = 0.4  # Very rapid fire!
		_shoot_rapid()

	if camera_ref and global_position.x < camera_ref.global_position.x - 900:
		queue_free()
	queue_redraw()


func _shoot_rapid() -> void:
	flash_timer = 0.08
	var bullet := Node2D.new()
	bullet.set_script(BulletScript)
	var barrel_end: Vector2 = global_position + Vector2(cos(turret_angle), sin(turret_angle)) * 25
	bullet.global_position = barrel_end
	bullet.velocity = Vector2(cos(turret_angle), sin(turret_angle)) * 350
	get_tree().current_scene.add_child(bullet)


func hit_by_bomb() -> void:
	if is_dying:
		return
	health -= 1
	flash_timer = 0.15
	SoundManager.play_hit()
	if health <= 0:
		is_dying = true
		death_timer = 0.8
		Events.villain_killed.emit(global_position, points_value)


func _draw() -> void:
	var flash: bool = flash_timer > 0 and fmod(flash_timer, 0.05) < 0.025

	# Base (sandbag circle)
	_draw_glow(Vector2.ZERO, 20, Color(0.45, 0.4, 0.3))
	_draw_glow(Vector2.ZERO, 16, Color(0.5, 0.45, 0.35))

	# Turret barrel (rotates toward player)
	var barrel_color := Color(0.3, 0.3, 0.3) if not flash else Color(1, 0.6, 0.2)
	var barrel_end := Vector2(cos(turret_angle), sin(turret_angle)) * 22
	draw_line(Vector2.ZERO, barrel_end, barrel_color, 4.0)
	# Muzzle flash
	if flash_timer > 0:
		var muzzle: Vector2 = barrel_end + Vector2(cos(turret_angle), sin(turret_angle)) * 5
		_draw_glow(muzzle, 6, Color(1, 0.8, 0.2, 0.8))

	# Turret hub
	_draw_glow(Vector2.ZERO, 8, Color(0.35, 0.35, 0.35))
	_draw_glow(Vector2.ZERO, 5, Color(0.4, 0.4, 0.4))

	# Health bar
	var bar_w: float = 30.0
	var hp_ratio: float = float(health) / float(max_health)
	draw_rect(Rect2(-bar_w / 2, -30, bar_w, 4), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(-bar_w / 2, -30, bar_w * hp_ratio, 4), Color(0.2, 0.8, 0.2).lerp(Color(0.8, 0.15, 0.1), 1.0 - hp_ratio))


func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	if radius < 1:
		return
	var points := PackedVector2Array()
	for i in range(13):
		var a: float = float(i) / 12.0 * TAU
		points.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
