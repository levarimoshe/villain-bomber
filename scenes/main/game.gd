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
const BossScript: GDScript = preload("res://scenes/boss/boss.gd")

var screen_shake_amount: float = 0.0
var screen_shake_decay: float = 0.9
var power_up_rain_timer: float = 5.0
var fade_overlay: ColorRect = null
var camera_target_x: float = 640.0
var trauma: float = 0.0  # 0.0-1.0 trauma-based shake
var hitstop_timer: float = 0.0
var accuracy_streak: int = 0  # Bombs that hit in a row
var accuracy_multiplier: float = 1.0


func _ready() -> void:
	Events.bomb_dropped.connect(_on_bomb_dropped)
	Events.villain_killed.connect(_on_villain_killed)
	Events.bomb_hit_ground.connect(_on_bomb_hit_ground)
	Events.game_over.connect(_on_game_over)
	Events.game_started.connect(_on_game_started)
	Events.villain_escaped.connect(_on_villain_escaped)
	Events.level_changed.connect(_on_level_changed)
	Events.player_hit.connect(_on_player_hit)
	Events.level_transition_started.connect(_on_boss_defeated)

	spawn_timer.timeout.connect(_spawn_villain)

	# Add ground to group for bomb collision detection
	ground_collider.add_to_group(&"ground")

	# Create fade overlay for smooth transitions
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUDLayer.add_child(fade_overlay)
	fade_overlay.z_index = 100

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
	SoundManager.start_music()
	camera_target_x = player.global_position.x + 150.0
	camera.global_position.x = camera_target_x
	# Fade in from black
	fade_overlay.color.a = 1.0
	var fade_tween := create_tween()
	fade_tween.tween_property(fade_overlay, "color:a", 0.0, 0.6)


func _on_game_over() -> void:
	spawn_timer.stop()
	GameState.save_high_score()
	player.set_physics_process(false)
	game_over_screen.show_game_over()
	hud.visible = false
	SoundManager.stop_music()
	SoundManager.speak("Game over!")


func _physics_process(delta: float) -> void:
	if GameState.game_phase != &"playing" and GameState.game_phase != &"level_transition":
		return

	# Camera — smooth lerp for all modes
	if GameState.boss_active:
		# Boss fight: lock camera on boss position (find the boss)
		var boss_node: Node = get_tree().get_first_node_in_group(&"boss")
		if boss_node:
			camera_target_x = boss_node.global_position.x
		camera.global_position.x = lerp(camera.global_position.x, camera_target_x, 0.03)
	elif GameState.is_arena_level:
		# Arena defense: camera on center
		camera_target_x = GameState.arena_center_x
		camera.global_position.x = lerp(camera.global_position.x, camera_target_x, 0.03)
	else:
		# Normal: follow player with offset based on facing
		var facing: int = 1
		if player.has_method("_physics_process"):
			facing = player.facing
		camera_target_x = player.global_position.x + 150.0 * float(facing)
		camera.global_position.x = lerp(camera.global_position.x, camera_target_x, 0.04)
	camera.global_position.y = lerp(camera.global_position.y, 360.0, 0.05)

	# Hit stop (brief freeze on impact)
	if hitstop_timer > 0:
		hitstop_timer -= delta
		Engine.time_scale = 0.05
		return
	elif Engine.time_scale < 1.0:
		Engine.time_scale = 1.0

	# Trauma-based screen shake (intensity = trauma^2)
	trauma = maxf(0.0, trauma - delta * 1.5)  # Decay
	if trauma > 0.01:
		var shake_intensity: float = trauma * trauma * 10.0
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		camera.offset = Vector2.ZERO

	# Camera zoom effects (smooth return to normal)
	camera.zoom = camera.zoom.lerp(Vector2.ONE, 0.03)

	# Update ground collider position to follow camera
	var ground_y := 590.0
	ground_collider.global_position = Vector2(camera.global_position.x, ground_y)

	# Power-up rain from the sky every 5-10 seconds
	if GameState.game_phase == &"playing":
		power_up_rain_timer -= delta
		if power_up_rain_timer <= 0:
			power_up_rain_timer = randf_range(4.0, 7.0)
			if GameState.boss_active:
				power_up_rain_timer = 5.0  # Guaranteed gifts during boss
			_spawn_sky_power_up()


