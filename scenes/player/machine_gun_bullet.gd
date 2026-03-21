extends Node2D

var velocity: Vector2 = Vector2(0, 350)
var lifetime: float = 2.0


func _ready() -> void:
	add_to_group(&"player_bullet")


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	position += velocity * delta
	lifetime -= delta

	# Check hit on villains
	for villain in get_tree().get_nodes_in_group(&"villains"):
		if not is_instance_valid(villain):
			continue
		if villain.get("is_dying") == true:
			continue
		var dist: float = global_position.distance_to(villain.global_position)
		if dist < 25.0:
			villain.hit_by_bomb()
			queue_free()
			return

	queue_redraw()

	if lifetime <= 0 or position.y > 700:
		queue_free()


func _draw() -> void:
	# Yellow tracer
	draw_line(Vector2(0, -8), Vector2(0, 4), Color(1, 0.9, 0.2, 0.8), 2.5)
	draw_line(Vector2(0, -5), Vector2(0, 2), Color(1, 1, 0.7, 1.0), 1.5)
	# Muzzle glow
	_draw_glow(Vector2.ZERO, 3.0, Color(1, 0.8, 0.2, 0.4))


func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	var segs: int = 8
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
