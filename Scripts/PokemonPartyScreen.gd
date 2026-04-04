extends Node2D

var pause = false


enum Page { MAIN, CHOSEN, SUMMARY, ITEM, SWITCH, MOVES }
var page: int = Page.MAIN

var selected_move = 0

var selected_sub_page: int = 0

var num_of_slots = 7

enum Options { FIRST_SLOT, SECOND_SLOT, THIRD_SLOT, FOURTH_SLOT, FIFTH_SLOT, SIXTH_SLOT, CANCEL }
var selected_option: int = Options.FIRST_SLOT

@onready var options: Dictionary = {
	Options.FIRST_SLOT: $FirstPokemonSlot,
	Options.SECOND_SLOT: $SecondPokemonSlot,
	Options.THIRD_SLOT: $ThirdPokemonSlot,
	Options.FOURTH_SLOT: $FourthPokemonSlot,
	Options.FIFTH_SLOT: $FifthPokemonSlot,
	Options.SIXTH_SLOT: $SixthPokemonSlot
}

# SelectBox positions for each slot
var select_box_positions: Dictionary = {
	Options.FIRST_SLOT: Vector2(25, 6),      # Adjust these coordinates to match your layout
	Options.SECOND_SLOT: Vector2(137, 6),
	Options.THIRD_SLOT: Vector2(25, 49),
	Options.FOURTH_SLOT: Vector2(137, 49),
	Options.FIFTH_SLOT: Vector2(25, 92),
	Options.SIXTH_SLOT: Vector2(137, 92),
	Options.CANCEL: Vector2(50, 130),         # does nothing
}

var slots_enabled: Dictionary = {
	Options.FIRST_SLOT: true,
	Options.SECOND_SLOT: true,
	Options.THIRD_SLOT: true,
	Options.FOURTH_SLOT: true,
	Options.FIFTH_SLOT: true,
	Options.SIXTH_SLOT: true,
	Options.CANCEL: true
}

func update_select_box():
	if selected_option == Options.CANCEL:
		$SelectBox.visible = false
		$CancelSprite.frame = 1
	else:
		$CancelSprite.frame = 0
		$SelectBox.visible = true
		$SelectBox.position = select_box_positions[selected_option]

func _ready():
	update_select_box()
	load_party()

func load_party():
	var party = Utils.get_party()
	for i in range(6):
		var slot = options[i]
		var slot_data = party[i]
		if slot_data["Name"] == "":
			slot.visible = false
			slots_enabled[i] = false
			$Covers.get_child(i).visible = true
		else:
			slot.lvl.text = str(int(slot_data["Level"]))
			slot.set_health(Utils.max_hp(slot_data["Name"], slot_data["Level"]), slot_data["Health"])
			slot.set_sprites(Utils.get_poke_num(slot_data["Name"]))
			slots_enabled[i] = true
			$Covers.get_child(i).visible = false

func stop():
	pause = true
	await get_tree().create_timer(0.1).timeout
	pause = false

