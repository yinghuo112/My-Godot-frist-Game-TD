extends Node

# --- 音量配置 ---
var music_volume: float = 0.5
var sfx_volume: float = 0.7

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_map: Dictionary = {}

var _config_path: String = "user://audio_settings.cfg"

func _ready():
	_generate_sounds()
	_setup_players()
	_load_settings()

# ===== 音效生成 =====

func _generate_sounds():
	_sfx_map["shoot"] = _make_tone(800, 0.08, 0.4)
	_sfx_map["die"] = _make_tone(200, 0.12, 0.3, true)
	_sfx_map["wave"] = _make_sweep(300, 700, 0.4, 0.3)
	_sfx_map["gameover"] = _make_sweep(500, 100, 0.6, 0.4)
	_sfx_map["lightning"] = _make_lightning()
	_sfx_map["fireball"] = _make_noise_tone(100, 0.25, 0.5)
	_sfx_map["freeze"] = _make_noise_tone(4000, 0.2, 0.3)
	_sfx_map["upgrade"] = _make_sweep(400, 1200, 0.3, 0.4)
	_sfx_map["coin"] = _make_tone(1800, 0.08, 0.3)
	_sfx_map["ui_click"] = _make_tone(1000, 0.03, 0.2)
	_sfx_map["place"] = _make_tone(120, 0.1, 0.5)
	_sfx_map["sell"] = _make_sweep(600, 200, 0.15, 0.35)

func _make_tone(freq: float, duration: float, amp: float, descend: bool = false) -> AudioStreamWAV:
	var rate = 22050
	var n = int(rate * duration)
	var data = PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t = float(i) / rate
		var f = freq * (1.0 - t / duration * 0.5) if descend else freq
		var s = sin(2.0 * PI * f * t) * amp
		var env = 1.0 - float(i) / n
		data.encode_s16(i * 2, int(s * env * 30000))
	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav

func _make_sweep(freq_from: float, freq_to: float, duration: float, amp: float) -> AudioStreamWAV:
	var rate = 22050
	var n = int(rate * duration)
	var data = PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t = float(i) / rate
		var f = freq_from + (freq_to - freq_from) * (t / duration)
		var s = sin(2.0 * PI * f * t) * amp
		var env = 1.0 - float(i) / n
		data.encode_s16(i * 2, int(s * env * 30000))
	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav

func _make_lightning() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.15
	var n = int(rate * duration)
	var data = PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t = float(i) / rate
		var env = 1.0 - t / duration
		var noise = randf_range(-1.0, 1.0)
		var tone = sin(2.0 * PI * 3000.0 * t)
		var s = (noise * 0.7 + tone * 0.3) * env * 0.5
		data.encode_s16(i * 2, int(s * 30000))
	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav

func _make_noise_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var rate = 22050
	var n = int(rate * duration)
	var data = PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t = float(i) / rate
		var env = 1.0 - t / duration
		var noise = randf_range(-1.0, 1.0)
		var tone = sin(2.0 * PI * freq * t)
		var s = (noise * 0.5 + tone * 0.5) * env * amp
		data.encode_s16(i * 2, int(s * 30000))
	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav

# ===== 播放器设置 =====

func _setup_players():
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.stream = load("res://音乐/BJ_TD.mp3")
	_music_player.volume_db = linear_to_db(music_volume)
	add_child(_music_player)

	for i in range(8):
		var p = AudioStreamPlayer.new()
		p.name = "SfxPlayer" + str(i)
		add_child(p)
		_sfx_players.append(p)

func _get_idle_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]

# ===== 通用播放接口 =====

func play(name: String, pitch_override: float = -1.0):
	if not _sfx_map.has(name):
		return
	var stream = _sfx_map[name] as AudioStreamWAV
	if not stream:
		return
	var p = _get_idle_sfx_player()
	if not p:
		return
	p.stream = stream
	p.volume_db = linear_to_db(sfx_volume)
	if pitch_override > 0:
		p.pitch_scale = pitch_override
	else:
		p.pitch_scale = 1.0 + randf_range(-0.1, 0.1)
	p.play()

# ===== 兼容旧接口 =====

func play_music():
	if _music_player and not _music_player.playing:
		_music_player.play()

func stop_music():
	if _music_player:
		_music_player.stop()

func play_shoot():
	play("shoot")

func play_die():
	play("die")

func play_wave():
	play("wave")

func play_gameover():
	play("gameover")

func play_lightning():
	play("lightning")

# ===== 暂停/恢复 =====

func pause_all():
	if _music_player and _music_player.playing:
		_music_player.stream_paused = true
	for p in _sfx_players:
		if p.playing:
			p.stream_paused = true

func resume_all():
	if _music_player:
		_music_player.stream_paused = false
	for p in _sfx_players:
		p.stream_paused = false

# ===== 音量管理 =====

func set_music_volume(v: float):
	music_volume = clampf(v, 0.0, 1.0)
	if _music_player:
		_music_player.volume_db = linear_to_db(music_volume)
	_save_settings()

func set_sfx_volume(v: float):
	sfx_volume = clampf(v, 0.0, 1.0)
	_save_settings()

func linear_to_db(v: float) -> float:
	if v <= 0.01:
		return -80.0
	return 20.0 * log(v) / log(10.0)

func set_music_volume_db(v: float):
	set_music_volume(db_to_linear(v))

func set_sfx_volume_db(v: float):
	set_sfx_volume(db_to_linear(v))

func _save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.save(_config_path)

func _load_settings():
	var cfg = ConfigFile.new()
	if cfg.load(_config_path) == OK:
		music_volume = cfg.get_value("audio", "music_volume", 0.5)
		sfx_volume = cfg.get_value("audio", "sfx_volume", 0.7)
