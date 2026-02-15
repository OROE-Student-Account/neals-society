extends Node2D

signal move_selected(move_index: int)  # ADD THIS LINE

@export var grammarite_node : Node = null

enum InputState { ACTION_BUTTONS, MOVE_LIST, WAITING }
var input_state = InputState.ACTION_BUTTONS

# for the action buttons
enum Buttons { FIGHT, SWITCH, ITEM, RUN }
var selected_button: int = Buttons.FIGHT
@onready var buttons: Dictionary = {
	Buttons.FIGHT: $Buttons/fight,
	Buttons.SWITCH: $Buttons/switchPkmn,
	Buttons.ITEM: $Buttons/item,
	Buttons.RUN: $Buttons/run,
}

var SELECT_ARROW_Y = 7
var DISTANCE_BETWEEN_MOVES = 11



func unset_active_option():
	for i in range(len(buttons)):
		buttons[i].frame = 0

func set_active_option():
	buttons[selected_button].frame = 1

func show_correct_menu():
	selected_button = 0
	if input_state == InputState.ACTION_BUTTONS:
		$Buttons.visible = true
		$MoveList.visible = false
		unset_active_option()
		set_active_option()
	elif input_state == InputState.MOVE_LIST:
		$Buttons.visible = false
		$MoveList.visible = true
		grammarite_node.update_moves()
		update_arrow_pos()
	elif input_state == InputState.WAITING:
		$Buttons.visible = false
		$MoveList.visible = false

func update_arrow_pos():
	$MoveList/Arrow.position.y = SELECT_ARROW_Y + (selected_button % 4) * DISTANCE_BETWEEN_MOVES



func _ready():
	set_active_option()
	show_correct_menu()
	update_arrow_pos()


func _input(event):
	match input_state:
		InputState.ACTION_BUTTONS:
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
					Buttons.FIGHT:
						input_state = InputState.MOVE_LIST
						show_correct_menu()

		InputState.MOVE_LIST:
			if event.is_action_pressed("x"):
				input_state = InputState.ACTION_BUTTONS
				show_correct_menu()
			elif event.is_action_pressed("ui_down"):
				selected_button = (selected_button + 1) % 4
				update_arrow_pos()
			elif event.is_action_pressed("ui_up"):
				selected_button = (selected_button + 3) % 4
				update_arrow_pos()
			elif event.is_action_pressed("z"):
				# emit signal
				input_state = InputState.WAITING
				move_selected.emit(selected_button) 
				show_correct_menu()
