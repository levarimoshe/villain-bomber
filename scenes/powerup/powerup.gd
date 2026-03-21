extends Node2D

var power_type: String = "shield"  # shield, rapid_fire, mega_bomb
var spin_angle: float = 0.0
var bob_time: float = 0.0
var lifetime: float = 8.0
var collect_radius: float = 30.0

var TYPE_COLORS: Dictionary = {
	"shield": Color(0.2, 0.5, 1.0),
	"rapid_fire": Color(1.0, 0.8, 0.1),
	"mega_bomb": Color(1.0, 0.2, 0.1),
}


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	spin_angle += delta * 4.0
	bob_time += delta
	lifetime -= delta

	# Float downward slowly
	position.y += 30.0 * delta

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

	if lifetime <= 0 or position.y > 700:
		queue_free()


func _draw() -> void:
	var color: Color = TYPE_COLORS.get(power_type, Color.WHITE)
	var bob: float = sin(bob_time * 3.0) * 4.0

	# Outer glow
	_draw_glow(Vector2(0, bob), 18.0, Color(color.r, color.g, color.b, 0.15))
	_draw_glow(Vector2(0, bob), 12.0, Color(color.r, color.g, color.b, 0.3))

	# Spinning diamond shape
	var points := PackedVector2Array()
	for i in range(4):
		var angle: float = spin_angle + float(i) * PI / 2.0
		points.append(Vector2(cos(angle) * 10, sin(angle) * 10 + bob))
	draw_colored_polygon(points, color)

	# Inner bright core
	_draw_glow(Vector2(0, bob), 5.0, Color(1, 1, 1, 0.8))

	# Icon based on type
	match power_type:
		"shield":
			# Small shield shape
			draw_arc(Vector2(0, bob), 6.0, PI * 0.2, PI * 0.8, 6, Color.WHITE, 2.0)
		"rapid_fire":
			# Lightning bolt
			draw_line(Vector2(-2, bob - 4), Vector2(1, bob), Color.WHITE, 2.0)
			draw_line(Vector2(1, bob), Vector2(-1, bob + 1), Color.WHITE, 2.0)
			draw_line(Vector2(-1, bob + 1), Vector2(2, bob + 5), Color.WHITE, 2.0)
		"mega_bomb":
			# Explosion icon
			_draw_glow(Vector2(0, bob), 4.0, Color(1, 0.5, 0, 0.8))

	# Fade out near end of lifetime
	if lifetime < 2.0:
		modulate.a = lifetime / 2.0


func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var pts := PackedVector2Array()
	var segs: int = 12
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		pts.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(pts, color)
