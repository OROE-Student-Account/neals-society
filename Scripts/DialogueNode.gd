extends Node
class_name DialogueTreeNode

@export var is_end_node = false # determines if this option ends the conversation
@export var option_name = "" # if this has a parent, this is the option name
@export var text = "" # text to show when this option is selected
@export var function = "" # what to do after this is selected
@export var func_node : Node = null
@export var args: Array[String] = []
@export var display : String = ""


func fix_text():
	var player_name = Utils.get_player_name()
	var parent_name = get_parent().name
	var rival_name = Utils.get_rival_name()
	
	# Update the 'text' variable
	text = text.replace("<player>", player_name)
	text = text.replace("<parent>", parent_name)
	text = text.replace("<rival>", rival_name)
	
	# Update the 'display' variable
	display = display.replace("<player>", player_name)
	display = display.replace("<parent>", parent_name)
	display = display.replace("<rival>", rival_name)


func get_children_nodes() -> Array[Node]:
	var children: Array[Node] = []
	for child in get_children():
		if child is DialogueTreeNode:
			children.append(child)
	return children


func begin_from_self():
	Utils.get_scene_manager().transition_to_dialogue(self)
