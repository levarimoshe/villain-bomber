extends Node
## Manages biome themes — changes sky, ground, building colors every 5 levels

signal biome_changed(biome_name: String)

var current_biome: String = "grassland"

# Biome definitions
var biomes: Dictionary = {
	"grassland": {
		"sky_top": Color(0.15, 0.2, 0.48),
		"sky_mid": Color(0.6, 0.82, 0.95),
		"sky_bottom": Color(0.95, 0.88, 0.75),
		"ground_color": Color(0.22, 0.55, 0.15),
		"ground_dark": Color(0.15, 0.42, 0.1),
		"earth_color": Color(0.4, 0.28, 0.12),
		"building_tint": Color(1, 1, 1),
		"weather": "clear",
	},
	"desert": {
		"sky_top": Color(0.3, 0.35, 0.55),
		"sky_mid": Color(0.85, 0.75, 0.55),
		"sky_bottom": Color(0.95, 0.85, 0.6),
		"ground_color": Color(0.7, 0.6, 0.35),
		"ground_dark": Color(0.6, 0.5, 0.3),
		"earth_color": Color(0.55, 0.4, 0.2),
		"building_tint": Color(0.9, 0.85, 0.7),
		"weather": "clear",
	},
	"arctic": {
		"sky_top": Color(0.2, 0.25, 0.4),
		"sky_mid": Color(0.6, 0.7, 0.85),
		"sky_bottom": Color(0.85, 0.88, 0.95),
		"ground_color": Color(0.85, 0.88, 0.92),
		"ground_dark": Color(0.7, 0.75, 0.82),
		"earth_color": Color(0.6, 0.62, 0.68),
		"building_tint": Color(0.8, 0.85, 0.95),
		"weather": "snow",
	},
	"volcanic": {
		"sky_top": Color(0.15, 0.08, 0.08),
		"sky_mid": Color(0.4, 0.15, 0.08),
		"sky_bottom": Color(0.6, 0.25, 0.1),
		"ground_color": Color(0.2, 0.18, 0.15),
		"ground_dark": Color(0.15, 0.12, 0.1),
		"earth_color": Color(0.25, 0.15, 0.08),
		"building_tint": Color(0.8, 0.6, 0.5),
		"weather": "ash",
	},
	"night_city": {
		"sky_top": Color(0.02, 0.02, 0.08),
		"sky_mid": Color(0.05, 0.05, 0.15),
		"sky_bottom": Color(0.1, 0.08, 0.2),
		"ground_color": Color(0.12, 0.15, 0.12),
		"ground_dark": Color(0.08, 0.1, 0.08),
		"earth_color": Color(0.15, 0.12, 0.1),
		"building_tint": Color(0.6, 0.7, 0.9),
		"weather": "night",
	},
}

var biome_order: Array = ["grassland", "desert", "arctic", "volcanic", "night_city"]


func _ready() -> void:
	Events.level_changed.connect(_on_level_changed)


func _on_level_changed(level: int) -> void:
	var biome_index: int = ((level - 1) / 5) % biome_order.size()
	var new_biome: String = biome_order[biome_index]
	if new_biome != current_biome:
		current_biome = new_biome
		biome_changed.emit(current_biome)
		SoundManager.speak("Entering %s zone" % current_biome.replace("_", " "))


func get_biome() -> Dictionary:
	return biomes[current_biome]


func get_sky_top() -> Color:
	return biomes[current_biome]["sky_top"]


func get_sky_mid() -> Color:
	return biomes[current_biome]["sky_mid"]


func get_sky_bottom() -> Color:
	return biomes[current_biome]["sky_bottom"]


func get_ground_color() -> Color:
	return biomes[current_biome]["ground_color"]


func get_ground_dark() -> Color:
	return biomes[current_biome]["ground_dark"]


func get_earth_color() -> Color:
	return biomes[current_biome]["earth_color"]
