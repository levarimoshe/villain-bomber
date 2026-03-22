extends Node2D
## Shield soldier — takes 2 hits, carries a shield

var speed: float = 60.0
var direction: int = -1
var is_dying: bool = false
var health: int = 2
var camera_ref: Camera2D = null
var anim_time: float = 0.0
var death_timer: float = 0.0
var flash_timer: float = 0.0
var points_value: int = 200


func _ready() -> void:
	add_to_group(&"villains")
	anim_time = randf() * TAU


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return
	if is_dying:
		death_timer -= delta
		modulate.a = clampf(death_timer / 0.5, 0.0, 1.0)
		rotation += delta * 8.0
		position.y -= 50 * delta
		if death_timer <= 0:
			queue_free()
		queue_redraw()
		return

	anim_time += delta * 6.0
	if flash_timer > 0:
		flash_timer -= delta
	position.x += direction * speed * delta

	if camera_ref and global_position.x < camera_ref.global_position.x - 900:
		Events.villain_escaped.emit()
		queue_free()
	queue_redraw()


func hit_by_bomb() -> void:
	if is_dying:
		return
	health -= 1
	flash_timer = 0.2
	SoundManager.play_hit()
	if health <= 0:
		is_dying = true
		death_timer = 0.5
		Events.villain_killed.emit(global_position, points_value)


func _draw() -> void:
	var sc: float = 1.7
	var flash: bool = flash_timer > 0 and fmod(flash_timer, 0.06) < 0.03
	var armor_color := Color(0.4, 0.4, 0.45) if not flash else Color(1, 0.5, 0.3)

	# Legs (walking)
	var leg_swing: float = sin(anim_time) * 0.4
	draw_line(Vector2(-3 * sc, 0), Vector2(sin(leg_swing) * 5 * sc, 12 * sc), Color(0.2, 0.2, 0.25), 3 * sc)
	draw_line(Vector2(3 * sc, 0), Vector2(sin(-leg_swing) * 5 * sc, 12 * sc), Color(0.2, 0.2, 0.25), 3 * sc)

	# Body
	draw_rect(Rect2(-6 * sc, -14 * sc, 12 * sc, 16 * sc), Color(0.2, 0.22, 0.18))

	# SHIELD (large, in front)
	var shield_x: float = 8.0 * sc * float(-direction)
	draw_rect(Rect2(shield_x - 4 * sc, -18 * sc, 8 * sc, 28 * sc), armor_color)
	draw_rect(Rect2(shield_x - 3 * sc, -16 * sc, 6 * sc, 24 * sc), armor_color.lightened(0.1))
	# Shield rivets
	draw_circle(Vector2(shield_x, -12 * sc), 1.5 * sc, armor_color.darkened(0.2))
	draw_circle(Vector2(shield_x, 0), 1.5 * sc, armor_color.darkened(0.2))

	# Head
	draw_circle(Vector2(0, -18 * sc), 5 * sc, Color(0.85, 0.7, 0.55))
	# Heavy helmet
	draw_circle(Vector2(0, -22 * sc), 7 * sc, armor_color)

	# Health indicator
	if health == 1:
		draw_circle(Vector2(0, -30 * sc), 3, Color(1, 0.3, 0.1))
	else:
		draw_circle(Vector2(0, -30 * sc), 3, Color(0.2, 0.8, 0.2))
