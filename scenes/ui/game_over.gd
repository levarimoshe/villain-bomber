extends Control

@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var highscore_label: Label = $VBoxContainer/HighScoreLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var restart_label: Label = $VBoxContainer/RestartLabel

var pulse_time: float = 0.0


func _process(delta: float) -> void:
	if not visible:
		return
	pulse_time += delta
	restart_label.modulate.a = 0.5 + 0.5 * sin(pulse_time * 3.0)


func show_game_over() -> void:
	score_label.text = "SCORE: %d" % GameState.score
	highscore_label.text = "HIGH SCORE: %d" % GameState.high_score
	var accuracy := 0.0
	if GameState.total_bombs_dropped > 0:
		accuracy = float(GameState.total_villains_killed) / float(GameState.total_bombs_dropped) * 100.0
	stats_label.text = "Villains defeated: %d | Accuracy: %d%% | Level: %d" % [
		GameState.total_villains_killed,
		int(accuracy),
		GameState.current_level,
	]
	visible = true
	pulse_time = 0.0


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"drop_bomb"):
		visible = false
		Events.game_started.emit()
