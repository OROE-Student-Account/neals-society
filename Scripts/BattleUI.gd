extends Node2D

signal move_selected(move_index: int)  # ADD THIS LINE

var pause = false

@export var grammarite_node : Node = null

@onready var switch_screen = preload("res://Scenes/BattleSwitchScene.tscn")
@onready var item_screen = preload("res://Scenes/BattleItemScreen.tscn")

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

var SELECT_ARROW_Y = 7.5
var DISTANCE_BETWEEN_MOVES = 10.5

@onready var info_text = $InfoText

func set_info_text(content):
	info_text.text = content
	info_text.visible = true

func hide_info_text():
	info_text.text = ""
	info_text.visible = false

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
		hide_info_text()
	elif input_state == InputState.MOVE_LIST:
		$Buttons.visible = false
		$MoveList.visible = true
		grammarite_node.update_moves()
		update_arrow_pos()
		hide_info_text()
	elif input_state == InputState.WAITING:
		$Buttons.visible = false
		$MoveList.visible = false

func update_arrow_pos():
	$MoveList/Arrow.position.y = SELECT_ARROW_Y + (selected_button % 4) * DISTANCE_BETWEEN_MOVES



func _ready():
	set_active_option()
	show_correct_menu()
	update_arrow_pos()
	
func stop():
	pause = true
	await get_tree().create_timer(0.1).timeout
	pause = false



func _input(event):
	if pause: return
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
						if get_parent().get_node("BattleManager").trainer == "random":
							Utils.get_scene_manager().transition_exit_battle()	
					Buttons.FIGHT:
						input_state = InputState.MOVE_LIST
						show_correct_menu()
					Buttons.SWITCH:
						input_state = InputState.WAITING
						show_correct_menu()
						get_parent().add_child(switch_screen.instantiate())
					Buttons.ITEM:
						input_state = InputState.WAITING
						show_correct_menu()
						get_parent().add_child(item_screen.instantiate())
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
				
				var party = Utils.get_party()
				if party[0]["PP"][selected_button] <= 0: return
				
				party[0]["PP"][selected_button] -= 1
				Utils.set_party(party)
				input_state = InputState.WAITING
				# emit signal
				move_selected.emit(selected_button) 
				show_correct_menu()
