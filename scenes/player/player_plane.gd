extends CharacterBody2D
## Luftrausers-style rotation movement:
## LEFT/RIGHT rotates the plane. Thrust pushes FORWARD in facing direction.
## transform.x = always the plane's forward direction.
## Smooth curves happen naturally from momentum + gradual rotation.

@export var thrust_power: float = 350.0      # Forward push strength
@export var rotation_speed: float = 3.0      # How fast the plane turns (rad/s)
@export var gravity: float = 120.0           # Gentle downward pull
@export var max_speed: float = 400.0         # Speed cap
@export var drag: float = 0.98              # Air resistance (momentum decay)
@export var min_y: float = 40.0
@export var max_y: float = 450.0

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
var facing: int = 1
var current_thrust: float = 0.0


func _ready() -> void:
	add_to_group(&"player")
	bomb_cooldown.wait_time = 0.3
	bomb_cooldown.one_shot = true
	bomb_cooldown.timeout.connect(func(): can_drop_bomb = true)
	# Start facing right
	rotation = 0.0


func _physics_process(delta: float) -> void:
	if GameState.game_phase != &"playing":
		return

	var input_h: float = Input.get_axis(&"move_left", &"move_right")
	var input_v: float = Input.get_axis(&"move_up", &"move_down")

	if GameState.is_arena_level and not GameState.boss_active:
		_arena_movement(delta, input_h, input_v)
	else:
		_rotation_flight(delta, input_h, input_v)

	# Clamp vertical position
	if global_position.y < min_y:
		global_position.y = min_y
		if velocity.y < 0:
			velocity.y *= -0.3  # Soft bounce off top
	if global_position.y > max_y:
		global_position.y = max_y
		if velocity.y > 0:
			velocity.y *= -0.3  # Soft bounce off bottom

	move_and_slide()

	# Visual follows the body rotation smoothly
	# The visual is a child so it inherits rotation, but we want
	# the visual to stay horizontal-ish (just tilt slightly)
	# So we counter-rotate the visual and add a tilt
	visual.rotation = -rotation + sin(rotation) * 0.3

	propeller_angle += delta * 30.0

	# Invulnerability flashing
	if GameState.is_invulnerable:
		flash_timer += delta
		visual.visible = fmod(flash_timer, 0.15) < 0.08
	else:
		visual.visible = true
		flash_timer = 0.0

	visual.queue_redraw()

	# Update facing for bomb direction
	if velocity.x > 10:
		facing = 1
	elif velocity.x < -10:
		facing = -1

	# === WEAPONS ===
	var cooldown_ready: bool = can_drop_bomb or GameState.has_rapid_fire
	if Input.is_action_just_pressed(&"drop_bomb") and cooldown_ready:
		var going_fast: bool = velocity.length() > 200.0
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


## THE CORE: Rotation-based flight (Luftrausers style)
func _rotation_flight(delta: float, input_h: float, input_v: float) -> void:
	# === ROTATION ===
	# LEFT/RIGHT rotates the plane body
	rotation += input_h * rotation_speed * delta

	# === THRUST ===
	# UP = more thrust, DOWN = less thrust, default = moderate forward push
	var thrust_input: float = 1.0  # Always some forward thrust
	if input_v < -0.1:
		thrust_input = 1.5  # UP = boost
	elif input_v > 0.1:
		thrust_input = 0.3  # DOWN = slow

	current_thrust = lerpf(current_thrust, thrust_power * thrust_input, 1.0 - exp(-5.0 * delta))

	# transform.x = the direction the plane faces (magic!)
	# This is what makes curves natural — velocity follows rotation
	var thrust_vector: Vector2 = transform.x * current_thrust

	# Apply thrust
	velocity += thrust_vector * delta

	# Apply gentle gravity (makes swooping feel natural)
	velocity.y += gravity * delta

	# Apply drag (air resistance — prevents infinite acceleration)
	velocity *= pow(drag, delta * 60.0)

	# Speed cap
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	# Ensure minimum forward speed so screen keeps scrolling
	if velocity.x < 30.0 and not GameState.boss_active:
		velocity.x = lerpf(velocity.x, 50.0, delta * 2.0)


