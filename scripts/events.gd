extends Node

signal enemy_moved(prev_pos, new_pos)
signal player_moved(pos, distance)
signal player_ranged_attack()
signal player_melee_attack()
signal level_door_open(entity_pos, door_pos, distance)
signal level_generation_complete(entrance)
signal level_fog_updated(cells)
signal end_turn(node) 
