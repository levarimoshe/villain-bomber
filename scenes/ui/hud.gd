extends Control

@onready var score_label: Label = $ScoreLabel
@onready var level_label: Label = $LevelLabel
@onready var lives_container: HBoxContainer = $LivesContainer
@onready var escape_bar: ColorRect = $EscapeBarBg/EscapeBarFill

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
	# === COMBO DISPLAY ===
	if combo_display_timer > 0 and combo_multiplier >= 2:
		var alpha: float = minf(combo_display_timer / 0.5, 1.0)
		var pulse: float = 1.0 + sin(warning_flash * 8.0) * 0.1
		var font: Font = ThemeDB.fallback_font
		var combo_text: String = "COMBO x%d!" % combo_multiplier
		var font_size: int = int(36 * pulse)
		var text_pos := Vector2(size.x / 2.0, 100)
		# Shadow
		draw_string(font, text_pos + Vector2(2, 2), combo_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, alpha * 0.6))
		# Main text
		var combo_color := Color(1, 0.8, 0.1, alpha) if combo_multiplier < 4 else Color(1, 0.3, 0.1, alpha)
		draw_string(font, text_pos, combo_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, combo_color)

	# === BULLET WARNING ARROWS ===
	var player_node: Node = get_tree().get_first_node_in_group(&"player")
	if player_node and GameState.game_phase == &"playing":
		var camera: Camera2D = get_viewport().get_camera_2d()
		if camera:
			_draw_bullet_warnings(player_node, camera)

	# === POWER-UP STATUS ===
	var status_y: float = 80.0
	if GameState.has_shield:
		_draw_power_status(Vector2(size.x - 40, status_y), "SH", Color(0.2, 0.5, 1.0), GameState.shield_timer / 5.0)
		status_y += 25
	if GameState.has_rapid_fire:
		_draw_power_status(Vector2(size.x - 40, status_y), "RF", Color(1, 0.8, 0.1), GameState.rapid_fire_timer / 4.0)
		status_y += 25
	if GameState.has_mega_bomb:
		_draw_power_status(Vector2(size.x - 40, status_y), "MB", Color(1, 0.2, 0.1), GameState.mega_bomb_timer / 8.0)

	# === KILL COUNTER ===
	var font2: Font = ThemeDB.fallback_font
	var kill_text: String = "KILLS: %d" % GameState.total_villains_killed
	draw_string(font2, Vector2(20, 95), kill_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.7, 0.7, 0.7))


func _draw_bullet_warnings(player_node: Node, camera: Camera2D) -> void:
	var cam_pos: Vector2 = camera.global_position
	var viewport_size: Vector2 = get_viewport_rect().size

	for child in get_tree().get_nodes_in_group(&"bullet"):
		if not is_instance_valid(child):
			continue
		var dist: float = child.global_position.distance_to(player_node.global_position)
		if dist < 250 and dist > 20:
			var dir: Vector2 = (child.global_position - player_node.global_position).normalized()
			# Convert to screen space
			var screen_pos: Vector2 = (player_node.global_position - cam_pos + viewport_size / 2)
			var arrow_pos: Vector2 = screen_pos + dir * 60
			var blink: float = 0.5 + 0.5 * sin(warning_flash * 12.0)
			# Draw warning triangle
			var perp := Vector2(-dir.y, dir.x)
			var tip: Vector2 = arrow_pos + dir * 12
			var base_l: Vector2 = arrow_pos - dir * 4 + perp * 6
			var base_r: Vector2 = arrow_pos - dir * 4 - perp * 6
			draw_colored_polygon(PackedVector2Array([tip, base_l, base_r]), Color(1, 0.1, 0.1, blink * 0.7))


func _draw_power_status(pos: Vector2, label_text: String, color: Color, fill: float) -> void:
	# Background
	draw_rect(Rect2(pos.x - 15, pos.y - 8, 30, 16), Color(0, 0, 0, 0.4))
	# Fill bar
	draw_rect(Rect2(pos.x - 14, pos.y - 7, 28 * fill, 14), Color(color.r, color.g, color.b, 0.6))
	# Label
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(pos.x - 8, pos.y + 4), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


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
		heart.add_theme_font_size_override("font_size", 28)
		heart.add_theme_color_override("font_color", Color.RED)
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
	pass  # Visual handled by _draw


func _update_escape_bar() -> void:
	var fill: float = float(GameState.escapes_this_life) / float(GameState.ESCAPE_THRESHOLD)
	escape_bar.scale.x = clampf(fill, 0.0, 1.0)
	escape_bar.color = Color.GREEN.lerp(Color.RED, fill)
