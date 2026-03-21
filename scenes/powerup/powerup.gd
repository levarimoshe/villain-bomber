extends Node2D

var power_type: String = "shield"
var spin_angle: float = 0.0
var bob_time: float = 0.0
var lifetime: float = 12.0
var collect_radius: float = 35.0
var from_sky: bool = false
var fall_speed: float = 45.0
var sparkle_particles: Array = []

var TYPE_COLORS: Dictionary = {
	"shield": Color(0.2, 0.5, 1.0),
	"rapid_fire": Color(1.0, 0.8, 0.1),
	"mega_bomb": Color(1.0, 0.2, 0.1),
}

var TYPE_NAMES: Dictionary = {
	"shield": "SHIELD",
	"rapid_fire": "RAPID FIRE",
	"mega_bomb": "MEGA BOMB",
}


func _ready() -> void:
	add_to_group(&"powerup")
	if from_sky:
		fall_speed = 55.0
		lifetime = 15.0


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	spin_angle += delta * 4.5
	bob_time += delta
	lifetime -= delta

	# Fall downward
	position.y += fall_speed * delta

	# Spawn sparkle trail
	if randf() < 0.4:
		sparkle_particles.append({
			"pos": Vector2(randf_range(-12, 12), randf_range(-12, 12)),
			"life": 0.6,
			"max_life": 0.6,
			"size": randf_range(1.5, 4.0),
		})

	# Update sparkles
	var i: int = 0
	while i < sparkle_particles.size():
		sparkle_particles[i]["life"] -= delta
		sparkle_particles[i]["pos"].y -= 20.0 * delta
		if sparkle_particles[i]["life"] <= 0:
			sparkle_particles.remove_at(i)
		else:
			i += 1
	while sparkle_particles.size() > 20:
		sparkle_particles.remove_at(0)

	# Check collection by player
	var player_node: Node = get_tree().get_first_node_in_group(&"player")
	if player_node:
		var dist: float = global_position.distance_to(player_node.global_position)
		if dist < collect_radius:
			GameState.activate_power_up(power_type)
			SoundManager.play_levelup()
			queue_free()
			return

	queue_redraw()

	if lifetime <= 0 or position.y > 750:
		queue_free()


func _draw() -> void:
	var color: Color = TYPE_COLORS.get(power_type, Color.WHITE)
	var bob: float = sin(bob_time * 3.0) * 5.0
	var pulse: float = 0.85 + 0.15 * sin(bob_time * 5.0)

	# === SPARKLE PARTICLES ===
	for sp in sparkle_particles:
		if sp["life"] > 0:
			var alpha: float = sp["life"] / sp["max_life"]
			var sz: float = sp["size"] * alpha
			_draw_glow(sp["pos"], sz, Color(color.r, color.g, color.b, alpha * 0.5))

	# === OUTER GLOW (pulsing) ===
	_draw_glow(Vector2(0, bob), 28.0 * pulse, Color(color.r, color.g, color.b, 0.08))
	_draw_glow(Vector2(0, bob), 20.0 * pulse, Color(color.r, color.g, color.b, 0.15))
	_draw_glow(Vector2(0, bob), 14.0 * pulse, Color(color.r, color.g, color.b, 0.25))

	# === SPINNING DIAMOND ===
	var points := PackedVector2Array()
	for i_pt in range(4):
		var angle: float = spin_angle + float(i_pt) * PI / 2.0
		var r: float = 12.0 * pulse
		points.append(Vector2(cos(angle) * r, sin(angle) * r + bob))
	draw_colored_polygon(points, color)

	# === INNER BRIGHT CORE ===
	_draw_glow(Vector2(0, bob), 6.0, Color(1, 1, 1, 0.85))

	# === TYPE ICON ===
	match power_type:
		"shield":
			draw_arc(Vector2(0, bob), 7.0, PI * 0.15, PI * 0.85, 8, Color.WHITE, 2.5)
			draw_line(Vector2(-5, bob + 3), Vector2(0, bob + 7), Color.WHITE, 2.0)
			draw_line(Vector2(5, bob + 3), Vector2(0, bob + 7), Color.WHITE, 2.0)
		"rapid_fire":
			draw_line(Vector2(-3, bob - 5), Vector2(1, bob), Color.WHITE, 2.5)
			draw_line(Vector2(1, bob), Vector2(-2, bob + 1), Color.WHITE, 2.5)
			draw_line(Vector2(-2, bob + 1), Vector2(3, bob + 6), Color.WHITE, 2.5)
		"mega_bomb":
			_draw_glow(Vector2(0, bob), 5.0, Color(1, 0.5, 0, 0.9))
			_draw_glow(Vector2(0, bob), 3.0, Color(1, 0.8, 0.2, 0.9))

	# === NAME LABEL (floating above) ===
	var name_text: String = TYPE_NAMES.get(power_type, "")
	var font: Font = ThemeDB.fallback_font
	var label_y: float = bob - 22
	draw_string(font, Vector2(-25, label_y), name_text, HORIZONTAL_ALIGNMENT_CENTER, 50, 10, Color(1, 1, 1, 0.7))

	# Fade out near end
	if lifetime < 3.0:
		var blink: float = sin(bob_time * 10.0)
		modulate.a = 0.3 + 0.7 * clampf(lifetime / 3.0, 0.0, 1.0) * (0.5 + 0.5 * blink)
	else:
		modulate.a = 1.0


func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var pts := PackedVector2Array()
	var segs: int = 12
	for i_seg in range(segs + 1):
		var a: float = float(i_seg) / float(segs) * TAU
		pts.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(pts, color)
