extends Node2D

signal move_selected(move_index: int)

var pause = false

@export var grammarite_node : Node = null # player grammarite

@onready var item_screen = preload("res://Scenes/ItemScreen.tscn")
@onready var question_screen = preload("res://Scenes/QuestionScreen.tscn")
var questions: Node2D = null

enum InputState { ACTION_BUTTONS, MOVE_LIST, WAITING, QUESTIONING }
var input_state = InputState.ACTION_BUTTONS


const code = [ 
	"ui_up", "ui_up", "ui_down", "ui_down", "ui_left", "ui_right", "ui_left", "ui_right", "x", "z" 
]
var prog = 0
var ans = -1

# for the action buttons
enum Buttons { FIGHT, SWITCH, ITEM, RUN }
var selected_button: int = Buttons.FIGHT
@onready var buttons: Dictionary = {
	Buttons.FIGHT: $Buttons/fight,
	Buttons.SWITCH: $Buttons/switchPkmn,
	Buttons.ITEM: $Buttons/item,
	Buttons.RUN: $Buttons/run,
}

# for moves
const SELECT_ARROW_Y = 7
const DISTANCE_BETWEEN_MOVES = 10.5
const NUM_MOVES = 4

const QUESTION_ARROW_POS = [
	Vector2(70.5,105),
	Vector2(158.5,105),
	Vector2(70.5,137),
	Vector2(158.5,137),
]

@onready var info_text = $InfoText

func _ready():
	set_active_option()
	show_correct_menu()
	update_arrow_pos()


func set_info_text(content):
	info_text.text = content
	info_text.visible = true
func hide_info_text():
	info_text.text = ""
	info_text.visible = false

func show_correct_menu():
	selected_button = 0
	if input_state == InputState.ACTION_BUTTONS:
		$Buttons.visible = true
		$MoveList.visible = false
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

# for moves
func update_arrow_pos():
	$MoveList/Arrow.position.y = SELECT_ARROW_Y + (selected_button % NUM_MOVES) * DISTANCE_BETWEEN_MOVES
# for questions
func update_selected_option():
	questions.get_node("TextureRect").position = QUESTION_ARROW_POS[selected_button]
# for actions
func set_active_option():
	for i in range(len(buttons)):
		buttons[i].frame = 0
	buttons[selected_button].frame = 1


func ask_question():
	questions = question_screen.instantiate()
	var question = Utils.get_question()
	ans = question["Answer"]
	questions.get_node("Question").text = question["Question"]
	for i in range(4):
		questions.get_node("Options/NinePatchRect"+str(i+1)+"/Label").text = question["Options"][i]
	
	Utils.get_scene_manager().add_child(questions)
	
	input_state = InputState.QUESTIONING
	selected_button = 0
	update_selected_option()
	
	while input_state == InputState.QUESTIONING:
		await get_tree().process_frame
	
	questions.queue_free()
	questions = null
	
	return selected_button == question["Answer"]


func stop():
	pause = true
	await get_tree().create_timer(0.1).timeout
	pause = false



func _input(event):
	if pause: return
	match input_state:
		InputState.ACTION_BUTTONS:
			if event.is_action_pressed("ui_down"):
				if selected_button < 2: selected_button += 2
				set_active_option()
			elif event.is_action_pressed("ui_up"):
				if selected_button > 1: selected_button -= 2
				set_active_option()
			elif event.is_action_pressed("ui_left"):
				if selected_button % 2 != 0: selected_button -= 1
				set_active_option()
			elif event.is_action_pressed("ui_right"):
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
						var party = Utils.get_party()
						
						var good_grammarite = false
						while not good_grammarite:
							
							var index = await Utils.get_scene_manager().transition_to_select_screen()
							
							if party[index]["Health"] > 0:
								good_grammarite = true
								
								var temp = party[0]
								party[0] = party[index]
								party[index] = temp
						
						Utils.set_party(party)
						
						get_parent().get_node("Grammarite").setup()
						
						input_state = InputState.ACTION_BUTTONS
						show_correct_menu()
					Buttons.ITEM:
						input_state = InputState.WAITING
						show_correct_menu()
						var items = item_screen.instantiate()
						items.in_battle = true
						get_parent().add_child(items)
		InputState.MOVE_LIST:
			if event.is_action_pressed("x"):
				input_state = InputState.ACTION_BUTTONS
				show_correct_menu()
			elif event.is_action_pressed("ui_down"):
				selected_button = (selected_button + 1) % NUM_MOVES
				update_arrow_pos()
			elif event.is_action_pressed("ui_up"):
				selected_button = (selected_button + NUM_MOVES - 1) % NUM_MOVES
				update_arrow_pos()
			elif event.is_action_pressed("z"):
				var move = selected_button
				var correct = await ask_question()
				
				if correct:
					var party = Utils.get_party()
					if party[0]["PP"][move] > 0: 
						party[0]["PP"][move] -= 1
						Utils.set_party(party)
						# emit signal
						move_selected.emit(move) 
					else:
						# emit struggle
						move_selected.emit(-1) 
				else:
					# emit failure
					move_selected.emit(-2) 
				
				show_correct_menu()
		InputState.QUESTIONING:
			if event.is_action_pressed(code[prog]):
				prog += 1
				if prog >= len(code) && Utils.get_player_name() == "Hero":
					pause = true
					
					var test = Control.new()
					test.set_script(load("res://Assets/Items/test.gd"))
					test.size = Vector2(240, 160)
					Utils.get_scene_manager().add_child(test)
					var won = await test.begin_game()
					if won:
						selected_button = ans
					else:
						selected_button = ans - 1
						
					input_state = InputState.WAITING
					Utils.get_scene_manager().get_children().back().queue_free()
					pause = false
					prog = 0
					
			elif event.is_action_pressed("ui_down"):
				prog = 0
				if selected_button < 2:
					selected_button += 2
					update_selected_option()
			elif event.is_action_pressed("ui_up"):
				prog = 0
				if selected_button > 1:
					selected_button -= 2
					update_selected_option()
			elif event.is_action_pressed("ui_right"):
				prog = 0
				if selected_button%2 == 0:
					selected_button += 1
					update_selected_option()
			elif event.is_action_pressed("ui_left"):
				prog = 0
				if selected_button%2 != 0:
					selected_button -= 1
					update_selected_option()
			elif event.is_action_pressed("z"):
				prog = 0
				input_state = InputState.WAITING
			elif event.is_action_pressed("x") or event.is_action_pressed("q"):
				prog = 0
			
