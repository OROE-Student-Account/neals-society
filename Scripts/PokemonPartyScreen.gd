extends Node2D

enum Options { FIRST_SLOT, SECOND_SLOT, THIRD_SLOT, FOURTH_SLOT, FIFTH_SLOT, SIXTH_SLOT, CANCEL }
var selected_option: int = Options.FIRST_SLOT

@onready var options: Dictionary = {
	Options.FIRST_SLOT: $FirstPokemonSlot/Background,
	Options.SECOND_SLOT: $SecondPokemonSlot/Background,
	Options.THIRD_SLOT: $ThirdPokemonSlot/Background,
	Options.FOURTH_SLOT: $FourthPokemonSlot/Background,
	Options.FIFTH_SLOT: $FifthPokemonSlot/Background,
	Options.SIXTH_SLOT: $SixthPokemonSlot/Background,
	Options.CANCEL: $CancelSprite,
}

var slots_enabled: Dictionary = {
	Options.FIRST_SLOT: true,
	Options.SECOND_SLOT: true,
	Options.THIRD_SLOT: true,
	Options.FOURTH_SLOT: true,
	Options.FIFTH_SLOT: true,
	Options.SIXTH_SLOT: true,
	Options.CANCEL: true
}

func unset_active_option():
	options[selected_option].frame = 0
	
func set_active_option():
	options[selected_option].frame = 1

func _ready():
	set_active_option()
	
	var party = Utils.get_party()
	for i in range(6):
		var slot = options[i].get_parent()
		var slot_data = party[i]
		if slot_data["Name"] == "":
			slot.visible = false
			slots_enabled[i] = false
		else:
			var max_health = Utils.get_grammarite_details(slot_data["Name"])["Stats"]["Health"]
			slot.lvl.text = str(int(slot_data["Level"]))
			slot.set_health(max_health, slot_data["Health"])
			slot.set_sprites(Utils.get_poke_num(slot_data["Name"]))
			slots_enabled[i] = true
		


func _input(event):
	if event.is_action_pressed("ui_down"):
		unset_active_option()
		selected_option = (selected_option + 1) % 7
		while not slots_enabled[selected_option]:
			selected_option = (selected_option + 1) % 7
		set_active_option()
	elif event.is_action_pressed("ui_up"):
		unset_active_option()
		selected_option = (selected_option + 6) % 7
		while not slots_enabled[selected_option]:
			selected_option = (selected_option + 6) % 7
		set_active_option()
	elif event.is_action_pressed("ui_left"):
		unset_active_option()
		selected_option = 0
		set_active_option()
	elif event.is_action_pressed("ui_right") and selected_option == Options.FIRST_SLOT:
		unset_active_option()
		selected_option = 1
		while not slots_enabled[selected_option]:
			selected_option = (selected_option + 1) % 7
		set_active_option()
	elif event.is_action_pressed("z"):
		match selected_option:
			Options.CANCEL:
				Utils.get_scene_manager().transition_exit_party_screen()	
