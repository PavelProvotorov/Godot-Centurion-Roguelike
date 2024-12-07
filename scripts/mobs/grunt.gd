extends Enemy2D

func _ready():
	behaviours = [
		BEHAVIOUR_TYPE.MELEE,
		BEHAVIOUR_TYPE.AMBUSH,
		BEHAVIOUR_TYPE.MOVE
	]
	attack_range = 1
	damage = 1
