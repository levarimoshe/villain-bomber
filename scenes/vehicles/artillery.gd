extends Node2D
## Artillery — fires large arcing shells from far away

var is_dying: bool = false
var health: int = 4
var max_health: int = 4
var camera_ref: Camera2D = null
var anim_time: float = 0.0
var death_timer: float = 0.0
var shoot_timer: float = 4.0
var points_value: int = 500
var recoil: float = 0.0
var cannon_angle: float = -1.2  # Pointing upward


func _ready() -> void:
	add_to_group(&"villains")
	shoot_timer = randf_range(2.0, 5.0)


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	if is_dying:
		death_timer -= delta
		modulate.a = clampf(death_timer / 1.0, 0.0, 1.0)
		if death_timer <= 0:
			Events.bomb_hit_ground.emit(global_position, 1.5, false)
			queue_free()
		queue_redraw()
		return

	anim_time += delta
	if recoil > 0:
		recoil -= delta * 5.0

	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_timer = randf_range(3.0, 6.0)
		_fire_shell()

	if camera_ref and global_position.x < camera_ref.global_position.x - 1000:
		queue_free()
	queue_redraw()


func _fire_shell() -> void:
	recoil = 1.0
	# Create artillery shell
	var shell := Node2D.new()
	shell.set_script(load("res://scenes/vehicles/artillery_shell.gd"))
	var barrel_end: Vector2 = global_position + Vector2(cos(cannon_angle), sin(cannon_angle)) * 35
	shell.global_position = barrel_end
	# Arc toward player
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player:
		var dx: float = player.global_position.x - global_position.x
		shell.velocity = Vector2(dx * 0.3, -350)
	else:
		shell.velocity = Vector2(-100, -350)
	get_tree().current_scene.add_child(shell)
	SoundManager.play_explosion()


func hit_by_bomb() -> void:
	if is_dying:
		return
	health -= 1
	if health <= 0:
		is_dying = true
		death_timer = 1.0
		Events.villain_killed.emit(global_position, points_value)


func _draw() -> void:
	var sc: float = 1.5
	# Base platform
	draw_rect(Rect2(-20 * sc, -2 * sc, 40 * sc, 8 * sc), Color(0.3, 0.3, 0.25))
	# Wheels
	draw_circle(Vector2(-14 * sc, 6 * sc), 5 * sc, Color(0.2, 0.2, 0.2))
	draw_circle(Vector2(14 * sc, 6 * sc), 5 * sc, Color(0.2, 0.2, 0.2))
	# Cannon barrel (with recoil animation)
	var recoil_offset: float = recoil * 5 * sc
	var barrel_start: Vector2 = Vector2(0, -4 * sc)
	var barrel_dir: Vector2 = Vector2(cos(cannon_angle), sin(cannon_angle))
	var barrel_end: Vector2 = barrel_start + barrel_dir * (30 * sc - recoil_offset)
	draw_line(barrel_start, barrel_end, Color(0.25, 0.28, 0.2), 5 * sc)
	# Muzzle brake
	if recoil > 0.5:
		_draw_glow(barrel_end, 8 * sc, Color(1, 0.7, 0.2, recoil * 0.8))
	# Shield
	draw_arc(barrel_start, 10 * sc, cannon_angle - 0.5, cannon_angle + 0.5, 8, Color(0.35, 0.35, 0.3), 3 * sc)
	# Sandbag walls
	for sb in range(4):
		var sbx: float = -15 * sc + sb * 10 * sc
		_draw_glow(Vector2(sbx, -1 * sc), 5 * sc, Color(0.5, 0.45, 0.3))

	# Health bar
	var bar_w: float = 40.0
	var hp: float = float(health) / float(max_health)
	draw_rect(Rect2(-bar_w / 2, -20 * sc, bar_w, 5), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(-bar_w / 2, -20 * sc, bar_w * hp, 5), Color(0.2, 0.8, 0.2).lerp(Color(0.8, 0.1, 0.1), 1.0 - hp))


func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	if radius < 1:
		return
	var points := PackedVector2Array()
	for i in range(13):
		var a: float = float(i) / 12.0 * TAU
		points.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
