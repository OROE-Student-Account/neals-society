extends CanvasLayer


@onready var ninePatch = $Control/NinePatchRect
@onready var box = $Control

var select_arrow: Node = null
var text_label: Node = null  # speaking text
var vbox: Node = null # options container


# Dialogue tree variables
var current_node: Node = null
var dialogue_root: Node = null
var target_node: Node = null  # Node that will receive function calls

signal dialogue_ended()

enum DialogueState { SHOWING_TEXT, SHOWING_OPTIONS }
var dialogue_state = DialogueState.SHOWING_TEXT

enum ScreenLoaded { NOTHING, DIALOGUE }
var screen_loaded = ScreenLoaded.NOTHING

var selected_option: int = 0


const ARROW_Y = [9, 25]


func _ready():
	vbox = ninePatch.get_child(0)
	select_arrow = ninePatch.get_child(1)
	text_label = ninePatch.get_child(2)
	
	box.visible = false
	select_arrow.position.y = 9 + (selected_option % 2) * 16

# starts a dialogue tree
func start_dialogue(root: Node):
	dialogue_root = root
	current_node = root
	target_node = root.func_node
	selected_option = 0
	
	# Disable player
	var player = Utils.get_player()
	player.set_physics_process(false)
	player.anim_tree.active = false
	
	var menu = Utils.get_scene_manager().get_node("Menu")
	menu.screen_loaded = menu.ScreenLoaded.DIALOGUE
	
	$Control/PanelContainer/Name.text = root.get_parent().name
	
	# Display the current node
	display_current_node()

func display_current_node():
	if current_node == null:
		end_dialogue()
		return
	
	current_node.fix_text()


	# if no text, run functions and end
	if current_node.text == "":
		var function = current_node.function
		var tar_node = target_node 
		if current_node.is_end_node:
			dialogue_ended.emit()
		end_dialogue()
		
		# Execute any function associated with this node
		if function != "" and tar_node != null:
			if tar_node.has_method(function):
				tar_node.call(function)
			else:
				print("DialogueManager: Function not found on target node")
		
		return
	
	# Show the text first
	dialogue_state = DialogueState.SHOWING_TEXT
	screen_loaded = ScreenLoaded.DIALOGUE
	
	# Display text from current node
	text_label.text = current_node.text
	text_label.visible = true
	
	# Hide options
	vbox.visible = false
	select_arrow.visible = false
	
	box.visible = true
	

func show_options():
	if current_node == null:
		end_dialogue()
		return
	dialogue_state = DialogueState.SHOWING_OPTIONS
	
	# Hide text
	text_label.visible = false
	
	# Get children (options)
	var children = current_node.get_children_nodes()
	
	# Check if this is an end node
	if current_node.is_end_node or children.size() == 0:
		if current_node.is_end_node:
			dialogue_ended.emit()
		end_dialogue()
		return
	
	
	# Set up the option buttons
	var option1_text = children[0].option_name if children.size() > 0 else ""
	var option2_text = children[1].option_name if children.size() > 1 else ""
	
	vbox.get_child(0).text = option1_text
	vbox.get_child(0).visible = option1_text != ""
	vbox.get_child(1).text = option2_text
	vbox.get_child(1).visible = option2_text != ""
	
	# Show options
	vbox.visible = true
	select_arrow.visible = true
	select_arrow.position.y = 9 + selected_option * 16


# Handles input
func _unhandled_input(event):
	if screen_loaded == ScreenLoaded.DIALOGUE:
		if dialogue_state == DialogueState.SHOWING_TEXT:
			# Waiting for Z to advance to options
			if event.is_action_pressed("z"):
				if current_node.is_end_node:
					var function = current_node.function
					var tar_node = target_node 
					end_dialogue()
					dialogue_ended.emit()
					
					# Execute any function associated with this node
					if function != "" and tar_node != null:
						if tar_node.has_method(function):
							tar_node.call(function)
						else:
							print("DialogueManager: Function not found on target node")
					return
				
				# Execute any function associated with this node
				elif current_node.function != "" and target_node != null:
					if target_node.has_method(current_node.function):
						target_node.call(current_node.function)
					else:
						print("DialogueManager: Function not found on target node")
				
				show_options()
		
		elif dialogue_state == DialogueState.SHOWING_OPTIONS:
			# Handle option selection
			var children = current_node.get_children_nodes() if current_node else []
			var num_options = children.size()
			
			if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
				if num_options > 1:
					selected_option = (selected_option + 1) % 2
					select_arrow.position.y = ARROW_Y[selected_option]
			
			elif event.is_action_pressed("z"):
				# Select the next node and move to that node
				if num_options > selected_option:
					current_node = children[selected_option]
					target_node = current_node.func_node
					selected_option = 0  # Reset option selection for next node
					display_current_node()

func end_dialogue():
	
	box.visible = false
	screen_loaded = ScreenLoaded.NOTHING
	dialogue_state = DialogueState.SHOWING_TEXT
	current_node = null
	dialogue_root = null
	target_node = null
	
	Utils.get_scene_manager().get_node("Menu").screen_loaded = 0
	
	var player = Utils.get_player()
	player.set_physics_process(true)
	player.anim_tree.active = true
