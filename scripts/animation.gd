extends Node
class_name TweenAnimation2D

const tween_speed = 10
var parent

func _init(parent:KinematicBody2D) -> void:
	self.parent = parent

func animation_move_to(pos:Vector2, target:Node, property:String) -> void:
	var tween:SceneTreeTween = parent.create_tween()
	tween.tween_property(target, property, pos, 1.0/tween_speed).set_trans(Tween.EASE_IN_OUT)
	tween.connect("finished", parent, "_on_animation_move_finished", [tween])

func animation_ranged(start:Vector2, finish:Vector2, target:Node, property:String) -> void:
	var tween:SceneTreeTween = parent.create_tween()
	tween.tween_property(target, property, finish, 0.8/tween_speed)
	tween.tween_property(target, property, start, 1.0/tween_speed).set_trans(Tween.EASE_OUT)
	tween.connect("finished", parent, "_on_animation_ranged_finished", [tween])

func animation_melee(start:Vector2, finish:Vector2, target:Node, property:String) -> void:
	var tween:SceneTreeTween = parent.create_tween()
	tween.tween_property(target, property, finish, 0.8/tween_speed)
	tween.tween_property(target, property, start, 1.0/tween_speed).set_trans(Tween.EASE_OUT)
	tween.connect("finished", parent, "_on_animation_melee_finished", [tween])
