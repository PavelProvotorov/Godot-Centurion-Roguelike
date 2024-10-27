extends Node
class_name ShadowCasting2D

var max_distance:int = 0
var center:Vector2 = Vector2(0, 0)
var visible_cells:Array = []

var tilemap_logic:TileMap
var tilemap_fog:TileMap
var tiles_block:Array
var tile_floor:int
var tile_fog:int

func _init(
	tilemap_logic:TileMap, 
	tilemap_fog:TileMap, 
	tiles_block:Array,
	tile_floor:int, 
	tile_fog:int
	):
	
	self.tilemap_logic = tilemap_logic
	self.tilemap_fog = tilemap_fog
	self.tiles_block = tiles_block
	self.tile_floor = tile_floor
	self.tile_fog = tile_fog

func update(center:Vector2, max_distance:int):
	self.center = center
	self.max_distance = max_distance
	
	for cell in visible_cells:
		tilemap_fog.set_cellv(cell, tile_fog)
	visible_cells.clear()
	
	shadow_casting(center)

func shadow_casting(origin : Vector2):
	mark_visible(origin)
	for i in range(4):
		var quadrant = Quadrant.new(i, origin)
		var first_row = Row.new(1, -1, 1, max_distance)
		scan(first_row, quadrant)

func reveal(tile : Vector2, quadrant : Quadrant):
	var result = quadrant.transform(tile)
	mark_visible(result)

func mark_visible(tile : Vector2):
	if distance(center, tile) > max_distance:
		return
	tilemap_fog.set_cellv(tile, -1)
	visible_cells.append(tile)

func is_wall(tile, quadrant : Quadrant) -> bool:
	if not tile: return false
	var result = quadrant.transform(tile)
	return is_blocking(result)

func is_floor(tile, quadrant : Quadrant) -> bool:
	if not tile: return false
	var result = quadrant.transform(tile)
	return not is_blocking(result)

func is_blocking(tile : Vector2) -> bool:
	return tiles_block.has(tilemap_logic.get_cellv(tile))

func slope(tile : Vector2) -> float:
	var row_depth = tile.x
	var col = tile.y
	return (2.0 * col - 1.0) / (2.0 * row_depth)

func is_symmetric(row : Row, tile : Vector2) -> bool:
	var col = tile.y
	return col >= row.depth * row.start_slope and col <= row.depth * row.end_slope

func scan(row : Row, quadrant : Quadrant):
	if row.depth > max_distance:
		return
	var prev_tile = null
	for tile in row.tiles():
		if is_wall(tile, quadrant) or is_symmetric(row, tile):
			reveal(tile, quadrant)
		if is_wall(prev_tile, quadrant) and is_floor(tile, quadrant):
			row.start_slope = slope(tile)
		if is_floor(prev_tile, quadrant) and is_wall(tile, quadrant):
			var next_row = row.next()
			next_row.end_slope = slope(tile)
			scan(next_row, quadrant)
		prev_tile = tile
	if is_floor(prev_tile, quadrant):
		scan(row.next(), quadrant)

class Quadrant:
	var cardinal
	var ox
	var oy

	func _init(cardinal, origin):
		self.cardinal = cardinal
		self.ox = origin.x
		self.oy = origin.y

	func transform(tile : Vector2):
		var row = tile.x
		var col = tile.y
		match self.cardinal:
			0:
				return Vector2(self.ox + col, self.oy - row)
			1:
				return Vector2(self.ox + row, self.oy + col)
			2:
				return Vector2(self.ox + col, self.oy + row)
			3:
				return Vector2(self.ox - row, self.oy + col)

class Row:
	var depth
	var start_slope
	var end_slope
	var max_distance

	func _init(depth : int, start_slope, end_slope, max_distance):
		self.depth = depth
		self.start_slope = start_slope
		self.end_slope = end_slope
		self.max_distance = max_distance

	func tiles() -> Array:
		var min_col = round_ties_up(self.depth * self.start_slope)
		var max_col = round_ties_down(self.depth * self.end_slope)
		var result = []
		for i in range(min_col, min(max_col + 1, max_distance)):
			result.append(Vector2(self.depth, i))
		return result

	func next() -> Row:
		return Row.new(self.depth + 1, self.start_slope, self.end_slope, max_distance)

	func round_ties_up(n) -> float:
		return floor(n + 0.5)

	func round_ties_down(n) -> float:
		return ceil(n - 0.5)

func distance(a: Vector2, b: Vector2) -> float:
	return a.distance_to(b)
