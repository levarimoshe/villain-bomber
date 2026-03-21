extends Node2D

var HELMET_COLORS := [
	Color(0.3, 0.35, 0.2),
	Color(0.25, 0.25, 0.3),
	Color(0.35, 0.28, 0.2),
]

var UNIFORM_COLORS := [
	Color(0.25, 0.35, 0.2),
	Color(0.2, 0.2, 0.3),
	Color(0.3, 0.25, 0.15),
]

var parent_villain: Area2D


func _ready() -> void:
	parent_villain = get_parent() as Area2D


func _draw() -> void:
	if not parent_villain:
		return

	var vtype: int = parent_villain.villain_type
	var anim: float = parent_villain.anim_time
	var is_officer: bool = vtype == 2
	var color_idx: int = clampi(vtype, 0, 2)

	var helmet_color: Color = HELMET_COLORS[color_idx]
	var uniform_color: Color = UNIFORM_COLORS[color_idx]
	if is_officer:
		helmet_color = Color(0.15, 0.12, 0.12)  # Dark beret
		uniform_color = Color(0.2, 0.18, 0.15)  # Dark officer uniform

	var skin_color := Color(0.85, 0.7, 0.55)
	var boot_color := Color(0.15, 0.12, 0.1)
	var belt_color := Color(0.35, 0.25, 0.12)

	# Scale factor (bigger villains!)
	var sc: float = 1.6
	if is_officer:
		sc = 1.9

	var leg_swing: float = sin(anim) * 0.5
	var arm_swing: float = sin(anim + PI) * 0.4

	# === LEGS ===
	var left_leg_end := Vector2(sin(leg_swing) * 7 * sc, 14 * sc)
	draw_line(Vector2(-3 * sc, 0), left_leg_end, uniform_color.darkened(0.1), 4.0 * sc)
	draw_rect(Rect2(left_leg_end.x - 4 * sc, left_leg_end.y, 7 * sc, 5 * sc), boot_color)

	var right_leg_end := Vector2(sin(-leg_swing) * 7 * sc, 14 * sc)
	draw_line(Vector2(3 * sc, 0), right_leg_end, uniform_color.darkened(0.1), 4.0 * sc)
	draw_rect(Rect2(right_leg_end.x - 4 * sc, right_leg_end.y, 7 * sc, 5 * sc), boot_color)

	# === TORSO ===
	draw_rect(Rect2(-7 * sc, -16 * sc, 14 * sc, 18 * sc), uniform_color)
	# Belt
	draw_rect(Rect2(-8 * sc, -5 * sc, 16 * sc, 3 * sc), belt_color)
	draw_rect(Rect2(-2 * sc, -5 * sc, 4 * sc, 3 * sc), Color(0.7, 0.6, 0.2))
	# Pockets
	draw_rect(Rect2(-6 * sc, -13 * sc, 5 * sc, 4 * sc), uniform_color.lightened(0.06))
	draw_rect(Rect2(1 * sc, -13 * sc, 5 * sc, 4 * sc), uniform_color.lightened(0.06))

	# === BACKPACK ===
	draw_rect(Rect2(-8 * sc, -14 * sc, 4 * sc, 10 * sc), uniform_color.darkened(0.15))

	# === ARMS + WEAPON ===
	var weapon_color := Color(0.3, 0.28, 0.25)
	# Left arm (holding weapon)
	var left_arm_end := Vector2(-7 * sc, -8 * sc) + Vector2(sin(arm_swing) * 3 * sc, 10 * sc)
	draw_line(Vector2(-7 * sc, -12 * sc), left_arm_end, uniform_color.darkened(0.05), 3.5 * sc)
	draw_circle(left_arm_end, 2.5 * sc, skin_color)

	# Rifle
	var rifle_start := left_arm_end + Vector2(-2 * sc, -3 * sc)
	var rifle_end := rifle_start + Vector2(-4 * sc, -18 * sc)
	draw_line(rifle_start, rifle_end, weapon_color, 2.5 * sc)
	# Rifle stock
	draw_line(rifle_start, rifle_start + Vector2(2 * sc, 5 * sc), weapon_color.darkened(0.1), 3.0 * sc)

	# Right arm
	var right_arm_end := Vector2(7 * sc, -8 * sc) + Vector2(sin(-arm_swing) * 3 * sc, 10 * sc)
	draw_line(Vector2(7 * sc, -12 * sc), right_arm_end, uniform_color.darkened(0.05), 3.5 * sc)
	draw_circle(right_arm_end, 2.5 * sc, skin_color)

	# === MUZZLE FLASH ===
	if parent_villain.muzzle_flash_timer > 0:
		var flash_pos: Vector2 = rifle_end + Vector2(-2 * sc, -5 * sc)
		_draw_circle_safe(flash_pos, 8 * sc, Color(1.0, 0.9, 0.3, 0.8))
		_draw_circle_safe(flash_pos, 5 * sc, Color(1.0, 1.0, 0.7, 0.9))
		_draw_circle_safe(flash_pos, 3 * sc, Color(1.0, 1.0, 1.0, 1.0))

	# === HEAD ===
	draw_rect(Rect2(-2 * sc, -20 * sc, 4 * sc, 5 * sc), skin_color)
	draw_circle(Vector2(0, -24 * sc), 8.0 * sc, skin_color)

	# Eyes
	draw_circle(Vector2(-3 * sc, -25 * sc), 2.0 * sc, Color.WHITE)
	draw_circle(Vector2(3 * sc, -25 * sc), 2.0 * sc, Color.WHITE)
	draw_circle(Vector2(-2.5 * sc, -25 * sc), 1.0 * sc, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(3.5 * sc, -25 * sc), 1.0 * sc, Color(0.1, 0.1, 0.1))
	# Angry eyebrows
	draw_line(Vector2(-5 * sc, -28 * sc), Vector2(-1 * sc, -27 * sc), Color(0.3, 0.2, 0.1), 1.5 * sc)
	draw_line(Vector2(5 * sc, -28 * sc), Vector2(1 * sc, -27 * sc), Color(0.3, 0.2, 0.1), 1.5 * sc)
	# Frown
	draw_arc(Vector2(0, -21 * sc), 3.0 * sc, 0.3, PI - 0.3, 8, Color(0.3, 0.15, 0.1), 2.0 * sc)

	# === HELMET / BERET ===
	if is_officer:
		# Officer beret
		_draw_ellipse(Vector2(0, -30 * sc), 10.0 * sc, 4.0 * sc, helmet_color)
		draw_rect(Rect2(-9 * sc, -28 * sc, 18 * sc, 2 * sc), helmet_color.lightened(0.1))
		# Gold badge
		_draw_circle_safe(Vector2(4 * sc, -30 * sc), 2.0 * sc, Color(0.8, 0.7, 0.1))
		# Medal on chest
		_draw_circle_safe(Vector2(3 * sc, -12 * sc), 2.5 * sc, Color(0.8, 0.7, 0.1))
		_draw_circle_safe(Vector2(3 * sc, -12 * sc), 1.5 * sc, Color(0.9, 0.1, 0.1))
	else:
		# Regular helmet
		_draw_ellipse(Vector2(0, -30 * sc), 10.0 * sc, 6.0 * sc, helmet_color)
		draw_rect(Rect2(-11 * sc, -27 * sc, 22 * sc, 2.5 * sc), helmet_color.darkened(0.1))
		draw_arc(Vector2(0, -31 * sc), 7.0 * sc, PI * 0.7, PI * 1.3, 6, helmet_color.lightened(0.15), 2.0 * sc)

	# === DUST CLOUD AT FEET ===
	var dust_x: float = sin(anim * 0.5) * 3
	_draw_circle_safe(Vector2(dust_x, 16 * sc), 4 * sc, Color(0.5, 0.45, 0.35, 0.15))
	_draw_circle_safe(Vector2(dust_x + 5, 14 * sc), 3 * sc, Color(0.5, 0.45, 0.35, 0.1))


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(17):
		var angle: float = float(i) / 16.0 * TAU
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)


func _draw_circle_safe(pos: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var points := PackedVector2Array()
	var segs: int = 12
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(pos + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
