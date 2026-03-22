extends CharacterBody2D

@export var move_speed: float = 300.0
@export var vertical_speed: float = 220.0
@export var min_y: float = 60.0
@export var max_y: float = 420.0

@onready var visual: Node2D = $PlaneVisual
@onready var bomb_cooldown: Timer = $BombCooldownTimer
@onready var bomb_drop_point: Marker2D = $BombDropPoint

const BombScene: PackedScene = preload("res://scenes/bomb/bomb.tscn")
const MachineGunScript: GDScript = preload("res://scenes/player/machine_gun_bullet.gd")

var can_drop_bomb: bool = true
var propeller_angle: float = 0.0
var exhaust_particles: Array[Dictionary] = []
var flash_timer: float = 0.0
var crosshair_pos: Vector2 = Vector2.ZERO
var mg_cooldown: float = 0.0
var orbit_angle: float = 0.0
var facing: int = 1  # 1=right, -1=left
var auto_drift: float = 60.0  # Gentle rightward drift when no input


func _ready() -> void:
	add_to_group(&"player")
	bomb_cooldown.wait_time = 0.3
	bomb_cooldown.one_shot = true
	bomb_cooldown.timeout.connect(func(): can_drop_bomb = true)


func _physics_process(delta: float) -> void:
	if GameState.game_phase != &"playing":
		return

	var input_h: float = Input.get_axis(&"move_left", &"move_right")
	var input_v: float = Input.get_axis(&"move_up", &"move_down")

	if GameState.is_arena_level and not GameState.boss_active:
		# Arena defense mode — orbit behavior
		var orbit_speed: float = 1.5 - input_h * 0.8
		var orbit_radius: float = 180.0 + input_h * 80.0
		orbit_radius = clampf(orbit_radius, 80.0, 300.0)
		orbit_angle += orbit_speed * delta

		var center_x: float = GameState.arena_center_x
		var center_y: float = 250.0 + input_v * 100.0
		center_y = clampf(center_y, min_y + 50, max_y - 50)

		var target_pos := Vector2(
			center_x + cos(orbit_angle) * orbit_radius,
			center_y + sin(orbit_angle) * orbit_radius * 0.4
		)
		velocity = (target_pos - global_position) * 5.0
		facing = 1 if velocity.x > 0 else -1
	elif GameState.boss_active:
		# Boss fight — free movement in locked area, no auto-scroll
		var target_vx: float = input_h * move_speed
		velocity.x = lerp(velocity.x, target_vx, 0.1)
		velocity.y = input_v * vertical_speed

		if input_h > 0.1:
			facing = 1
		elif input_h < -0.1:
			facing = -1
	else:
		# Normal mode — FREE MOVEMENT with U-turn
		var target_vx: float
		if absf(input_h) > 0.1:
			# Player is pressing left or right
			target_vx = input_h * move_speed
			if input_h > 0.1:
				facing = 1
			elif input_h < -0.1:
				facing = -1
		else:
			# No horizontal input — gentle drift right
			target_vx = auto_drift

		velocity.x = lerp(velocity.x, target_vx, 0.08)
		velocity.y = input_v * vertical_speed

	# Clamp vertical
	if global_position.y <= min_y and velocity.y < 0.0:
		velocity.y = 0.0
		global_position.y = min_y
	if global_position.y >= max_y and velocity.y > 0.0:
		velocity.y = 0.0
		global_position.y = max_y

	move_and_slide()

	# Flip plane visual based on facing direction
	visual.scale.x = float(facing)

	# Bank based on vertical movement
	var target_rotation: float = velocity.y * 0.0012 * float(facing)
	visual.rotation = lerp(visual.rotation, target_rotation, 0.1)

	propeller_angle += delta * 30.0

	# Invulnerability flashing
	if GameState.is_invulnerable:
		flash_timer += delta
		visual.visible = fmod(flash_timer, 0.15) < 0.08
	else:
		visual.visible = true
		flash_timer = 0.0

	visual.queue_redraw()

	# Bomb input
	var cooldown_ready: bool = can_drop_bomb or GameState.has_rapid_fire
	if Input.is_action_just_pressed(&"drop_bomb") and cooldown_ready:
		var going_fast: bool = absf(velocity.x) > 250.0
		if GameState.nuke_ready and going_fast:
			_drop_nuke()
		else:
			_drop_bomb()

	# Machine gun (hold M, level 3+)
	if GameState.current_level >= 3:
		mg_cooldown -= delta
		if Input.is_action_pressed(&"machine_gun") and mg_cooldown <= 0:
			_fire_machine_gun()
			mg_cooldown = 0.08

	_update_crosshair()
	_update_exhaust(delta)


