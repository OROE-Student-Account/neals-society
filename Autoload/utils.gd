extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var seen_question_ids: Dictionary = {}

# Testing only: set false to keep working quest progress between editor runs.
# Saved slots are not changed; loading one restores its saved progress.
@export var reset_quest_progress_in_editor := false

# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_feature("editor") and reset_quest_progress_in_editor:
		reset_quest_progress()
	reset_scenes()
	# pass

func reset_quest_progress() -> void:
	var definitions = load_json_file("res://GrammariteData/Quests.json")
	var quests: Array = []
	for _quest in definitions:
		quests.append({"Progress": "Incoming"})
	# Replacing each entry also clears lesson steps, reward flags, and signs.
	save_json_file("res://Data/Quests.json", quests)

func reset_scenes():
	var scenes = load_json_file("res://Data/Scenes.json")
	
	for scene_name in scenes:
		var town = scenes[scene_name]
		if town.has("Items"):
			for item_name in town["Items"]:
				town["Items"][item_name]["Collected"] = false
		
		# Iterate over the values in the Trainers dictionary
		if town.has("Trainers"):
			for trainer_name in town["Trainers"]:
				town["Trainers"][trainer_name]["Talked"] = false
		
		if town.has("Obstacles"):
			for obstacle in town["Obstacles"]:
				town["Obstacles"][obstacle]["Broken"] = false
	
	var quests = load_json_file("res://GrammariteData/Quests.json")
	# breaks quest objects because they should only appear on quest accept
	for quest in quests:
		if quest.has("Load"):
			scenes[quest["Load"]["Scene"]]["Obstacles"][quest["Load"]["Node"]]["Broken"] = true
	
	save_json_file("res://Data/Scenes.json", scenes)
	
	var shops = load_json_file("res://GrammariteData/Shop.json")
	save_json_file("res://Data/Shop.json", shops)


func get_player():
	return get_node("/root/SceneManager/CurrentScene").get_child(0).find_child("Player")
func get_scene_manager():
	return get_node("/root/SceneManager")



func get_grammarite_details(grammarite_name):
	if not grammarite_name: print("NO NAME INPUTTED"); return
	var available_moves = load_json_file("res://GrammariteData/BaseMoves.json")[grammarite_name]
	var stats = load_json_file("res://GrammariteData/Stats.json")[grammarite_name]
	var details = { "Stats": stats, "Moves": [] }
	for move in available_moves:
		var move_info = load_json_file("res://GrammariteData/Moves.json")[move]
		move_info["Name"] = move
		details["Moves"].append(move_info)
	
	return details


func get_trainer(trainer):
	return load_json_file("res://GrammariteData/Trainers.json")[trainer]

func get_move(move):
	return load_json_file("res://GrammariteData/Moves.json")[move]


func get_party():
	return load_json_file("res://Data/Inventory.json")["Party"]
func set_party(party):
	var inv = load_json_file("res://Data/Inventory.json")
	
	inv["Party"] = party
	
	save_json_file("res://Data/Inventory.json", inv)


func add_to_inventory(item: String):
	var inv = load_json_file("res://Data/Inventory.json")
	inv["Items"].append(item)
	save_json_file("res://Data/Inventory.json", inv)
func remove_from_inventory(item: String) -> bool: # whether or not removed something
	var inv = load_json_file("res://Data/Inventory.json")
	for i in range(len(inv["Items"])):
		if inv["Items"][i] == item:
			inv["Items"].pop_at(i)
			
			save_json_file("res://Data/Inventory.json", inv)
			return true
	return false


func get_items():
	var inv = load_json_file("res://Data/Inventory.json")["Items"]
	
	return inv
func get_item_data(item_name):
	return load_json_file("res://GrammariteData/Items.json")[item_name]


func check_item_picked_up(item: String, scene = "Town"):
	return load_json_file("res://Data/Scenes.json")[scene]["Items"][item]["Collected"]
func update_item_picked_up(item: String, value: bool, scene = "Town"):
	var data = load_json_file("res://Data/Scenes.json")
	data[scene]["Items"][item]["Collected"] = value
	save_json_file("res://Data/Scenes.json", data)

func check_trainer_attacked(node_name: String, scene = "Town"):
	return load_json_file("res://Data/Scenes.json")[scene]["Trainers"][node_name]["Talked"]
