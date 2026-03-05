extends Node

@export var trainer_name = ""

func begin_battle():
	Utils.get_scene_manager().transition_to_battle(trainer_name)