func _spawn_villain() -> void:
	if GameState.game_phase != &"playing":
		return
	# No soldiers during boss fight — boss only!
	if GameState.boss_active:
		return

	var cam_x := camera.global_position.x

	if GameState.is_arena_level:
		# Arena mode — spawn from both sides!
		var spawn_count: int = randi_range(1, 3)
		for s in range(spawn_count):
			var villain := VillainScene.instantiate()
			var from_right: bool = randf() < 0.5
			var spawn_x: float
			if from_right:
				spawn_x = cam_x + randf_range(650, 800)
				villain.direction = -1
			else:
				spawn_x = cam_x - randf_range(650, 800)
				villain.direction = 1
			var ground_y: float = _get_ground_y_approx(spawn_x)
			villain.global_position = Vector2(spawn_x, ground_y)
			villain.speed = randf_range(70.0, 120.0) * GameState.villain_speed_multiplier
			villain.camera_ref = camera
			villains_container.add_child(villain)
		return

	# Normal mode — spawn from right
	var villain := VillainScene.instantiate()
	var spawn_x := cam_x + 750.0
	var ground_y_at_spawn := _get_ground_y_approx(spawn_x)
	villain.global_position = Vector2(spawn_x, ground_y_at_spawn)
	villain.speed = randf_range(60.0, 110.0) * GameState.villain_speed_multiplier
	villain.direction = -1
	villain.camera_ref = camera
	villains_container.add_child(villain)

	# Group spawns
	var extra_count: int = 0
	var group_chance: float = 0.4 + GameState.current_level * 0.08
	if randf() < group_chance:
		extra_count = 1
	if randf() < group_chance * 0.4:
		extra_count = 2

	for e in range(extra_count):
		var extra := VillainScene.instantiate()
		extra.global_position = Vector2(spawn_x + randf_range(30, 100) * (e + 1), ground_y_at_spawn)
		extra.speed = randf_range(50.0, 100.0) * GameState.villain_speed_multiplier
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
	accuracy_streak += 1
	accuracy_multiplier = minf(1.0 + float(accuracy_streak) * 0.25, 3.0)
	GameState.add_score(points)
	var multiplier: int = GameState.get_combo_multiplier()
	_spawn_score_popup(pos, points * multiplier)

	# JUICE: hit stop + kill flash + trauma
	hitstop_timer = 0.03  # Brief freeze frame
	trauma = minf(trauma + 0.25, 1.0)
	# Kill flash (brief white overlay)
	if fade_overlay:
		fade_overlay.color = Color(1, 1, 1, 0.15)
		var flash_tween := create_tween()
		flash_tween.tween_property(fade_overlay, "color:a", 0.0, 0.08)

	_spawn_villain_death_effect(pos)

	# Chance to spawn power-up
	if randf() < 0.18:
		_spawn_power_up(pos)

	# Check level/arena progression
	if GameState.boss_active:
		pass  # Boss must die to advance — boss.gd handles boss_active flag
	elif GameState.is_arena_level:
		_arena_villain_killed()
	elif GameState.villains_killed_this_level >= GameState.villains_per_level:
		_start_level_transition()


func _on_villain_escaped() -> void:
	GameState.register_escape()


func _on_player_hit() -> void:
	if GameState.game_phase != &"playing":
		return
	if GameState.is_invulnerable:
		return  # No effect during i-frames
	if GameState.has_shield:
		# Shield absorbs the hit — big visual feedback
		GameState.has_shield = false
		screen_shake_amount = 5.0
		player.modulate = Color(0.3, 0.6, 1.0)  # Blue flash
		var tween := create_tween()
		tween.tween_property(player, "modulate", Color.WHITE, 0.4)
		SoundManager.play_shield_break()
		# Spawn shield break particles
		_spawn_shield_break_effect(player.global_position)
		return
	# Actually take damage
	screen_shake_amount = 12.0
	player.modulate = Color.RED
	var tween2 := create_tween()
	tween2.tween_property(player, "modulate", Color.WHITE, 0.3)
	GameState.lose_life()
	SoundManager.play_hit()


