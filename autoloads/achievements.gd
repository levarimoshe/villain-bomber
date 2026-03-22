extends Node
## Achievement tracking and popup system

signal achievement_unlocked(name: String, description: String)

var unlocked: Dictionary = {}
var popup_queue: Array = []
var popup_timer: float = 0.0

var ACHIEVEMENTS: Dictionary = {
	"first_blood": {"name": "First Blood", "desc": "Kill your first villain"},
	"combo_x3": {"name": "Combo Master", "desc": "Get a x3 combo"},
	"combo_x5": {"name": "Combo King", "desc": "Get a x5 combo"},
	"boss_kill": {"name": "Boss Slayer", "desc": "Defeat a boss"},
	"nuke_10": {"name": "Carpet Bomber", "desc": "Kill 10+ with one nuke"},
	"level_5": {"name": "Veteran", "desc": "Reach level 5"},
	"level_10": {"name": "Elite", "desc": "Reach level 10"},
	"level_20": {"name": "Legend", "desc": "Reach level 20"},
	"score_5k": {"name": "High Roller", "desc": "Score 5,000 points"},
	"score_20k": {"name": "Score Master", "desc": "Score 20,000 points"},
	"kills_50": {"name": "Destroyer", "desc": "Kill 50 villains total"},
	"kills_200": {"name": "Annihilator", "desc": "Kill 200 villains total"},
	"no_damage": {"name": "Untouchable", "desc": "Complete a level without damage"},
	"all_weapons": {"name": "Arsenal", "desc": "Unlock all weapons"},
	"shield_save": {"name": "Lucky Shield", "desc": "Shield blocks a hit"},
	"rapid_max": {"name": "Bullet Hell", "desc": "Reach rapid fire level 3"},
}


func _ready() -> void:
	load_achievements()
	Events.villain_killed.connect(_on_kill)
	Events.combo_updated.connect(_on_combo)
	Events.level_changed.connect(_on_level)
	Events.score_changed.connect(_on_score)


func _process(delta: float) -> void:
	if popup_timer > 0:
		popup_timer -= delta


func unlock(key: String) -> void:
	if unlocked.has(key):
		return
	if not ACHIEVEMENTS.has(key):
		return
	unlocked[key] = true
	var ach: Dictionary = ACHIEVEMENTS[key]
	achievement_unlocked.emit(ach["name"], ach["desc"])
	popup_queue.append(ach)
	popup_timer = 3.0
	SoundManager.play_levelup()
	save_achievements()


func _on_kill(_pos: Vector2, _pts: int) -> void:
	if GameState.total_villains_killed == 1:
		unlock("first_blood")
	if GameState.total_villains_killed >= 50:
		unlock("kills_50")
	if GameState.total_villains_killed >= 200:
		unlock("kills_200")


func _on_combo(_count: int, mult: int) -> void:
	if mult >= 3:
		unlock("combo_x3")
	if mult >= 5:
		unlock("combo_x5")


func _on_level(level: int) -> void:
	if level >= 5:
		unlock("level_5")
	if level >= 10:
		unlock("level_10")
	if level >= 20:
		unlock("level_20")


func _on_score(score: int) -> void:
	if score >= 5000:
		unlock("score_5k")
	if score >= 20000:
		unlock("score_20k")


func get_popup() -> Dictionary:
	if popup_queue.size() > 0 and popup_timer > 0:
		return popup_queue[0]
	elif popup_queue.size() > 0 and popup_timer <= 0:
		popup_queue.remove_at(0)
	return {}


func save_achievements() -> void:
	var file := FileAccess.open("user://achievements.save", FileAccess.WRITE)
	if file:
		file.store_var(unlocked)


func load_achievements() -> void:
	if FileAccess.file_exists("user://achievements.save"):
		var file := FileAccess.open("user://achievements.save", FileAccess.READ)
		if file:
			var data: Variant = file.get_var()
			if data is Dictionary:
				unlocked = data
