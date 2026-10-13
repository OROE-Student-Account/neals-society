extends Node2D

@export var free_on_load: bool = false;

func _ready():
	var scene = Utils.get_scene_manager().get_node("CurrentScene").get_child(0).name
	if not free_on_load:
		if Utils.check_obstacle(name, scene):
			queue_free()
	else:
		if not Utils.check_obstacle(name, scene):
			queue_free()

func broken():
	var scene = Utils.get_scene_manager().get_node("CurrentScene").get_child(0).name
	Utils.update_obstacle(name, true, scene)
	queue_free()
