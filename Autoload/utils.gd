extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_player():
	return get_node("/root/SceneManager/CurrentScene").get_child(0).find_child("Player")

func get_scene_manager():
	return get_node("/root/SceneManager")


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


func add_to_inventory(item: String):
	var inv = load_json_file("res://Data/Inventory.json")
	inv["Items"].append(item)
	save_json_file("res://Data/Inventory.json", inv)



func check_item_picked_up(item: String, scene = "Town"):
	var data = load_json_file("res://Data/"+scene+".json")
	
	return data["Items"][item]["Collected"]

func update_item_picked_up(item: String, value: bool, scene = "Town"):
	var file_path = "res://Data/"+scene+".json"
	var data = load_json_file(file_path)
	data["Items"][item]["Collected"] = value
	save_json_file(file_path, data)


func check_trainer_attacked(node_name: String, scene = "Town"):
	var data = load_json_file("res://Data/"+scene+".json")
	
	return data["Trainers"][node_name]["Talked"]

func update_trainer_attacked(node_name: String, value: bool, scene = "Town"):
	var file_path = "res://Data/"+scene+".json"
	var data = load_json_file(file_path)
	data["Trainers"][node_name]["Talked"] = value
	save_json_file(file_path, data)




func reset_town():
	var town = load_json_file("res://Data/Town.json")
	
	# Iterate over the values in the Items dictionary
	for item_name in town["Items"]:
		town["Items"][item_name]["Collected"] = false
	
	# Iterate over the values in the Trainers dictionary
	for trainer_name in town["Trainers"]:
		town["Trainers"][trainer_name]["Talked"] = false
	
	save_json_file("res://Data/Town.json", town)



func save_json_file(file_path, data):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	var json_string = JSON.stringify(data, "\t")  # "\t" adds good formatting with tabs
	file.store_string(json_string)
	file.close()

func load_json_file(file_path):
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	return json.data
