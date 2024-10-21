extends TileMap

onready var TILESET = self.tile_set
onready var TILEMAP_BASE = $Base
onready var TILEMAP_DEBRIS = $Debris

onready var TILES_DECO:Dictionary = {
	FLOOR = TILESET.find_tile_by_name("TILE_FLOOR"),
	WALL = TILESET.find_tile_by_name("TILE_WALL"),
	BASE = TILESET.find_tile_by_name("TILE_BASE "),
	ENTRANCE = TILESET.find_tile_by_name("TILE_ENTRANCE"),
	EXIT = TILESET.find_tile_by_name("TILE_EXIT")
	}

func _ready():
	pass

func decorate_level(data:Dictionary):
	clear_decorations()
	for key in data:
		var cells = data.get(key)
		var atlas_id = TILESET.find_tile_by_name(key)
		var tiles = utility_atlas_get_tiles(TILESET, key, atlas_id)
		
		match key:
			"TILE_BASE":
				tilemap_set_random_texture(TILEMAP_BASE, cells, tiles, atlas_id)
			"TILE_DEBRIS":
				tilemap_set_random_texture(TILEMAP_DEBRIS, cells, tiles, atlas_id)
			_:
				tilemap_set_random_texture(self, cells, tiles, atlas_id)
		pass
	pass

func clear_decorations() -> void:
	self.clear()
	TILEMAP_BASE.clear()
	TILEMAP_DEBRIS.clear()

func tilemap_set_random_texture(tilemap:TileMap, cells:Array, tiles:Array, atlas_id:int) -> void:
	randomize()
	for cell in cells:
		var tile = tiles[randi() % tiles.size()]
		tilemap.set_cellv(cell, atlas_id, false, false, false, tile)
	pass

func utility_atlas_get_tiles(tileset:TileSet, tile_name:String, atlas_id:int) -> Array:
	var atlas:Rect2 = tileset.tile_get_region(atlas_id)
	var atlas_size_x:int = atlas.size.x / tileset.autotile_get_size(atlas_id).x
	var atlas_size_y:int = atlas.size.y / tileset.autotile_get_size(atlas_id).y
	var atlas_tiles_array:Array = []
	
	for y in range(atlas_size_y):
		for x in range(atlas_size_x):
			var priority = tileset.autotile_get_subtile_priority(atlas_id,Vector2(x,y))
			for p in priority:
				atlas_tiles_array.append(Vector2(x,y))
				
	return atlas_tiles_array
