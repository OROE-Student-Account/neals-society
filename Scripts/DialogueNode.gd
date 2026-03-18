extends Node
class_name DialogueTreeNode

@export var is_end_node = false # determines if this option ends the conversation
@export var option_name = "" # if this has a parent, this is the option name
@export var text = "" # text to show when this option is selected
@export var function = "" # what to do after this is selected
@export var func_node : Node = null


func fix_text():
	var name = Utils.get_player_name()
	var pieces = text.split("<name>")
	text = ""
	for i in range(len(pieces)):
		if i != len(pieces)-1:
			text += pieces[i] + name
		else:
			text += pieces[i]


func get_children_nodes() -> Array[Node]:
	var children: Array[Node] = []
	for child in get_children():
		if child is DialogueTreeNode:
			children.append(child)
	return children


func begin_from_self():
	Utils.get_scene_manager().transition_to_dialogue(self)
