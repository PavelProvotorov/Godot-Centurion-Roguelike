extends Entity2D
class_name Enemy2D

var BEHAVIOUR_TYPE = {
	"IDLE": {
		"check": funcref(self, "idle_behaviour"),
		"handle": funcref(self, "handle_idle"),
		"data": {},
	},
	"MELEE": {
		"check": funcref(self, "melee_behaviour"),
		"handle": funcref(self, "handle_melee_attack"),
		"data": funcref(self, "get_melee_data"),
	},
	"RANGED": {
		"check": funcref(self, "ranged_behaviour"),
		"handle": funcref(self, "handle_ranged_attack"),
		"data": funcref(self, "get_ranged_data"),
	},
	"AMBUSH":{
		"check": funcref(self, "ambush_behaviour"),
		"handle": funcref(self, "handle_idle"),
		"data": {},
	},
	"MOVE":{
		"check": funcref(self, "move_behaviour"),
		"handle": funcref(self, "handle_movement"),
		"data": funcref(self, "get_movement_data"),
	},
}

var behaviours = [
	BEHAVIOUR_TYPE.MELEE,
	BEHAVIOUR_TYPE.MOVE
]

var path:Array = []

func _ready():
	Events.connect("level_fog_updated", self, "_on_level_fog_updated")
	attack_range = 1

func _on_level_fog_updated(cells:Array) -> void:
	if cells.has(self.position / grid_size) && !(self.is_in_group("ACTIVE")):
		self.add_to_group("ACTIVE")
	pass

func _on_start_turn() -> void:
	path = (_level.find_path(self.position, target.position))
	process_behaviours()
	
func process_behaviours():
	for behaviour in behaviours:
		var check = behaviour.get("check")
		if check.call_func():
			var handle = behaviour.get("handle")
			var data = behaviour.get("data")
			if (typeof(data) == TYPE_OBJECT): data = data.call_func()
			handle.call_funcv([data])
			return
	print("SKIP")
	Events.emit_signal("end_turn", self)

func get_melee_data() -> Dictionary:
	return {
		"start": self.position,
		"finish": path[1] * grid_size,
	}

func get_ranged_data() -> Dictionary:
	return {
		"start": self.position,
		"finish": path[1] * grid_size,
	}

func get_movement_data() -> Dictionary:
	return {
		"start": self.position,
		"finish": path[1] * grid_size,
	}

func melee_behaviour() -> bool:
	if path.size() == 2 and target_in_sight(self.position, target.position):
		print("MELEE")
		return true
	return false

func ranged_behaviour() -> bool:
	if (path.size() > 2) and ((path.size()-1) <= attack_range) and target_in_sight(self.position, target.position):
		print("RANGED")
		return true
	return false

func move_behaviour() -> bool:
	if path.size() > 2:
		print("MOVE")
		return true
	return false

func ambush_behaviour() -> bool:
	if path.size() == 3 and !target_in_sight(self.position, target.position):
		return true
	return false

func idle_behaviour() -> bool:
	if path.size() == 0:
		print("IDLE")
		return true
	return false
