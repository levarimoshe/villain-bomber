extends Node

# Procedural sound effects using AudioStreamWAV
var explosion_stream: AudioStreamWAV
var bomb_drop_stream: AudioStreamWAV
var shoot_stream: AudioStreamWAV
var hit_stream: AudioStreamWAV
var levelup_stream: AudioStreamWAV
var combo_stream: AudioStreamWAV
var shield_break_stream: AudioStreamWAV
var nuke_charge_stream: AudioStreamWAV


var music_player: AudioStreamPlayer = null
var music_playing: bool = false


func _ready() -> void:
	explosion_stream = _make_explosion()
	bomb_drop_stream = _make_bomb_drop()
	shoot_stream = _make_shoot()
	hit_stream = _make_hit()
	levelup_stream = _make_levelup()
	combo_stream = _make_combo()
	shield_break_stream = _make_shield_break()
	nuke_charge_stream = _make_nuke_charge()


func start_music() -> void:
	if music_playing:
		return
	music_playing = true
	music_player = AudioStreamPlayer.new()
	music_player.stream = _make_music()
	music_player.volume_db = -12.0
	music_player.bus = &"Master"
	add_child(music_player)
	music_player.play()
	music_player.finished.connect(_on_music_finished)


func stop_music() -> void:
	music_playing = false
	if music_player:
		music_player.stop()
		music_player.queue_free()
		music_player = null


func _on_music_finished() -> void:
	if music_playing and music_player:
		music_player.stream = _make_music()
		music_player.play()


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


func play_shield_break() -> void:
	_play(shield_break_stream, -3.0)


func play_nuke_charge() -> void:
	_play(nuke_charge_stream, -4.0)


func speak(text: String) -> void:
	# Use Godot's built-in Text-to-Speech
	var voices: Array = DisplayServer.tts_get_voices()
	var voice_id: String = ""
	# Try to find an English voice
	for v in voices:
		var lang: String = v.get("language", "")
		if lang.begins_with("en"):
			voice_id = v.get("id", "")
			break
	if voice_id == "" and voices.size() > 0:
		voice_id = voices[0].get("id", "")
	if voice_id != "":
		DisplayServer.tts_speak(text, voice_id, 80, 0.9, 1.2)


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


func _make_shield_break() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.4
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = exp(-t * 6.0)
		# Glass breaking: high freq noise + descending crystal tone
		var crystal: float = sin(t * 2000.0 * TAU * (1.0 - t * 0.5)) * 0.3
		var glass: float = randf_range(-0.5, 0.5) * envelope
		var shimmer: float = sin(t * 4000.0 * TAU) * envelope * 0.15
		var sample: float = (crystal + glass + shimmer) * envelope
		var value: int = clampi(int(sample * 28000.0), -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var s1 := AudioStreamWAV.new()
	s1.format = AudioStreamWAV.FORMAT_16_BITS
	s1.mix_rate = sample_rate
	s1.data = data
	return s1


func _make_nuke_charge() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.8
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = minf(t * 3.0, 1.0) * (1.0 - t / duration) * 0.5
		# Rising dramatic tone — builds up tension
		var freq: float = 150.0 + t * t * 800.0  # Accelerating rise
		var sample: float = sin(t * freq * TAU) * envelope
		sample += sin(t * freq * 2.0 * TAU) * envelope * 0.15
		# Add rumble
		sample += sin(t * 60.0 * TAU) * envelope * 0.3
		var value: int = clampi(int(sample * 30000.0), -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var s2 := AudioStreamWAV.new()
	s2.format = AudioStreamWAV.FORMAT_16_BITS
	s2.mix_rate = sample_rate
	s2.data = data
	return s2


func _make_music() -> AudioStreamWAV:
	var sample_rate := 22050
	var bpm := 120.0
	var beats := 16  # 16 beats = 8 seconds
	var beat_len: float = 60.0 / bpm
	var duration: float = beat_len * float(beats)
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	# Notes for a simple military march melody (frequencies in Hz)
	var melody: Array = [220, 0, 262, 0, 330, 294, 262, 0, 220, 0, 330, 294, 262, 220, 196, 0]
	var bass_notes: Array = [110, 110, 130, 130, 110, 110, 98, 98, 110, 110, 130, 130, 146, 130, 110, 110]

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var beat: int = int(t / beat_len) % beats
		var beat_t: float = fmod(t, beat_len) / beat_len

		var sample: float = 0.0

		# Bass drum on beats 0, 4, 8, 12
		if beat % 4 == 0:
			var kick_t: float = beat_t * beat_len
			if kick_t < 0.15:
				var kick_env: float = exp(-kick_t * 25.0)
				sample += sin(kick_t * 80.0 * TAU) * kick_env * 0.25

		# Snare on beats 2, 6, 10, 14
		if beat % 4 == 2:
			var snare_t: float = beat_t * beat_len
			if snare_t < 0.1:
				sample += randf_range(-0.12, 0.12) * exp(-snare_t * 30.0)

		# Hi-hat on every beat
		var hh_t: float = beat_t * beat_len
		if hh_t < 0.03:
			sample += randf_range(-0.05, 0.05) * exp(-hh_t * 80.0)

		# Melody
		var mel_freq: int = melody[beat]
		if mel_freq > 0:
			var mel_env: float = maxf(0.0, 1.0 - beat_t * 1.5) * 0.15
			sample += sin(t * float(mel_freq) * TAU) * mel_env
			sample += sin(t * float(mel_freq) * 2.0 * TAU) * mel_env * 0.08

		# Bass line
		var bass_freq: int = bass_notes[beat]
		sample += sin(t * float(bass_freq) * TAU) * 0.1

		var value: int = clampi(int(sample * 28000.0), -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var music := AudioStreamWAV.new()
	music.format = AudioStreamWAV.FORMAT_16_BITS
	music.mix_rate = sample_rate
	music.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.loop_end = num_samples
	music.data = data
	return music
