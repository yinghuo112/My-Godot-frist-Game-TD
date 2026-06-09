extends Node

signal font_changed(font_name: String)

var _fonts: Dictionary = {}
var _current_font: String = ""

func _ready():
	_scan_fonts()

func _scan_fonts():
	_fonts.clear()
	var dir = DirAccess.open("res://UI/Font/")
	if not dir:
		return
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if file.ends_with(".ttf") or file.ends_with(".otf"):
			var path = "res://UI/Font/" + file
			var font: FontFile = load(path)
			if font:
				_fonts[file.get_basename()] = font
		file = dir.get_next()
	dir.list_dir_end()

func get_font_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for font_name in _fonts.keys():
		names.append(font_name)
	names.sort()
	return names

func apply_font(font_name: String):
	if not _fonts.has(font_name):
		return
	_current_font = font_name
	var theme = Theme.new()
	theme.default_font = _fonts[font_name]
	get_tree().root.theme = theme
	font_changed.emit(font_name)

func get_current_font() -> String:
	return _current_font

func get_font(font_name: String) -> FontFile:
	return _fonts.get(font_name)
