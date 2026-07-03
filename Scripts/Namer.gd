extends Control

func _ready():
	Utils.get_scene_manager().name_selected.connect(_recieve_name)

@export var function = ""
@export var name_prompt = "What should your name be?"

func _recieve_name(chosen_name, from_node):
	if from_node != self: return
	Utils.callv(function, [chosen_name])
	

func name_this():
	Utils.get_scene_manager().transition_to_naming_screen(self)