func _on_bomb_hit_ground(pos: Vector2, bomb_scale: float, was_nuke: bool) -> void:
	# Determine explosion visual scale and blast radius
	var visual_scale: float = bomb_scale
	var blast_radius: float

	if was_nuke:
		# NUKE — kills everything on screen with DRAMA
		blast_radius = 800.0
		visual_scale = 1.8
		trauma = 1.0
		# Slow motion for nuke impact
		Engine.time_scale = 0.2
		var slowmo_tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		slowmo_tween.tween_interval(0.3)
		slowmo_tween.tween_property(Engine, "time_scale", 1.0, 0.2)
		# Camera zoom in
		camera.zoom = Vector2(1.15, 1.15)
	else:
		# Normal bomb — base 100px, scales with speed, mega bomb doubles
		var base: float = 100.0
		if GameState.has_mega_bomb:
			base = 180.0
		blast_radius = base * bomb_scale
		visual_scale = maxf(bomb_scale, 1.2)  # Always a decent explosion

	_spawn_explosion(pos, visual_scale)

	# Kill all villains in blast radius
	var kill_count: int = 0
	for villain in villains_container.get_children():
		if villain.has_method("hit_by_bomb") and not villain.is_dying:
			var dist: float = villain.global_position.distance_to(pos)
			if dist < blast_radius:
				villain.hit_by_bomb()
				kill_count += 1

	# Accuracy streak: miss resets, hits counted in _on_villain_killed
	if kill_count == 0 and not was_nuke:
		accuracy_streak = 0
		accuracy_multiplier = 1.0

	# Nuke voice feedback
	if was_nuke and kill_count > 0:
		SoundManager.speak("%d enemies destroyed!" % kill_count)


func _spawn_explosion(pos: Vector2, scale_factor: float = 1.0) -> void:
	var explosion := ExplosionScene.instantiate()
	explosion.global_position = pos
	explosion.max_radius = 75.0 * scale_factor
	explosion.scale = Vector2(scale_factor, scale_factor)
	explosions_container.add_child(explosion)
	screen_shake_amount = 8.0 * scale_factor
	SoundManager.play_explosion()

	# Spawn lingering ground fire — scales with explosion
	var FireScript: GDScript = preload("res://scenes/explosion/ground_fire.gd")
	var fire := Node2D.new()
	fire.set_script(FireScript)
	fire.global_position = pos
	fire.scale = Vector2(scale_factor, scale_factor)
	explosions_container.add_child(fire)


func _start_level_transition() -> void:
	GameState.game_phase = &"level_transition"
	spawn_timer.stop()
	SoundManager.play_levelup()

	# Smooth fade out → show text → fade in
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.7, 0.4)  # Fade to dark
	tween.tween_callback(func():
		level_label.visible = true
		level_label.text = "LEVEL %d COMPLETE!" % GameState.current_level
	)
	tween.tween_interval(1.5)  # Hold
	tween.tween_callback(func(): level_label.visible = false)
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.4)  # Fade back in
	tween.tween_callback(_finish_level_transition)


func _finish_level_transition() -> void:
	GameState.advance_level()
	GameState.game_phase = &"playing"
	level_label.visible = false

	# Boss fight every 6 levels (5, 11, 17...)
	if (GameState.current_level + 1) % 6 == 0:
		_spawn_boss_arena()
	# Arena defense every 3 levels (but not boss levels)
	elif GameState.current_level % 3 == 0:
		_start_arena_level()
	else:
		GameState.is_arena_level = false
		spawn_timer.wait_time = GameState.spawn_interval
		spawn_timer.start()


