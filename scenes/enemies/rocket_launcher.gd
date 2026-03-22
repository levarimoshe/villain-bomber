extends Node2D
## Rocket launcher — fires slow homing rockets

var speed: float = 50.0
var direction: int = -1
var is_dying: bool = false
var health: int = 2
var camera_ref: Camera2D = null
var anim_time: float = 0.0
var death_timer: float = 0.0
var shoot_timer: float = 3.0
var points_value: int = 300
var muzzle_flash: float = 0.0

const BulletScript = preload("res://scenes/villain/bullet.gd")


func _ready() -> void:
	add_to_group(&"villains")
	shoot_timer = randf_range(2.0, 4.0)


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return
	if is_dying:
		death_timer -= delta
		modulate.a = clampf(death_timer / 0.5, 0.0, 1.0)
		rotation += delta * 6.0
		position.y -= 40 * delta
		if death_timer <= 0:
			queue_free()
		queue_redraw()
		return

	anim_time += delta * 6.0
	if muzzle_flash > 0:
		muzzle_flash -= delta
	position.x += direction * speed * delta

	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_timer = randf_range(3.0, 5.0)
		_fire_rocket()

	if camera_ref and global_position.x < camera_ref.global_position.x - 900:
		Events.villain_escaped.emit()
		queue_free()
	queue_redraw()


func _fire_rocket() -> void:
	muzzle_flash = 0.15
	# Fire a homing rocket (use guided missile logic)
	var MissileScript: GDScript = load("res://scenes/weapons/guided_missile.gd")
	var rocket := Node2D.new()
	rocket.set_script(MissileScript)
	rocket.global_position = global_position + Vector2(0, -25)
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player:
		rocket.velocity = (player.global_position - global_position).normalized() * 180.0
	else:
		rocket.velocity = Vector2(0, -200)
	# Make it an enemy rocket (damages player)
	rocket.add_to_group(&"bullet")
	get_tree().current_scene.add_child(rocket)
	SoundManager.play_shoot()


func hit_by_bomb() -> void:
	if is_dying:
		return
	health -= 1
	if health <= 0:
		is_dying = true
		death_timer = 0.5
		Events.villain_killed.emit(global_position, points_value)


func _draw() -> void:
	var sc: float = 1.6
	var leg_swing: float = sin(anim_time) * 0.3

	# Legs
	draw_line(Vector2(-3 * sc, 0), Vector2(sin(leg_swing) * 4 * sc, 12 * sc), Color(0.22, 0.25, 0.18), 3 * sc)
	draw_line(Vector2(3 * sc, 0), Vector2(sin(-leg_swing) * 4 * sc, 12 * sc), Color(0.22, 0.25, 0.18), 3 * sc)

	# Heavy body
	draw_rect(Rect2(-7 * sc, -15 * sc, 14 * sc, 17 * sc), Color(0.22, 0.25, 0.18))

	# RPG launcher on shoulder
	var rpg_dir: float = float(-direction)
	draw_line(Vector2(rpg_dir * 3 * sc, -14 * sc), Vector2(rpg_dir * 20 * sc, -18 * sc), Color(0.3, 0.3, 0.25), 4 * sc)
	# Launcher tube end
	draw_circle(Vector2(rpg_dir * 20 * sc, -18 * sc), 3 * sc, Color(0.25, 0.25, 0.2))

	# Muzzle flash
	if muzzle_flash > 0:
		draw_circle(Vector2(rpg_dir * 22 * sc, -18 * sc), 8 * sc, Color(1, 0.8, 0.2, 0.7))

	# Head
	draw_circle(Vector2(0, -20 * sc), 5 * sc, Color(0.85, 0.7, 0.55))
	# Helmet
	draw_circle(Vector2(0, -24 * sc), 7 * sc, Color(0.28, 0.3, 0.2))
