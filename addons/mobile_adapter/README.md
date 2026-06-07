# MobileAdapter 手机适配模块

## 文件结构

```
addons/mobile_adapter/
├── MobileAdapter.gd       # 核心单例（需注册为 AutoLoad）
├── MobileUIAdapter.gd     # UI 自适应工具（静态方法）
└── README.md              # 本文件
```

## 使用步骤

### 1. 注册 AutoLoad

项目设置 → 自动加载 → 添加 `addons/mobile_adapter/MobileAdapter.gd`，节点名 `MobileAdapter`。

### 2. 调用初始化

在游戏主场景的 `_ready()` 中调用：

```gdscript
MobileAdapter.setup()
```

### 3. 适配 UI（可选）

对需要适配的面板调用工具方法：

```gdscript
MobileUIAdapter.anchor_right_panel(info_panel, 300)
MobileUIAdapter.scale_font(level_label, 14)
```

## API 说明

### MobileAdapter

| 方法/属性 | 说明 |
|-----------|------|
| `is_mobile()` | 当前是否为手机平台 |
| `is_android()` | 当前是否为 Android |
| `is_ios()` | 当前是否为 iOS |
| `setup()` | 自动完成相机适配 + 调试按钮 + 性能优化 |
| `adapt_camera()` | 屏幕旋转后重新适配相机缩放 |
| `make_touch_friendly(button)` | 将按钮设为触控安全尺寸 |
| `get_touch_pos()` | 获取触摸位置（PC 返回鼠标位置） |
| `touch_friendly_min_size` | 配置触控安全区尺寸（默认 48×48） |
| `zoom_min / zoom_max` | 相机缩放范围（默认 0.5~1.5） |
| `design_width / design_height` | 设计基准分辨率（默认 1280×720） |

### MobileUIAdapter

| 方法 | 说明 |
|------|------|
| `resize_panel(panel, max_w, fraction)` | 按屏幕比例调整面板宽度 |
| `anchor_fullscreen(node)` | 将 Control 设为全屏锚点 |
| `anchor_right_panel(node, w)` | 将面板锚定到右侧 |
| `scale_font(label, base_size)` | 根据屏幕宽度比例缩放字体 |

## 平台兼容

| 平台 | is_mobile | 触摸拖拽 | 捏合缩放 | 调试按钮 | 粒子优化 |
|------|-----------|---------|---------|---------|---------|
| Windows | false | 关闭 | 关闭 | 不创建 | 不应用 |
| Android | true | 开启 | 开启 | 创建 | 应用 |
| iOS | true | 开启 | 开启 | 创建 | 应用 |

## 在新项目中复用

1. 复制 `addons/mobile_adapter/` 整个目录到新项目
2. 注册 `MobileAdapter.gd` 为 AutoLoad
3. 主场景调 `MobileAdapter.setup()`
4. （可选）对 UI 面板调用 `MobileUIAdapter` 的方法
