extends Node
class_name Generator2D

const DIRECTIONS = [
	Vector2.UP,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.RIGHT
]

const MIN_ROOM_SIZE = 2
const MIN_SPLIT_SIZE = MIN_ROOM_SIZE * 2 + 1
var object_big_cells
var object_small_cells
var MAP_HEIGHT
var MAP_WIDTH
var TILES
var _tilemap

func _init(tilemap:TileMap):
	self._tilemap = tilemap
	self.MAP_WIDTH = tilemap.get_used_rect().size.x
	self.MAP_HEIGHT = tilemap.get_used_rect().size.y
	self.TILES = {
		EMPTY = _tilemap.tile_set.find_tile_by_name("TILE_EMPTY"),
		FLOOR = _tilemap.tile_set.find_tile_by_name("TILE_FLOOR"),
		WALL = _tilemap.tile_set.find_tile_by_name("TILE_WALL"),
		DOOR = _tilemap.tile_set.find_tile_by_name("TILE_DOOR"),
		OBJECT = _tilemap.tile_set.find_tile_by_name("TILE_OBJECT"),
		ENTRANCE = _tilemap.tile_set.find_tile_by_name("TILE_ENTRANCE"),
		EXIT = _tilemap.tile_set.find_tile_by_name("TILE_EXIT"),
	}
	generator_generate_level()

func generator_generate_level() -> void:
	randomize()
	generator_clear_level()
	generator_room_subdivide(1, 1, MAP_WIDTH - 2, MAP_HEIGHT - 2)
	generator_clear_dead_ends(_tilemap, [TILES.DOOR, TILES.WALL], TILES.FLOOR, TILES.FLOOR)
	generator_fill_one_way_rooms(_tilemap, TILES.FLOOR, TILES.WALL)
	generator_remove_room_walls(_tilemap, [TILES.WALL, TILES.DOOR])
	object_big_cells = furnisher_place_object(_tilemap, Vector2(2, 2), 3)
	object_small_cells = furnisher_place_object(_tilemap, Vector2(1, 1), 5)
	generator_add_passages(_tilemap)

func generator_room_subdivide(x1, y1, x2, y2):
	randomize()
	var w = x2 - x1 + 1
	var h = y2 - y1 + 1
	
	if randf() < 0.5:
		if w >= MIN_SPLIT_SIZE:
			generator_room_subdivide_width(x1, y1, x2, y2)
		elif h >= MIN_SPLIT_SIZE:
			generator_room_subdivide_height(x1, y1, x2, y2)
	else:
		if h >= MIN_SPLIT_SIZE:
			generator_room_subdivide_height(x1, y1, x2, y2)
		elif w >= MIN_SPLIT_SIZE:
			generator_room_subdivide_width(x1, y1, x2, y2)

func generator_room_subdivide_width(x1, y1, x2, y2):
	randomize()
	var x = rand_range(x1 + MIN_ROOM_SIZE, x2 - MIN_ROOM_SIZE)

	for y in range(y1, y2 + 1):
		_tilemap.set_cell(x, y, TILES.WALL)

	generator_room_subdivide(x1, y1, x - 1, y2)
	generator_room_subdivide(x + 1, y1, x2, y2)

	var doory = rand_range(y1 + 1, y2 - 1)
	_tilemap.set_cell(x, doory, TILES.DOOR)

	# Account for walls placed deeper into recursion.
	_tilemap.set_cell(x-1, doory, TILES.FLOOR)
	_tilemap.set_cell(x+1, doory, TILES.FLOOR)

func generator_room_subdivide_height(x1, y1, x2, y2):
	randomize()
	var y = rand_range(y1 + MIN_ROOM_SIZE, y2 - MIN_ROOM_SIZE)

	for x in range(x1, x2 + 1):
		_tilemap.set_cell(x, y, TILES.WALL)

	generator_room_subdivide(x1, y1, x2, y - 1)
	generator_room_subdivide(x1, y + 1, x2, y2)

	var doorx = rand_range(x1 + 1, x2 - 1)
	_tilemap.set_cell(doorx, y, TILES.DOOR)
	
	# Account for walls placed deeper into recursion.
	_tilemap.set_cell(doorx, y-1, TILES.FLOOR)
	_tilemap.set_cell(doorx, y+1, TILES.FLOOR)

