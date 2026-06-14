extends CanvasLayer


enum NamingState { TYPING, CONFIRMING }
var naming_state = NamingState.TYPING
var selected_option = 0
var pause = true
var prompt = ""

func _ready():
	$Control.visible = false
	$Transition.color.a = 0

func text_submitted(str: String):
	var entered_text = $Control/LineEdit.text
	if entered_text.strip_edges() != "":  # Only if they entered something
		naming_state = NamingState.CONFIRMING
		$Control/Prompt.text = "Are you sure?"
		$Control/LineEdit.editable = false
		$Control/LineEdit.release_focus()
		selected_option = 0
		update_naming_buttons()

func stop():
	pause = true
	await get_tree().create_timer(0.1).timeout
	pause = false

func load_naming_screen(initial_prompt):
	pause = false
	var menu = Utils.get_scene_manager().get_node("Menu")
	var saved_screen = menu.screen_loaded
	menu.screen_loaded = menu.ScreenLoaded.NAMING
	
	prompt = initial_prompt
	
	naming_state = NamingState.TYPING
	selected_option = 1
	$Transition.color.a = 0
	$Control.visible = true
	
	# Set initial prompt
	$Control/Prompt.text = prompt
	update_naming_buttons()
	$Control/LineEdit.grab_focus()
	$Control/LineEdit.editable = true
	
	var chosen_name = await get_chosen_name()
	
	menu.screen_loaded = saved_screen
	pause = true
	
	queue_free()
	
	return chosen_name

func get_chosen_name() -> String:
	# Wait for the user to finish naming
	while $Control.visible:
		await get_tree().process_frame
	
	return $Control/LineEdit.text

func update_naming_buttons():
	# Update button frames based on selection
	stop()
	if selected_option == 0:
		$Control/Accept.frame = 1  # Selected
		$Control/Accept.get_node("Label").visible = true
		$Control/Cancel.frame = 0  # Unselected
		$Control/Cancel.get_node("Label").visible = false
	else:
		$Control/Accept.frame = 0  # Unselected
		$Control/Accept.get_node("Label").visible = false
		$Control/Cancel.frame = 1  # Selected
		$Control/Cancel.get_node("Label").visible = true
	if naming_state == NamingState.TYPING:
		$Control/Accept.visible = false
		$Control/Cancel.visible = false
	else:
		$Control/Accept.visible = true
		$Control/Cancel.visible = true

func finished_fading():
	$Control.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if pause: return
	match naming_state:
		NamingState.CONFIRMING:
			if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				# Toggle between Accept and Cancel
				selected_option = 1 - selected_option
				update_naming_buttons()
			
			elif event.is_action_pressed("z") and selected_option == 0:
				$AnimationPlayer.play("FadeToBlack")
				
			elif event.is_action_pressed("x") or event.is_action_pressed("z"):
				naming_state = NamingState.TYPING
				$Control/Prompt.text = prompt
				$Control/LineEdit.editable = true
				$Control/LineEdit.grab_focus()
				update_naming_buttons()
