extends Node2D

var buildings: Array = []
var smoke_time: float = 0.0
const TILE_WIDTH: int = 2560
const GROUND_BASE_Y: float = 580.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var x: float = 60.0
	while x < TILE_WIDTH - 100:
		var btype: int = rng.randi() % 4  # 0=bunker, 1=tower, 2=factory, 3=headquarters
		var w: float = [70.0, 45.0, 90.0, 100.0][btype]
		var h: float = [55.0, 140.0, 80.0, 100.0][btype]
		h += rng.randf_range(-10.0, 20.0)
		var ground_y: float = GROUND_BASE_Y - (sin(x * 0.005) * 45.0 + sin(x * 0.013) * 20.0)
		buildings.append({
			"type": btype,
			"rect": Rect2(x, ground_y - h, w, h),
			"ground_y": ground_y,
			"has_flag": rng.randf() > 0.5,
			"has_radar": rng.randf() > 0.6,
			"has_smokestack": btype == 2 or rng.randf() > 0.7,
			"door_side": rng.randi() % 2,
			"color_var": rng.randf_range(-0.03, 0.03),
		})
		x += w + rng.randf_range(100.0, 280.0)


func _process(delta: float) -> void:
	smoke_time += delta
	queue_redraw()


func _draw() -> void:
	for b in buildings:
		var r: Rect2 = b["rect"]
		var btype: int = b["type"]
		var cv: float = b["color_var"]

		# === BASE WALL ===
		var wall_color := Color(0.22 + cv, 0.22 + cv, 0.25 + cv)
		draw_rect(r, wall_color)

		# Dark edges for 3D effect
		draw_rect(Rect2(r.position.x, r.position.y, 3, r.size.y), wall_color.darkened(0.25))
		draw_rect(Rect2(r.position.x + r.size.x - 3, r.position.y, 3, r.size.y), wall_color.darkened(0.15))
		# Top edge
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3), wall_color.lightened(0.1))

		# === RIVETS ===
		_draw_rivets(r, wall_color)

		# === WARNING STRIPES (bottom) ===
		_draw_warning_stripes(r)

		# === SKULL EMBLEM ===
		var skull_x: float = r.position.x + r.size.x * 0.5
		var skull_y: float = r.position.y + r.size.y * 0.35
		if btype != 1:  # Not on thin towers
			_draw_skull(Vector2(skull_x, skull_y), 12.0)

		# === WINDOWS (evil red/orange glow) ===
		_draw_evil_windows(r, btype)

		# === DOOR ===
		var door_x: float = r.position.x + r.size.x * 0.4
		if b["door_side"] == 1:
			door_x = r.position.x + r.size.x * 0.6
		var door_w: float = 14.0
		var door_h: float = 22.0
		draw_rect(Rect2(door_x - door_w / 2, r.position.y + r.size.y - door_h, door_w, door_h), Color(0.08, 0.08, 0.08))
		# Door frame
		draw_rect(Rect2(door_x - door_w / 2 - 1, r.position.y + r.size.y - door_h - 1, door_w + 2, 2), Color(0.4, 0.35, 0.1))

		# === TYPE-SPECIFIC FEATURES ===
		match btype:
			0: _draw_bunker_details(r, b)
			1: _draw_tower_details(r, b)
			2: _draw_factory_details(r, b)
			3: _draw_hq_details(r, b)

		# === BARBED WIRE ===
		_draw_barbed_wire(r)

		# === FLAG ===
		if b["has_flag"]:
			_draw_evil_flag(Vector2(r.position.x + r.size.x * 0.8, r.position.y - 5))

		# === RADAR DISH ===
		if b["has_radar"]:
			_draw_radar(Vector2(r.position.x + r.size.x * 0.3, r.position.y - 2))

		# === SMOKESTACK ===
		if b["has_smokestack"]:
			_draw_smokestack(Vector2(r.position.x + r.size.x * 0.15, r.position.y))


func _draw_rivets(r: Rect2, color: Color) -> void:
	var rivet_color := color.lightened(0.15)
	# Top row
	var spacing: float = 12.0
	var y_pos: float = r.position.y + 8
	var x: float = r.position.x + 6
	while x < r.position.x + r.size.x - 4:
		draw_rect(Rect2(x - 1.5, y_pos - 1.5, 3, 3), rivet_color)
		x += spacing
	# Bottom row
	y_pos = r.position.y + r.size.y - 8
	x = r.position.x + 6
	while x < r.position.x + r.size.x - 4:
		draw_rect(Rect2(x - 1.5, y_pos - 1.5, 3, 3), rivet_color)
		x += spacing


func _draw_warning_stripes(r: Rect2) -> void:
	var stripe_h: float = 8.0
	var y: float = r.position.y + r.size.y - stripe_h
	var stripe_w: float = 10.0
	var x: float = r.position.x
	var idx: int = 0
	while x < r.position.x + r.size.x:
		var w: float = minf(stripe_w, r.position.x + r.size.x - x)
		var color: Color = Color(0.8, 0.7, 0.0) if idx % 2 == 0 else Color(0.15, 0.15, 0.15)
		draw_rect(Rect2(x, y, w, stripe_h), color)
		x += stripe_w
		idx += 1