func load_summary(slot_num):
	self.add_child(load("res://Scenes/SummaryScreen.tscn").instantiate())
	
	var slot_data = Utils.get_party()[slot_num]
	var details = Utils.get_grammarite_details(slot_data["Name"])
	var stats = details["Stats"]
	
	# stats
	var labels = $SummaryScreen/Stats/Labels
	var HP = int(stats["Health"])
	var DEF = int(stats["Defense"])
	var SPD = int(stats["Speed"])
	var ATK = int(stats["Attack"])
	
	labels.get_child(0).text = str(HP)
	labels.get_child(1).text = str(DEF)
	labels.get_child(2).text = str(SPD)
	labels.get_child(3).text = str(ATK)
	
	# do the polygon
	var polygon = $SummaryScreen/Stats/BG/Actual.polygon
	
	# 40 / Max stat
	HP *= 0.2
	polygon[0].x = -HP
	polygon[0].y = -HP
	
	ATK *= 0.2
	polygon[1].x = ATK
	polygon[1].y = -ATK
	
	SPD *= 0.2
	polygon[2].x = SPD
	polygon[2].y = SPD
	
	DEF *= 0.2
	polygon[3].x = -DEF
	polygon[3].y = DEF
	
	$SummaryScreen/Stats/BG/Actual.polygon = polygon
	
	$SummaryScreen/Grammarite.texture = load("res://Assets/Pokemon/Pokemon"+str(1+Utils.get_poke_num(slot_data["Name"]))+".png")
	
	# types
	var info = $SummaryScreen/Info/NinePatchRect
	if len(stats["Types"]) == 1:
		info.get_child(0).get_child(0).visible = false
		info.get_child(1).visible = true
		info.get_child(1).text = str(stats["Types"][0])
	elif len(stats["Types"]) == 2:
		info.get_child(0).get_child(0).visible = true
		info.get_child(1).visible = false
		info.get_child(0).get_child(0).get_child(0).text = str(stats["Types"][0])
		info.get_child(0).get_child(0).get_child(1).text = str(stats["Types"][1])
	
	# LVL and XP
	var lvl = int(slot_data["Level"])
	var xp = int(100 * (slot_data["Level"] - lvl))
	
	info.get_child(2).text = "LVL: "+str(lvl)
	info.get_child(3).text = "XP: "+str(xp)
	
	# name and grammadex num
	info.get_child(4).text = slot_data["Name"]
	info.get_child(5).text = "Grammarite # "+str(Utils.get_poke_num(slot_data["Name"])+1)
	
	# hp
	info.get_child(6).text = "HP: "+str(int(slot_data["Health"]))+" / "+str(int(Utils.max_hp(slot_data["Name"], slot_data["Level"])))
	
	# nickname
	info.get_child(7).text = slot_data["Nickname"]

func update_move_box():
	$MovesScreen/SelectBox.size.y = 15
	$MovesScreen/SelectBox.position.y = 20 + selected_move*16
	if selected_move == 1:
		$MovesScreen/SelectBox.size.y = 14
	elif selected_move > 1:
		$MovesScreen/SelectBox.position.y -= 1
	
	var move_nodes = $MovesScreen/Moves.get_children()
	for i in range(len(move_nodes)):
		var box = move_nodes[i]
		if i != selected_move:
			for j in range(5):
				if j != 0 and j != 3:
					box.get_child(j).visible = false
		else:
			for j in range(5):
				if j != 0 and j != 3:
					box.get_child(j).visible = true

func load_moves(slot_num):
	selected_move = 0
	self.add_child(load("res://Scenes/MovesPartyScreen.tscn").instantiate())
	
	
	var slot_data = Utils.get_party()[slot_num]
	var stats = Utils.get_grammarite_details(slot_data["Name"])["Stats"]
	
	$MovesScreen/Grammarite.texture = load("res://Assets/Pokemon/Pokemon"+str(1+Utils.get_poke_num(slot_data["Name"]))+".png")
	# types
	var info = $MovesScreen/Info
	if len(stats["Types"]) == 1:
		info.get_child(0).get_child(0).visible = false
		info.get_child(1).visible = true
		info.get_child(1).text = str(stats["Types"][0])
	elif len(stats["Types"]) == 2:
		info.get_child(0).get_child(0).visible = true
		info.get_child(1).visible = false
		info.get_child(0).get_child(0).get_child(0).text = str(stats["Types"][0])
		info.get_child(0).get_child(0).get_child(1).text = str(stats["Types"][1])
	
	info.get_child(2).text = slot_data["Name"]
	# nickname
	info.get_child(3).text = slot_data["Nickname"]
	
	
	var moves = []
	
	for i in range(4):
		var move_info = Utils.get_move(slot_data["Moves"][i])
		move_info["Name"] = slot_data["Moves"][i]
		moves.append(move_info)
	
	
	var PP = slot_data["PP"]
	
	var move_nodes = $MovesScreen/Moves.get_children()
	for i in range(len(move_nodes)):
		var box = move_nodes[i]
		box.get_child(0).text = moves[i]["Name"]
		box.get_child(1).text = moves[i]["Type"]
		box.get_child(2).text = str(int(PP[i])) + "/" + str(int(moves[i]["PP"]))
		box.get_child(3).text = str(int(moves[i]["Damage"]))
		box.get_child(4).text = str(int(100 * moves[i]["Accuracy"])) + "%"
	
	update_move_box()

