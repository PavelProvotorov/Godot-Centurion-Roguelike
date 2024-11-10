extends Node2D

onready var debug_label = preload("res://scenes/DebugLabel.tscn")
onready var debug_player = preload("res://mobs/Player.tscn")

onready var _tilemap_logic = $Logic
onready var _tilemap_debug = $Debug
onready var _tilemap_decor = $Decor
onready var _tilemap_debris = $Debris
onready var _tilemap_base = $Base
onready var _tilemap_fog = $Fog
onready var level_rect = _tilemap_logic.get_used_rect()

onready var TILES = {
	EMPTY = _tilemap_logic.tile_set.find_tile_by_name("TILE_EMPTY"),
	FLOOR = _tilemap_logic.tile_set.find_tile_by_name("TILE_FLOOR"),
	WALL = _tilemap_logic.tile_set.find_tile_by_name("TILE_WALL"),
	DOOR = _tilemap_logic.tile_set.find_tile_by_name("TILE_DOOR"),
	OBJECT = _tilemap_logic.tile_set.find_tile_by_name("TILE_OBJECT"),
	ENTRANCE = _tilemap_logic.tile_set.find_tile_by_name("TILE_ENTRANCE"),
	EXIT = _tilemap_logic.tile_set.find_tile_by_name("TILE_EXIT"),
	FOG = _tilemap_fog.tile_set.find_tile_by_name("TILE_FOG")
	}

var _shadowcasting:ShadowCasting2D
var _pathfinding:PathFinding2D
var _generator:Generator2D
var _decorator:Decorator2D

func _ready():
	randomize()
	Events.connect("player_moved", self, "_on_player_moved")
	Events.connect("level_door_open", self, "_on_level_door_open")
	
	debug_add_cell_positions(_tilemap_logic.get_used_cells())
	add_player()
	generate_level()
	
func _process(delta):
	if Input.is_action_just_pressed("ui_space"):
		generate_level()
	pass

func generate_level():
	_generator = Generator2D.new(
		_tilemap_logic
	)
	
	_decorator = Decorator2D.new(
		_tilemap_decor,
		_tilemap_base,
		_tilemap_debris
	)
	
	_pathfinding = PathFinding2D.new(
		tilemap_get_cells_in_array(_tilemap_logic, [
			TILES.ENTRANCE,
			TILES.FLOOR,
			TILES.EXIT,
			TILES.DOOR
		])
	)
	_pathfinding.disable_points(_tilemap_logic.get_used_cells_by_id(TILES.DOOR))

	_decorator.decorate_level({
		"TILE_FLOOR": _tilemap_logic.get_used_cells_by_id(TILES.FLOOR),
		"TILE_WALL": _tilemap_logic.get_used_cells_by_id(TILES.WALL),
		"TILE_ENTRANCE": _tilemap_logic.get_used_cells_by_id(TILES.ENTRANCE),
		"TILE_EXIT": _tilemap_logic.get_used_cells_by_id(TILES.EXIT),
		"TILE_BASE": _generator.generator_get_walls_base(),
		"TILE_DEBRIS": _tilemap_logic.get_used_cells_by_id(TILES.FLOOR),
		"TILE_DOOR_CLOSED": _tilemap_logic.get_used_cells_by_id(TILES.DOOR),
		"TILE_OBJECT_BIG": _generator.object_big_cells,
		"TILE_OBJECT_SMALL": _generator.object_small_cells
	})
	
	_shadowcasting = ShadowCasting2D.new(
		_tilemap_logic,
		_tilemap_fog,
		[TILES.WALL, TILES.DOOR],
		TILES.FLOOR,
		TILES.FOG
	)
	
	Events.emit_signal(
		"level_generation_complete", 
		_tilemap_logic.map_to_world(_generator.generator_get_entrance())
	)

func add_player():
	var player = debug_player.instance()
	player.set_position(Vector2(0, 0))
	_tilemap_logic.add_child(player)

func get_tile_position_name(pos:Vector2) -> String:
	var pos_tilemap = _tilemap_logic.world_to_map(pos)
	return TILES.find_key(_tilemap_logic.get_cellv(pos_tilemap))

func tilemap_get_cells_in_array(tilemap:TileMap, ids:Array) -> Array:
	var cells = []
	for id in ids:
		cells.append_array(tilemap.get_used_cells_by_id(id))
	return cells

func _on_level_door_open(entity_pos:Vector2, door_pos:Vector2, distance:int) -> void:
	var entity_pos_tilemap = _tilemap_logic.world_to_map(entity_pos)
	var door_pos_tilemap = _tilemap_logic.world_to_map(door_pos)
	
	_tilemap_logic.set_cellv(door_pos_tilemap, TILES.FLOOR)
	_decorator.update_decoration('TILE_DOOR_OPEN', [door_pos_tilemap])
	_pathfinding.enable_points([door_pos_tilemap])
	_shadowcasting.update(entity_pos_tilemap, distance)

func _on_player_moved(pos:Vector2, distance:int) -> void:
	var pos_tilemap = _tilemap_logic.world_to_map(pos)
	print("Player moved: ", pos_tilemap, " > ", distance)
	_shadowcasting.update(pos_tilemap, distance)

func debug_print_rooms() -> void:
	print("---------------------")
	var rooms = _generator.generator_get_rooms(TILES.FLOOR)
	for room in rooms.size():
		print(room, ": ", rooms[room])

func debug_add_cell_positions(cells:PoolVector2Array) -> void:
	for cell in cells:
		var label = debug_label.instance()
		label.text = str(cell)
		label.set_position(_tilemap_debug.map_to_world(cell))
		_tilemap_debug.add_child(label)
