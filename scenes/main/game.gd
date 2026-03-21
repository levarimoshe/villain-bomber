extends Node2D

@onready var bombs_container: Node2D = $Entities/Bombs
@onready var villains_container: Node2D = $Entities/Villains
@onready var explosions_container: Node2D = $Entities/Explosions
@onready var spawn_timer: Timer = $VillainSpawnTimer
@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Entities/PlayerPlane
@onready var hud: Control = $HUDLayer/HUD
@onready var main_menu: Control = $UILayer/MainMenu
@onready var game_over_screen: Control = $UILayer/GameOver
@onready var ground_collider: StaticBody2D = $GroundCollider
@onready var level_label: Label = $HUDLayer/LevelTransitionLabel

const VillainScene: PackedScene = preload("res://scenes/villain/villain.tscn")
const ExplosionScene: PackedScene = preload("res://scenes/explosion/explosion.tscn")
const BombScene: PackedScene = preload("res://scenes/bomb/bomb.tscn")

var screen_shake_amount: float = 0.0
var screen_shake_decay: float = 0.9
var power_up_rain_timer: float = 5.0


func _ready() -> void:
	Events.bomb_dropped.connect(_on_bomb_dropped)
	Events.villain_killed.connect(_on_villain_killed)
	Events.bomb_hit_ground.connect(_on_bomb_hit_ground)
	Events.game_over.connect(_on_game_over)
	Events.game_started.connect(_on_game_started)
	Events.villain_escaped.connect(_on_villain_escaped)
	Events.level_changed.connect(_on_level_changed)
	Events.player_hit.connect(_on_player_hit)

	spawn_timer.timeout.connect(_spawn_villain)

	# Add ground to group for bomb collision detection
	ground_collider.add_to_group(&"ground")

	# Start in menu state
	_show_menu()


func _show_menu() -> void:
	GameState.game_phase = &"menu"
	player.visible = false
	player.set_physics_process(false)
	spawn_timer.stop()
	main_menu.visible = true
	game_over_screen.visible = false
	hud.visible = false
	level_label.visible = false
	_clear_entities()


func _on_game_started() -> void:
	GameState.reset()
	GameState.game_phase = &"playing"
	player.visible = true
	player.set_physics_process(true)
	player.global_position = Vector2(300, 250)
	main_menu.visible = false
	game_over_screen.visible = false
	hud.visible = true
	level_label.visible = false
	spawn_timer.wait_time = GameState.spawn_interval
	spawn_timer.start()
	_clear_entities()
	Events.score_changed.emit(0)
	Events.lives_changed.emit(GameState.lives)
	Events.level_changed.emit(1)


func _on_game_over() -> void:
	spawn_timer.stop()
	GameState.save_high_score()
	player.set_physics_process(false)
	game_over_screen.show_game_over()
	hud.visible = false


func _physics_process(delta: float) -> void:
	if GameState.game_phase != &"playing" and GameState.game_phase != &"level_transition":
		return

	# Camera follows player
	camera.global_position.x = player.global_position.x + 200.0
	camera.global_position.y = 360.0

	# Screen shake
	if screen_shake_amount > 0.5:
		camera.offset = Vector2(
			randf_range(-screen_shake_amount, screen_shake_amount),
			randf_range(-screen_shake_amount, screen_shake_amount)
		)
		screen_shake_amount *= screen_shake_decay
	else:
		camera.offset = Vector2.ZERO
		screen_shake_amount = 0.0

	# Update ground collider position to follow camera
	var ground_y := 590.0
	ground_collider.global_position = Vector2(camera.global_position.x, ground_y)

	# Power-up rain from the sky every 5-10 seconds
	if GameState.game_phase == &"playing":
		power_up_rain_timer -= delta
		if power_up_rain_timer <= 0:
			power_up_rain_timer = randf_range(5.0, 10.0)
			_spawn_sky_power_up()


func _spawn_villain() -> void:
	if GameState.game_phase != &"playing":
		return

	var villain := VillainScene.instantiate()
	var cam_x := camera.global_position.x
	# Spawn from right side
	var spawn_x := cam_x + 750.0
	var ground_y_at_spawn := _get_ground_y_approx(spawn_x)
	villain.global_position = Vector2(spawn_x, ground_y_at_spawn)
	villain.speed = randf_range(90.0, 140.0) * GameState.villain_speed_multiplier
	villain.direction = -1
	villain.camera_ref = camera
	villains_container.add_child(villain)

	# Group spawns — more likely at higher levels
	var extra_count: int = 0
	var group_chance: float = 0.4 + GameState.current_level * 0.08
	if randf() < group_chance:
		extra_count = 1
	if randf() < group_chance * 0.4:
		extra_count = 2

	for e in range(extra_count):
		var extra := VillainScene.instantiate()
		extra.global_position = Vector2(spawn_x + randf_range(30, 100) * (e + 1), ground_y_at_spawn)
		extra.speed = randf_range(70.0, 130.0) * GameState.villain_speed_multiplier
		extra.direction = -1
		extra.camera_ref = camera
		villains_container.add_child(extra)


func _on_bomb_dropped(bomb: Node2D) -> void:
	bombs_container.add_child(bomb)
	GameState.total_bombs_dropped += 1