func _draw_skull(center: Vector2, size: float) -> void:
	# Background circle
	_draw_circle_at(center, size + 2, Color(0.6, 0.1, 0.1, 0.6))
	# Skull head
	_draw_circle_at(center + Vector2(0, -2), size * 0.7, Color(0.85, 0.82, 0.75))
	# Jaw
	draw_rect(Rect2(center.x - size * 0.4, center.y + size * 0.2, size * 0.8, size * 0.3), Color(0.8, 0.77, 0.7))
	# Eye sockets
	_draw_circle_at(center + Vector2(-size * 0.25, -3), size * 0.2, Color(0.1, 0.1, 0.1))
	_draw_circle_at(center + Vector2(size * 0.25, -3), size * 0.2, Color(0.1, 0.1, 0.1))
	# Red glow in eyes
	_draw_circle_at(center + Vector2(-size * 0.25, -3), size * 0.1, Color(0.8, 0.1, 0.0, 0.7))
	_draw_circle_at(center + Vector2(size * 0.25, -3), size * 0.1, Color(0.8, 0.1, 0.0, 0.7))
	# Nose hole
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, 1), center + Vector2(-2, 5), center + Vector2(2, 5)
	]), Color(0.2, 0.2, 0.2))
	# Teeth
	for i in range(4):
		var tx: float = center.x - 4 + i * 3
		draw_rect(Rect2(tx, center.y + size * 0.3, 2, 4), Color(0.9, 0.87, 0.8))


func _draw_evil_windows(r: Rect2, btype: int) -> void:
	var win_w: float = 8.0
	var win_h: float = 10.0
	var margin: float = 12.0
	var cols: int = int((r.size.x - margin * 2) / (win_w + 8))
	var rows: int = int((r.size.y - 50) / (win_h + 12))
	rows = clampi(rows, 0, 4)
	for row in range(rows):
		for col in range(cols):
			var wx: float = r.position.x + margin + col * (win_w + 8)
			var wy: float = r.position.y + 18 + row * (win_h + 12)
			# Window frame
			draw_rect(Rect2(wx - 1, wy - 1, win_w + 2, win_h + 2), Color(0.3, 0.3, 0.3))
			# Window glow
			var flicker: float = sin(smoke_time * 2.0 + wx * 0.1 + wy * 0.2)
			var glow_alpha: float = 0.5 + flicker * 0.3
			var glow_color := Color(0.9, 0.3, 0.05, glow_alpha)
			if fmod(wx + wy, 30.0) > 15.0:
				glow_color = Color(0.9, 0.6, 0.1, glow_alpha * 0.7)
			draw_rect(Rect2(wx, wy, win_w, win_h), glow_color)


func _draw_bunker_details(r: Rect2, b: Dictionary) -> void:
	# Flat reinforced roof
	draw_rect(Rect2(r.position.x - 4, r.position.y - 4, r.size.x + 8, 6), Color(0.3, 0.3, 0.32))
	# Sandbags at base
	for i in range(int(r.size.x / 12)):
		var sx: float = r.position.x + i * 12 + 3
		var sy: float = b["ground_y"] - 8
		_draw_circle_at(Vector2(sx + 5, sy), 5, Color(0.5, 0.45, 0.3))
		_draw_circle_at(Vector2(sx + 5, sy + 4), 4, Color(0.45, 0.4, 0.28))


func _draw_tower_details(r: Rect2, b: Dictionary) -> void:
	# Pointed roof
	draw_colored_polygon(PackedVector2Array([
		Vector2(r.position.x - 5, r.position.y),
		Vector2(r.position.x + r.size.x / 2, r.position.y - 25),
		Vector2(r.position.x + r.size.x + 5, r.position.y),
	]), Color(0.3, 0.15, 0.15))
	# Searchlight beam
	var beam_angle: float = sin(smoke_time * 0.8) * 0.5
	var beam_origin := Vector2(r.position.x + r.size.x / 2, r.position.y - 20)
	var beam_len: float = 200.0
	var beam_end := beam_origin + Vector2(sin(beam_angle) * beam_len, cos(beam_angle) * beam_len * 0.3 + beam_len * 0.6)
	var beam_width: float = 40.0
	var left := beam_end + Vector2(-beam_width, 0)
	var right := beam_end + Vector2(beam_width, 0)
	draw_colored_polygon(PackedVector2Array([beam_origin, left, right]), Color(1, 1, 0.7, 0.06))
	# Light source
	_draw_circle_at(beam_origin, 5, Color(1, 1, 0.8, 0.8))


