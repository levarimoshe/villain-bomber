extends Node
## Full game state save/load system

const SAVE_PATH: String = "user://game_save.dat"

var stats: Dictionary = {
	"total_kills": 0,
	"total_deaths": 0,
	"total_bombs": 0,
	"total_games": 0,
	"highest_combo": 0,
	"highest_level": 0,
	"highest_score": 0,
	"total_playtime": 0.0,
	"bosses_killed": 0,
	"nukes_used": 0,
}

var playtime_timer: float = 0.0


func _ready() -> void:
	load_stats()
	Events.villain_killed.connect(_on_kill)
	Events.game_over.connect(_on_game_over)
	Events.game_started.connect(_on_game_start)


func _process(delta: float) -> void:
	if GameState.game_phase == &"playing":
		playtime_timer += delta
		stats["total_playtime"] = stats.get("total_playtime", 0.0) + delta


func _on_kill(_pos: Vector2, _pts: int) -> void:
	stats["total_kills"] = stats.get("total_kills", 0) + 1


func _on_game_over() -> void:
	stats["total_deaths"] = stats.get("total_deaths", 0) + 1
	stats["total_bombs"] = stats.get("total_bombs", 0) + GameState.total_bombs_dropped
	if GameState.current_level > stats.get("highest_level", 0):
		stats["highest_level"] = GameState.current_level
	if GameState.score > stats.get("highest_score", 0):
		stats["highest_score"] = GameState.score
	save_stats()
	Upgrades.save_upgrades()


func _on_game_start() -> void:
	stats["total_games"] = stats.get("total_games", 0) + 1


func save_stats() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(stats)


func load_stats() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data: Variant = file.get_var()
			if data is Dictionary:
				stats = data


func get_stat(key: String) -> Variant:
	return stats.get(key, 0)


func format_playtime() -> String:
	var total: int = int(stats.get("total_playtime", 0.0))
	var hours: int = total / 3600
	var minutes: int = (total % 3600) / 60
	return "%dh %dm" % [hours, minutes]
