extends Node

var current_mission: String = ""
var mission_target: int = 0
var mission_progress: int = 0
var mission_active: bool = false
var mission_complete: bool = false
var mission_type: String = ""

const MISSIONS: Array = [
	{"type": "kills", "text": "Kill %d enemies", "min": 5, "max": 8},
	{"type": "combo", "text": "Get a x%d combo", "min": 3, "max": 4},
	{"type": "no_hit", "text": "Kill %d enemies without getting hit", "min": 3, "max": 5},
	{"type": "powerups", "text": "Collect %d power-ups", "min": 1, "max": 2},
]

var no_hit_streak: int = 0


func _ready() -> void:
	Events.villain_killed.connect(_on_villain_killed)
	Events.combo_updated.connect(_on_combo_updated)
	Events.player_hit.connect(_on_player_hit)
	Events.power_up_collected.connect(_on_power_up_collected)
	Events.level_changed.connect(_on_level_changed)
	Events.game_started.connect(_on_game_started)


func generate_mission() -> void:
	var m: Dictionary = MISSIONS[randi() % MISSIONS.size()]
	mission_type = m["type"]
	mission_target = randi_range(m["min"], m["max"])
	current_mission = m["text"] % mission_target
	mission_progress = 0
	mission_active = true
	mission_complete = false
	no_hit_streak = 0


func _check_complete() -> void:
	if mission_complete or not mission_active:
		return
	if mission_progress >= mission_target:
		mission_complete = true
		GameState.add_score(1000)
		SoundManager.speak("Mission complete! Bonus points!")


func _on_villain_killed(_pos: Vector2, _points: int) -> void:
	if not mission_active or mission_complete:
		return
	if mission_type == "kills":
		mission_progress += 1
		_check_complete()
	elif mission_type == "no_hit":
		no_hit_streak += 1
		mission_progress = no_hit_streak
		_check_complete()


func _on_combo_updated(_count: int, mult: int) -> void:
	if not mission_active or mission_complete:
		return
	if mission_type == "combo" and mult >= mission_target:
		mission_progress = mult
		_check_complete()


func _on_player_hit() -> void:
	if mission_type == "no_hit":
		no_hit_streak = 0
		mission_progress = 0


func _on_power_up_collected(_type: String) -> void:
	if not mission_active or mission_complete:
		return
	if mission_type == "powerups":
		mission_progress += 1
		_check_complete()


func _on_level_changed(_level: int) -> void:
	generate_mission()


func _on_game_started() -> void:
	generate_mission()
