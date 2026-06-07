@tool
extends EditorScript

const GRASS_SOURCE := 0
const EXPAND := 4

func _run():
	var tilemap = _find_tilemap()
	if not tilemap:
		return
	var bounds = _get_bounds(tilemap)
	var added := 0
	for x in range(bounds.position.x - EXPAND, bounds.end.x + EXPAND):
		for y in range(bounds.position.y - EXPAND, bounds.end.y + EXPAND):
			var cell = Vector2i(x, y)
			if tilemap.get_cell_source_id(cell) == -1:
				tilemap.set_cell(cell, GRASS_SOURCE, Vector2i(0, 0))
				added += 1
	print("Added %d grass tiles, expanded by %d tiles on each side." % [added, EXPAND])

func _find_tilemap():
	var root = get_scene()
	if not root:
		printerr("No scene open")
		return null
	var tilemap = root.get_node_or_null("TileMapLayer")
	if not tilemap:
		printerr("TileMapLayer not found")
	return tilemap

func _get_bounds(tilemap):
	var used = tilemap.get_used_cells()
	if used.is_empty():
		return Rect2i(0, 0, 0, 0)
	var min_c = used[0]
	var max_c = used[0]
	for c in used:
		min_c = Vector2i(min(min_c.x, c.x), min(min_c.y, c.y))
		max_c = Vector2i(max(max_c.x, c.x), max(max_c.y, c.y))
	return Rect2i(min_c, max_c - min_c + Vector2i(1, 1))
