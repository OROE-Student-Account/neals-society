extends Node2D


var num_of_slots = 7

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
	
	load_party()


func load_party():
	var party = Utils.get_party()
	for i in range(6):
		var slot = options[i].get_parent()
		var slot_data = party[i]
		if slot_data["Name"] == "":
			slot.visible = false
			slots_enabled[i] = false
		else:
			slot.lvl.text = str(int(slot_data["Level"]))
			slot.set_health(Utils.max_hp(slot_data["Name"], slot_data["Level"]), slot_data["Health"])
			slot.set_sprites(Utils.get_poke_num(slot_data["Name"]))
			slots_enabled[i] = true


func exit():
	var UI = get_parent().get_node("BattleUI")
	UI.stop()
	UI.input_state = 0
	UI.show_correct_menu()
	get_parent().get_node("Grammarite").setup()
	queue_free()


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
		if selected_option == Options.CANCEL:
			exit()
		else:
			var party = Utils.get_party()

			var temp = party[0]
			party[0] = party[selected_option]
			party[selected_option] = temp

			Utils.set_party(party)
			exit()
	elif event.is_action_pressed("x"):
		exit()
