extends KinematicBody2D

onready var _sprite = $AnimatedSprite
onready var _raycast = $RayCast2D
onready var _camera = $Camera2D
onready var _level = get_tree().get_first_node_in_group("LEVEL")
var _animation = TweenAnimation2D.new(self)

const visibility = 5
const grid_size = 8
enum STATE {
	IDLE,
	ACTIVE
}
var current_state = STATE.IDLE

func _ready():
	Events.connect("level_generation_complete", self, "_on_level_generation_complete")
	
	var rect = _level.level_rect
	_camera.limit_left = ((rect.position.x) * grid_size)
	_camera.limit_right = ((rect.end.x) * grid_size)
	_camera.limit_top = ((rect.position.y) * grid_size)
	_camera.limit_bottom = ((rect.end.y) * grid_size)


func _physics_process(delta) -> void:
	match current_state:
		STATE.IDLE:
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
		move_to_position(pos)

func process_tilemap_collision(pos:Vector2) -> void:
	print(_level.get_tile_position_name(pos))
	match _level.get_tile_position_name(pos):
		"DOOR":
			Events.emit_signal("level_door_open", self.position, pos, visibility)
		_:
			pass

func move_to_position(pos:Vector2) -> void:
	current_state = STATE.ACTIVE
	_animation.animation_move_to(self.position + pos)

func shoot_in_direction(pos:Vector2) -> void:
	current_state = STATE.ACTIVE
	_animation.animation_shoot(self.position, self.position - (pos/2))
	
func _on_level_generation_complete(entrance:Vector2) -> void:
	self.position = entrance
	_camera.reset_smoothing()
	Events.emit_signal("player_moved", self.position, visibility)
	
func _on_animation_move_finished(tween:SceneTreeTween) -> void:
	current_state = STATE.IDLE
	Events.emit_signal("player_moved", self.position, visibility)
	
func _on_animation_shot_finished(tween:SceneTreeTween) -> void:
	current_state = STATE.IDLE
	Events.emit_signal("player_shot", self.position, visibility)