func update_trainer_attacked(node_name: String, value: bool, scene = "Town"):
	var data = load_json_file("res://Data/Scenes.json")
	data[scene]["Trainers"][node_name]["Talked"] = value
	save_json_file("res://Data/Scenes.json", data)

func check_obstacle(node_name: String, scene = "Town"):
	return load_json_file("res://Data/Scenes.json")[scene]["Obstacles"][node_name]["Broken"]
func update_obstacle(node_name: String, value: bool, scene = "Town"):
	var data = load_json_file("res://Data/Scenes.json")
	data[scene]["Obstacles"][node_name]["Broken"] = value
	save_json_file("res://Data/Scenes.json", data)

func max_hp(grammarite_name, level: int) -> int:
	return int(20 + 2 * level + int(0.01 * level * load_json_file("res://GrammariteData/Stats.json")[grammarite_name]["Health"] - 0.001))


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

func get_random_grammarite(level: int, types: Array) -> String:
	var grams = load_json_file("res://GrammariteData/Names.json")
	var evos = load_json_file("res://GrammariteData/Evolutions.json")
	
	# Load the stats file once here to prevent disk lag during the loop
	var stats_data = load_json_file("res://GrammariteData/Stats.json")
	
	if grams.is_empty() or types.is_empty():
		return ""
	
	while true:
		# 1. Pick a target type (maintains your awesome duplicate-weighting system!)
		var target_type = types.pick_random()
		
		# 2. Pick a random candidate
		var candidate_name = grams.pick_random()
		var candidate_id = get_poke_num(candidate_name)
		
		# 3. EVOLUTION CHECK
		# Upper Bound: Is it overdue for an evolution?
		if can_evolve(candidate_name, level) >= 0:
			continue
			
		# Lower Bound: Is it an evolved form spawning at too low a level?
		if candidate_id > 0:
			var previous_stage_evo_level = evos[candidate_id - 1]
			if previous_stage_evo_level != -1 and level < previous_stage_evo_level:
				continue
		
		# 4. TYPE CHECK: Pass the stats data into our checker
		if candidate_has_or_will_gain_type(candidate_id, target_type, grams, evos, stats_data):
			return candidate_name

	return ""


# Helper function to check current and future types using your Stats layout
func candidate_has_or_will_gain_type(start_id: int, target_type: String, grams: Array, evos: Array, stats_data: Dictionary) -> bool:
	var current_id = start_id
	
	while current_id < grams.size():
		var current_name = grams[current_id]
		
		# Accessing the types using your exact dictionary structure pattern
		if stats_data.has(current_name):
			var current_types = stats_data[current_name]["Types"] # Matches details["Stats"]["Types"]
			if target_type in current_types:
				return true
				
		# Check if this evolution line can go further
		var level_needed = evos[current_id]
		if level_needed == -1:
			break # End of evolution line reached
			
		current_id += 1
		
	return false

func can_evolve(grammarite_name, level):
	var evos = load_json_file("res://GrammariteData/Evolutions.json")
	var level_needed = evos[get_poke_num(grammarite_name)]
	if level_needed == -1: return -1000
	return level - level_needed


func get_poke_num(grammarite_name):
	var names = load_json_file("res://GrammariteData/Names.json")
	return names.find(grammarite_name)
func get_name_from_num(grammarite_num):
	return load_json_file("res://GrammariteData/Names.json")[grammarite_num]


func set_player_name(new_name):
	var inv = load_json_file("res://Data/Inventory.json")
	inv["Name"] = new_name
	save_json_file("res://Data/Inventory.json", inv)
func get_player_name(slot: int = 0):
	if slot == 0:
		return load_json_file("res://Data/Inventory.json")["Name"]
	else:
		var file = load_json_file("res://Saves/"+str(slot)+"/Inventory.json")
		if file.has("Name"):
			return file["Name"]
		else:
			return ""

func set_rival_name(new_name):
	var stu =  load_json_file("res://Data/OtherStuff.json")
	stu["Rival Name"] = new_name
	save_json_file("res://Data/OtherStuff.json", stu)
func get_rival_name():
	return load_json_file("res://Data/OtherStuff.json")["Rival Name"]
	