func load_item(slot_num):
	self.add_child(load("res://Scenes/ItemPartyScreen.tscn").instantiate())
	
	var slot_data = Utils.get_party()[slot_num]
	
	if slot_data["Item"] != "":
		var item = Utils.get_item_data(slot_data["Item"])
		
		$ItemPartyScreen/Box/Description.text = item["Description"]
		var file_path = "res://Assets/Items/" + slot_data["Item"] + ".png"
		$ItemPartyScreen/TextureRect.texture = load(file_path)
	else:
		$ItemPartyScreen/Box/Description.text = "No item equipped"
		$ItemPartyScreen/TextureRect.texture = null

func update_page():
	selected_sub_page = 0
	$PageOptions/Arrow.position.y = 6 + (selected_sub_page % 4) * 13
	$SwitchLocation/Arrow.position.y = 6 + (selected_sub_page % num_of_slots) * 13
	
	if has_node("SummaryScreen"):
		$SummaryScreen.queue_free()
	if has_node("MovesScreen"):
		$MovesScreen.queue_free()
	if has_node("ItemPartyScreen"):
		$ItemPartyScreen.queue_free()
	
	match page:
		Page.MAIN:
			$NinePatchRect/InfoText.text = "Choose a Grammarite."
			$PageOptions.visible = false
			$SwitchLocation.visible = false
		Page.CHOSEN:
			$NinePatchRect/InfoText.text = "Do what with this Grammarite?"
			$PageOptions.visible = true
			$SwitchLocation.visible = false
		Page.SUMMARY:
			$PageOptions.visible = false
			load_summary(selected_option)
		Page.MOVES:
			$PageOptions.visible = false
			load_moves(selected_option)
		Page.ITEM:
			$PageOptions.visible = false
			load_item(selected_option)
		Page.SWITCH:
			$NinePatchRect/InfoText.text = "Put this Grammarite where?"
			$PageOptions.visible = false
			$SwitchLocation.visible = true
			
			var children = $SwitchLocation/VBoxContainer.get_children()
			var count = 0
			for i in range(len(children)):
				if slots_enabled[i]:
					children[i].visible = true
					count += 1
				else:
					children[i].visible = false
			num_of_slots = count
			
			$SwitchLocation.position.y = 54 + 13 * (7 - count)
			$SwitchLocation.size.y = 100 - 13 * (7 - count)

