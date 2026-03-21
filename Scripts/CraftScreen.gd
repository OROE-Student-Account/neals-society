extends Node2D

enum Page { MAIN, SWITCH }
var page = Page.MAIN

enum Options { SWITCH1, SWITCH2, CANCEL }
var selected_option = 0

@onready var buttons = $Buttons
@onready var shard_select = $ShardSelect


var types = [
	"Grammar",
	"Literature",
	"Homework",
	"Slang",
	"Paper",
	"Nature",
	"Supply",
	"Knowledge",
	"Ink",
	"Animal",
	"Machine"
]

var border_positions = [
	Vector2(64,48),
	Vector2(96,48),
	Vector2(128,48),
	Vector2(160,48),
	Vector2(80,80),
	Vector2(112,80),
	Vector2(144,80),
	Vector2(64,112),
	Vector2(96,112),
	Vector2(128,112),
	Vector2(160,112)
]


func _ready() -> void:
	update_buttons()
	update_screen()



func update_screen():
	match page:
		Page.MAIN:
			shard_select.visible = false
		Page.SWITCH:
			shard_select.visible = true

func update_buttons():
	match page:
		Page.MAIN:
			for butt in buttons.get_children():
				butt.frame = 0
			buttons.get_child(selected_option).frame = 1
		Page.SWITCH:
			shard_select.get_node("Border").position = border_positions[selected_option]


func _input(event):
	match page:
		Page.MAIN:
			if event.is_action_pressed("ui_up"):
				if selected_option == Options.CANCEL:
					selected_option = Options.SWITCH2
				update_buttons()
				
			elif event.is_action_pressed("ui_down"):
				selected_option = Options.CANCEL
				update_buttons()
				
			elif event.is_action_pressed("ui_right"):
				if selected_option == Options.SWITCH1:
					selected_option = Options.SWITCH2
				update_buttons()
				
			elif event.is_action_pressed("ui_right"):
				if selected_option == Options.SWITCH2:
					selected_option = Options.SWITCH1
				update_buttons()
				
			elif event.is_action_pressed("x") or (event.is_action_pressed("z") and selected_option == Options.CANCEL):
				Utils.get_scene_manager().transition_exit_crafter()
				
			elif event.is_action_pressed("z"):
				if selected_option == Options.SWITCH1:
					page = Page.SWITCH
					selected_option = 0
					update_screen()
					update_buttons()
				elif selected_option == Options.SWITCH2:
					page = Page.SWITCH
					selected_option = 0
					update_screen()
					update_buttons()
		Page.SWITCH:
			if event.is_action_pressed("ui_up"):
				if selected_option > 7:
					selected_option -= 4
				elif selected_option > 3:
					selected_option -= 3
				update_buttons()
				
			elif event.is_action_pressed("ui_down"):
				if selected_option < 3:
					selected_option += 4
				elif selected_option < 7:
					selected_option += 3
				update_buttons()
				
			elif event.is_action_pressed("ui_right"):
				if selected_option != 3 and selected_option != 6 and selected_option != 10:
					selected_option += 1
				update_buttons()
				
			elif event.is_action_pressed("ui_left"):
				if selected_option != 0 and selected_option != 4 and selected_option != 7:
					selected_option -= 1
				update_buttons()
