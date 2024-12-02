extends Node
class_name Queue

var queue:Array = []

func process(tree:SceneTree, node) -> void:
	queue.erase(node)
	print("Queue after erase: ", queue)
	if queue.size() == 0:
		print("Building queue")
		build(tree)
		print("New queue is: ", queue)
		
	var next_node = queue[0]
	print("Next turn for: ", next_node)
	next_node._on_start_turn()

func build(tree:SceneTree) -> void:
	queue = []
	queue.append_array(tree.get_nodes_in_group("ACTIVE"))
	queue.append_array(tree.get_nodes_in_group("PLAYER"))