func _drop_bomb() -> void:
	can_drop_bomb = false
	if not GameState.has_rapid_fire:
		bomb_cooldown.start()
	else:
		bomb_cooldown.wait_time = 0.12
		bomb_cooldown.start()
		bomb_cooldown.wait_time = 0.3

	var speed_factor: float = clampf(absf(velocity.x) / 500.0, 0.0, 1.0)
	var bomb_scale: float = 1.0 + speed_factor * 0.8

	if GameState.has_rapid_fire:
		for i in range(3):
			var bomb := BombScene.instantiate()
			var offset_x: float = float(i - 1) * 15.0
			var offset_y: float = abs(i - 1) * 5.0
			bomb.global_position = bomb_drop_point.global_position + Vector2(offset_x * facing, offset_y)
			var spread_angle: float = float(i - 1) * 0.15
			var base_vel := Vector2(velocity.x * 0.8, 30.0)
			bomb.initial_velocity = base_vel.rotated(spread_angle)
			bomb.speed_scale = bomb_scale
			Events.bomb_dropped.emit(bomb)
	else:
		var bomb := BombScene.instantiate()
		bomb.global_position = bomb_drop_point.global_position
		bomb.initial_velocity = Vector2(velocity.x * 0.8, 30.0)
		bomb.speed_scale = bomb_scale
		Events.bomb_dropped.emit(bomb)

	SoundManager.play_bomb_drop()


func _drop_nuke() -> void:
	can_drop_bomb = false
	bomb_cooldown.start()
	GameState.use_nuke()
	var bomb := BombScene.instantiate()
	bomb.global_position = bomb_drop_point.global_position
	bomb.initial_velocity = Vector2(velocity.x * 0.8, 30.0)
	bomb.speed_scale = GameState.NUKE_SCALE
	bomb.is_nuke = true
	Events.bomb_dropped.emit(bomb)
	SoundManager.play_bomb_drop()
	SoundManager.speak("Nuke deployed!")


func _fire_machine_gun() -> void:
	var bullet := Node2D.new()
	bullet.set_script(MachineGunScript)
	bullet.global_position = global_position + Vector2(randf_range(-5, 5) * facing, 15)
	bullet.velocity = Vector2(velocity.x * 0.3, 350)
	get_tree().current_scene.add_child(bullet)


func _update_crosshair() -> void:
	var bomb_pos := bomb_drop_point.global_position
	var bomb_vel := Vector2(velocity.x * 0.8, 30.0)
	var gravity: float = 420.0
	var ground_y: float = 580.0

	for step in range(120):
		var dt: float = 0.016
		bomb_vel.y += gravity * dt
		bomb_pos += bomb_vel * dt
		if bomb_pos.y >= ground_y:
			crosshair_pos = bomb_pos
			return
	crosshair_pos = bomb_pos


func _update_exhaust(delta: float) -> void:
	if randf() < 0.6:
		var exhaust_offset_x: float = -35.0 * float(facing)
		exhaust_particles.append({
			"pos": Vector2(global_position.x + exhaust_offset_x, global_position.y + randf_range(-3, 3)),
			"life": 0.5,
			"max_life": 0.5,
			"size": randf_range(2.0, 5.0),
		})

	var i := 0
	while i < exhaust_particles.size():
		exhaust_particles[i]["life"] -= delta
		exhaust_particles[i]["pos"].x -= velocity.x * 0.3 * delta
		if exhaust_particles[i]["life"] <= 0:
			exhaust_particles.remove_at(i)
		else:
			i += 1

	while exhaust_particles.size() > 30:
		exhaust_particles.remove_at(0)