func generator_clear_dead_ends(tilemap:TileMap, ids:Array, check_tile:int, set_tile:int):
	var completed = false

	while !completed:
		completed = true
		var cells = tilemap_get_cells_in_array(tilemap, ids)

		for cell in cells:
			var count = util_count_nearby_tiles_4(cell, [check_tile])
			if count >= 3:
				tilemap.set_cellv(cell, set_tile)
				completed = false

	pass

func generator_remove_room_walls(tilemap:TileMap, tiles:Array) -> void:
	randomize()
	var walls:Array = generator_get_room_walls(tilemap, tiles)
	walls.shuffle()
	
	var cells = []
	for i in (randi() % 3 + 1):
		if walls.size() != 0:
			var wall = walls.pick_random()
			cells.append_array(wall)
			walls.erase(wall)
	
	for cell in cells:
		tilemap.set_cellv(cell, TILES.FLOOR)
	
	generator_clear_dead_ends(_tilemap, [TILES.DOOR, TILES.WALL], TILES.FLOOR, TILES.FLOOR)
	pass

func generator_get_room_walls(tilemap: TileMap, tiles:Array) -> Array:
	var walls = []
	var visited = []
	
	for x in range(0, MAP_WIDTH):
		for y in range(0, MAP_HEIGHT):
			
			var cell = Vector2(x, y)
			if tilemap.get_cellv(cell) in tiles and !visited.has(cell) and util_count_nearby_tiles_4(cell, [TILES.FLOOR]) >= 2:
				var wall = generator_wall_flood_fill(tilemap, tiles, cell, visited)
				if wall.size() > 0:
					walls.append(wall)
	return walls

func generator_wall_flood_fill(tilemap:TileMap, tiles:Array, start_cell:Vector2, visited:Array):
	var wall = []
	var stack = [start_cell]
	
	while stack:
		var cell = stack.pop_back()
		
		if !visited.has(cell) and tilemap.get_cellv(cell) in tiles:
			visited.append(cell)
			if util_count_nearby_tiles_4(cell, [TILES.FLOOR]) >= 2:
				wall.append(cell)
			
			for direction in DIRECTIONS:
				var neighbor = cell + direction
				if !visited.has(neighbor) and tilemap.get_cellv(neighbor) in tiles:
					if util_count_nearby_tiles_4(neighbor, [TILES.FLOOR]) >= 2:
						stack.append(neighbor)
	return wall

func generator_room_apply_padding(room:Array) -> Array:
	var result = []
	for cell in room:
		var count = 0
		count += util_count_nearby_tiles_4(cell, [TILES.WALL, TILES.DOOR])
		if count == 0:
			result.append(cell)
			
	return result

func generator_get_rooms(tilemap: TileMap, tile:int):
	var rooms = []
	var visited = []
	
	for x in range(0, MAP_WIDTH):
		for y in range(0, MAP_HEIGHT):
			
			var cell = Vector2(x, y)
			if tilemap.get_cellv(cell) == tile and !visited.has(cell):
				var room = generator_room_flood_fill(tilemap, tile, cell, visited)
				if room.size() > 0:
					rooms.append(room)
	return rooms

func generator_add_passages(tilemap:TileMap) -> void:
	randomize()
	var exit:Vector2
	var entrance:Vector2
	var cells = tilemap.get_used_cells_by_id(TILES.FLOOR)
	
	cells.shuffle()
	entrance = cells.pick_random()
	generator_add_entrance(tilemap, entrance)
	
	for cell in cells:
		exit = cell
		if cell.distance_to(entrance) >= 8:
			break
			
	generator_add_exit(tilemap, exit)
	pass

