class_name IntroAudio
extends Node
## Small original procedural soundtrack. Nothing plays until set_mode is called.

const SAMPLE_RATE: int = 22050
const RADIO_BEAT: float = 0.42
const VALID_MODES: Array[String] = ["radio", "quiet", "dread", "sting"]

var _player: AudioStreamPlayer
var _streams: Dictionary = {}
var _mode: String = "quiet"
var _volume: float = 0.35


func _ready() -> void:
	_ensure_player()


func set_volume(value: float) -> void:
	_volume = clampf(value, 0.0, 1.0)
	if is_instance_valid(_player):
		_player.volume_db = linear_to_db(maxf(_volume, 0.0001))
		_player.stream_paused = is_zero_approx(_volume)


func set_mode(mode: String) -> void:
	if not VALID_MODES.has(mode):
		push_warning("IntroAudio: unknown mode '%s'." % mode)
		return
	_ensure_player()
	if mode == _mode and mode != "sting" and _player.playing:
		return
	_mode = mode
	_player.stop()
	if mode == "quiet":
		_player.stream = null
		return
	if not _streams.has(mode):
		_streams[mode] = _make_stream(mode)
	_player.stream = _streams[mode]
	_player.play()
	_player.stream_paused = is_zero_approx(_volume)


func _ensure_player() -> void:
	if is_instance_valid(_player):
		return
	_player = AudioStreamPlayer.new()
	_player.name = "IntroSoundtrack"
	_player.volume_db = linear_to_db(maxf(_volume, 0.0001))
	add_child(_player)


func _make_stream(mode: String) -> AudioStreamWAV:
	var seconds: float = 1.6
	if mode == "radio":
		seconds = RADIO_BEAT * 16.0
	elif mode == "dread":
		seconds = 8.0
	var frame_count: int = int(round(seconds * SAMPLE_RATE))
	var samples: PackedByteArray = PackedByteArray()
	samples.resize(frame_count * 2)
	for frame in range(frame_count):
		var time: float = float(frame) / SAMPLE_RATE
		var sample: float = 0.0
		match mode:
			"radio":
				sample = _radio_sample(time, seconds)
			"dread":
				sample = _dread_sample(time)
			"sting":
				sample = _sting_sample(time, seconds)
		samples.encode_s16(frame * 2, int(clampf(sample, -0.85, 0.85) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	if mode != "sting":
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = frame_count
	return stream


func _radio_sample(time: float, duration: float) -> float:
	# Sixteen newly composed notes, with pauses and soft bell-like attacks.
	const NOTES: Array[int] = [62, 66, 69, 73, 71, 66, 64, -1, 67, 71, 74, 69, 73, 71, 64, -1]
	const CHORDS: Array = [[50, 54, 57], [47, 50, 54], [43, 47, 50], [45, 49, 52]]
	var beat: int = mini(int(time / RADIO_BEAT), 15)
	var local: float = fmod(time, RADIO_BEAT)
	var bar_local: float = fmod(time, RADIO_BEAT * 4.0)
	var envelope: float = minf(local / 0.018, 1.0) * minf((RADIO_BEAT - local) / 0.08, 1.0)
	envelope *= exp(-3.4 * local)
	var sample: float = 0.0
	if NOTES[beat] >= 0:
		var frequency: float = _midi_frequency(NOTES[beat])
		sample += envelope * (0.11 * sin(TAU * frequency * local) + 0.018 * sin(TAU * frequency * 2.0 * local))
	var chord_envelope: float = minf(bar_local / 0.06, 1.0) * minf((RADIO_BEAT * 4.0 - bar_local) / 0.18, 1.0)
	chord_envelope *= exp(-0.65 * bar_local)
	for note in CHORDS[beat / 4]:
		sample += 0.022 * chord_envelope * sin(TAU * _midi_frequency(note) * bar_local)
	# Gentle fade at the loop boundary prevents clicks.
	return sample * minf(time / 0.04, 1.0) * minf((duration - time) / 0.06, 1.0)


func _dread_sample(time: float) -> float:
	# All frequencies complete whole cycles in eight seconds: a seamless loop.
	var breathing: float = 0.7 + 0.3 * sin(TAU * 0.125 * time)
	return breathing * (0.085 * sin(TAU * 55.0 * time) + 0.042 * sin(TAU * 82.5 * time) + 0.016 * sin(TAU * 110.25 * time))


func _sting_sample(time: float, duration: float) -> float:
	# A restrained descending dissonance, never louder than the melody peak.
	var envelope: float = minf(time / 0.035, 1.0) * exp(-3.1 * time)
	envelope *= minf((duration - time) / 0.15, 1.0)
	var phase: float = TAU * (230.0 * time - 33.0 * time * time)
	return envelope * (0.11 * sin(phase) + 0.07 * sin(phase * 1.047) + 0.025 * sin(TAU * 61.0 * time))


func _midi_frequency(note: int) -> float:
	return 440.0 * pow(2.0, float(note - 69) / 12.0)