func _on_villain_killed(pos: Vector2, points: int) -> void:
	GameState.total_villains_killed += 1
	GameState.villains_killed_this_level += 1
	GameState.register_kill()
	GameState.add_score(points)
	var multiplier: int = GameState.get_combo_multiplier()
	_spawn_score_popup(pos, points * multiplier)

	# Spawn a mini explosion at the villain's death position
	_spawn_villain_death_effect(pos)

	# Chance to spawn power-up
	if randf() < 0.12:
		_spawn_power_up(pos)

	if GameState.villains_killed_this_level >= GameState.villains_per_level:
		_start_level_transition()


func _on_villain_escaped() -> void:
	GameState.register_escape()


func _on_player_hit() -> void:
	if GameState.game_phase != &"playing":
		return
	if GameState.is_invulnerable or GameState.has_shield:
		GameState.lose_life()  # Will be blocked by shield/invuln in game_state
		return
	screen_shake_amount = 12.0
	player.modulate = Color.RED
	var tween := create_tween()
	tween.tween_property(player, "modulate", Color.WHITE, 0.3)
	GameState.lose_life()
	SoundManager.play_hit()


func _on_bomb_hit_ground(pos: Vector2) -> void:
	_spawn_explosion(pos)
	# Check if any nearby villains are hit by the blast radius
	var blast_radius: float = 65.0 if not GameState.has_mega_bomb else 130.0
	for villain in villains_container.get_children():
		if villain.has_method("hit_by_bomb") and not villain.is_dying:
			var dist: float = villain.global_position.distance_to(pos)
			if dist < blast_radius:
				villain.hit_by_bomb()


func _spawn_explosion(pos: Vector2) -> void:
	var explosion := ExplosionScene.instantiate()
	explosion.global_position = pos
	explosions_container.add_child(explosion)
	screen_shake_amount = 8.0
	SoundManager.play_explosion()

	# Spawn lingering ground fire
	var FireScript: GDScript = preload("res://scenes/explosion/ground_fire.gd")
	var fire := Node2D.new()
	fire.set_script(FireScript)
	fire.global_position = pos
	explosions_container.add_child(fire)


func _start_level_transition() -> void:
	GameState.game_phase = &"level_transition"
	spawn_timer.stop()
	SoundManager.play_levelup()
	level_label.visible = true
	level_label.text = "LEVEL %d COMPLETE!" % GameState.current_level

	# Wait 2 seconds then advance
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(_finish_level_transition)


func _finish_level_transition() -> void:
	GameState.advance_level()
	GameState.game_phase = &"playing"
	level_label.visible = false
	spawn_timer.wait_time = GameState.spawn_interval
	spawn_timer.start()


func _on_level_changed(_level: int) -> void:
	pass # HUD handles display


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if GameState.game_phase == &"playing":
			GameState.game_phase = &"paused"
			spawn_timer.paused = true
			level_label.text = "PAUSED\nPress ESC to Resume"
			level_label.visible = true
		elif GameState.game_phase == &"paused":
			GameState.game_phase = &"playing"
			spawn_timer.paused = false
			level_label.visible = false


func _clear_entities() -> void:
	for child in bombs_container.get_children():
		child.queue_free()
	for child in villains_container.get_children():
		child.queue_free()
	for child in explosions_container.get_children():
		child.queue_free()
	# Clean up bullets (they're added to the scene root)
	for child in get_children():
		if child.has_method("_draw_glow") or child.is_in_group(&"bullet"):
			child.queue_free()


func _spawn_score_popup(pos: Vector2, points: int) -> void:
	var popup := Label.new()
	popup.text = "+%d" % points
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", 20)
	popup.add_theme_color_override("font_color", Color.YELLOW)
	popup.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.add_theme_constant_override("outline_size", 3)
	popup.global_position = pos - Vector2(20, 30)
	add_child(popup)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 50, 0.8)
	tween.tween_property(popup, "modulate:a", 0.0, 0.8)
	tween.finished.connect(popup.queue_free)


func _spawn_power_up(pos: Vector2) -> void:
	var PowerUpScript: GDScript = preload("res://scenes/powerup/powerup.gd")
	var pu := Node2D.new()
	pu.set_script(PowerUpScript)
	pu.global_position = pos + Vector2(0, -20)
	var types: Array = ["shield", "rapid_fire", "mega_bomb"]
	pu.power_type = types[randi() % types.size()]
	add_child(pu)


func _spawn_sky_power_up() -> void:
	var PowerUpScript: GDScript = preload("res://scenes/powerup/powerup.gd")
	var pu := Node2D.new()
	pu.set_script(PowerUpScript)
	# Spawn above the camera view, ahead of the player
	var cam_x: float = camera.global_position.x
	pu.global_position = Vector2(cam_x + randf_range(-200, 400), -30)
	var types: Array = ["shield", "rapid_fire", "mega_bomb"]
	pu.power_type = types[randi() % types.size()]
	pu.from_sky = true
	add_child(pu)


func _spawn_villain_death_effect(pos: Vector2) -> void:
	# Mini explosion at villain position
	var VillainDeathScript: GDScript = preload("res://scenes/explosion/villain_death_fx.gd")
	var fx := Node2D.new()
	fx.set_script(VillainDeathScript)
	fx.global_position = pos
	explosions_container.add_child(fx)


func _get_ground_y_approx(world_x: float) -> float:
	return 580.0 - (sin(world_x * 0.005) * 45.0 + sin(world_x * 0.013) * 20.0) - 10.0
