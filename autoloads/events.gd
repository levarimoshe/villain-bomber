extends Node

# Game flow
signal game_started
signal game_over
signal game_paused
signal game_resumed
signal level_changed(level: int)
signal level_transition_started(level: int)

# Scoring
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal extra_life_gained
signal combo_updated(combo_count: int, multiplier: int)

# Gameplay events
signal bomb_dropped(bomb: Node2D)
signal villain_killed(position: Vector2, points: int)
signal villain_escaped
signal bomb_hit_ground(position: Vector2)
signal player_hit
signal power_up_collected(type: String)
signal power_up_spawned(power_up: Node2D)
