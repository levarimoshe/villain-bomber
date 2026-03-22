extends Control

@onready var score_label: Label = $LeftPanel/VBox/ScoreLabel
@onready var level_label: Label = $LeftPanel/VBox/LevelLabel
@onready var lives_container: HBoxContainer = $RightPanel/VBox/LivesContainer
@onready var escape_bar: ColorRect = $LeftPanel/VBox/EscapeBarBg/EscapeBarFill
@onready var escape_label: Label = $LeftPanel/VBox/EscapeLabel

var combo_display_timer: float = 0.0
var combo_count: int = 0
var combo_multiplier: int = 1
var warning_flash: float = 0.0


func _ready() -> void:
	Events.score_changed.connect(_on_score_changed)
	Events.lives_changed.connect(_on_lives_changed)
	Events.level_changed.connect(_on_level_changed)
	Events.villain_escaped.connect(_on_villain_escaped)
	Events.game_started.connect(_on_game_started)
	Events.combo_updated.connect(_on_combo_updated)
	Events.power_up_collected.connect(_on_power_up_collected)


func _process(delta: float) -> void:
	if combo_display_timer > 0:
		combo_display_timer -= delta
	warning_flash += delta
	queue_redraw()


func _draw() -> void:
	# === COMBO DISPLAY (center screen, big) ===
	if combo_display_timer > 0 and combo_multiplier >= 2:
		var alpha: float = minf(combo_display_timer / 0.5, 1.0)
		var pulse: float = 1.0 + sin(warning_flash * 8.0) * 0.12
		var font: Font = ThemeDB.fallback_font
		var combo_text: String = "COMBO x%d!" % combo_multiplier
		var font_size: int = int(42 * pulse)
		var text_pos := Vector2(size.x / 2.0, 120)
		# Glow
		draw_string(font, text_pos + Vector2(0, 1), combo_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size + 4, Color(1, 0.5, 0, alpha * 0.3))
		# Shadow
		draw_string(font, text_pos + Vector2(2, 3), combo_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, alpha * 0.7))
		# Main text
		var combo_color := Color(1, 0.85, 0.15, alpha) if combo_multiplier < 4 else Color(1, 0.25, 0.1, alpha)
		draw_string(font, text_pos, combo_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, combo_color)

	# === BULLET WARNING ARROWS ===
	var player_node: Node = get_tree().get_first_node_in_group(&"player")
	if player_node and GameState.game_phase == &"playing":
		var camera: Camera2D = get_viewport().get_camera_2d()
		if camera:
			_draw_bullet_warnings(player_node, camera)

	# === POWER-UP STATUS (right side, below lives) ===
	var status_x: float = size.x - 85
	var status_y: float = 110.0
	if GameState.has_shield:
		_draw_power_status(Vector2(status_x, status_y), "SHIELD", Color(0.2, 0.5, 1.0), GameState.shield_timer / 5.0)
		status_y += 28
	if GameState.has_rapid_fire:
		_draw_power_status(Vector2(status_x, status_y), "RAPID", Color(1, 0.8, 0.1), GameState.rapid_fire_timer / 4.0)
		status_y += 28
	if GameState.has_mega_bomb:
		_draw_power_status(Vector2(status_x, status_y), "MEGA", Color(1, 0.2, 0.1), GameState.mega_bomb_timer / 8.0)

	# === NUKE CHARGE METER (bottom center) ===
	_draw_nuke_meter()

	# === MISSION OBJECTIVE ===
	if Mission.mission_active:
		var font3: Font = ThemeDB.fallback_font
		var mission_color := Color(0.3, 1.0, 0.3, 0.8) if not Mission.mission_complete else Color(1.0, 0.9, 0.2, 0.8)
		var mission_text: String = Mission.current_mission
		if Mission.mission_complete:
			mission_text = "MISSION COMPLETE! +1000"
		else:
			mission_text += " (%d/%d)" % [Mission.mission_progress, Mission.mission_target]
		draw_string(font3, Vector2(size.x / 2.0, 75), mission_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, mission_color)

	# === CURRENT WEAPON (bottom center) ===
	var wep_font: Font = ThemeDB.fallback_font
	var wep_name: String = WeaponSystem.get_current_name()
	var wep_color: Color = WeaponSystem.get_current_color()
	draw_string(wep_font, Vector2(size.x / 2.0, size.y - 30), "[Q] " + wep_name + " [E]", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(wep_color.r, wep_color.g, wep_color.b, 0.8))
	# Controls hint
	draw_string(wep_font, Vector2(size.x / 2.0, size.y - 12), "M: Machine Gun  |  Space: Fire Weapon", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.6, 0.6, 0.6, 0.35))

	# === GREETING (top center) ===
	var hour: int = Time.get_datetime_dict_from_system()["hour"]
	var greeting: String = "Good Evening"
	if hour < 12:
		greeting = "Good Morning"
	elif hour < 17:
		greeting = "Good Afternoon"
	var greet_font: Font = ThemeDB.fallback_font
	draw_string(greet_font, Vector2(size.x / 2.0, 30), greeting, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(1, 1, 1, 0.35))

	# === ACCURACY STREAK (bottom center-right) ===
	var game_node: Node = get_tree().current_scene
	if game_node and game_node.has_method("_get_ground_y_approx"):
		var streak: int = game_node.accuracy_streak
		if streak >= 2:
			var streak_font: Font = ThemeDB.fallback_font
			var streak_text: String = "STREAK x%.1f" % game_node.accuracy_multiplier
			var streak_color := Color(0.3, 1, 0.3, 0.7) if streak < 5 else Color(1, 0.8, 0.1, 0.9)
			draw_string(streak_font, Vector2(size.x / 2.0 + 120, size.y - 15), streak_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, streak_color)

	# === RAPID FIRE LEVEL ===
	if GameState.has_rapid_fire and GameState.rapid_fire_level > 1:
		var rf_font: Font = ThemeDB.fallback_font
		draw_string(rf_font, Vector2(size.x - 80, size.y - 15), "RF Lv.%d" % GameState.rapid_fire_level, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.8, 0.1, 0.7))

	# === KILL COUNTER (bottom left) ===
	var font2: Font = ThemeDB.fallback_font
	var kill_text: String = "KILLS: %d" % GameState.total_villains_killed
	draw_string(font2, Vector2(24, size.y - 20), kill_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.8, 0.8, 0.8, 0.5))


