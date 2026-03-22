extends Node

# ---- State ----
var score: int = 0
var lives: int = 3
var current_level: int = 1
var high_score: int = 0
var game_phase: StringName = &"menu"
var escapes_this_life: int = 0

# ---- Combo ----
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 2.0

# ---- Power-ups ----
var has_shield: bool = false
var shield_timer: float = 0.0
var has_rapid_fire: bool = false
var rapid_fire_timer: float = 0.0
var has_mega_bomb: bool = false
var mega_bomb_timer: float = 0.0

# ---- Arena mode ----
var is_arena_level: bool = false
var arena_wave: int = 0
var arena_max_waves: int = 3
var arena_kills_this_wave: int = 0
var arena_kills_needed: int = 8
var arena_center_x: float = 0.0
var boss_active: bool = false

# ---- Nuke charge ----
var nuke_charge: float = 0.0  # 0.0 to 1.0
var nuke_ready: bool = false
const NUKE_CHARGE_PER_KILL: float = 0.12  # ~8 kills to fully charge
const NUKE_BLAST_RADIUS: float = 800.0
const NUKE_SCALE: float = 5.0

# ---- Invulnerability ----
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0
const INVULNERABILITY_DURATION: float = 1.5

# ---- Level scaling ----
var villain_speed_multiplier: float = 1.0
var spawn_interval: float = 2.0
var villains_per_level: int = 10
var villains_killed_this_level: int = 0
var total_villains_killed: int = 0
var total_bombs_dropped: int = 0

# ---- Constants ----
const MAX_LIVES: int = 5
const STARTING_LIVES: int = 3
const POINTS_HIT: int = 100
const POINTS_DIRECT: int = 250
const POINTS_MULTI_BONUS: int = 200
const POINTS_LEVEL_BONUS: int = 500
const EXTRA_LIFE_INTERVAL: int = 3000
const ESCAPE_THRESHOLD: int = 10
const BASE_SPAWN_INTERVAL: float = 1.2
const MIN_SPAWN_INTERVAL: float = 0.35
const SPAWN_DECAY: float = 0.82
const SPEED_INCREASE_PER_LEVEL: float = 0.18


func _process(delta: float) -> void:
	# Combo timer
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0
			Events.combo_updated.emit(0, 1)

	# Invulnerability timer
	if is_invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			is_invulnerable = false

	# Power-ups persist until death — no timers


func reset() -> void:
	score = 0
	lives = STARTING_LIVES
	current_level = 1
	escapes_this_life = 0
	villains_killed_this_level = 0
	total_villains_killed = 0
	total_bombs_dropped = 0
	combo_count = 0
	combo_timer = 0.0
	nuke_charge = 0.0
	nuke_ready = false
	has_shield = false
	has_rapid_fire = false
	has_mega_bomb = false
	is_invulnerable = false
	_recalculate_difficulty()


func add_score(points: int) -> void:
	var old_score := score
	# Apply combo multiplier
	var multiplier: int = get_combo_multiplier()
	var actual_points: int = points * multiplier
	score += actual_points
	if score / EXTRA_LIFE_INTERVAL > old_score / EXTRA_LIFE_INTERVAL:
		lives = mini(lives + 1, MAX_LIVES)
		Events.extra_life_gained.emit()
		Events.lives_changed.emit(lives)
	if score > high_score:
		high_score = score
	Events.score_changed.emit(score)


func register_kill() -> void:
	combo_count += 1
	combo_timer = COMBO_WINDOW
	var mult: int = get_combo_multiplier()
	Events.combo_updated.emit(combo_count, mult)
	if mult >= 2:
		SoundManager.play_combo()
	# Charge the nuke meter with sound feedback
	if not nuke_ready:
		var old_charge: float = nuke_charge
		nuke_charge = minf(nuke_charge + NUKE_CHARGE_PER_KILL, 1.0)
		# Play charge sound at each 25% threshold
		var old_quarter: int = int(old_charge * 4.0)
		var new_quarter: int = int(nuke_charge * 4.0)
		if new_quarter > old_quarter:
			SoundManager.play_nuke_charge()
		if nuke_charge >= 1.0:
			nuke_ready = true
			SoundManager.play_levelup()
			SoundManager.speak("Nuke ready. Fly fast and drop it!")


func use_nuke() -> void:
	nuke_charge = 0.0
	nuke_ready = false


func get_combo_multiplier() -> int:
	if combo_count < 2:
		return 1
	return mini(combo_count, 5)


func lose_life() -> void:
	if is_invulnerable:
		return
	if has_shield:
		# Shield absorbs hit but ALL power-ups are lost
		_clear_all_powerups()
		return
	# Actually lose a life — clear all power-ups
	lives -= 1
	escapes_this_life = 0
	is_invulnerable = true
	invulnerability_timer = INVULNERABILITY_DURATION
	_clear_all_powerups()
	Events.lives_changed.emit(lives)
	if lives <= 0:
		game_phase = &"game_over"
		Events.game_over.emit()


func _clear_all_powerups() -> void:
	has_shield = false
	has_rapid_fire = false
	has_mega_bomb = false


func register_escape() -> void:
	escapes_this_life += 1
	if escapes_this_life >= ESCAPE_THRESHOLD:
		lose_life()


func advance_level() -> void:
	current_level += 1
	villains_killed_this_level = 0
	add_score(POINTS_LEVEL_BONUS * (current_level - 1))
	_recalculate_difficulty()
	Events.level_changed.emit(current_level)


func activate_power_up(type: String) -> void:
	match type:
		"shield":
			has_shield = true
			SoundManager.speak("Shield activated")
		"rapid_fire":
			has_rapid_fire = true
			SoundManager.speak("Rapid fire!")
		"mega_bomb":
			has_mega_bomb = true
			SoundManager.speak("Mega bomb!")
	Events.power_up_collected.emit(type)


func _recalculate_difficulty() -> void:
	villain_speed_multiplier = 1.0 + (current_level - 1) * SPEED_INCREASE_PER_LEVEL
	spawn_interval = maxf(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL * pow(SPAWN_DECAY, current_level - 1))
	villains_per_level = 10 + (current_level - 1) * 3


func save_high_score() -> void:
	var file := FileAccess.open("user://highscore.save", FileAccess.WRITE)
	if file:
		file.store_var(high_score)


func load_high_score() -> void:
	if FileAccess.file_exists("user://highscore.save"):
		var file := FileAccess.open("user://highscore.save", FileAccess.READ)
		if file:
			high_score = file.get_var()


func _ready() -> void:
	load_high_score()
