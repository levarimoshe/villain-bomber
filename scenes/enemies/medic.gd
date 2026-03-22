extends Node2D
## Medic — heals nearby villains, priority target, doesn't shoot

var speed: float = 70.0
var direction: int = -1
var is_dying: bool = false
var health: int = 1
var camera_ref: Camera2D = null
var anim_time: float = 0.0
var death_timer: float = 0.0
var heal_timer: float = 2.0
var points_value: int = 300


func _ready() -> void:
	add_to_group(&"villains")
	add_to_group(&"medic")
	anim_time = randf() * TAU


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return
	if is_dying:
		death_timer -= delta
		modulate.a = clampf(death_timer / 0.5, 0.0, 1.0)
		position.y -= 60 * delta
		if death_timer <= 0:
			queue_free()
		queue_redraw()
		return

	anim_time += delta * 7.0
	position.x += direction * speed * delta

	# Heal nearby villains
	heal_timer -= delta
	if heal_timer <= 0:
		heal_timer = 2.0
		_heal_nearby()

	if camera_ref and global_position.x < camera_ref.global_position.x - 900:
		Events.villain_escaped.emit()
		queue_free()
	queue_redraw()


func _heal_nearby() -> void:
	for villain in get_tree().get_nodes_in_group(&"villains"):
		if villain == self or not is_instance_valid(villain):
			continue
		if villain.get("is_dying") == true:
			continue
		var dist: float = global_position.distance_to(villain.global_position)
		if dist < 100 and villain.get("health") != null:
			var max_hp = villain.get("max_health")
			if max_hp == null:
				max_hp = 1
			if villain.health < max_hp:
				villain.health = mini(villain.health + 1, max_hp)


func hit_by_bomb() -> void:
	if is_dying:
		return
	is_dying = true
	death_timer = 0.5
	Events.villain_killed.emit(global_position, points_value)


func _draw() -> void:
	var sc: float = 1.5
	var leg_swing: float = sin(anim_time) * 0.4

	# Legs
	draw_line(Vector2(-3 * sc, 0), Vector2(sin(leg_swing) * 5 * sc, 11 * sc), Color(0.8, 0.8, 0.75), 3 * sc)
	draw_line(Vector2(3 * sc, 0), Vector2(sin(-leg_swing) * 5 * sc, 11 * sc), Color(0.8, 0.8, 0.75), 3 * sc)

	# White uniform
	draw_rect(Rect2(-6 * sc, -14 * sc, 12 * sc, 16 * sc), Color(0.85, 0.85, 0.8))

	# Red cross on chest
	draw_rect(Rect2(-1 * sc, -12 * sc, 2 * sc, 8 * sc), Color(0.8, 0.1, 0.1))
	draw_rect(Rect2(-4 * sc, -9 * sc, 8 * sc, 2 * sc), Color(0.8, 0.1, 0.1))

	# Medical bag
	draw_rect(Rect2(-8 * sc, -6 * sc, 5 * sc, 6 * sc), Color(0.7, 0.2, 0.15))

	# Head
	draw_circle(Vector2(0, -18 * sc), 5 * sc, Color(0.85, 0.7, 0.55))
	# White cap
	draw_circle(Vector2(0, -22 * sc), 6 * sc, Color(0.9, 0.9, 0.85))
	# Red cross on cap
	draw_rect(Rect2(-1, -24 * sc, 2, 4), Color(0.8, 0.1, 0.1))

	# Heal aura (pulsing green glow)
	var pulse: float = 0.3 + 0.2 * sin(anim_time * 0.5)
	_draw_glow(Vector2(0, -5 * sc), 20 * sc, Color(0.2, 0.9, 0.2, pulse * 0.15))


func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	if radius < 1:
		return
	var points := PackedVector2Array()
	for i in range(13):
		var a: float = float(i) / 12.0 * TAU
		points.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
