extends KinematicBody2D
class_name Entity2D

onready var _level = get_tree().get_first_node_in_group("LEVEL")
onready var _animation = TweenAnimation2D.new(self)
onready var target = get_tree().get_first_node_in_group("PLAYER")

const grid_size = 8

func _ready():
	Events.connect("level_fog_updated", self, "_on_level_fog_updated")
	pass
	
func handle_movement(start:Vector2, finish:Vector2) -> void:
	Events.emit_signal("enemy_moved", start, finish)
	
	if is_path_hidden(start / grid_size, finish / grid_size):
		self.position = finish
		Events.emit_signal("end_turn", self)
	else:
		_animation.animation_move_to(finish)

func handle_melee_attack(start:Vector2, finish:Vector2) -> void:
	_animation.animation_melee(start, finish)

func handle_ranged_attack(start:Vector2, finish:Vector2) -> void:
	_animation.animation_ranged(self.position, self.position - (finish/2))

func is_path_hidden(start:Vector2, finish:Vector2) -> bool:
	return _level.is_fog_cell(start) && _level.is_fog_cell(finish)

func _on_animation_move_finished(tween:SceneTreeTween) -> void:
	if !(tween.is_running()): Events.emit_signal("end_turn", self)
	
func _on_animation_ranged_finished(tween:SceneTreeTween) -> void:
	if !(tween.is_running()): Events.emit_signal("end_turn", self)

func _on_animation_melee_finished(tween:SceneTreeTween) -> void:
	if !(tween.is_running()): Events.emit_signal("end_turn", self)

func _on_level_fog_updated(cells:Array) -> void:
	if cells.has(self.position / grid_size) && !(self.is_in_group("ACTIVE")):
		self.add_to_group("ACTIVE")
	pass

func _on_start_turn() -> void:
	var path = (_level.find_path(self.position, target.position))
	if path.size() > 2:
		handle_movement(self.position, path[1] * grid_size)
	elif path.size() == 2:
		handle_melee_attack(self.position, path[1] * grid_size)
	else:
		Events.emit_signal("end_turn", self)
