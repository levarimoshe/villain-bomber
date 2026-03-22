extends CharacterBody2D
## Smooth physics-based plane movement using lerp_angle and momentum

@export var max_speed: float = 320.0
@export var acceleration: float = 400.0
@export var turn_speed: float = 2.0  # Radians per second
@export var min_y: float = 60.0
@export var max_y: float = 420.0
@export var drift_speed: float = 80.0  # Auto-drift when no input

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

# Physics-based movement
var flight_angle: float = 0.0  # Current flight direction (radians)
var current_speed: float = 200.0  # Current forward speed
var facing: int = 1


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
		_arena_movement(delta, input_h, input_v)
	else:
		_free_flight_movement(delta, input_h, input_v)

	# Clamp vertical position
	if global_position.y <= min_y:
		global_position.y = min_y
		if velocity.y < 0:
			velocity.y = 0
	if global_position.y >= max_y:
		global_position.y = max_y
		if velocity.y > 0:
			velocity.y = 0

	move_and_slide()

	# === VISUAL ROTATION ===
	# The visual smoothly rotates to match flight direction
	# Using lerp_angle for proper wrapping around PI/-PI
	var target_visual_rot: float = flight_angle * 0.4 + velocity.y * 0.001
	visual.rotation = lerp_angle(visual.rotation, target_visual_rot, _smooth(4.0, delta))

	# NO scale.x flip — just rotation handles direction
	# This prevents the visual "cut/snap" issue entirely

	propeller_angle += delta * 30.0

	# Invulnerability flashing
	if GameState.is_invulnerable:
		flash_timer += delta
		visual.visible = fmod(flash_timer, 0.15) < 0.08
	else:
		visual.visible = true
		flash_timer = 0.0

	visual.queue_redraw()

	# Update facing for other systems (bombs, exhaust)
	if velocity.x > 10:
		facing = 1
	elif velocity.x < -10:
		facing = -1

	# === WEAPONS ===
	var cooldown_ready: bool = can_drop_bomb or GameState.has_rapid_fire
	if Input.is_action_just_pressed(&"drop_bomb") and cooldown_ready:
		var going_fast: bool = absf(velocity.x) > 200.0
		if GameState.nuke_ready and going_fast:
			_drop_nuke()
		else:
			var weapon: Dictionary = WeaponSystem.get_current_weapon()
			if weapon["name"] == "Bomb" or weapon["script_path"] == "":
				_drop_bomb()
			else:
				_fire_special_weapon(weapon)

	# Machine gun (M key, level 3+)
	if GameState.current_level >= 3:
		mg_cooldown -= delta
		if Input.is_action_pressed(&"machine_gun") and mg_cooldown <= 0:
			_fire_machine_gun()
			mg_cooldown = 0.08

	_update_crosshair()
	_update_exhaust(delta)


## Frame-rate independent smoothing factor
func _smooth(speed: float, delta: float) -> float:
	return 1.0 - exp(-speed * delta)


## Free flight — smooth momentum-based movement
func _free_flight_movement(delta: float, input_h: float, input_v: float) -> void:
	# Determine target flight angle based on input
	var target_angle: float = flight_angle

	if absf(input_h) > 0.1:
		if input_h > 0:
			target_angle = 0.0  # Right
		else:
			target_angle = PI  # Left
	else:
		# No horizontal input — gently steer back to rightward
		target_angle = 0.0

	# Smoothly rotate flight angle using lerp_angle (handles PI wrapping!)
	flight_angle = lerp_angle(flight_angle, target_angle, _smooth(turn_speed, delta))

	# Speed: accelerate/decelerate based on input
	var target_speed: float = drift_speed
	if absf(input_h) > 0.1:
		target_speed = max_speed
	current_speed = lerpf(current_speed, target_speed, _smooth(3.0, delta))

	# Calculate velocity from angle + speed
	velocity.x = cos(flight_angle) * current_speed

	# Vertical movement is independent (up/down keys)
	var target_vy: float = input_v * max_speed * 0.7
	velocity.y = lerpf(velocity.y, target_vy, _smooth(5.0, delta))


## Arena orbit movement
func _arena_movement(delta: float, input_h: float, input_v: float) -> void:
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
	flight_angle = velocity.angle()


