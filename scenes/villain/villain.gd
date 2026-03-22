extends Area2D

@export var speed: float = 80.0
var direction: int = -1
var is_dying: bool = false
var anim_time: float = 0.0
var villain_type: int = 0  # 0=soldier, 1=soldier_alt, 2=officer
var camera_ref: Camera2D = null
var shoot_timer: float = 0.0
var shoot_interval: float = 2.5
var can_shoot: bool = true
var muzzle_flash_timer: float = 0.0
var death_timer: float = 0.0
var death_spin: float = 0.0
var death_velocity: Vector2 = Vector2.ZERO

const BulletScript = preload("res://scenes/villain/bullet.gd")


func _ready() -> void:
	add_to_group(&"villains")
	# Officer type at level 3+
	if GameState.current_level >= 3 and randf() < 0.25:
		villain_type = 2
	else:
		villain_type = randi() % 2
	anim_time = randf() * TAU
	# Fewer shooters at start, gradually more per level
	var shoot_chance: float = minf(0.15 + GameState.current_level * 0.05, 0.6)
	can_shoot = randf() < shoot_chance
	# Shoot interval: slower at start, faster at higher levels
	var base_interval: float = maxf(1.5, 3.5 - GameState.current_level * 0.1)
	shoot_interval = randf_range(base_interval, base_interval + 2.0)
	shoot_timer = randf_range(1.0, shoot_interval)


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	# Death animation
	if is_dying:
		death_timer -= delta
		death_spin += delta * 12.0
		death_velocity.y -= 80.0 * delta
		position += death_velocity * delta
		modulate.a = clampf(death_timer / 0.5, 0.0, 1.0)
		$VillainVisual.rotation = death_spin
		$VillainVisual.queue_redraw()
		if death_timer <= 0:
			queue_free()
		return

	# Dodge at high levels
	if GameState.current_level >= 5 and randf() < 0.01:
		speed = speed * randf_range(0.6, 1.5)

	position.x += direction * speed * delta
	anim_time += delta * 8.0

	# Muzzle flash countdown
	if muzzle_flash_timer > 0:
		muzzle_flash_timer -= delta

	$VillainVisual.scale.x = float(-direction)
	$VillainVisual.queue_redraw()

	# Shooting
	if can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			shoot_timer = shoot_interval
			_shoot()

	if camera_ref:
		var cam_x := camera_ref.global_position.x
		if global_position.x < cam_x - 800:
			Events.villain_escaped.emit()
			queue_free()


func _shoot() -> void:
	muzzle_flash_timer = 0.12
	var bullet := Node2D.new()
	bullet.set_script(BulletScript)
	bullet.global_position = global_position + Vector2(direction * 10, -35)

	var player_node: Node = get_tree().get_first_node_in_group(&"player")
	if player_node:
		var dir_to_player: Vector2 = (player_node.global_position - global_position).normalized()
		var spread: float = randf_range(-0.3, 0.3)
		dir_to_player = dir_to_player.rotated(spread)
		bullet.velocity = dir_to_player * randf_range(200.0, 320.0)
	else:
		bullet.velocity = Vector2(0, -250)

	get_tree().current_scene.add_child(bullet)
	SoundManager.play_shoot()


func hit_by_bomb() -> void:
	if is_dying:
		return
	is_dying = true
	death_timer = 0.5
	death_velocity = Vector2(randf_range(-40, 40), -120)
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	Events.villain_killed.emit(global_position, GameState.POINTS_HIT)