func set_last_center(num: int):
	var stuff = load_json_file("res://Data/OtherStuff.json")
	stuff["Last Grammarite Center"] = num
	save_json_file("res://Data/OtherStuff.json", stuff)
func get_last_center():
	return load_json_file("res://GrammariteData/OtherStuff.json")["GCLocations"][load_json_file("res://Data/OtherStuff.json")["Last Grammarite Center"]]

func get_shop():
	var shops = load_json_file("res://Data/Shop.json")
	var last_center = load_json_file("res://Data/OtherStuff.json")["Last Grammarite Center"]
	return shops[last_center]
func set_shop(new_stock):
	var shops = load_json_file("res://Data/Shop.json")
	var last_center = load_json_file("res://Data/OtherStuff.json")["Last Grammarite Center"]
	shops[last_center] = new_stock
	save_json_file("res://Data/Shop.json", shops)


func load_quests():
	var quest_info = load_json_file("res://GrammariteData/Quests.json")
	var quest_details = load_json_file("res://Data/Quests.json")
	# Older save slots predate newly added quests. Keep their existing progress.
	if quest_details.size() < quest_info.size():
		while quest_details.size() < quest_info.size():
			quest_details.append({"Progress": "Incoming"})
		save_json_file("res://Data/Quests.json", quest_details)
	
	var quests = []
	
	for i in range(len(quest_info)):
		var quest = quest_details[i]
		if quest["Progress"] != "Unstarted":
			quest["ID"] = i
			var add_quest = quest_info[i]
			add_quest["Details"] = quest
			quests.append(add_quest)
	
	return quests
func set_quest_progress(prog: String, id: int):
	var quests = load_json_file("res://Data/Quests.json")
	quests[id]["Progress"] = prog
	save_json_file("res://Data/Quests.json", quests)
func update_quest_objective(id: int, objective_index: int, is_complete: bool) -> void:
	var quests = load_json_file("res://Data/Quests.json")
	var quest_save = quests[id]
	
	# Make sure this quest actually uses the boolean array
	if quest_save.has("Objectives") and objective_index < quest_save["Objectives"].size():
		quest_save["Objectives"][objective_index] = is_complete
		save_json_file("res://Data/Quests.json", quests)
		
		# See if this change finishes the quest!
		_check_quest_completion(id)
func update_quest_count(id: int, amount: int = 1) -> void:
	var quests = load_json_file("res://Data/Quests.json")
	var quest_save = quests[id]
	
	# Initialize the count if it doesn't exist yet
	if not quest_save.has("Count"):
		quest_save["Count"] = 0
		
	quest_save["Count"] += amount
	save_json_file("res://Data/Quests.json", quests)
	
	# See if we hit the required number!
	_check_quest_completion(id)
func _check_quest_completion(id: int) -> void:
	var quests_save = load_json_file("res://Data/Quests.json")
	var quests_info = load_json_file("res://GrammariteData/Quests.json")
	
	var save_data = quests_save[id]
	var static_data = quests_info[id]
	
	var objectives_met = true
	var count_met = true
	
	# 1. Check boolean objectives (if they exist)
	if save_data.has("Objectives"):
		for obj_status in save_data["Objectives"]:
			if obj_status == false:
				objectives_met = false
				break # One false objective ruins the batch
				
	# 2. Check the count (if a RequiredCount is specified in the static data)
	if static_data.has("RequiredCount"):
		var current_count = save_data.get("Count", 0)
		if current_count < static_data["RequiredCount"]:
			count_met = false
			
	# 3. If both conditions are satisfied, mark it complete!
	if objectives_met and count_met and save_data["Progress"] != "Rewarding"  and save_data["Progress"] != "Completed":
		set_quest_progress("Rewarding", id)

func get_recipe(shard1, shard2):
	var recipes = load_json_file("res://GrammariteData/Recipes.json")
	var craft = {}
	if recipes.has(shard1) and recipes[shard1].has(shard2):
		craft = recipes[shard1][shard2]
	elif recipes.has(shard2) and recipes[shard2].has(shard1):
		craft = recipes[shard2][shard1]
	
	return craft



func caught_yet(grammarite):
	var dex = load_json_file("res://Data/Grammadex.json")
	return dex[get_poke_num(grammarite)]
