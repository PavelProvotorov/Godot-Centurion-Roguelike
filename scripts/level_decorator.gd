extends Node
class_name Decorator2D

var tileset
var _tilemap_deco 
var _tilemap_base
var _tilemap_debris

func _init(deco:TileMap, base:TileMap, debris:TileMap):
	self._tilemap_deco = deco
	self._tilemap_base = base
	self._tilemap_debris = debris
	self.tileset = deco.tile_set

func clear_decorations() -> void:
	_tilemap_deco.clear()
	_tilemap_base.clear()
	_tilemap_debris.clear()

func decorate_level(data:Dictionary):
	clear_decorations()
	for key in data:
		var cells = data.get(key)
		var atlas_id = tileset.find_tile_by_name(key)
		var tiles = utility_atlas_get_tiles(tileset, key, atlas_id)
		
		match key:
			"TILE_BASE":
				tilemap_set_random_texture(_tilemap_base, cells, tiles, atlas_id)
			"TILE_DEBRIS":
				tilemap_set_random_texture(_tilemap_debris, cells, tiles, atlas_id)
			_:
				tilemap_set_random_texture(_tilemap_deco, cells, tiles, atlas_id)
		pass
	pass

func update_decoration(key:String, pos:Array) -> void:
	var atlas_id = tileset.find_tile_by_name(key)
	var tiles = utility_atlas_get_tiles(tileset, key, atlas_id)
	tilemap_set_random_texture(_tilemap_deco, pos, tiles, atlas_id)

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
