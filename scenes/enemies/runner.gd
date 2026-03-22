extends Node2D
## Runner — very fast, small, hard to hit, worth more points

var speed: float = 200.0
var direction: int = -1
var is_dying: bool = false
var health: int = 1
var camera_ref: Camera2D = null
var anim_time: float = 0.0
var death_timer: float = 0.0
var points_value: int = 250


func _ready() -> void:
	add_to_group(&"villains")
	anim_time = randf() * TAU
	speed = randf_range(180, 260)


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return
	if is_dying:
		death_timer -= delta
		modulate.a = clampf(death_timer / 0.3, 0.0, 1.0)
		position.y -= 100 * delta
		if death_timer <= 0:
			queue_free()
		queue_redraw()
		return

	anim_time += delta * 14.0  # Fast animation
	position.x += direction * speed * delta

	if camera_ref and global_position.x < camera_ref.global_position.x - 900:
		Events.villain_escaped.emit()
		queue_free()
	queue_redraw()


func hit_by_bomb() -> void:
	if is_dying:
		return
	is_dying = true
	death_timer = 0.3
	Events.villain_killed.emit(global_position, points_value)


func _draw() -> void:
	var sc: float = 1.2  # Smaller than regular
	var leg_swing: float = sin(anim_time) * 0.7  # Faster legs

	# Legs (sprinting)
	draw_line(Vector2(-2 * sc, 0), Vector2(sin(leg_swing) * 8 * sc, 10 * sc), Color(0.25, 0.3, 0.15), 2.5 * sc)
	draw_line(Vector2(2 * sc, 0), Vector2(sin(-leg_swing) * 8 * sc, 10 * sc), Color(0.25, 0.3, 0.15), 2.5 * sc)

	# Lean forward body (sprinting pose)
	draw_rect(Rect2(-4 * sc, -10 * sc, 8 * sc, 12 * sc), Color(0.25, 0.3, 0.15))

	# Head (forward lean)
	draw_circle(Vector2(3 * sc * float(-direction), -14 * sc), 4 * sc, Color(0.85, 0.7, 0.55))
	# Bandana instead of helmet
	draw_rect(Rect2(-1 * sc + 3 * sc * float(-direction), -17 * sc, 6 * sc, 2 * sc), Color(0.7, 0.15, 0.1))

	# Speed lines
	for i in range(3):
		var lx: float = float(direction) * (10 + i * 6) * sc
		var ly: float = float(i - 1) * 4 * sc - 5 * sc
		draw_line(Vector2(lx, ly), Vector2(lx + direction * 8 * sc, ly), Color(1, 1, 1, 0.15), 1.0)
