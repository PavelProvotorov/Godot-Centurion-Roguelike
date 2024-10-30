extends AStar2D
class_name PathFinding2D

var _astar = AStar2D.new()

func _init(cells:Array):
	astar_build(cells)

func get_path(start:Vector2, end:Vector2) -> Array:
	return _astar.get_point_path(uuid(start),uuid(end))

func disable_points(points:Array) -> void:
	for point in points:
		_astar.set_point_disabled(uuid(point), true)

func enable_points(points:Array) -> void: 
	for point in points:
		_astar.set_point_disabled(uuid(point), false)

func astar_build(cells:Array):
	astar_add_points(cells)
	astar_connect_points(_astar.get_points())

func astar_add_points(cells:Array) -> void:
	for cell in cells:
		_astar.add_point(uuid(cell), cell, 1.0)

func astar_connect_points(points:Array):
	var directions = [
		Vector2.UP, 
		Vector2.DOWN, 
		Vector2.LEFT, 
		Vector2.RIGHT
	]
	for point in points:
		for direction in directions:
			var point_vector:Vector2 = _astar.get_point_position(point)
			var check_point:Vector2 =  point_vector + direction
			if points.has(uuid(check_point)):
				_astar.connect_points(point, uuid(check_point), false)

func uuid(point:Vector2) -> int:
	return int((point.x + point.y) * (point.x + point.y + 1) / 2 + point.y)
