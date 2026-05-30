extends Node

# --- 音量配置 ---
var music_volume: float = 0.5
var sfx_volume: float = 0.7

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []

# --- 生成的音频缓存 ---
var _sfx_shoot: AudioStreamWAV
var _sfx_die: AudioStreamWAV
var _sfx_wave: AudioStreamWAV
var _sfx_gameover: AudioStreamWAV

var _config_path: String = "user://audio_settings.cfg"

# 初始化音效管理器：生成音效、创建播放器、加载音量设置
func _ready():
	_generate_sounds()
	_setup_players()
	_load_settings()

# 生成所有音效缓存的采样数据
func _generate_sounds():
	_sfx_shoot = _make_tone(800, 0.08, 0.4)
	_sfx_die = _make_tone(200, 0.12, 0.3, true)
	_sfx_wave = _make_sweep(300, 700, 0.4, 0.3)
	_sfx_gameover = _make_sweep(500, 100, 0.6, 0.4)

# 生成单音采样（可选降调）
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

# 生成频率扫描采样
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

# 创建音乐和音效播放器
func _setup_players():
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.stream = load("res://音乐/BJ_TD.mp3")
	_music_player.volume_db = linear_to_db(music_volume)
	add_child(_music_player)

	for i in range(4):
		var p = AudioStreamPlayer.new()
		p.name = "SfxPlayer" + str(i)
		add_child(p)
		_sfx_players.append(p)

# 获取空闲的音效播放器
func _get_idle_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]

# 播放背景音乐
func play_music():
	if _music_player and not _music_player.playing:
		_music_player.play()

# 停止背景音乐
func stop_music():
	if _music_player:
		_music_player.stop()

# 播放射击音效
func play_shoot():
	_play_sfx(_sfx_shoot, sfx_volume)

# 播放死亡音效
func play_die():
	_play_sfx(_sfx_die, sfx_volume)

# 播放波次开始音效
func play_wave():
	_play_sfx(_sfx_wave, sfx_volume)

# 播放游戏结束音效
func play_gameover():
	_play_sfx(_sfx_gameover, sfx_volume)

# 播放指定音效流
func _play_sfx(stream: AudioStreamWAV, vol: float):
	var p = _get_idle_sfx_player()
	if p:
		p.stream = stream
		p.volume_db = linear_to_db(vol)
		p.play()

# 设置音乐音量并持久化
func set_music_volume(v: float):
	music_volume = clampf(v, 0.0, 1.0)
	if _music_player:
		_music_player.volume_db = linear_to_db(music_volume)
	_save_settings()

# 设置音效音量并持久化
func set_sfx_volume(v: float):
	sfx_volume = clampf(v, 0.0, 1.0)
	_save_settings()

# 将线性音量转换为 dB
func linear_to_db(v: float) -> float:
	if v <= 0.01:
		return -80.0
	return 20.0 * log(v) / log(10.0)

# 保存音量设置到文件
func _save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.save(_config_path)

# 从文件加载音量设置
func _load_settings():
	var cfg = ConfigFile.new()
	if cfg.load(_config_path) == OK:
		music_volume = cfg.get_value("audio", "music_volume", 0.5)
		sfx_volume = cfg.get_value("audio", "sfx_volume", 0.7)

# 通过 dB 值设置音乐音量
func set_music_volume_db(v: float):
	set_music_volume(db_to_linear(v))

# 通过 dB 值设置音效音量
func set_sfx_volume_db(v: float):
	set_sfx_volume(db_to_linear(v))
