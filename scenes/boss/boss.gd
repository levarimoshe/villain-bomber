extends Node2D
## Boss tank — appears every 5 levels, takes multiple hits

var speed: float = 40.0
var direction: int = -1
var health: int = 5
var max_health: int = 5
var is_dying: bool = false
var camera_ref: Camera2D = null
var shoot_timer: float = 1.5
var shoot_interval: float = 1.0
var anim_time: float = 0.0
var flash_timer: float = 0.0
var death_timer: float = 0.0

const BulletScript = preload("res://scenes/villain/bullet.gd")


func _ready() -> void:
	add_to_group(&"villains")
	add_to_group(&"boss")
	SoundManager.speak("Boss incoming!")


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	anim_time += delta

	if is_dying:
		death_timer -= delta
		modulate.a = clampf(death_timer / 1.0, 0.0, 1.0)
		if death_timer <= 0:
			queue_free()
		queue_redraw()
		return

	if flash_timer > 0:
		flash_timer -= delta

	position.x += direction * speed * delta

	# Shoot frequently
	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_timer = shoot_interval
		_shoot()

	queue_redraw()

	if camera_ref:
		var cam_x := camera_ref.global_position.x
		if global_position.x < cam_x - 900:
			Events.villain_escaped.emit()
			queue_free()


func _shoot() -> void:
	for i in range(2):  # Double shot
		var bullet := Node2D.new()
		bullet.set_script(BulletScript)
		bullet.global_position = global_position + Vector2(direction * 30, -25 + i * 10)

		var player_node: Node = get_tree().get_first_node_in_group(&"player")
		if player_node:
			var dir_to_player: Vector2 = (player_node.global_position - global_position).normalized()
			dir_to_player = dir_to_player.rotated(randf_range(-0.2, 0.2))
			bullet.velocity = dir_to_player * randf_range(250.0, 350.0)
		else:
			bullet.velocity = Vector2(0, -280)

		get_tree().current_scene.add_child(bullet)
	SoundManager.play_shoot()


func hit_by_bomb() -> void:
	if is_dying:
		return
	health -= 1
	flash_timer = 0.2
	SoundManager.play_hit()

	if health <= 0:
		is_dying = true
		death_timer = 1.0
		Events.villain_killed.emit(global_position, 500)
		SoundManager.speak("Boss destroyed!")


func _draw() -> void:
	var sc: float = 1.0
	var flash: bool = flash_timer > 0 and fmod(flash_timer, 0.08) < 0.04

	# === TREADS ===
	var tread_color := Color(0.2, 0.2, 0.2) if not flash else Color(1, 0.5, 0.3)
	draw_rect(Rect2(-45, 10, 90, 14), tread_color)
	draw_rect(Rect2(-45, -4, 90, 14), tread_color)
	# Tread wheels
	for i in range(6):
		var wx: float = -38 + i * 15
		_draw_circle_at(Vector2(wx, 17), 5, Color(0.25, 0.25, 0.25))
		_draw_circle_at(Vector2(wx, 3), 5, Color(0.25, 0.25, 0.25))

	# === BODY ===
	var body_color := Color(0.3, 0.35, 0.2) if not flash else Color(1, 0.6, 0.3)
	draw_rect(Rect2(-35, -20, 70, 25), body_color)
	# Armor plating lines
	draw_line(Vector2(-35, -15), Vector2(35, -15), body_color.darkened(0.15), 1.5)
	draw_line(Vector2(-35, -8), Vector2(35, -8), body_color.darkened(0.15), 1.5)
	# Side armor
	draw_rect(Rect2(-38, -18, 5, 20), body_color.darkened(0.1))
	draw_rect(Rect2(33, -18, 5, 20), body_color.darkened(0.1))

	# === TURRET ===
	var turret_color := Color(0.28, 0.32, 0.18) if not flash else Color(1, 0.5, 0.2)
	draw_rect(Rect2(-18, -32, 36, 14), turret_color)
	draw_rect(Rect2(-20, -30, 40, 2), turret_color.lightened(0.1))

	# === CANNON ===
	var cannon_dir: float = float(direction)
	draw_line(Vector2(cannon_dir * 18, -26), Vector2(cannon_dir * 50, -28), Color(0.25, 0.28, 0.15), 5.0)
	# Muzzle
	draw_rect(Rect2(cannon_dir * 48 - 3, -31, 6, 6), Color(0.2, 0.22, 0.12))

	# === SKULL EMBLEM ===
	_draw_circle_at(Vector2(0, -10), 6, Color(0.8, 0.8, 0.7, 0.6))
	_draw_circle_at(Vector2(-2.5, -11), 1.5, Color(0.1, 0.1, 0.1))
	_draw_circle_at(Vector2(2.5, -11), 1.5, Color(0.1, 0.1, 0.1))

	# === HEALTH BAR ===
	var bar_w: float = 60.0
	var bar_h: float = 6.0
	var bar_x: float = -bar_w / 2.0
	var bar_y: float = -42.0
	draw_rect(Rect2(bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2), Color(0, 0, 0, 0.7))
	var hp_ratio: float = float(health) / float(max_health)
	var hp_color := Color.GREEN.lerp(Color.RED, 1.0 - hp_ratio)
	draw_rect(Rect2(bar_x, bar_y, bar_w * hp_ratio, bar_h), hp_color)

	# === EXHAUST SMOKE ===
	var smoke_x: float = -direction * 40
	var smoke_t: float = fmod(anim_time, 0.8)
	_draw_circle_at(Vector2(smoke_x, 5 - smoke_t * 20), 4 + smoke_t * 6, Color(0.3, 0.3, 0.3, 0.2 * (1.0 - smoke_t / 0.8)))


func _draw_circle_at(pos: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var points := PackedVector2Array()
	var segs: int = 12
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(pos + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
