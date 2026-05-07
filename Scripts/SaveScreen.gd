extends Node2D


enum Options { MODE, SLOT1, SLOT2, SLOT3, CANCEL }
var selected_option = Options.SLOT1

enum Modes { SAVE, LOAD, CLEAR }
var mode = Modes.SAVE

func _ready():
	select_button()
	set_mode()
	load_slots()

func load_slots():
	for i in range(3):
		var player_name = Utils.get_player_name(i+1)
		if player_name != "":
			$Slots.get_child(i).get_node("Name").text = player_name
		else:
			$Slots.get_child(i).get_node("Name").text = "Empty" 

func set_mode():
	match mode:
		Modes.SAVE:
			$Text.text = "Saving Mode"
		Modes.LOAD:
			$Text.text = "Loading Mode"
		Modes.CLEAR:
			$Text.text = "Delete File"

func select_button():
	$Cancel.frame = 0
	$Mode.frame = 0
	$Mode/Text.visible = false
	$Arrow.visible = false
	if selected_option == Options.CANCEL:
		$Cancel.frame = 1
	elif selected_option == Options.MODE:
		$Mode.frame = 1
		$Mode/Text.visible = true
	else:
		$Arrow.visible = true
		$Arrow.position.x = -14 + 64 * selected_option


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("x") or (selected_option == Options.CANCEL and event.is_action_pressed("z")):
		Utils.get_scene_manager().transition_exit_menu("Save")
	
	elif event.is_action_pressed("ui_down"):
		if selected_option == Options.SLOT3:
			selected_option = Options.CANCEL
		elif selected_option == Options.SLOT1:
			selected_option = Options.MODE
		select_button()
	
	elif event.is_action_pressed("ui_up"):
		if selected_option == Options.CANCEL:
			selected_option = Options.SLOT3
		elif selected_option == Options.MODE:
			selected_option = Options.SLOT1
		select_button()
	
	elif event.is_action_pressed("ui_right") and selected_option != Options.CANCEL:
		selected_option += 1
		select_button()
	
	elif event.is_action_pressed("ui_left") and selected_option != Options.MODE:
		selected_option -= 1
		select_button()
	
	elif event.is_action_pressed("z"):
		
		if selected_option == Options.MODE:
			match mode:
				Modes.SAVE:
					mode = Modes.LOAD
				Modes.LOAD:
					mode = Modes.CLEAR
				Modes.CLEAR:
					mode = Modes.SAVE
			set_mode()
		else:
			match mode:
				Modes.SAVE:
					Utils.save_to_save_slot(selected_option)
				Modes.LOAD:
					Utils.load_slot(selected_option)
					Utils.get_scene_manager().transition_exit_save_screen()
				Modes.CLEAR:
					Utils.fill_empty_slot(selected_option)
			load_slots()