func generator_add_entrance(tilemap:TileMap, cell:Vector2) -> void:
	tilemap.set_cellv(cell, TILES.ENTRANCE)
	pass

func generator_add_exit(tilemap:TileMap, cell:Vector2)  -> void:
	tilemap.set_cellv(cell, TILES.EXIT)
	pass

func generator_get_entrance() -> Vector2:
	return _tilemap.get_used_cells_by_id(TILES.ENTRANCE)[0]

func generator_get_exit() -> Vector2:
	return _tilemap.get_used_cells_by_id(TILES.EXIT)[0]

func generator_get_walls_base() -> Array:
	var cells = _tilemap.get_used_cells_by_id(TILES.WALL)
	var result = []
	for cell in cells:
		result.append_array(util_get_tile_in_directon(cell, [TILES.FLOOR], Vector2.DOWN))
	return result

func generator_room_flood_fill(tilemap:TileMap, tile:int, start_cell:Vector2, visited:Array):
	var room = []
	var stack = [start_cell]
	
	while stack:
		var cell = stack.pop_back()
		
		if !visited.has(cell) and tilemap.get_cellv(cell) == tile:
			visited.append(cell)
			room.append(cell)
			
			for direction in DIRECTIONS:
				var neighbor = cell + direction
				if !visited.has(neighbor) and tilemap.get_cellv(neighbor) == tile:
					stack.append(neighbor)
	return room

func generator_fill_one_way_rooms(tilemap:TileMap, tile_check:int, tile_fill:int) -> void:
	var rooms = generator_get_rooms(tilemap, tile_check)
	rooms = generator_get_one_way_rooms(rooms.duplicate())
	
	for room in rooms:
		for cell in room:
			tilemap.set_cellv(cell, tile_fill)
	pass

func generator_get_one_way_rooms(rooms:Array) -> Array:
	var output:Array = []
	var door_list:Array = []
	
	for room in rooms:
		door_list = []
		
		for cell in room:
			door_list.append_array(util_get_nearby_tiles_4(cell, [TILES.DOOR]))
		
		if door_list.size() == 1:
			var duplicate = room.duplicate(true)
			duplicate.append_array(door_list)
			output.append(duplicate)
			
	return output

func generator_clear_level() -> void:
	var rect = _tilemap.get_used_rect()
	var rect_start = Vector2(rect.position.x + 1, rect.position.y + 1)
	var rect_end = Vector2(rect.end.x - 2, rect.end.y - 2)
	
	for width in range(int(rect_start.x), int(rect_end.x) + 1):
		for height in range(int(rect_start.y), int(rect_end.y) + 1):
			_tilemap.set_cell(width, height, TILES.FLOOR)
	pass

func furnisher_place_object(tilemap:TileMap, size:Vector2, max_count:int) -> Array:
	randomize()
	var result = []
	
	for i in (randi() % max_count):
		var cells = furnisher_get_free_space(tilemap, size)
		if cells.size() != 0:
			cells.shuffle()
			var cell = cells.pick_random()
			cells.erase(cell)
			result.append(cell)

			for x in range(size.x):
				for y in range(size.y):
					tilemap.set_cell(cell.x + x, cell.y + y, TILES.OBJECT)

	return result

func furnisher_get_free_space(tilemap:TileMap, size:Vector2) -> Array:
	var result = []
	var cells = furnisher_get_cells(tilemap)
	for cell in cells:
		if furnisher_space_is_free(cells, cell, size):
			result.append(cell)
	return result

func furnisher_space_is_free(cells:Array, cell:Vector2, size:Vector2) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			var check_cell = cell + Vector2(x, y)
			if !cells.has(check_cell):
				return false
	return true

func furnisher_get_cells(tilemap:TileMap) -> Array:
	var result_cells = []
	var check_cells = tilemap.get_used_cells_by_id(TILES.FLOOR)
	for cell in check_cells:
		var count = util_count_nearby_tiles_8(cell, [
			TILES.WALL, 
			TILES.DOOR, 
			TILES.OBJECT
		])
		if count == 0:
			result_cells.append(cell)
			
	return result_cells

