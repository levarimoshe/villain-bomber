extends Node2D
## EMP bomb — disables all enemy shooting for 5 seconds

const GRAVITY: float = 380.0

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 5.0


func _ready() -> void:
	add_to_group(&"projectile")


func _physics_process(delta: float) -> void:
	if GameState.game_phase == &"paused":
		return

	velocity.y += GRAVITY * delta
	position += velocity * delta
	lifetime -= delta

	if global_position.y > 570:
		_detonate()
		queue_free()
		return

	queue_redraw()
	if lifetime <= 0:
		queue_free()


func _detonate() -> void:
	# Disable all villain shooting for 5 seconds
	for villain in get_tree().get_nodes_in_group(&"villains"):
		if is_instance_valid(villain):
			villain.set("can_shoot", false)

	# Re-enable after 5 seconds
	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	get_tree().current_scene.add_child(timer)
	timer.timeout.connect(func():
		for v in get_tree().get_nodes_in_group(&"villains"):
			if is_instance_valid(v):
				v.set("can_shoot", true)
		timer.queue_free()
	)
	timer.start()

	# Visual: blue shockwave
	Events.bomb_hit_ground.emit(global_position, 2.0, false)
	SoundManager.speak("E M P activated!")


func _draw() -> void:
	# Blue EMP device
	var pulse: float = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.01)
	draw_circle(Vector2.ZERO, 8 * pulse, Color(0.2, 0.4, 1.0, 0.3))
	draw_circle(Vector2.ZERO, 5, Color(0.3, 0.5, 1.0, 0.7))
	draw_circle(Vector2.ZERO, 3, Color(0.5, 0.7, 1.0, 1.0))
	# Lightning arcs
	for i in range(4):
		var a: float = float(i) / 4.0 * TAU + Time.get_ticks_msec() * 0.005
		var end: Vector2 = Vector2(cos(a) * 10, sin(a) * 10)
		draw_line(Vector2.ZERO, end, Color(0.5, 0.8, 1.0, 0.6), 1.5)