func catch(grammarite):
	var dex = load_json_file("res://Data/Grammadex.json")
	if !dex[get_poke_num(grammarite)]:
		get_scene_manager().grammadex()
		dex[get_poke_num(grammarite)] = true
		save_json_file("res://Data/Grammadex.json", dex)

func get_num_grammarites():
	return len(load_json_file("res://GrammariteData/Names.json"))


func get_money() -> int:
	return load_json_file("res://Data/Inventory.json")["Money"]
func set_money(mon: int):
	var inv = load_json_file("res://Data/Inventory.json")
	inv["Money"] = mon
	save_json_file("res://Data/Inventory.json", inv)


func get_bookshelf():
	return load_json_file("res://Data/Bookshelf.json")
func set_bookshelf(input):
	var books = load_json_file("res://Data/Bookshelf.json")
	books = input
	save_json_file("res://Data/Bookshelf.json", books)
func add_to_bookshelf(grammarite):
	var books = load_json_file("res://Data/Bookshelf.json")
	for i in range(12):
		if books[i] == {}:
			books[i] = grammarite
			save_json_file("res://Data/Bookshelf.json", books)
			return true
	return false


var question_list = [
	"Vocabulary",
	"Syntax",
	"Punctuation"
]
var alphabet = "abcdefghijklmnopqrstuvwxyz"
var vowels = "aeiou"
var consonants = "bcdfghjklmnpqrstvwxyz"
var punctuation = "?!.,;:-\"' "
func get_question(): 
	var seen_question_ids: Dictionary = {}
	# Get the question
	var type_of_question = question_list.pick_random()
	var questions = load_json_file("res://GrammariteData/Questions.json")[type_of_question]
	var question = questions.pick_random()
	#Ensure it is 'difficult' to annoy testers
	while question["Difficulty"] != "Shakespeare":
		question = questions.pick_random()

	# setup for returning
	var answer = question["Answer"]
	var returning = { 
		"Question": question["Question"],
		"Answer": randi()%4,
		"Type": type_of_question,
		"Options": [ "", "", "", "" ]
	}
	returning["Options"][returning["Answer"]] = answer
	
	# get the options
	for i in range(4):
		if i != returning["Answer"]:
			var option = ""
			var letters: Array = vowels.split()
			letters.append_array(consonants.split())
			
			while option in returning["Options"] or option == "":
				if type_of_question == "Punctuation":
					var marks: Array = punctuation.split()
					var mark = marks.pick_random()
					option = mark
				elif type_of_question == "Syntax":
					var type_of_answer = randi()%3
					
					var words: Array = question["Question"].split(" ")
					words = words.slice(5)
					var word = words.pick_random()
					
					if type_of_answer < 2: # Random word from the question
						option = word
					elif type_of_answer == 2: # Question word with random letter
						var index = randi()%len(word)
						var old_let = word[index]
						
						var vows: Array = vowels.split()
						var cons: Array = consonants.split()
						
						var new_let = ""
						if old_let in vows:
							new_let = vows.pick_random()
						else:
							new_let = cons.pick_random()
						
						word[index] = new_let
						option = word
				elif type_of_question == "Vocabulary":
					var type_of_answer = randi()%2 # 2 is num types of answers
					
					if type_of_answer == 0: # Completely Random Word
						var length = randi()%int((len(answer)/2+2))+2
						var word = ""
						
						var max_letters = 0
						var letter = 0
						var on_vowels = randf() > 0.65
						
						var vows: Array = vowels.split()
						var cons: Array = consonants.split()
						
						while word.length() < length:
							if on_vowels:
								if max_letters == 0:
									max_letters = randi()%3
								letter += 1.4
								word += vows.pick_random()
								if letter >= max_letters:
									max_letters = 0
									letter = fmod(letter, 1.0)
									on_vowels = false
							else:
								if max_letters == 0:
									max_letters = randi()%4
								letter += 1.3
								word += cons.pick_random()
								if letter >= max_letters:
									max_letters = 0
									letter = fmod(letter, 1.0)
									on_vowels = true
						option = word
					elif type_of_answer == 1: # Answer with random letter
						var word = answer
						var index = randi()%len(word)
						var old_let = word[index]
						
						var vows: Array = vowels.split()
						var cons: Array = consonants.split()
						
						var new_let = ""
						if old_let in vows:
							new_let = vows.pick_random()
						else:
							new_let = cons.pick_random()
						
						word[index] = new_let
						option = word
				
				if type_of_question != "Punctuation":
					var temp = ""
					option = option.to_lower()
					#flag to capitalize first letter
					var cap = false
					for j in range(len(option)):
						if option[j] in letters:
							if not cap:
								temp += option[j].to_upper()
								cap = true
							else:
								temp += option[j]
					option = temp
			
			
			returning["Options"][i] = option
	
	return returning


