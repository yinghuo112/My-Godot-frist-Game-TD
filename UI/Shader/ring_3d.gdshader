shader_type canvas_item;

// =============================================================================
// 3D 立体环 Shader — 在矩形纹理中绘制带立体感的圆环
// 用法：挂到 TextureRect 的 material 上，TextureRect 必须为正方形
// UV 原点在纹理中心，内/外半径均为占边长的比例
// =============================================================================

// --- 环形态 ---
uniform float inner_radius : hint_range(0.0, 1.0) = 0.2;       // 内圈半径（占边长比例）
uniform float outer_radius : hint_range(0.0, 1.0) = 0.5;       // 外圈半径（占边长比例）

// --- 颜色 ---
uniform vec4 base_color : source_color = vec4(0.2, 0.6, 0.0, 1.0);  // 环的主色

// --- 光照参数 ---
uniform vec3 light_dir = vec3(0.3, -0.2, 0.9);                 // 光照方向（向量，无需归一化，shader 内部会归一化）
uniform float shininess : hint_range(0.0, 1.0) = 0.5;          // 高光强度（0=无高光, 1=最强）
uniform float spec_power : hint_range(1.0, 128.0) = 16.0;      // 高光锐度（越大高光越集中）
uniform float ambient_strength : hint_range(0.0, 1.0) = 0.3;   // 环境光强度（背光面最低亮度）
uniform float diffuse_strength : hint_range(0.0, 1.0) = 0.7;   // 漫反射强度（光照影响程度）

// --- 径向渐变 ---
uniform float gradient_min : hint_range(0.0, 1.0) = 0.5;       // 内圈亮度（0=黑, 1=原色）
uniform float gradient_max : hint_range(0.0, 1.0) = 1.0;       // 外圈亮度（0=黑, 1=原色）

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);

    if (dist < inner_radius || dist > outer_radius) {
        discard;
    }

    // 径向渐变（内→外）
    float t = (dist - inner_radius) / (outer_radius - inner_radius);
    float brightness = gradient_min + (gradient_max - gradient_min) * t;

    // 法线近似：把 2D 圆盘视为一个半球
    vec3 normal = normalize(vec3(uv.x, uv.y, 0.5));
    vec3 light = normalize(light_dir);

    // 漫反射
    float diff = max(dot(normal, light), 0.0);
    diff = ambient_strength + diffuse_strength * diff;

    // 高光（Blinn-Phong）
    vec3 view_dir = vec3(0.0, 0.0, 1.0);
    vec3 half_vec = normalize(light + view_dir);
    float spec = pow(max(dot(normal, half_vec), 0.0), spec_power) * shininess;

    vec3 final_color = base_color.rgb * brightness * diff + vec3(1.0) * spec;
    COLOR = vec4(final_color, base_color.a * brightness);
}