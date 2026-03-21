extends CharacterBody2D

@export var move_speed: float = 280.0
@export var vertical_speed: float = 220.0
@export var base_scroll_speed: float = 200.0
@export var min_y: float = 60.0
@export var max_y: float = 420.0

@onready var visual: Node2D = $PlaneVisual
@onready var bomb_cooldown: Timer = $BombCooldownTimer
@onready var bomb_drop_point: Marker2D = $BombDropPoint

const BombScene: PackedScene = preload("res://scenes/bomb/bomb.tscn")

var can_drop_bomb: bool = true
var propeller_angle: float = 0.0
var exhaust_particles: Array[Dictionary] = []
var flash_timer: float = 0.0
var crosshair_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group(&"player")
	bomb_cooldown.wait_time = 0.3
	bomb_cooldown.one_shot = true
	bomb_cooldown.timeout.connect(func(): can_drop_bomb = true)


func _physics_process(delta: float) -> void:
	if GameState.game_phase != &"playing":
		return

	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis(&"move_left", &"move_right")
	input_dir.y = Input.get_axis(&"move_up", &"move_down")

	velocity.x = base_scroll_speed + input_dir.x * move_speed
	velocity.y = input_dir.y * vertical_speed

	if global_position.y <= min_y and velocity.y < 0.0:
		velocity.y = 0.0
		global_position.y = min_y
	if global_position.y >= max_y and velocity.y > 0.0:
		velocity.y = 0.0
		global_position.y = max_y

	move_and_slide()

	var target_rotation := velocity.y * 0.0012
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

	# Bomb input — respect rapid fire power-up
	var cooldown_ready: bool = can_drop_bomb or GameState.has_rapid_fire
	if Input.is_action_just_pressed(&"drop_bomb") and cooldown_ready:
		_drop_bomb()

	# Calculate crosshair position (where bomb would land)
	_update_crosshair()

	_update_exhaust(delta)


func _drop_bomb() -> void:
	can_drop_bomb = false
	if not GameState.has_rapid_fire:
		bomb_cooldown.start()
	else:
		# Rapid fire: very short cooldown
		bomb_cooldown.wait_time = 0.1
		bomb_cooldown.start()
		bomb_cooldown.wait_time = 0.3  # Reset for normal
	var bomb := BombScene.instantiate()
	bomb.global_position = bomb_drop_point.global_position
	bomb.initial_velocity = Vector2(velocity.x * 0.8, 30.0)
	Events.bomb_dropped.emit(bomb)
	SoundManager.play_bomb_drop()


func _update_crosshair() -> void:
	# Simulate bomb trajectory to find landing point
	var bomb_pos := bomb_drop_point.global_position
	var bomb_vel := Vector2(velocity.x * 0.8, 30.0)
	var gravity: float = 420.0
	var ground_y: float = 580.0  # Approximate ground level

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
		exhaust_particles.append({
			"pos": Vector2(global_position.x - 35, global_position.y + randf_range(-3, 3)),
			"life": 0.5,
			"max_life": 0.5,
			"size": randf_range(2.0, 5.0),
		})

	var i := 0
	while i < exhaust_particles.size():
		exhaust_particles[i]["life"] -= delta
		exhaust_particles[i]["pos"].x -= base_scroll_speed * 0.3 * delta
		if exhaust_particles[i]["life"] <= 0:
			exhaust_particles.remove_at(i)
		else:
			i += 1

	while exhaust_particles.size() > 30:
		exhaust_particles.remove_at(0)
