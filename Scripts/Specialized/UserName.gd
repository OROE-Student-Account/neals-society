extends Control

@onready var line_edit = $LineEdit
@export var anim_player : AnimationPlayer = null
@export var particles : Node2D = null

func _ready():
	# Ensure the UI starts hidden
	visible = false
	
	# Automatically connect the LineEdit's built-in Enter-key signal
	line_edit.text_submitted.connect(_on_text_submitted)


# 1. The requested test function to show the UI and grab focus
func test():
	visible = true
	line_edit.text = "" # Clear any old text
	line_edit.editable = true
	
	var player = Utils.get_player()
	player.set_physics_process(false)
	
	Utils.get_scene_manager().menu.screen_loaded = Utils.get_scene_manager().menu.ScreenLoaded.NAMING
	
	# Force the game to focus on the text box so the player can type immediately
	line_edit.grab_focus()


# 2. This triggers automatically when the player presses 'Enter' inside the LineEdit
func _on_text_submitted(new_text: String):
	# Clean up any accidental spaces at the start or end
	var final_text = new_text.strip_edges()
	
	# Only proceed if they actually typed something
	if final_text != "":
		# Run your target function
		on_name_confirmed(final_text)
		
		# Hide the UI and release focus so player input goes back to the game
		visible = false
		line_edit.editable = false
		line_edit.release_focus()
		var player = Utils.get_player()
		player.set_physics_process(true)
		player.player_state = player.PlayerState.IDLE
		Utils.get_scene_manager().menu.screen_loaded = Utils.get_scene_manager().menu.ScreenLoaded.NOTHING


# 3. The "other function" that runs after confirmation
func on_name_confirmed(chosen_name: String):
	
	Utils.set_player_name(chosen_name)
	anim_player.play("sleep")
	particles.position = Utils.get_player().position
	# Put whatever logic you need to happen next right here!