func _draw_bullet_warnings(player_node: Node, camera: Camera2D) -> void:
	var cam_pos: Vector2 = camera.global_position
	var viewport_size: Vector2 = get_viewport_rect().size

	for child in get_tree().get_nodes_in_group(&"bullet"):
		if not is_instance_valid(child):
			continue
		var dist: float = child.global_position.distance_to(player_node.global_position)
		if dist < 250 and dist > 20:
			var dir: Vector2 = (child.global_position - player_node.global_position).normalized()
			var screen_pos: Vector2 = (player_node.global_position - cam_pos + viewport_size / 2)
			var arrow_pos: Vector2 = screen_pos + dir * 65
			var blink: float = 0.5 + 0.5 * sin(warning_flash * 12.0)
			var perp := Vector2(-dir.y, dir.x)
			var tip: Vector2 = arrow_pos + dir * 14
			var base_l: Vector2 = arrow_pos - dir * 5 + perp * 7
			var base_r: Vector2 = arrow_pos - dir * 5 - perp * 7
			draw_colored_polygon(PackedVector2Array([tip, base_l, base_r]), Color(1, 0.1, 0.1, blink * 0.8))


func _draw_power_status(pos: Vector2, label_text: String, color: Color, fill: float) -> void:
	var w: float = 70.0
	var h: float = 18.0
	# Background
	draw_rect(Rect2(pos.x - 2, pos.y - 2, w + 4, h + 4), Color(0, 0, 0, 0.5))
	# Fill bar
	draw_rect(Rect2(pos.x, pos.y, w * clampf(fill, 0, 1), h), Color(color.r, color.g, color.b, 0.65))
	# Border
	draw_rect(Rect2(pos.x - 2, pos.y - 2, w + 4, h + 4), Color(color.r, color.g, color.b, 0.4), false, 1.0)
	# Label
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(pos.x + 4, pos.y + 13), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func _on_game_started() -> void:
	_refresh_all()


