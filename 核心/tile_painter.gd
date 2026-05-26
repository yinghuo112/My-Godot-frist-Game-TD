extends TileMapLayer

func _ready():
    var diag = get_node_or_null("../UI/HUD/DiagLabel")
    if diag == null:
        print("DiagLabel not found!")
    else:
        diag.text = "Script OK"

    var ts = tile_set
    if ts == null:
        if diag != null: diag.text = "ERR: no tile_set"
        return
    if diag != null: diag.text = "TS:" + str(ts.get_source_count())

    var path_cells = [
        Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
        Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0),
        Vector2i(7, 0), Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0),
        Vector2i(11, 0), Vector2i(12, 0), Vector2i(13, 0), Vector2i(14, 0),
        Vector2i(15, 0), Vector2i(16, 0), Vector2i(17, 0),
        Vector2i(17, 1), Vector2i(17, 2),
        Vector2i(16, 2), Vector2i(15, 2), Vector2i(14, 2), Vector2i(13, 2),
        Vector2i(12, 2), Vector2i(11, 2), Vector2i(10, 2), Vector2i(9, 2),
        Vector2i(8, 2), Vector2i(7, 2), Vector2i(6, 2), Vector2i(5, 2),
        Vector2i(4, 2), Vector2i(3, 2), Vector2i(2, 2), Vector2i(1, 2),
        Vector2i(0, 2),
        Vector2i(0, 3), Vector2i(0, 4), Vector2i(0, 5),
        Vector2i(-1, 5), Vector2i(-1, 6),
        Vector2i(0, 6), Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6),
        Vector2i(4, 6), Vector2i(5, 6), Vector2i(6, 6), Vector2i(7, 6),
        Vector2i(8, 6), Vector2i(9, 6), Vector2i(10, 6), Vector2i(11, 6),
        Vector2i(12, 6), Vector2i(13, 6), Vector2i(14, 6), Vector2i(15, 6),
        Vector2i(16, 6), Vector2i(17, 6),
        Vector2i(17, 7),
    ]

    for x in range(-2, 18):
        for y in range(-1, 9):
            set_cell(Vector2i(x, y), 0, Vector2i.ZERO)

    for cell in path_cells:
        set_cell(cell, 1, Vector2i.ZERO)
    if diag != null: diag.text = "Tiles:" + str(path_cells.size())
