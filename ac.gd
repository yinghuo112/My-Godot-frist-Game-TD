
extends "res://防御塔/tower_base.gd"  # 如果你用了 class_name，这里也可以直接写 extends TowerBase

# 下面写仅属于射手（AC）的独特逻辑
# _init 是构造函数，专门用来初始化属于该类自己的独特数据
func _init() -> void:
	# 直接对父类的变量重新赋值，不需要再加 var 或 @export
	range_radius = 180.0  # 射手天生手长，默认改成 180