func _on_level_changed(_level: int) -> void:
	WeaponSystem.check_unlocks()


func _on_boss_defeated(_level: int) -> void:
	_start_level_transition()


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
	# Spawn ahead OR behind the player (50/50 chance)
	var cam_x: float = camera.global_position.x
	var player_x: float = player.global_position.x
	var spawn_x: float
	if randf() < 0.5:
		# Ahead of player
		spawn_x = player_x + randf_range(100, 400)
	else:
		# Behind player — they need to slow down or it passes them
		spawn_x = player_x + randf_range(-350, -50)
	pu.global_position = Vector2(spawn_x, -30)
	var types: Array = ["shield", "rapid_fire", "mega_bomb"]
	pu.power_type = types[randi() % types.size()]
	pu.from_sky = true
	add_child(pu)


func _start_arena_level() -> void:
	GameState.is_arena_level = true
	GameState.arena_wave = 1
	GameState.arena_kills_this_wave = 0
	GameState.arena_kills_needed = 6 + GameState.current_level
	GameState.arena_center_x = player.global_position.x + 100
	spawn_timer.wait_time = 0.8  # Fast spawning in arena
	spawn_timer.start()
	level_label.visible = true
	level_label.text = "DEFENSE MODE!\nWave %d/%d" % [GameState.arena_wave, GameState.arena_max_waves]
	SoundManager.speak("Defense mode! Hold your position!")

	# Hide label after 2 seconds
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(func(): level_label.visible = false)


func _arena_villain_killed() -> void:
	GameState.arena_kills_this_wave += 1
	if GameState.arena_kills_this_wave >= GameState.arena_kills_needed:
		GameState.arena_wave += 1
		GameState.arena_kills_this_wave = 0
		if GameState.arena_wave > GameState.arena_max_waves:
			# Arena complete
			GameState.is_arena_level = false
			_start_level_transition()
		else:
			# Next wave
			GameState.arena_kills_needed += 3
			level_label.visible = true
			level_label.text = "Wave %d/%d" % [GameState.arena_wave, GameState.arena_max_waves]
			SoundManager.speak("Wave %d!" % GameState.arena_wave)
			var tween := create_tween()
			tween.tween_interval(1.5)
			tween.tween_callback(func(): level_label.visible = false)


func _spawn_boss_arena() -> void:
	GameState.is_arena_level = true
	GameState.arena_center_x = player.global_position.x + 200
	spawn_timer.wait_time = 2.0
	spawn_timer.start()

	# Fade transition for boss entrance
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.6, 0.3)
	tween.tween_callback(func():
		level_label.visible = true
		level_label.text = "BOSS FIGHT!"
		# Spawn boss during the dark
		var boss := Node2D.new()
		boss.set_script(BossScript)
		var ground_y: float = _get_ground_y_approx(GameState.arena_center_x + 300)
		boss.global_position = Vector2(GameState.arena_center_x + 400, ground_y - 20)
		boss.camera_ref = camera
		boss.target_x = GameState.arena_center_x
		villains_container.add_child(boss)
	)
	tween.tween_interval(1.5)
	tween.tween_callback(func(): level_label.visible = false)
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.4)


func _spawn_shield_break_effect(pos: Vector2) -> void:
	var ShieldFX: GDScript = preload("res://scenes/explosion/shield_break_fx.gd")
	var fx := Node2D.new()
	fx.set_script(ShieldFX)
	fx.global_position = pos
	explosions_container.add_child(fx)


func _spawn_villain_death_effect(pos: Vector2) -> void:
	# Mini explosion at villain position
	var VillainDeathScript: GDScript = preload("res://scenes/explosion/villain_death_fx.gd")
	var fx := Node2D.new()
	fx.set_script(VillainDeathScript)
	fx.global_position = pos
	explosions_container.add_child(fx)


func _get_ground_y_approx(world_x: float) -> float:
	return 580.0 - (sin(world_x * 0.005) * 45.0 + sin(world_x * 0.013) * 20.0) - 10.0
