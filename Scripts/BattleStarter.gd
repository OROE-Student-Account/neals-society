extends Node

@export var trainer_name = ""

func begin_battle():
	var gram_name = ""
	if trainer_name == "random":
		var grass_manager = get_parent().get_parent()
		# level can be 2 lower or higher than expected
		var lvl = min(100, max(1, int(randf()*6)-2 + grass_manager.encounter_level))
		gram_name = Utils.get_random_grammarite(lvl, grass_manager.encounter_types)
		gram_name += str(lvl).pad_zeros(3)
	
	Utils.get_scene_manager().transition_to_battle(trainer_name, gram_name)
