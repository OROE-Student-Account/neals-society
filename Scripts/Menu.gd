extends CanvasLayer

const Screens: Dictionary = {
	"Party": preload("res://Scenes/PartyScreen.tscn"),
	"Item": preload("res://Scenes/ItemScreen.tscn"),
	"Save": preload("res://Scenes/SaveScreen.tscn"),
	
	"Computer": preload("res://Scenes/ComputerScreen.tscn"),
	"Quest": preload("res://Scenes/QuestScreen.tscn"),
	"Harvester": preload("res://Scenes/HarvesterScreen.tscn"),
	"Crafter":  preload("res://Scenes/CrafterScreen.tscn"),
	"Bookshelf": preload("res://Scenes/BookshelfScreen.tscn"),
}



@onready var arrow = $Control/Arrow 
@onready var menu = $Control

enum ScreenLoaded { NOTHING, DIALOGUE, JUST_MENU, MENU_SUBSCREEN, SUBSCREEN, NAMING, BATTLE }
var screen_loaded = ScreenLoaded.NOTHING
var selected_option: int = 0

var pausing = false

# SelectBox positions for 2x3 grid (adjust these to match your layout)
var select_box_positions: Array[Vector2] = [
	Vector2(80, 62),   # Option 0 (top-left)
	Vector2(146, 63),   # Option 1 (top-right)
	Vector2(80, 80),   # Option 2 (middle-left)
	Vector2(146, 80),   # Option 3 (middle-right)
	Vector2(80, 97),   # Option 4 (bottom-left)
	Vector2(146, 97),   # Option 5 (bottom-right)
]

signal open_menu
signal close_menu


func _ready():
	menu.visible = false
	update_select_box()

func transition():
	pausing = true
	await get_tree().create_timer(2.0).timeout
	pausing = false

func load_submenu(submenu: String): 
	var screen = Screens[submenu].instantiate()
	
	match submenu:
		# Menu Subscreens
		"Computer", "Party", "Item", "Save":
			menu.visible = false
			screen_loaded = ScreenLoaded.MENU_SUBSCREEN
			if submenu == "Item":
				screen.in_battle = false
		
		# Other Menus
		"Quest", "Bookshelf", "Harvester", "Crafter":
			screen_loaded = ScreenLoaded.SUBSCREEN
	
	add_child(screen)

func unload_submenu(submenu: String): 
	emit_signal("close_menu")
	match submenu:
		# Menu Subscreens
		"Computer", "Party", "Item", "Save":
			menu.visible = true
			screen_loaded = ScreenLoaded.JUST_MENU
		
		# Other Menus
		"Quest", "Bookshelf", "Harvester", "Crafter":
			screen_loaded = ScreenLoaded.NOTHING
	
	var node = get_node_or_null(submenu+"Screen")
	if node:
		remove_child(node)

func unload_submenus(from_menu: bool):
	emit_signal("close_menu")
	var names = []
	if from_menu:
		menu.visible = true
		screen_loaded = ScreenLoaded.JUST_MENU
		names = ["Computer", "Party", "Item", "Save"]
	else:
		screen_loaded = ScreenLoaded.NOTHING
		names = ["Quest", "Bookshelf", "Harvester", "Crafter"]
	for i in names:
		var node = get_node_or_null(i+"Screen")
		if node: 
			remove_child(node)


func update_select_box():
	arrow.position = select_box_positions[selected_option]



func _unhandled_input(event):
	match screen_loaded:
		ScreenLoaded.NOTHING:
			if event.is_action_pressed("menu"):
				pausing = false
				var player = Utils.get_player()
				if not player.is_moving:
					player.set_physics_process(false)
					menu.visible = true
					screen_loaded = ScreenLoaded.JUST_MENU
					emit_signal("open_menu")
		
		ScreenLoaded.JUST_MENU:
			if event.is_action_pressed("menu") or event.is_action_pressed("x") or (event.is_action_pressed("z") and selected_option == 5):
				if not pausing:
					selected_option = 0
					update_select_box()
					var player = Utils.get_player()
					player.set_physics_process(true)
					player.player_state = player.PlayerState.IDLE
					menu.visible = false
					screen_loaded = ScreenLoaded.NOTHING
			
			elif event.is_action_pressed("ui_down"):
				# Move down 2 positions (next row)
				if selected_option <= 3:  # Not in bottom row (0-3)
					selected_option += 2
					update_select_box()
			
			elif event.is_action_pressed("ui_up"):
				# Move up 2 positions (previous row)
				if selected_option >= 2:  # Not in top row (2-5)
					selected_option -= 2
					update_select_box()
			
			elif event.is_action_pressed("ui_left"):
				# Move left only if in right column (odd indices: 1, 3, 5)
				if selected_option % 2 == 1:
					selected_option -= 1
					update_select_box()
			
			elif event.is_action_pressed("ui_right"):
				# Move right only if in left column (even indices: 0, 2, 4)
				if selected_option % 2 == 0:
					selected_option += 1
					update_select_box()
			
			elif event.is_action_pressed("z"):
				transition()
				match selected_option:
					0:
						Utils.get_scene_manager().transition_to_menu("Party")
					1:
						pass
					2:
						Utils.get_scene_manager().transition_to_menu("Item")
					3:
						Utils.get_scene_manager().transition_to_menu("Save")
					4:
						Utils.get_scene_manager().transition_to_menu("Computer")
					5:
						# Close menu (already handled above)
						pass
