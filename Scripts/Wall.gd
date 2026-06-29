extends Node2D


func _ready():
	var scene = Utils.get_scene_manager().get_node("CurrentScene").get_child(0).name
	if Utils.check_obstacle(name, scene):
		queue_free()

func broken():
	var scene = Utils.get_scene_manager().get_node("CurrentScene").get_child(0).name
	Utils.update_obstacle(name, true, scene)
	queue_free()
