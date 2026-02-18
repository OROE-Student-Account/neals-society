extends Node2D

var pause = false


enum Page { MAIN, CHOSEN, SUMMARY }
var page: int = Page.MAIN

var selected_sub_page: int = 0

enum Options { FIRST_SLOT, SECOND_SLOT, THIRD_SLOT, FOURTH_SLOT, FIFTH_SLOT, SIXTH_SLOT, CANCEL }
var selected_option: int = Options.FIRST_SLOT

@onready var options: Dictionary = {
	Options.FIRST_SLOT: $FirstPokemonSlot/Background,
	Options.SECOND_SLOT: $SecondPokemonSlot/Background,
	Options.THIRD_SLOT: $ThirdPokemonSlot/Background,
	Options.FOURTH_SLOT: $FourthPokemonSlot/Background,
	Options.FIFTH_SLOT: $FifthPokemonSlot/Background,
	Options.SIXTH_SLOT: $SixthPokemonSlot/Background,
	Options.CANCEL: $CancelSprite,
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

func unset_active_option():
	options[selected_option].frame = 0
	
func set_active_option():
	options[selected_option].frame = 1

func _ready():
	set_active_option()
	
	var party = Utils.get_party()
	for i in range(6):
		var slot = options[i].get_parent()
		var slot_data = party[i]
		if slot_data["Name"] == "":
			slot.visible = false
			slots_enabled[i] = false
		else:
			var max_health = Utils.get_grammarite_details(slot_data["Name"])["Stats"]["Health"]
			slot.lvl.text = str(int(slot_data["Level"]))
			slot.set_health(max_health, slot_data["Health"])
			slot.set_sprites(Utils.get_poke_num(slot_data["Name"]))
			slots_enabled[i] = true


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
	
	labels.get_child(0).get_child(1).text = str(HP)
	labels.get_child(1).get_child(1).text = str(DEF)
	labels.get_child(2).get_child(1).text = str(SPD)
	labels.get_child(3).get_child(1).text = str(ATK)
	
	# do the polygon
	var polygon = $SummaryScreen/Stats/BG/Actual.polygon
	
	# 32 / Max stat
	HP *= 0.32
	polygon[0].x = -HP
	polygon[0].y = -HP
	
	DEF *= 3.2
	polygon[1].x = DEF
	polygon[1].y = -DEF
	
	ATK *= 0.32
	polygon[2].x = ATK
	polygon[2].y = ATK
	
	SPD *= 3.2
	polygon[3].x = -SPD
	polygon[3].y = SPD
	
	$SummaryScreen/Stats/BG/Actual.polygon = polygon
	
	
	
	# types
	var info = $SummaryScreen/Info/NinePatchRect
	if len(stats["Types"]) == 1:
		info.get_child(0).text = "Type:"
		info.get_child(0).get_child(0).visible = false
		info.get_child(1).visible = true
		info.get_child(1).text = str(stats["Types"][0])
	elif len(stats["Types"]) == 2:
		info.get_child(0).text = "Types:"
		info.get_child(0).get_child(0).visible = true
		info.get_child(1).visible = false
		info.get_child(0).get_child(0).get_child(0).text = str(stats["Types"][0])
		info.get_child(0).get_child(0).get_child(1).text = str(stats["Types"][1])
	
	
	# LVL and XP
	var lvl = int(slot_data["Level"])
	var exp = int(100 * (slot_data["Level"] - lvl))
	
	info.get_child(2).text = "LVL: "+str(lvl)
	info.get_child(3).text = "XP: "+str(exp)
	
	# name and grammadex num
	info.get_child(4).text = slot_data["Name"]
	info.get_child(5).text = "DEX #: "+str(Utils.get_poke_num(slot_data["Name"])+1)


func update_page():
	selected_sub_page = 0
	$PageOptions/Arrow.position.y = 6 + (selected_sub_page % 5) * 13
	
	if $SummaryScreen:
		$SummaryScreen.queue_free()
	
	match page:
		Page.MAIN:
			$InfoText.text = "Choose a Grammarite."
			$PageOptions.visible = false
		Page.CHOSEN:
			$InfoText.text = "Do what with this Grammarite?"
			$PageOptions.visible = true
		Page.SUMMARY:
			$PageOptions.visible = false
			load_summary(selected_option)



func _input(event):
	if pause: return
	match page:
		Page.MAIN:
			if event.is_action_pressed("ui_down"):
				unset_active_option()
				selected_option = (selected_option + 1) % 7
				while not slots_enabled[selected_option]:
					selected_option = (selected_option + 1) % 7
				set_active_option()
			elif event.is_action_pressed("ui_up"):
				unset_active_option()
				selected_option = (selected_option + 6) % 7
				while not slots_enabled[selected_option]:
					selected_option = (selected_option + 6) % 7
				set_active_option()
			elif event.is_action_pressed("ui_left"):
				unset_active_option()
				selected_option = 0
				set_active_option()
			elif event.is_action_pressed("ui_right") and selected_option == Options.FIRST_SLOT:
				unset_active_option()
				selected_option = 1
				while not slots_enabled[selected_option]:
					selected_option = (selected_option + 1) % 7
				set_active_option()
			elif event.is_action_pressed("z"):
				if selected_option == Options.CANCEL:
					Utils.get_scene_manager().transition_exit_party_screen()
				else:
					page = Page.CHOSEN
					update_page()
			elif event.is_action_pressed("x"):
				Utils.get_scene_manager().transition_exit_party_screen()
		Page.CHOSEN:
			if event.is_action_pressed("x") or (event.is_action_pressed("z") and selected_sub_page == 4):
				page = Page.MAIN
				update_page()
				stop()
				
			elif event.is_action_pressed("ui_down"):
				selected_sub_page =  (selected_sub_page + 1) % 5
				$PageOptions/Arrow.position.y = 6 + (selected_sub_page % 5) * 13
				
			elif event.is_action_pressed("ui_up"):
				selected_sub_page =  (selected_sub_page + 4) % 5
				$PageOptions/Arrow.position.y = 6 + (selected_sub_page % 5) * 13
			elif event.is_action_pressed("z") and selected_sub_page == 0:
				page = Page.SUMMARY
				update_page()
		Page.SUMMARY:
			if event.is_action_pressed("x"):
				page = Page.CHOSEN
				update_page()
				stop()