func _refresh_all() -> void:
	_on_score_changed(GameState.score)
	_on_lives_changed(GameState.lives)
	_on_level_changed(GameState.current_level)
	_update_escape_bar()


func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	for child in lives_container.get_children():
		child.queue_free()
	for i in range(new_lives):
		var heart := Label.new()
		heart.text = "♥"
		heart.add_theme_font_size_override("font_size", 32)
		heart.add_theme_color_override("font_color", Color(1, 0.15, 0.15))
		heart.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		heart.add_theme_constant_override("outline_size", 3)
		lives_container.add_child(heart)


func _on_level_changed(new_level: int) -> void:
	level_label.text = "LEVEL %d" % new_level


func _on_villain_escaped() -> void:
	_update_escape_bar()


func _on_combo_updated(count: int, mult: int) -> void:
	combo_count = count
	combo_multiplier = mult
	if mult >= 2:
		combo_display_timer = 2.0


func _on_power_up_collected(_type: String) -> void:
	pass


func _draw_nuke_meter() -> void:
	var bar_w: float = 200.0
	var bar_h: float = 22.0
	var bar_x: float = size.x / 2.0 - bar_w / 2.0
	var bar_y: float = size.y - 45.0
	var charge: float = GameState.nuke_charge
	var ready: bool = GameState.nuke_ready

	# Background
	draw_rect(Rect2(bar_x - 2, bar_y - 2, bar_w + 4, bar_h + 4), Color(0, 0, 0, 0.6))

	# Fill — orange to red gradient
	if charge > 0:
		var fill_color := Color(1, 0.5, 0.0).lerp(Color(1, 0.15, 0.0), charge)
		draw_rect(Rect2(bar_x, bar_y, bar_w * charge, bar_h), fill_color)

	# Border
	var border_color := Color(0.5, 0.5, 0.5, 0.5)
	if ready:
		var pulse: float = 0.5 + 0.5 * sin(warning_flash * 6.0)
		border_color = Color(1, 0.3, 0.0, pulse)
	draw_rect(Rect2(bar_x - 2, bar_y - 2, bar_w + 4, bar_h + 4), border_color, false, 2.0)

	# Label
	var font: Font = ThemeDB.fallback_font
	if ready:
		var pulse_alpha: float = 0.7 + 0.3 * sin(warning_flash * 6.0)
		draw_string(font, Vector2(bar_x + 10, bar_y + 16), "NUKE READY! FLY FAST + BOMB!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.8, 0.1, pulse_alpha))
	else:
		draw_string(font, Vector2(bar_x + bar_w / 2 - 30, bar_y + 16), "NUKE CHARGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.8, 0.8, 0.6))

	# Nuke icon
	if ready:
		var icon_x: float = bar_x - 25
		var icon_y: float = bar_y + bar_h / 2.0
		var glow_pulse: float = 0.5 + 0.5 * sin(warning_flash * 5.0)
		_draw_circle_at(Vector2(icon_x, icon_y), 12.0, Color(1, 0.3, 0, glow_pulse * 0.4))
		_draw_circle_at(Vector2(icon_x, icon_y), 8.0, Color(1, 0.5, 0, glow_pulse * 0.7))
		_draw_circle_at(Vector2(icon_x, icon_y), 4.0, Color(1, 0.9, 0.3, 1.0))


func _draw_circle_at(pos: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var points := PackedVector2Array()
	var segs: int = 12
	for i_c in range(segs + 1):
		var a: float = float(i_c) / float(segs) * TAU
		points.append(pos + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)


func _update_escape_bar() -> void:
	var fill: float = float(GameState.escapes_this_life) / float(GameState.ESCAPE_THRESHOLD)
	escape_bar.scale.x = clampf(fill, 0.0, 1.0)
	escape_bar.color = Color.GREEN.lerp(Color.RED, fill)
	escape_label.text = "THREAT: %d/%d" % [GameState.escapes_this_life, GameState.ESCAPE_THRESHOLD]
