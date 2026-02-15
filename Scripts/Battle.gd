extends Node2D


# for the action buttons
enum Buttons { FIGHT, SWITCH, ITEM, RUN }
var selected_button: int = Buttons.FIGHT
@onready var buttons: Dictionary = {
	Buttons.FIGHT: $Buttons/fight,
	Buttons.SWITCH: $Buttons/switchPkmn,
	Buttons.ITEM: $Buttons/item,
	Buttons.RUN: $Buttons/run,
}


func unset_active_option():
	buttons[selected_button].frame = 0

func set_active_option():
	buttons[selected_button].frame = 1

func _ready():
	set_active_option()


func _input(event):
	if event.is_action_pressed("ui_down"):
		unset_active_option()
		if selected_button < 2: selected_button += 2
		set_active_option()
	elif event.is_action_pressed("ui_up"):
		unset_active_option()
		if selected_button > 1: selected_button -= 2
		set_active_option()
	elif event.is_action_pressed("ui_left"):
		unset_active_option()
		if selected_button % 2 != 0: selected_button -= 1
		set_active_option()
	elif event.is_action_pressed("ui_right"):
		unset_active_option()
		if selected_button % 2 == 0: selected_button += 1
		set_active_option()
	elif event.is_action_pressed("z"):
		match selected_button:
			Buttons.RUN:
				Utils.get_scene_manager().transition_exit_battle()	