func _drop_bomb() -> void:
	can_drop_bomb = false
	if not GameState.has_rapid_fire:
		bomb_cooldown.start()
	else:
		var rf_cooldowns: Array = [0.3, 0.12, 0.08, 0.05]
		bomb_cooldown.wait_time = rf_cooldowns[clampi(GameState.rapid_fire_level, 0, 3)]
		bomb_cooldown.start()
		bomb_cooldown.wait_time = 0.3

	var speed_factor: float = clampf(absf(velocity.x) / 500.0, 0.0, 1.0)
	var bomb_scale: float = 1.0 + speed_factor * 0.8

	if GameState.has_rapid_fire:
		var bomb_count: int = 1 + GameState.rapid_fire_level * 2
		var half: int = bomb_count / 2
		for i in range(bomb_count):
			var bomb := BombScene.instantiate()
			var offset_idx: int = i - half
			bomb.global_position = bomb_drop_point.global_position + Vector2(float(offset_idx) * 12.0, abs(offset_idx) * 3.0)
			var spread: float = float(offset_idx) * 0.1
			bomb.initial_velocity = Vector2(velocity.x * 0.7, 50.0).rotated(spread)
			bomb.speed_scale = bomb_scale
			Events.bomb_dropped.emit(bomb)
	else:
		var bomb := BombScene.instantiate()
		bomb.global_position = bomb_drop_point.global_position
		bomb.initial_velocity = Vector2(velocity.x * 0.7, 50.0)
		bomb.speed_scale = bomb_scale
		Events.bomb_dropped.emit(bomb)

	SoundManager.play_bomb_drop()


func _drop_nuke() -> void:
	can_drop_bomb = false
	bomb_cooldown.start()
	GameState.use_nuke()
	var bomb := BombScene.instantiate()
	bomb.global_position = bomb_drop_point.global_position
	bomb.initial_velocity = Vector2(velocity.x * 0.7, 50.0)
	bomb.speed_scale = GameState.NUKE_SCALE
	bomb.is_nuke = true
	Events.bomb_dropped.emit(bomb)
	SoundManager.play_bomb_drop()
	SoundManager.speak("Nuke deployed!")


func _fire_special_weapon(weapon: Dictionary) -> void:
	can_drop_bomb = false
	bomb_cooldown.wait_time = weapon["cooldown"]
	bomb_cooldown.start()

	var script_path: String = weapon["script_path"]
	var WeaponScript: GDScript = load(script_path)
	var projectile := Node2D.new()
	projectile.set_script(WeaponScript)
	projectile.global_position = bomb_drop_point.global_position
	projectile.velocity = Vector2(velocity.x * 0.7, 50.0)
	get_tree().current_scene.add_child(projectile)
	SoundManager.play_bomb_drop()


func _fire_machine_gun() -> void:
	var bullet := Node2D.new()
	bullet.set_script(MachineGunScript)
	bullet.global_position = global_position + Vector2(0, 15)
	bullet.velocity = Vector2(velocity.x * 0.2, 350)
	get_tree().current_scene.add_child(bullet)


func _update_crosshair() -> void:
	var bomb_pos := bomb_drop_point.global_position
	var bomb_vel := Vector2(velocity.x * 0.7, 50.0)
	var gravity: float = 420.0
	var ground_y: float = 580.0
	for step in range(120):
		bomb_vel.y += gravity * 0.016
		bomb_pos += bomb_vel * 0.016
		if bomb_pos.y >= ground_y:
			crosshair_pos = bomb_pos
			return
	crosshair_pos = bomb_pos


func _update_exhaust(delta: float) -> void:
	if randf() < 0.6:
		var behind: float = -30.0 if facing == 1 else 30.0
		exhaust_particles.append({
			"pos": Vector2(global_position.x + behind, global_position.y + randf_range(-3, 3)),
			"life": 0.5,
			"max_life": 0.5,
			"size": randf_range(2.0, 5.0),
		})

	var i := 0
	while i < exhaust_particles.size():
		exhaust_particles[i]["life"] -= delta
		exhaust_particles[i]["pos"].x -= velocity.x * 0.2 * delta
		if exhaust_particles[i]["life"] <= 0:
			exhaust_particles.remove_at(i)
		else:
			i += 1
	while exhaust_particles.size() > 30:
		exhaust_particles.remove_at(0)
