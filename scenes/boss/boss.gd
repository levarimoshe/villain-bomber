extends Node2D
## Giant boss tank — forces arena mode, must be killed to progress

var speed: float = 25.0
var direction: int = -1
var health: int = 15
var max_health: int = 15
var is_dying: bool = false
var camera_ref: Camera2D = null
var shoot_timer: float = 2.0
var shoot_interval: float = 1.8
var anim_time: float = 0.0
var flash_timer: float = 0.0
var death_timer: float = 0.0
var reached_center: bool = false
var target_x: float = 0.0

const BulletScript = preload("res://scenes/villain/bullet.gd")


func _ready() -> void:
	add_to_group(&"villains")
	add_to_group(&"boss")
	GameState.boss_active = true
	# Boss gets faster at higher levels
	shoot_interval = maxf(0.6, 1.8 - float(GameState.current_level) / 30.0)
	shoot_timer = shoot_interval
	SoundManager.speak("Boss incoming!")


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	anim_time += delta

	if is_dying:
		death_timer -= delta
		modulate.a = clampf(death_timer / 1.5, 0.0, 1.0)
		# Shake while dying
		position.x += randf_range(-3, 3)
		if death_timer <= 0:
			GameState.boss_active = false
			GameState.is_arena_level = false
			# Trigger level transition after boss dies
			Events.level_transition_started.emit(GameState.current_level)
			queue_free()
		queue_redraw()
		return

	if flash_timer > 0:
		flash_timer -= delta

	# Move toward center, then stop
	if not reached_center:
		position.x += direction * speed * delta
		if camera_ref:
			var cam_x: float = camera_ref.global_position.x
			if absf(position.x - cam_x) < 50:
				reached_center = true

	# Shoot 3-way spread
	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_timer = shoot_interval
		_shoot_spread()

	queue_redraw()


func _shoot_spread() -> void:
	var player_node: Node = get_tree().get_first_node_in_group(&"player")
	if not player_node:
		return

	var base_dir: Vector2 = (player_node.global_position - global_position).normalized()

	# 3-way spread
	for angle_offset in [-0.25, 0.0, 0.25]:
		var bullet := Node2D.new()
		bullet.set_script(BulletScript)
		bullet.global_position = global_position + Vector2(0, -35)
		var dir: Vector2 = base_dir.rotated(angle_offset)
		bullet.velocity = dir * randf_range(220.0, 300.0)
		get_tree().current_scene.add_child(bullet)

	SoundManager.play_shoot()


func hit_by_bomb() -> void:
	if is_dying:
		return
	health -= 1
	flash_timer = 0.25

	if health <= 0:
		is_dying = true
		death_timer = 1.5
		Events.villain_killed.emit(global_position, 2000)
		SoundManager.speak("Boss destroyed!")


