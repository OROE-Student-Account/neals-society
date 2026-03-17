extends CanvasLayer


enum NamingState { TYPING, CONFIRMING }
var naming_state = NamingState.TYPING
var selected_option = 0
var pause = false

func _ready():
	visible = false

func stop():
	pause = true
	await get_tree().create_timer(0.1).timeout
	pause = false

func load_naming_screen():
	naming_state = NamingState.TYPING
	selected_option = 1
	$Transition.color = Color(1,1,1,0)
	visible = true
	
	# Set initial prompt
	$Prompt.text = "What should your name be?"
	
	update_naming_buttons()
	
	# Focus on text input
	$LineEdit.grab_focus()
	
	var chosen_name = await get_chosen_name()
	
	return chosen_name

func get_chosen_name() -> String:
	# Wait for the user to finish naming
	while visible:
		await get_tree().process_frame
	
	return $LineEdit.text

func update_naming_buttons():
	# Update button frames based on selection
	stop()
	if selected_option == 0:
		$Accept.frame = 1  # Selected
		$Cancel.frame = 0  # Unselected
	else:
		$Accept.frame = 0  # Unselected
		$Cancel.frame = 1  # Selected
	if naming_state == NamingState.TYPING:
		$Accept.visible = false
		$Cancel.visible = false
	else:
		$Accept.visible = true
		$Cancel.visible = true

func finished_fading():
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if pause: return
	match naming_state:
		NamingState.TYPING:
			if event.is_action_pressed("enter") or event.is_action_pressed("z") or event.is_action_pressed("x"):
				# User pressed Enter or Z - move to confirmation
				var entered_text = $LineEdit.text
				if entered_text.strip_edges() != "":  # Only if they entered something
					naming_state = NamingState.CONFIRMING
					$Prompt.text = "Are you sure?"
					$LineEdit.editable = false
					$LineEdit.release_focus()
					selected_option = 0
					update_naming_buttons()
		
		NamingState.CONFIRMING:
			if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				# Toggle between Accept and Cancel
				selected_option = 1 - selected_option
				update_naming_buttons()
			
			elif event.is_action_pressed("z") and selected_option == 0:
				$AnimationPlayer.play("FadeToBlack")
				
			elif event.is_action_pressed("x") or event.is_action_pressed("z"):
				naming_state = NamingState.TYPING
				$Prompt.text = "What should your name be?"
				$LineEdit.editable = true
				$LineEdit.grab_focus()
				update_naming_buttons()
