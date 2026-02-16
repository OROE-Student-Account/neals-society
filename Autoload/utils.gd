extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_player():
	return get_node("/root/SceneManager/CurrentScene").get_children().back().find_child("Player")

func get_scene_manager():
	return get_node("/root/SceneManager")


# NEED TO IMPROVE, RIGHT NOW IT JUST TAKES BASE MOVES AND BASE INFORMATION.
func get_grammarite_details(grammarite_name):
	if not name: return
	var available_moves = load_json_file("res://GrammariteData/BaseMoves.json")[grammarite_name]
	var stats = load_json_file("res://GrammariteData/Stats.json")[grammarite_name]
	var details = { "Stats": stats, "Moves": [] }
	for move in available_moves:
		var move_info = load_json_file("res://GrammariteData/Moves.json")[move]
		move_info["Name"] = move
		details["Moves"].append(move_info)
	
	return details

var type_chart_dict = {
	"Weak": 0.5,
	"None": 1.0,
	"Strong": 2.0
}

func get_damage_multiplier(attack_type, defend_type1, defend_type2 = "None"):
	var mult = 1.0
	
	var type_chart = load_json_file("res://GrammariteData/TypeChart.json")
	
	mult *= type_chart_dict[type_chart[attack_type][defend_type1]]
	if defend_type2 != "None":
		mult *= type_chart_dict[type_chart[attack_type][defend_type2]]
	
	return mult


func get_party():
	return load_json_file("res://Data/Inventory.json")["Party"]


func get_poke_num(grammarite_name):
	var names = load_json_file("res://GrammariteData/Names.json")
	return names.find(grammarite_name)


func load_json_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	return json.data
