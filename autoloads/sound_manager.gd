extends Node

# Procedural sound effects using AudioStreamWAV
var explosion_stream: AudioStreamWAV
var bomb_drop_stream: AudioStreamWAV
var shoot_stream: AudioStreamWAV
var hit_stream: AudioStreamWAV
var levelup_stream: AudioStreamWAV
var combo_stream: AudioStreamWAV


func _ready() -> void:
	explosion_stream = _make_explosion()
	bomb_drop_stream = _make_bomb_drop()
	shoot_stream = _make_shoot()
	hit_stream = _make_hit()
	levelup_stream = _make_levelup()
	combo_stream = _make_combo()


func play_explosion() -> void:
	_play(explosion_stream, -5.0)


func play_bomb_drop() -> void:
	_play(bomb_drop_stream, -8.0)


func play_shoot() -> void:
	_play(shoot_stream, -12.0)


func play_hit() -> void:
	_play(hit_stream, -3.0)


func play_levelup() -> void:
	_play(levelup_stream, -5.0)


func play_combo() -> void:
	_play(combo_stream, -6.0)


func _play(stream: AudioStreamWAV, volume_db: float = 0.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = &"Master"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func _make_explosion() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.6
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = exp(-t * 5.0)
		# Mix of noise + low rumble
		var noise: float = randf_range(-1.0, 1.0)
		var rumble: float = sin(t * 80.0 * TAU) * 0.5
		var sample: float = (noise * 0.7 + rumble * 0.3) * envelope
		var value: int = clampi(int(sample * 32000.0), -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


func _make_bomb_drop() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.4
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = exp(-t * 3.0)
		# Descending whistle
		var freq: float = 800.0 - t * 1500.0
		var sample: float = sin(t * freq * TAU) * envelope * 0.4
		# Add some noise
		sample += randf_range(-0.1, 0.1) * envelope
		var value: int = clampi(int(sample * 32000.0), -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


func _make_shoot() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.15
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = exp(-t * 25.0)
		var sample: float = sin(t * 600.0 * TAU) * envelope * 0.5
		sample += randf_range(-0.3, 0.3) * envelope
		var value: int = clampi(int(sample * 32000.0), -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


func _make_hit() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.3
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = exp(-t * 8.0)
		var sample: float = sin(t * 200.0 * TAU) * envelope * 0.6
		sample += sin(t * 100.0 * TAU) * envelope * 0.3
		sample += randf_range(-0.2, 0.2) * envelope
		var value: int = clampi(int(sample * 32000.0), -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


func _make_levelup() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.5
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = (1.0 - t / duration) * 0.5
		# Ascending arpeggio
		var freq: float = 400.0 + t * 800.0
		var sample: float = sin(t * freq * TAU) * envelope
		sample += sin(t * freq * 1.5 * TAU) * envelope * 0.3
		var value: int = clampi(int(sample * 32000.0), -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


func _make_combo() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.25
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = (1.0 - t / duration) * 0.4
		var freq: float = 600.0 + t * 1200.0
		var sample: float = sin(t * freq * TAU) * envelope
		sample += sin(t * freq * 2.0 * TAU) * envelope * 0.2
		var value: int = clampi(int(sample * 32000.0), -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream5 := AudioStreamWAV.new()
	stream5.format = AudioStreamWAV.FORMAT_16_BITS
	stream5.mix_rate = sample_rate
	stream5.data = data
	return stream5