func tilemap_get_cells_in_array(tilemap:TileMap, ids:Array) -> Array:
	var cells = []
	for id in ids:
		cells.append_array(tilemap.get_used_cells_by_id(id))
	return cells

func util_count_nearby_tiles_4(cell:Vector2, tiles:Array) -> int:
	var count:int = 0
	if _tilemap.get_cell(cell.x, cell.y-1) in tiles:  count += 1
	if _tilemap.get_cell(cell.x, cell.y+1) in tiles:  count += 1
	if _tilemap.get_cell(cell.x-1, cell.y) in tiles:  count += 1
	if _tilemap.get_cell(cell.x+1, cell.y) in tiles:  count += 1
	return count

func util_get_nearby_tiles_4(cell:Vector2, tiles:Array) -> Array:
	var list:Array = []
	if _tilemap.get_cell(cell.x, cell.y-1) in tiles:  list.append(Vector2(cell.x, cell.y-1))
	if _tilemap.get_cell(cell.x, cell.y+1) in tiles:  list.append(Vector2(cell.x, cell.y+1))
	if _tilemap.get_cell(cell.x-1, cell.y) in tiles:  list.append(Vector2(cell.x-1, cell.y))
	if _tilemap.get_cell(cell.x+1, cell.y) in tiles:  list.append(Vector2(cell.x+1, cell.y))
	return list

func util_count_nearby_tiles_8(cell:Vector2, tiles:Array) -> int:
	var count:int = 0
	if _tilemap.get_cell(cell.x, cell.y-1)   in tiles:  count += 1
	if _tilemap.get_cell(cell.x, cell.y+1)   in tiles:  count += 1
	if _tilemap.get_cell(cell.x-1, cell.y)   in tiles:  count += 1
	if _tilemap.get_cell(cell.x+1, cell.y)   in tiles:  count += 1
	if _tilemap.get_cell(cell.x+1, cell.y+1) in tiles:  count += 1
	if _tilemap.get_cell(cell.x+1, cell.y-1) in tiles:  count += 1
	if _tilemap.get_cell(cell.x-1, cell.y+1) in tiles:  count += 1
	if _tilemap.get_cell(cell.x-1, cell.y-1) in tiles:  count += 1
	return count

func util_get_nearby_tiles_8(cell:Vector2, tiles:Array) -> Array:
	var list:Array = []
	if _tilemap.get_cell(cell.x, cell.y-1)   in tiles:  list.append(Vector2(cell.x, cell.y-1))
	if _tilemap.get_cell(cell.x, cell.y+1)   in tiles:  list.append(Vector2(cell.x, cell.y+1))
	if _tilemap.get_cell(cell.x-1, cell.y)   in tiles:  list.append(Vector2(cell.x-1, cell.y))
	if _tilemap.get_cell(cell.x+1, cell.y)   in tiles:  list.append(Vector2(cell.x+1, cell.y))
	if _tilemap.get_cell(cell.x+1, cell.y+1) in tiles:  list.append(Vector2(cell.x+1, cell.y+1))
	if _tilemap.get_cell(cell.x+1, cell.y-1) in tiles:  list.append(Vector2(cell.x+1, cell.y-1))
	if _tilemap.get_cell(cell.x-1, cell.y+1) in tiles:  list.append(Vector2(cell.x-1, cell.y+1))
	if _tilemap.get_cell(cell.x-1, cell.y-1) in tiles:  list.append(Vector2(cell.x-1, cell.y-1))
	return list

func util_get_tile_in_directon(cell:Vector2, tiles:Array, direction:Vector2) -> Array:
	var list:Array = []
	var pos:Vector2 = cell + direction
	if _tilemap.get_cellv(pos) in tiles:
		list.append(pos)
	return list
