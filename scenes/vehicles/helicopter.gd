extends Node2D
## Enemy helicopter — flies at player altitude, shoots sideways

var speed: float = 120.0
var direction: int = -1
var is_dying: bool = false
var health: int = 3
var max_health: int = 3
var camera_ref: Camera2D = null
var anim_time: float = 0.0
var death_timer: float = 0.0
var shoot_timer: float = 2.0
var points_value: int = 400
var hover_y: float = 200.0
var blade_angle: float = 0.0

const BulletScript = preload("res://scenes/villain/bullet.gd")


func _ready() -> void:
	add_to_group(&"villains")
	hover_y = randf_range(120, 300)
	shoot_timer = randf_range(1.0, 2.5)


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	if is_dying:
		death_timer -= delta
		modulate.a = clampf(death_timer / 1.0, 0.0, 1.0)
		position.y += 100 * delta  # Fall
		rotation += delta * 3.0
		if death_timer <= 0:
			Events.bomb_hit_ground.emit(global_position, 1.2, false)
			queue_free()
		queue_redraw()
		return

	anim_time += delta
	blade_angle += delta * 25.0  # Fast blade spin
	position.x += direction * speed * delta
	# Hover at target altitude with bob
	var target_y: float = hover_y + sin(anim_time * 2.0) * 15.0
	position.y = lerpf(position.y, target_y, 2.0 * delta)

	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_timer = randf_range(1.5, 3.0)
		_shoot()

	if camera_ref and (global_position.x < camera_ref.global_position.x - 900 or global_position.x > camera_ref.global_position.x + 1200):
		queue_free()
	queue_redraw()


func _shoot() -> void:
	var bullet := Node2D.new()
	bullet.set_script(BulletScript)
	bullet.global_position = global_position + Vector2(direction * 20, 10)
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		bullet.velocity = dir * 280.0
	else:
		bullet.velocity = Vector2(direction * 250, 50)
	get_tree().current_scene.add_child(bullet)
	SoundManager.play_shoot()


func hit_by_bomb() -> void:
	if is_dying:
		return
	health -= 1
	if health <= 0:
		is_dying = true
		death_timer = 1.0
		Events.villain_killed.emit(global_position, points_value)
		SoundManager.play_explosion()


func _draw() -> void:
	var sc: float = 1.0
	# Body
	draw_rect(Rect2(-18 * sc, -6 * sc, 36 * sc, 14 * sc), Color(0.3, 0.35, 0.2))
	# Cockpit glass
	draw_colored_polygon(PackedVector2Array([
		Vector2(direction * 16 * sc, -4 * sc),
		Vector2(direction * 22 * sc, 0),
		Vector2(direction * 16 * sc, 4 * sc),
	]), Color(0.4, 0.6, 0.8, 0.8))
	# Tail boom
	draw_line(Vector2(-direction * 18 * sc, 0), Vector2(-direction * 35 * sc, -2 * sc), Color(0.25, 0.3, 0.18), 3 * sc)
	# Tail rotor
	var tail_spin: float = sin(blade_angle * 3) * 6
	draw_line(Vector2(-direction * 35 * sc, -2 * sc + tail_spin), Vector2(-direction * 35 * sc, -2 * sc - tail_spin), Color(0.4, 0.4, 0.4), 2)
	# Main rotor blades (spinning)
	var b1: float = cos(blade_angle) * 28 * sc
	draw_line(Vector2(-b1, -8 * sc), Vector2(b1, -8 * sc), Color(0.35, 0.35, 0.35), 2.5)
	var b2: float = sin(blade_angle) * 28 * sc
	draw_line(Vector2(-b2, -8 * sc), Vector2(b2, -8 * sc), Color(0.35, 0.35, 0.35, 0.6), 2.5)
	# Rotor hub
	draw_circle(Vector2(0, -8 * sc), 3 * sc, Color(0.4, 0.4, 0.4))
	# Skids
	draw_line(Vector2(-12 * sc, 8 * sc), Vector2(12 * sc, 8 * sc), Color(0.3, 0.3, 0.3), 2)
	draw_line(Vector2(-10 * sc, 6 * sc), Vector2(-10 * sc, 8 * sc), Color(0.3, 0.3, 0.3), 2)
	draw_line(Vector2(10 * sc, 6 * sc), Vector2(10 * sc, 8 * sc), Color(0.3, 0.3, 0.3), 2)

	# Health bar
	if health < max_health:
		var bar_w: float = 30.0
		var hp_ratio: float = float(health) / float(max_health)
		draw_rect(Rect2(-bar_w / 2, -18, bar_w, 4), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-bar_w / 2, -18, bar_w * hp_ratio, 4), Color(0.2, 0.8, 0.2).lerp(Color(0.8, 0.15, 0.1), 1.0 - hp_ratio))
