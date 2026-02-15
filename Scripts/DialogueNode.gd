extends Node
class_name DialogueTreeNode

@export var is_end_node = false # determines if this option ends the conversation
@export var option_name = "" # if this has a parent, this is the option name
@export var text = "" # text to show when this option is selected
@export var function = "" # what to do after this is selected


func get_children_nodes() -> Array[Node]:
	var children: Array[Node] = []
	for child in get_children():
		if child is DialogueTreeNode:
			children.append(child)
	return children


func begin_from_self():
	Utils.get_scene_manager().transition_to_dialogue(self, self)

func begin_battle():
	Utils.get_scene_manager().transition_to_battle()