#{
			#"Question": "",
			#"Answer": "",
			#"Difficulty": ""
		#}



func get_question_by_grade(grade: int) -> Dictionary:
	var path = "res://GrammariteData/Questions_Grade%d.json" % grade
	var bank = load_json_file(path)

	if not bank is Dictionary:
		push_warning("Question bank could not be loaded: " + path)
		return {}

	var categories = ["Vocabulary", "Syntax", "Punctuation"]
	var eligible = []

	for category in categories:
		if not bank.has(category):
			continue

		for q in bank[category]:
			if int(q.get("Grade", 0)) == grade and not seen_question_ids.has(q["ID"]):
				eligible.append({
					"type": category,
					"data": q
				})

	if eligible.is_empty():
		push_warning("No unused questions for Grade " + str(grade))
		return {}

	var selected = eligible.pick_random()
	var item = selected["data"]

	seen_question_ids[item["ID"]] = true

	var options: Array = [item["Answer"]]
	options.append_array(item["Distractors"])
	options.shuffle()

	print("Grade: ", grade, " | Category: ", selected["type"])

	return {
		"Question": item["Question"],
		"Answer": options.find(item["Answer"]),
		"Type": selected["type"],
		"Options": options
	}



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


# Update to save and load the bookshelf
var data_file_names = [
	"Bookshelf",
	"Inventory",
	"OtherStuff",
	"Quests",
	"Scenes",
	"Grammadex"
]
func save_to_save_slot(num: int):
	var slot_path = "res://Saves/"+str(num)+"/"
	for file_name in data_file_names:
		save_json_file(slot_path+file_name+".json", load_json_file("res://Data/"+file_name+".json"))
func load_slot(num: int):
	var slot_path = "res://Saves/"+str(num)+"/"
	for file_name in data_file_names:
		save_json_file("res://Data/"+file_name+".json", load_json_file(slot_path+file_name+".json"))
func fill_empty_slot(num: int):
	var slot_path = "res://Saves/"+str(num)+"/"
	var inv = {
		"Abilities": [],
		"Items": [],
		"Money": 0.0,
		"Name": "",
		"Party": []
	}
	for i in range(6):
		inv["Party"].append({
			"Health": 0.0,
			"Item": "",
			"Level": 1.0,
			"Moves": [ "", "", "", ""],
			"Name": "",
			"Nickname": "",
			"PP": [ 0, 0, 0, 0 ]
		})
	
	save_json_file(slot_path+"Inventory.json", inv)
	
	var scenes = load_json_file("res://Data/Scenes.json")
	for scene_name in scenes:
		var town = scenes[scene_name]
		if town.has("Items"):
			for item_name in town["Items"]:
				town["Items"][item_name]["Collected"] = false
		
		# Iterate over the values in the Trainers dictionary
		if town.has("Trainers"):
			for trainer_name in town["Trainers"]:
				town["Trainers"][trainer_name]["Talked"] = false
		
		if town.has("Obstacles"):
			for obstacle in town["Obstacles"]:
				town["Obstacles"][obstacle]["Broken"] = false
	save_json_file(slot_path+"Scenes.json", scenes)
	
	
	save_json_file(slot_path+"OtherStuff.json", {"Last Grammarite Center": 0.0})
	
	var quests = []
	var quest_details = load_json_file("res://GrammariteData/Quests.json")
	for i in range(len(quest_details)):
		quests.append({"Progess": "None"})
	save_json_file(slot_path+"Quests.json", quests)
	
	var bookshelf = []
	for i in range(12):
		bookshelf.append({})
	save_json_file(slot_path+"Bookshelf.json", bookshelf)
	
	var dex = []
	for i in range(len(load_json_file("res://GrammariteData/Names.json"))):
		dex.append(false)
	save_json_file(slot_path+"Grammadex.json", dex)
