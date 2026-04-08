extends Node2D

enum State { MAIN }
var state = State.MAIN


func fix_party():
	var party = Utils.get_party()
	
	for i in range(6):
		if party[i]["Name"] != "":
			var slot = party[i]
			
			# fill pp
			for j in range(4):
				slot["PP"][j] = Utils.get_move(slot["Moves"][j])["PP"]
			
			slot["Health"] = Utils.max_hp(slot["Name"], slot["Level"])
	
	Utils.set_party(party)


func _unhandled_input(event: InputEvent) -> void:
	match state:
		State.MAIN:
			if  event.is_action_pressed("z"):
				fix_party()
				
			elif event.is_action_pressed("x"):
				# Exit
				Utils.get_scene_manager().transition_exit_menu("Computer")
