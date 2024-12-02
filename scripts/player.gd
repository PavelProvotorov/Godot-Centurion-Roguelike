extends Entity2D

onready var _sprite = $AnimatedSprite
onready var _raycast = $RayCast2D
onready var _camera = $Camera2D

const visibility = 5
enum STATE {
	IDLE,
	ACTIVE
}
var current_state = STATE.IDLE

func _ready():
	Events.connect("level_generation_complete", self, "_on_level_generation_complete")
	
#	var rect = _level.level_rect
#	_camera.limit_left = ((rect.position.x) * grid_size)
#	_camera.limit_right = ((rect.end.x) * grid_size)
#	_camera.limit_top = ((rect.position.y) * grid_size)
#	_camera.limit_bottom = ((rect.end.y) * grid_size)

func _input(event):
	match current_state:
		STATE.IDLE:
			if Input.is_action_just_pressed("ui_skip"):
				skip_turn()
			if Input.is_action_just_pressed("ui_up"):
				check_move_direction(Vector2.UP * grid_size)
			if Input.is_action_just_pressed("ui_down"):
				check_move_direction(Vector2.DOWN * grid_size)
			if Input.is_action_just_pressed("ui_left"): 
				_sprite.flip_h = true
				check_move_direction(Vector2.LEFT * grid_size)
			if Input.is_action_just_pressed("ui_right"): 
				_sprite.flip_h = false
				check_move_direction(Vector2.RIGHT * grid_size)
		_:
			pass
	pass

func check_move_direction(pos:Vector2) -> void:
	_raycast.cast_to = pos
	_raycast.force_raycast_update()
	
	if _raycast.is_colliding():
		print(_raycast.get_collider())
		match _raycast.get_collider().get_class():
			"TileMap":
				process_tilemap_collision(self.position + pos)
			_:
				pass
	else:
		handle_movement(self.position, pos)

func process_tilemap_collision(pos:Vector2) -> void:
	print(_level.get_tile_position_name(pos))
	match _level.get_tile_position_name(pos):
		"DOOR":
			Events.emit_signal("level_door_open", self.position, pos, visibility)
		_:
			pass

func skip_turn() -> void:
	current_state = STATE.ACTIVE
	Events.emit_signal("end_turn", self)

func handle_movement(start:Vector2, finish:Vector2) -> void:
	current_state = STATE.ACTIVE
	_animation.animation_move_to(self.position + finish)

func handle_ranged_attack(start:Vector2, finish:Vector2) -> void:
	current_state = STATE.ACTIVE
	_animation.animation_shoot(self.position, self.position - (finish/2))
	
func _on_level_generation_complete(entrance:Vector2) -> void:
	self.position = entrance
	_camera.reset_smoothing()
	Events.emit_signal("player_moved", self.position, visibility)
	
func _on_animation_move_finished(tween:SceneTreeTween) -> void:
	Events.emit_signal("player_moved", self.position, visibility)
	if !(tween.is_running()): Events.emit_signal("end_turn", self)
	
func _on_animation_ranged_finished(tween:SceneTreeTween) -> void:
	Events.emit_signal("player_ranged_attack", self.position, visibility)
	if !(tween.is_running()): Events.emit_signal("end_turn", self)

func _on_animation_melee_finihsed(tween:SceneTreeTween) -> void:
	Events.emit_signal("player_melee_attack", self.position, visibility)
	if !(tween.is_running()): Events.emit_signal("end_turn", self)

func _on_level_fog_updated(cells) -> void:
	pass

func _on_start_turn() -> void:
	current_state = STATE.IDLE
