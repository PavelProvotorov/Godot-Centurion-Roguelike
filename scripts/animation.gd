extends Node
class_name TweenAnimation2D

const tween_speed = 10
var parent

func _init(parent:KinematicBody2D) -> void:
	self.parent = parent

func animation_move_to(pos:Vector2) -> void:
	var tween:SceneTreeTween = parent.create_tween()
	tween.tween_property(parent, 'position', pos, 1.0/tween_speed).set_trans(Tween.EASE_IN_OUT)
	tween.connect("finished", parent, "_on_animation_move_finished", [tween])

func animation_shoot(start:Vector2, finish:Vector2) -> void:
	var tween:SceneTreeTween = parent.create_tween()
	tween.tween_property(parent, 'position', finish, 0.8/tween_speed)
	tween.tween_property(parent, 'position', start, 1.0/tween_speed).set_trans(Tween.EASE_OUT)
	tween.connect("finished", parent, "_on_animation_shot_finished", [tween])