func _draw() -> void:
	var flash: bool = flash_timer > 0 and fmod(flash_timer, 0.08) < 0.04
	var sc: float = 3.0  # 3x size!

	# === TREADS (huge) ===
	var tread_color := Color(0.18, 0.18, 0.18) if not flash else Color(1, 0.4, 0.2)
	draw_rect(Rect2(-45 * sc, 8 * sc, 90 * sc, 14 * sc), tread_color)
	draw_rect(Rect2(-45 * sc, -6 * sc, 90 * sc, 14 * sc), tread_color)
	# Tread wheels
	for i in range(8):
		var wx: float = -42 * sc + float(i) * 12 * sc
		_draw_circle_at(Vector2(wx, 15 * sc), 6 * sc, Color(0.22, 0.22, 0.22))
		_draw_circle_at(Vector2(wx, 1 * sc), 6 * sc, Color(0.22, 0.22, 0.22))

	# === BODY (massive) ===
	var body_color := Color(0.28, 0.33, 0.18) if not flash else Color(1, 0.5, 0.2)
	draw_rect(Rect2(-38 * sc, -22 * sc, 76 * sc, 28 * sc), body_color)
	# Armor plates
	for plate in range(4):
		var px: float = -32 * sc + float(plate) * 18 * sc
		draw_rect(Rect2(px, -20 * sc, 15 * sc, 24 * sc), body_color.lightened(0.04))
		draw_rect(Rect2(px, -20 * sc, 15 * sc, 1.5 * sc), body_color.lightened(0.1))
	# Side armor
	draw_rect(Rect2(-40 * sc, -20 * sc, 4 * sc, 25 * sc), body_color.darkened(0.12))
	draw_rect(Rect2(36 * sc, -20 * sc, 4 * sc, 25 * sc), body_color.darkened(0.12))

	# === TURRET ===
	var turret_color := Color(0.25, 0.3, 0.16) if not flash else Color(1, 0.45, 0.15)
	draw_rect(Rect2(-20 * sc, -35 * sc, 40 * sc, 15 * sc), turret_color)
	# Turret top highlight
	draw_rect(Rect2(-22 * sc, -33 * sc, 44 * sc, 2 * sc), turret_color.lightened(0.1))

	# === MAIN CANNON ===
	draw_line(Vector2(0, -28 * sc), Vector2(0, -55 * sc), Color(0.22, 0.25, 0.13), 6 * sc)
	# Muzzle brake
	draw_rect(Rect2(-5 * sc, -57 * sc, 10 * sc, 4 * sc), Color(0.2, 0.22, 0.12))

	# === SKULL EMBLEM (large) ===
	_draw_circle_at(Vector2(0, -10 * sc), 10 * sc, Color(0.75, 0.75, 0.65, 0.5))
	_draw_circle_at(Vector2(-4 * sc, -12 * sc), 2.5 * sc, Color(0.1, 0.1, 0.1))
	_draw_circle_at(Vector2(4 * sc, -12 * sc), 2.5 * sc, Color(0.1, 0.1, 0.1))
	# Red eyes
	_draw_circle_at(Vector2(-4 * sc, -12 * sc), 1.2 * sc, Color(0.9, 0.1, 0.0, 0.7))
	_draw_circle_at(Vector2(4 * sc, -12 * sc), 1.2 * sc, Color(0.9, 0.1, 0.0, 0.7))

	# === HEALTH BAR (wide) ===
	var bar_w: float = 120.0
	var bar_h: float = 8.0
	var bar_x: float = -bar_w / 2.0
	var bar_y: float = -65 * sc
	# Background
	draw_rect(Rect2(bar_x - 2, bar_y - 2, bar_w + 4, bar_h + 4), Color(0, 0, 0, 0.8))
	# Fill
	var hp_ratio: float = float(health) / float(max_health)
	var hp_color := Color(0.2, 0.9, 0.2).lerp(Color(0.9, 0.15, 0.1), 1.0 - hp_ratio)
	draw_rect(Rect2(bar_x, bar_y, bar_w * hp_ratio, bar_h), hp_color)
	# Border
	draw_rect(Rect2(bar_x - 2, bar_y - 2, bar_w + 4, bar_h + 4), Color(0.5, 0.5, 0.5, 0.5), false, 1.5)
	# Boss label
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(-15, bar_y - 5), "BOSS", HORIZONTAL_ALIGNMENT_CENTER, 30, 12, Color(1, 0.3, 0.1, 0.9))

	# === EXHAUST ===
	for smoke_i in range(2):
		var smoke_side: float = -35 * sc + float(smoke_i) * 70 * sc
		var smoke_t: float = fmod(anim_time + float(smoke_i) * 0.5, 1.0)
		_draw_circle_at(Vector2(smoke_side, 10 * sc - smoke_t * 25), 4 + smoke_t * 8, Color(0.25, 0.25, 0.25, 0.2 * (1.0 - smoke_t)))


func _draw_circle_at(pos: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var points := PackedVector2Array()
	var segs: int = 14
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(pos + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
