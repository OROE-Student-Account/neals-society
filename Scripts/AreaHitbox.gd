extends Area2D

@export var name_of_area: String = ""

# Creates a nice list in the inspector where you can add as many strings as you want

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node2D):
	Utils.get_scene_manager().get_node("Labelfornewarea").text_for_new_area(name_of_area)