func _draw_factory_details(r: Rect2, b: Dictionary) -> void:
	# Saw-tooth roof
	var teeth: int = int(r.size.x / 25)
	var tooth_w: float = r.size.x / float(teeth)
	for i in range(teeth):
		var tx: float = r.position.x + i * tooth_w
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx, r.position.y),
			Vector2(tx + tooth_w * 0.3, r.position.y - 15),
			Vector2(tx + tooth_w, r.position.y),
		]), Color(0.28, 0.28, 0.3))
	# Pipes on wall
	draw_line(Vector2(r.position.x + 8, r.position.y + 20), Vector2(r.position.x + 8, r.position.y + r.size.y - 15), Color(0.35, 0.32, 0.2), 3.0)
	draw_line(Vector2(r.position.x + r.size.x - 8, r.position.y + 20), Vector2(r.position.x + r.size.x - 8, r.position.y + r.size.y - 15), Color(0.35, 0.32, 0.2), 3.0)


func _draw_hq_details(r: Rect2, b: Dictionary) -> void:
	# Fortified top with battlements
	var batt_w: float = 10.0
	var batt_h: float = 12.0
	var x: float = r.position.x
	while x < r.position.x + r.size.x - batt_w:
		draw_rect(Rect2(x, r.position.y - batt_h, batt_w - 3, batt_h), Color(0.25, 0.25, 0.28))
		x += batt_w + 4
	# Large skull on front
	_draw_skull(Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.3), 18.0)


func _draw_barbed_wire(r: Rect2) -> void:
	var y: float = r.position.y - 2
	var x: float = r.position.x - 5
	var end_x: float = r.position.x + r.size.x + 5
	var wire_color := Color(0.4, 0.4, 0.4)
	# Main wire
	draw_line(Vector2(x, y), Vector2(end_x, y), wire_color, 1.0)
	# Barbs
	var bx: float = x + 5
	while bx < end_x - 5:
		draw_line(Vector2(bx, y - 3), Vector2(bx + 2, y + 3), wire_color, 1.0)
		draw_line(Vector2(bx, y + 3), Vector2(bx + 2, y - 3), wire_color, 1.0)
		bx += 8


func _draw_evil_flag(pos: Vector2) -> void:
	# Pole
	draw_line(pos, pos + Vector2(0, -35), Color(0.4, 0.4, 0.4), 2.0)
	# Flag cloth (animated wave)
	var wave: float = sin(smoke_time * 3.0) * 3.0
	var flag_points := PackedVector2Array([
		pos + Vector2(0, -35),
		pos + Vector2(22 + wave, -32 + wave * 0.3),
		pos + Vector2(20 + wave * 0.8, -22),
		pos + Vector2(0, -20),
	])
	draw_colored_polygon(flag_points, Color(0.6, 0.05, 0.05))
	# Skull on flag
	_draw_circle_at(pos + Vector2(10 + wave * 0.5, -27), 4, Color(0.85, 0.8, 0.7))
	# Eye dots on flag skull
	draw_rect(Rect2(pos.x + 8 + wave * 0.5, pos.y - 29, 2, 2), Color(0.2, 0.0, 0.0))
	draw_rect(Rect2(pos.x + 12 + wave * 0.5, pos.y - 29, 2, 2), Color(0.2, 0.0, 0.0))


func _draw_radar(pos: Vector2) -> void:
	# Base
	draw_rect(Rect2(pos.x - 3, pos.y - 8, 6, 8), Color(0.35, 0.35, 0.35))
	# Dish (rotating)
	var angle: float = smoke_time * 1.5
	var dish_end: Vector2 = pos + Vector2(cos(angle) * 15, -8 + sin(angle) * 4 - 6)
	draw_line(pos + Vector2(0, -8), dish_end, Color(0.45, 0.45, 0.45), 2.0)
	_draw_circle_at(dish_end, 3, Color(0.5, 0.5, 0.5))
	# Blinking light
	var blink: float = fmod(smoke_time, 1.0)
	if blink < 0.3:
		_draw_circle_at(pos + Vector2(0, -10), 2, Color(0.0, 1.0, 0.0, 0.8))


func _draw_smokestack(pos: Vector2) -> void:
	# Chimney
	draw_rect(Rect2(pos.x - 5, pos.y - 30, 10, 30), Color(0.3, 0.25, 0.2))
	draw_rect(Rect2(pos.x - 7, pos.y - 32, 14, 4), Color(0.35, 0.3, 0.25))
	# Smoke puffs
	for i in range(5):
		var t: float = fmod(smoke_time * 0.4 + float(i) * 0.3, 1.5)
		var sx: float = pos.x + sin(t * 3.0 + float(i)) * 8.0
		var sy: float = pos.y - 32 - t * 40.0
		var alpha: float = (1.0 - t / 1.5) * 0.25
		var size: float = 6.0 + t * 15.0
		_draw_circle_at(Vector2(sx, sy), size, Color(0.3, 0.3, 0.3, alpha))


func _draw_circle_at(pos: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var points := PackedVector2Array()
	var segs: int = 12
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		points.append(pos + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(points, color)
