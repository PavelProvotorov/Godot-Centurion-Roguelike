extends Entity2D

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

func _input(event):
	match current_state:
		STATE.IDLE:
			if Input.is_action_just_pressed("ui_skip"):
				handle_idle({})
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

func set_camera_limits() -> void:
	var rect = _level.level_rect
	_camera.limit_left = ((rect.position.x) * grid_size)
	_camera.limit_right = ((rect.end.x) * grid_size)
	_camera.limit_top = ((rect.position.y) * grid_size)
	_camera.limit_bottom = ((rect.end.y) * grid_size)

func check_move_direction(pos:Vector2) -> void:
	_raycast.cast_to = pos
	_raycast.force_raycast_update()
	
	if _raycast.is_colliding():
		var collider = _raycast.get_collider()
		if collider.is_in_group("LEVEL"):
			process_tilemap_collision(self.position + pos)
		elif collider.is_in_group("ENEMY"):
			handle_melee_attack({
				"start": self.position, 
				"finish": collider.position,
			})
	else:
		handle_movement({
			"start": self.position, 
			"finish": pos,
		})

func process_tilemap_collision(pos:Vector2) -> void:
	print(_level.get_tile_position_name(pos))
	match _level.get_tile_position_name(pos):
		"DOOR":
			Events.emit_signal("level_door_open", self.position, pos, visibility)
		_:
			pass

func handle_idle(data:Dictionary) -> void:
	current_state = STATE.ACTIVE
	Events.emit_signal("player_moved", self.position, visibility)
	Events.emit_signal("end_turn", self)

func handle_movement(data:Dictionary) -> void:
	current_state = STATE.ACTIVE
	var start = data.start
	var finish = data.finish
	_animation.animation_move_to((self.position + finish), self, 'position')

func handle_melee_attack(data:Dictionary) -> void:
	current_state = STATE.ACTIVE
	self.z_index += 1
	var start = data.start
	var finish = data.finish
	_animation.animation_melee(start, finish, self, 'position')

func handle_ranged_attack(data:Dictionary) -> void:
	current_state = STATE.ACTIVE
	self.z_index += 1
	var start = data.start
	var finish = data.finish
	_animation.animation_ranged(self.position, self.position - (finish/2), self, 'position')
	
func _on_level_generation_complete(entrance:Vector2) -> void:
	self.position = entrance
	_camera.reset_smoothing()
	Events.emit_signal("player_moved", self.position, visibility)
	
func _on_animation_move_finished(tween:SceneTreeTween) -> void:
	if tween.is_running(): printerr("Move tween animation not complete")
	Events.emit_signal("player_moved", self.position, visibility)
	Events.emit_signal("end_turn", self)
	
func _on_animation_ranged_finished(tween:SceneTreeTween) -> void:
	self.z_index -= 1
	if tween.is_running(): printerr("Ranged tween animation not complete")
	Events.emit_signal("player_ranged_attack", self.position, visibility)
	Events.emit_signal("end_turn", self)

func _on_animation_melee_finihsed(tween:SceneTreeTween) -> void:
	self.z_index -= 1
	if tween.is_running(): printerr("Melee tween animation not complete")
	Events.emit_signal("player_melee_attack", self.position, visibility)
	Events.emit_signal("end_turn", self)

func _on_start_turn() -> void:
	current_state = STATE.IDLE
