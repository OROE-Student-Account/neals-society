extends CanvasLayer


@onready var ninePatch = $Control/NinePatchRect
@onready var box = $Control

var select_arrow: Node = null
var text_label: Node = null  # speaking text
var vbox: Node = null # options container


# Dialogue tree variables
var current_node: DialogueNode = null
var dialogue_root: DialogueNode = null
var target_node: Node = null  # Node that will receive function calls


enum DialogueState { SHOWING_TEXT, SHOWING_OPTIONS }
var dialogue_state = DialogueState.SHOWING_TEXT

enum ScreenLoaded { NOTHING, DIALOGUE }
var screen_loaded = ScreenLoaded.NOTHING

var selected_option: int = 0

func _ready():
	vbox = ninePatch.get_child(0)
	select_arrow = ninePatch.get_child(1)
	text_label = ninePatch.get_child(2)
	
	box.visible = false
	select_arrow.position.y = 9 + (selected_option % 2) * 16

# starts a dialogue tree
func start_dialogue(root, function_target: Node = null):
	dialogue_root = root
	current_node = root
	target_node = function_target
	selected_option = 0
	
	# Disable player
	var player = Utils.get_player()
	player.set_physics_process(false)
	player.anim_tree.active = false
	
	# Display the current node
	display_current_node()

func display_current_node():
	if current_node == null:
		end_dialogue()
		return
	
	# Execute any function associated with this node
	if current_node.function != "" and target_node != null:
		if target_node.has_method(current_node.function):
			target_node.call(current_node.function)
		else:
			push_warning("DialogueManager: Function '%s' not found on target node" % current_node.function)
	
	# Show the text first
	show_text()

func show_text():
	if current_node.text == "":
		end_dialogue()
		return
	
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
	dialogue_state = DialogueState.SHOWING_OPTIONS
	
	# Hide text
	text_label.visible = false
	
	# Check if this is an end node
	if current_node.is_end_node:
		end_dialogue()
		return
	
	# Get children (options)
	var children = current_node.get_children_nodes()
	
	if children.size() == 0:
		# No children treat as end
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
				show_options()
		
		elif dialogue_state == DialogueState.SHOWING_OPTIONS:
			# Handle option selection
			var children = current_node.get_children_nodes() if current_node else []
			var num_options = children.size()
			
			if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
				if num_options > 1:
					selected_option = (selected_option % 2 + 1) % 2
					select_arrow.position.y = 9 + selected_option * 16
			
			elif event.is_action_pressed("z"):
				# Select the next node and move to that node
				if num_options > selected_option:
					current_node = children[selected_option]
					selected_option = 0  # Reset option selection for next node
					display_current_node()

func end_dialogue():
	box.visible = false
	screen_loaded = ScreenLoaded.NOTHING
	dialogue_state = DialogueState.SHOWING_TEXT
	current_node = null
	dialogue_root = null
	
	var player = Utils.get_player()
	player.set_physics_process(true)
	player.anim_tree.active = true
