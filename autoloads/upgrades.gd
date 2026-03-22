extends Node
## Permanent upgrade system — spend score points on upgrades between levels

signal upgrade_purchased(upgrade_name: String)

var upgrade_points: int = 0

var upgrades: Dictionary = {
	"speed": {"name": "Plane Speed", "level": 0, "max": 3, "cost": [500, 1000, 2000], "desc": "+15% speed per level"},
	"blast": {"name": "Blast Radius", "level": 0, "max": 3, "cost": [400, 800, 1500], "desc": "+20% explosion radius"},
	"armor": {"name": "Extra Armor", "level": 0, "max": 2, "cost": [600, 1200], "desc": "+1 life"},
	"cooldown": {"name": "Fast Reload", "level": 0, "max": 3, "cost": [300, 700, 1400], "desc": "-15% bomb cooldown"},
	"magnet": {"name": "Gift Magnet", "level": 0, "max": 2, "cost": [400, 900], "desc": "+50% power-up pickup range"},
	"damage": {"name": "Machine Gun+", "level": 0, "max": 3, "cost": [350, 750, 1500], "desc": "+30% MG damage range"},
}


func get_speed_bonus() -> float:
	return 1.0 + upgrades["speed"]["level"] * 0.15


func get_blast_bonus() -> float:
	return 1.0 + upgrades["blast"]["level"] * 0.2


func get_cooldown_bonus() -> float:
	return 1.0 - upgrades["cooldown"]["level"] * 0.15


func get_magnet_bonus() -> float:
	return 1.0 + upgrades["magnet"]["level"] * 0.5


func get_damage_bonus() -> float:
	return 1.0 + upgrades["damage"]["level"] * 0.3


func can_afford(upgrade_key: String) -> bool:
	var u: Dictionary = upgrades[upgrade_key]
	if u["level"] >= u["max"]:
		return false
	return GameState.score >= u["cost"][u["level"]]


func purchase(upgrade_key: String) -> bool:
	if not can_afford(upgrade_key):
		return false
	var u: Dictionary = upgrades[upgrade_key]
	var cost: int = u["cost"][u["level"]]
	GameState.score -= cost
	Events.score_changed.emit(GameState.score)
	u["level"] += 1

	# Apply immediate effects
	if upgrade_key == "armor":
		GameState.lives += 1
		Events.lives_changed.emit(GameState.lives)

	upgrade_purchased.emit(u["name"])
	SoundManager.speak("Upgrade: %s" % u["name"])
	return true


func save_upgrades() -> void:
	var file := FileAccess.open("user://upgrades.save", FileAccess.WRITE)
	if file:
		for key in upgrades:
			file.store_var(upgrades[key]["level"])


func load_upgrades() -> void:
	if FileAccess.file_exists("user://upgrades.save"):
		var file := FileAccess.open("user://upgrades.save", FileAccess.READ)
		if file:
			for key in upgrades:
				if not file.eof_reached():
					upgrades[key]["level"] = file.get_var()


func reset_upgrades() -> void:
	for key in upgrades:
		upgrades[key]["level"] = 0


func _ready() -> void:
	load_upgrades()
