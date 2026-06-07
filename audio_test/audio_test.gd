extends Node

@export var frequency: float = 440.0
@export var volume: float = 0.3
@export var wave_type: String = "sine"
@export var duration: float = 0.5

var _player: AudioStreamPlayer
var _label: Label

func _ready():
	_label = Label.new()
	_label.text = "状态: 就绪，按 [空格] 播放音效"
	_label.position = Vector2(10, 10)
	add_child(_label)

	_player = AudioStreamPlayer.new()
	add_child(_player)
	print("audio_test _ready() 完成")

func _process(_delta):
	if Input.is_key_pressed(KEY_SPACE):
		if not _player.playing:
			print("→ 空格按下，生成 WAV")
			_player.stream = _generate_wav()
			_player.play()
			_label.text = "播放中 (%s, %.0fHz)" % [wave_type, frequency]
	else:
		if _player.playing:
			_player.stop()
			_label.text = "就绪，按 [空格] 播放"
			print("← 空格松开")

func _generate_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 44100
	wav.stereo = false

	var count = int(44100 * duration)
	var data := PackedByteArray()
	data.resize(count * 2)

	var phase := 0.0
	var inc = frequency * TAU / 44100.0

	for i in count:
		var s := 0.0
		match wave_type:
			"sine":    s = sin(phase)
			"square":  s = 1.0 if sin(phase) >= 0 else -1.0
			"saw":     s = 2.0 * (phase / TAU - floor(phase / TAU + 0.5))
			"noise":   s = randf_range(-1.0, 1.0)
		var val = int(s * volume * 32767)
		val = clampi(val, -32768, 32767)
		var idx = i * 2
		data[idx] = val & 0xFF
		data[idx + 1] = (val >> 8) & 0xFF
		phase = fmod(phase + inc, TAU)

	wav.data = data
	return wav