## Arena orbit movement (unchanged)
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
	# Rotate body to face velocity direction
	if velocity.length() > 10:
		rotation = velocity.angle()


func _drop_bomb() -> void:
	can_drop_bomb = false
	if not GameState.has_rapid_fire:
		bomb_cooldown.start()
	else:
		var rf_cooldowns: Array = [0.3, 0.12, 0.08, 0.05]
		bomb_cooldown.wait_time = rf_cooldowns[clampi(GameState.rapid_fire_level, 0, 3)]
		bomb_cooldown.start()
		bomb_cooldown.wait_time = 0.3

	var speed_factor: float = clampf(velocity.length() / 500.0, 0.0, 1.0)
	var bomb_scale: float = 1.0 + speed_factor * 0.8

	if GameState.has_rapid_fire:
		var bomb_count: int = 1 + GameState.rapid_fire_level * 2
		var half: int = bomb_count / 2
		for i in range(bomb_count):
			var bomb := BombScene.instantiate()
			var offset_idx: int = i - half
			var offset: Vector2 = transform.y * float(offset_idx) * 12.0
			bomb.global_position = bomb_drop_point.global_position + offset
			var spread: float = float(offset_idx) * 0.08
			bomb.initial_velocity = velocity * 0.5 + Vector2(0, 50)
			bomb.initial_velocity = bomb.initial_velocity.rotated(spread)
			bomb.speed_scale = bomb_scale
			Events.bomb_dropped.emit(bomb)
	else:
		var bomb := BombScene.instantiate()
		bomb.global_position = bomb_drop_point.global_position
		bomb.initial_velocity = velocity * 0.5 + Vector2(0, 50)
		bomb.speed_scale = bomb_scale
		Events.bomb_dropped.emit(bomb)

	SoundManager.play_bomb_drop()


func _drop_nuke() -> void:
	can_drop_bomb = false
	bomb_cooldown.start()
	GameState.use_nuke()
	var bomb := BombScene.instantiate()
	bomb.global_position = bomb_drop_point.global_position
	bomb.initial_velocity = velocity * 0.5 + Vector2(0, 50)
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
	projectile.velocity = velocity * 0.5 + Vector2(0, 50)
	get_tree().current_scene.add_child(projectile)
	SoundManager.play_bomb_drop()


func _fire_machine_gun() -> void:
	var bullet := Node2D.new()
	bullet.set_script(MachineGunScript)
	# Fire downward from plane
	bullet.global_position = global_position + Vector2(0, 15).rotated(rotation)
	bullet.velocity = Vector2(velocity.x * 0.2, 350)
	get_tree().current_scene.add_child(bullet)


func _update_crosshair() -> void:
	var bomb_pos: Vector2 = bomb_drop_point.global_position
	var bomb_vel: Vector2 = velocity * 0.5 + Vector2(0, 50)
	var grav: float = 420.0
	var ground_y: float = 580.0
	for step in range(120):
		bomb_vel.y += grav * 0.016
		bomb_pos += bomb_vel * 0.016
		if bomb_pos.y >= ground_y:
			crosshair_pos = bomb_pos
			return
	crosshair_pos = bomb_pos


func _update_exhaust(delta: float) -> void:
	if randf() < 0.6:
		# Exhaust comes from behind the plane (opposite of transform.x)
		var behind: Vector2 = -transform.x * 30
		exhaust_particles.append({
			"pos": Vector2(global_position.x + behind.x, global_position.y + behind.y + randf_range(-3, 3)),
			"life": 0.5,
			"max_life": 0.5,
			"size": randf_range(2.0, 5.0),
		})

	var i := 0
	while i < exhaust_particles.size():
		exhaust_particles[i]["life"] -= delta
		exhaust_particles[i]["pos"] += -transform.x * 20 * delta
		if exhaust_particles[i]["life"] <= 0:
			exhaust_particles.remove_at(i)
		else:
			i += 1
	while exhaust_particles.size() > 30:
		exhaust_particles.remove_at(0)