func _input(event):
	if pause: return
	match page:
		Page.MAIN:
			if event.is_action_pressed("ui_down"):
				if selected_option == Options.CANCEL:
					# Already at bottom, do nothing
					pass
				elif selected_option == Options.FIFTH_SLOT or selected_option == Options.SIXTH_SLOT:
					# From bottom row, go to cancel
					selected_option = Options.CANCEL
				else:
					# Move down two slots (to next row)
					var next_option = selected_option + 2
					if next_option <= Options.SIXTH_SLOT:
						selected_option = next_option
						# Skip if not enabled
						while not slots_enabled[selected_option] and selected_option <= Options.SIXTH_SLOT:
							selected_option += 2
							if selected_option > Options.SIXTH_SLOT:
								selected_option = Options.CANCEL
								break
				update_select_box()
				
			elif event.is_action_pressed("ui_up"):
				if selected_option == Options.CANCEL:
					# From cancel, go to bottom row
					# Try to go to the same column we came from, or just go to FIFTH_SLOT
					selected_option = Options.FIFTH_SLOT
					while not slots_enabled[selected_option] and selected_option < Options.CANCEL:
						selected_option -= 1
						if selected_option == Options.CANCEL:
							selected_option = Options.FIRST_SLOT
							break
				elif selected_option >= Options.FIRST_SLOT and selected_option <= Options.SIXTH_SLOT:
					# Move up two slots (to previous row)
					var prev_option = selected_option - 2
					if prev_option >= Options.FIRST_SLOT:
						selected_option = prev_option
						# Skip if not enabled
						while not slots_enabled[selected_option] and selected_option >= Options.FIRST_SLOT:
							selected_option -= 2
							if selected_option < Options.FIRST_SLOT:
								# Wrap around or stay
								selected_option += 2
								break
				update_select_box()
				
			elif event.is_action_pressed("ui_left"):
				if selected_option == Options.CANCEL:
					# Cancel has no left movement
					pass
				elif selected_option % 2 == 1:  # Right column (odd indices: 1, 3, 5)
					# Move to left column
					selected_option -= 1
					# Skip if not enabled
					while not slots_enabled[selected_option] and selected_option >= Options.FIRST_SLOT:
						selected_option -= 2
						if selected_option < Options.FIRST_SLOT:
							selected_option += 1  # Go back
							break
					update_select_box()
				# If already in left column (even indices: 0, 2, 4), do nothing
			
			elif event.is_action_pressed("ui_right"):
				if selected_option == Options.CANCEL:
					# Cancel has no right movement
					pass
				elif selected_option % 2 == 0:  # Left column (even indices: 0, 2, 4)
					# Move to right column
					selected_option += 1
					# Skip if not enabled
					while not slots_enabled[selected_option] and selected_option <= Options.SIXTH_SLOT:
						selected_option += 2
						if selected_option > Options.SIXTH_SLOT:
							selected_option -= 1  # Go back
							break
					update_select_box()
				# If already in right column (odd indices: 1, 3, 5), do nothing
			
			elif event.is_action_pressed("z"):
				if selected_option == Options.CANCEL:
					Utils.get_scene_manager().transition_exit_party_screen()
				else:
					page = Page.CHOSEN
					update_page()
			
			elif event.is_action_pressed("x"):
				Utils.get_scene_manager().transition_exit_party_screen()
		Page.CHOSEN:
			if event.is_action_pressed("x") or (event.is_action_pressed("z") and selected_sub_page == 3):
				page = Page.MAIN
				update_page()
				stop()
				
			elif event.is_action_pressed("ui_down"):
				selected_sub_page =  (selected_sub_page + 1) % 4
				$PageOptions/Arrow.position.y = 6 + (selected_sub_page % 4) * 13
				
			elif event.is_action_pressed("ui_up"):
				selected_sub_page =  (selected_sub_page + 3) % 4
				$PageOptions/Arrow.position.y = 6 + (selected_sub_page % 4) * 13
			elif event.is_action_pressed("z"):
				if selected_sub_page == 0:
					page = Page.SUMMARY
					update_page()
				elif selected_sub_page == 1:
					page = Page.SWITCH
					update_page()
				elif selected_sub_page == 2:
					page = Page.ITEM
					update_page()
		Page.SUMMARY:
			if event.is_action_pressed("x"):
				page = Page.CHOSEN
				update_page()
				stop()
			elif event.is_action_pressed("z"):
				page = Page.MOVES
				update_page()
		Page.MOVES:
			if event.is_action_pressed("x"):
				page = Page.CHOSEN
				update_page()
				stop()
			elif event.is_action_pressed("z"):
				page = Page.SUMMARY
				update_page()
			elif event.is_action_pressed("ui_up") and selected_move != 0:
				selected_move -= 1
				update_move_box()
			elif event.is_action_pressed("ui_down") and selected_move != 3:
				selected_move += 1
				update_move_box()
		Page.ITEM:
			if event.is_action_pressed("x"):
				page = Page.CHOSEN
				update_page()
				stop()
			elif event.is_action_pressed("z"):
				Utils.get_scene_manager().transition_to_item_screen()
		Page.SWITCH:
			if event.is_action_pressed("x") or (event.is_action_pressed("z") and selected_sub_page == num_of_slots - 1):
				page = Page.CHOSEN
				update_page()
				stop()
			elif event.is_action_pressed("ui_down"):
				selected_sub_page =  (selected_sub_page + 1) % num_of_slots
				$SwitchLocation/Arrow.position.y = 6 + (selected_sub_page % num_of_slots) * 13
			elif event.is_action_pressed("ui_up"):
				selected_sub_page =  (selected_sub_page + num_of_slots - 1) % num_of_slots
				$SwitchLocation/Arrow.position.y = 6 + (selected_sub_page % num_of_slots) * 13
			elif event.is_action_pressed("z"):
				var party = Utils.get_party()
				
				var temp = party[selected_option]
				party[selected_option] = party[selected_sub_page]
				party[selected_sub_page] = temp
				
				Utils.set_party(party)
				
				load_party()
				
				page = Page.MAIN
				update_page()
