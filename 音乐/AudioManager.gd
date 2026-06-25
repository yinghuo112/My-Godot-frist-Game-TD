extends Node
## 全局单例音频管理器，管控全游戏所有的音频逻辑

# 常量定义，统一管理总线名称，避免硬编码问题
const BGM_BUS_NAME = "BGM"
const SFX_BUS_NAME = "SFX"

# 预加载获取总线唯一索引
@onready var bgm_bus_index = AudioServer.get_bus_index(BGM_BUS_NAME)
@onready var sfx_bus_index = AudioServer.get_bus_index(SFX_BUS_NAME)

# 背景音乐常驻播放器（bgm持续播放，无需频繁创建销毁）
var bgm_player: AudioStreamPlayer
