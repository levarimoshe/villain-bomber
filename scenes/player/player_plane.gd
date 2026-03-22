extends CharacterBody2D
## Simple side-scroller plane: UP/DOWN move, RIGHT speeds up, LEFT turns back.
## NO rotation physics. Plane stays horizontal. Just smooth velocity control.

@export var base_speed: float = 150.0       # Default rightward speed
@export var boost_speed: float = 200.0      # Extra speed when pressing RIGHT
@export var turn_speed: float = 180.0       # How fast LEFT pulls you back
@export var vertical_speed: float = 250.0   # UP/DOWN speed
@export var min_y: float = 40.0
@export var max_y: float = 450.0
@export var smoothing: float = 4.0          # How fast velocity changes

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


func _ready() -> void:
	add_to_group(&"player")
	bomb_cooldown.wait_time = 0.3
	bomb_cooldown.one_shot = true
	bomb_cooldown.timeout.connect(func(): can_drop_bomb = true)
	rotation = 0  # ALWAYS horizontal


func _physics_process(delta: float) -> void:
	if GameState.game_phase != &"playing":
		return

	# Keep body rotation at zero — plane is ALWAYS horizontal
	rotation = 0

	var input_h: float = Input.get_axis(&"move_left", &"move_right")
	var input_v: float = Input.get_axis(&"move_up", &"move_down")

	if GameState.is_arena_level and not GameState.boss_active:
		_arena_movement(delta, input_h, input_v)
	else:
		_simple_flight(delta, input_h, input_v)

	# Clamp vertical
	if global_position.y < min_y:
		global_position.y = min_y
		if velocity.y < 0:
			velocity.y = 0
	if global_position.y > max_y:
		global_position.y = max_y
		if velocity.y > 0:
			velocity.y = 0

	move_and_slide()

	# Visual: tiny tilt based on vertical speed (cosmetic only)
	var tilt: float = velocity.y * 0.0015
	visual.rotation = lerpf(visual.rotation, tilt, smoothing * delta)

	# No scale flip — plane always faces right visually
	visual.scale.x = 1.0

	propeller_angle += delta * 30.0

	# Update facing for bomb/exhaust direction
	if velocity.x > 0:
		facing = 1
	else:
		facing = -1

	# Invulnerability flashing
	if GameState.is_invulnerable:
		flash_timer += delta
		visual.visible = fmod(flash_timer, 0.15) < 0.08
	else:
		visual.visible = true
		flash_timer = 0.0

	visual.queue_redraw()

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

	# Machine gun
	if GameState.current_level >= 3:
		mg_cooldown -= delta
		if Input.is_action_pressed(&"machine_gun") and mg_cooldown <= 0:
			_fire_machine_gun()
			mg_cooldown = 0.08

	_update_crosshair()
	_update_exhaust(delta)


## Simple flight: UP=up, DOWN=down, RIGHT=fast, LEFT=turn back
func _simple_flight(delta: float, input_h: float, input_v: float) -> void:
	# Horizontal: base speed + input
	var target_vx: float
	if input_h > 0.1:
		target_vx = base_speed + boost_speed  # RIGHT = fast
	elif input_h < -0.1:
		target_vx = -turn_speed  # LEFT = go backwards (smooth U-turn)
	else:
		target_vx = base_speed  # No input = cruise right

	# Vertical: direct control
	var target_vy: float = input_v * vertical_speed

	# Smooth lerp (frame-rate independent)
	var s: float = 1.0 - exp(-smoothing * delta)
	velocity.x = lerpf(velocity.x, target_vx, s)
	velocity.y = lerpf(velocity.y, target_vy, s)


## Arena orbit
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
			var spread: float = float(offset_idx) * 0.08
			bomb.initial_velocity = Vector2(velocity.x * 0.6, 50.0).rotated(spread)
			bomb.speed_scale = bomb_scale
			Events.bomb_dropped.emit(bomb)
	else:
		var bomb := BombScene.instantiate()
		bomb.global_position = bomb_drop_point.global_position
		bomb.initial_velocity = Vector2(velocity.x * 0.6, 50.0)
		bomb.speed_scale = bomb_scale
		Events.bomb_dropped.emit(bomb)

	SoundManager.play_bomb_drop()


func _drop_nuke() -> void:
	can_drop_bomb = false
	bomb_cooldown.start()
	GameState.use_nuke()
	var bomb := BombScene.instantiate()
	bomb.global_position = bomb_drop_point.global_position
	bomb.initial_velocity = Vector2(velocity.x * 0.6, 50.0)
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
	projectile.velocity = Vector2(velocity.x * 0.6, 50.0)
	get_tree().current_scene.add_child(projectile)
	SoundManager.play_bomb_drop()


func _fire_machine_gun() -> void:
	var bullet := Node2D.new()
	bullet.set_script(MachineGunScript)
	bullet.global_position = global_position + Vector2(0, 15)
	bullet.velocity = Vector2(velocity.x * 0.2, 350)
	get_tree().current_scene.add_child(bullet)


func _update_crosshair() -> void:
	var bomb_pos: Vector2 = bomb_drop_point.global_position
	var bomb_vel: Vector2 = Vector2(velocity.x * 0.6, 50.0)
	var grav: float = 420.0
	for step in range(120):
		bomb_vel.y += grav * 0.016
		bomb_pos += bomb_vel * 0.016
		if bomb_pos.y >= 580.0:
			crosshair_pos = bomb_pos
			return
	crosshair_pos = bomb_pos


func _update_exhaust(delta: float) -> void:
	if randf() < 0.6:
		exhaust_particles.append({
			"pos": Vector2(global_position.x - 30, global_position.y + randf_range(-3, 3)),
			"life": 0.5,
			"max_life": 0.5,
			"size": randf_range(2.0, 5.0),
		})

	var i := 0
	while i < exhaust_particles.size():
		exhaust_particles[i]["life"] -= delta
		exhaust_particles[i]["pos"].x -= 40 * delta
		if exhaust_particles[i]["life"] <= 0:
			exhaust_particles.remove_at(i)
		else:
			i += 1
	while exhaust_particles.size() > 30:
		exhaust_particles.remove_at(0)
