extends Node
## Manages all weapon types, switching, cooldowns, and unlocks

signal weapon_changed(weapon_name: String)

var current_weapon_index: int = 0
var weapons: Array[Dictionary] = []
var weapon_cooldowns: Dictionary = {}


func _ready() -> void:
	# Define all weapons
	weapons = [
		{
			"name": "Bomb",
			"description": "Standard explosive bomb",
			"cooldown": 0.3,
			"unlocked": true,
			"color": Color(0.4, 0.4, 0.4),
			"script_path": "",  # Uses default bomb
		},
		{
			"name": "Cluster Bomb",
			"description": "Splits into 5 mini bombs",
			"cooldown": 0.8,
			"unlocked": false,
			"unlock_level": 3,
			"color": Color(0.9, 0.5, 0.1),
			"script_path": "res://scenes/weapons/cluster_bomb.gd",
		},
		{
			"name": "Napalm",
			"description": "Massive fire area",
			"cooldown": 1.2,
			"unlocked": false,
			"unlock_level": 6,
			"color": Color(1.0, 0.3, 0.0),
			"script_path": "res://scenes/weapons/napalm.gd",
		},
		{
			"name": "Guided Missile",
			"description": "Homes on nearest enemy",
			"cooldown": 0.6,
			"unlocked": false,
			"unlock_level": 8,
			"color": Color(0.3, 0.8, 0.3),
			"script_path": "res://scenes/weapons/guided_missile.gd",
		},
		{
			"name": "Carpet Bomb",
			"description": "Drops 10 bombs in a line",
			"cooldown": 2.0,
			"unlocked": false,
			"unlock_level": 10,
			"color": Color(0.6, 0.3, 0.1),
			"script_path": "res://scenes/weapons/carpet_bomb.gd",
		},
		{
			"name": "EMP",
			"description": "Disables enemy shooting",
			"cooldown": 3.0,
			"unlocked": false,
			"unlock_level": 12,
			"color": Color(0.2, 0.5, 1.0),
			"script_path": "res://scenes/weapons/emp_bomb.gd",
		},
	]


func _input(event: InputEvent) -> void:
	if GameState.game_phase != &"playing":
		return
	# Q = previous weapon, E = next weapon
	if event.is_action_pressed(&"prev_weapon"):
		_cycle_weapon(-1)
	elif event.is_action_pressed(&"next_weapon"):
		_cycle_weapon(1)


func _cycle_weapon(direction: int) -> void:
	var start := current_weapon_index
	for attempt in range(weapons.size()):
		current_weapon_index = (current_weapon_index + direction + weapons.size()) % weapons.size()
		if weapons[current_weapon_index]["unlocked"]:
			weapon_changed.emit(weapons[current_weapon_index]["name"])
			SoundManager.play_combo()  # Click sound
			return
	current_weapon_index = start  # No other weapon available


func get_current_weapon() -> Dictionary:
	return weapons[current_weapon_index]


func get_current_name() -> String:
	return weapons[current_weapon_index]["name"]


func get_current_cooldown() -> float:
	return weapons[current_weapon_index]["cooldown"]


func get_current_color() -> Color:
	return weapons[current_weapon_index]["color"]


func check_unlocks() -> void:
	for w in weapons:
		if not w["unlocked"] and w.has("unlock_level"):
			if GameState.current_level >= w["unlock_level"]:
				w["unlocked"] = true
				SoundManager.speak("New weapon unlocked: %s!" % w["name"])


func get_unlocked_weapons() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for w in weapons:
		if w["unlocked"]:
			result.append(w)
	return result
