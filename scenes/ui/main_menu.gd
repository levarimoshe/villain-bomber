extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/SubtitleLabel
@onready var highscore_label: Label = $VBoxContainer/HighScoreLabel

var pulse_time: float = 0.0


func _ready() -> void:
	_update_highscore()


func _process(delta: float) -> void:
	if not visible:
		return
	pulse_time += delta
	var alpha := 0.5 + 0.5 * sin(pulse_time * 3.0)
	subtitle_label.modulate.a = alpha


func _update_highscore() -> void:
	if GameState.high_score > 0:
		highscore_label.text = "HIGH SCORE: %d" % GameState.high_score
		highscore_label.visible = true
	else:
		highscore_label.visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"drop_bomb"):
		Events.game_started.emit()
