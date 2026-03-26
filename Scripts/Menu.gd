extends CanvasLayer

const PokemonPartyScreen = preload("res://Scenes/PokemonPartyScreen.tscn")
const ItemScreen = preload("res://Scenes/ItemScreen.tscn")
const SaveScreen = preload("res://Scenes/SaveScreen.tscn")
const StorageScreen = preload("res://Scenes/GrammariteStorage.tscn")
const QuestScreen = preload("res://Scenes/QuestScreen.tscn")
const HarvestScreen = preload("res://Scenes/HarvestScreen.tscn")
const CraftScreen = preload("res://Scenes/CraftScreen.tscn")
const BookScreen = preload("res://Scenes/BookScreen.tscn")

@onready var arrow = $Control/Arrow 
@onready var menu = $Control

enum ScreenLoaded { NOTHING, DIALOGUE, JUST_MENU, ITEM_SCREEN, PARTY_SCREEN, COMPUTER, NAMING, BATTLE, QUESTS, SHARDS, SAVE_SCREEN, BOOKSHELF }
var screen_loaded = ScreenLoaded.NOTHING
var selected_option: int = 0

# SelectBox positions for 2x3 grid (adjust these to match your layout)
var select_box_positions: Array[Vector2] = [
	Vector2(80, 62),   # Option 0 (top-left)
	Vector2(146, 63),   # Option 1 (top-right)
	Vector2(80, 80),   # Option 2 (middle-left)
	Vector2(146, 80),   # Option 3 (middle-right)
	Vector2(80, 97),   # Option 4 (bottom-left)
	Vector2(146, 97),   # Option 5 (bottom-right)
]

func _ready():
	menu.visible = false
	update_select_box()
	Utils.get_scene_manager().name_selected.connect(_recieve_player_name)


var name_prompt = "What should your name be?"
func _recieve_player_name(chosen_name, from_node):
	if from_node != self: return
	Utils.set_player_name(chosen_name)



func update_select_box():
	arrow.position = select_box_positions[selected_option]

func load_party_screen():
	menu.visible = false
	screen_loaded = ScreenLoaded.PARTY_SCREEN
	var party_screen = PokemonPartyScreen.instantiate()
	add_child(party_screen)
func unload_party_screen():
	menu.visible = true
	screen_loaded = ScreenLoaded.JUST_MENU
	remove_child($PokemonPartyScreen)

func load_item_screen():
	menu.visible = false
	screen_loaded = ScreenLoaded.ITEM_SCREEN
	var item_screen = ItemScreen.instantiate()
	item_screen.in_battle = false
	add_child(item_screen)
func unload_item_screen():
	menu.visible = true
	screen_loaded = ScreenLoaded.JUST_MENU
	remove_child($ItemScreen)

func load_save_screen():
	menu.visible = false
	screen_loaded = ScreenLoaded.SAVE_SCREEN
	var save_screen = SaveScreen.instantiate()
	add_child(save_screen)
func unload_save_screen():
	menu.visible = true
	screen_loaded = ScreenLoaded.JUST_MENU
	remove_child($SaveScreen)


func load_storage_screen():
	screen_loaded = ScreenLoaded.COMPUTER
	var storage_screen = StorageScreen.instantiate()
	add_child(storage_screen)
func unload_storage_screen():
	screen_loaded = ScreenLoaded.NOTHING
	remove_child($GrammariteStorage)

func load_quests():
	screen_loaded = ScreenLoaded.QUESTS
	var quest_screen = QuestScreen.instantiate()
	add_child(quest_screen)
func unload_quests():
	screen_loaded = ScreenLoaded.NOTHING
	remove_child($QuestScreen)

func load_harvester():
	screen_loaded = ScreenLoaded.SHARDS
	var harvest_screen = HarvestScreen.instantiate()
	add_child(harvest_screen)
func unload_harvester():
	screen_loaded = ScreenLoaded.NOTHING
	remove_child($HarvestScreen)

func load_crafter():
	screen_loaded = ScreenLoaded.SHARDS
	var craft_screen = CraftScreen.instantiate()
	add_child(craft_screen)
func unload_crafter():
	screen_loaded = ScreenLoaded.NOTHING
	remove_child($CraftScreen)

func load_bookshelf():
	screen_loaded = ScreenLoaded.BOOKSHELF
	var book_screen = BookScreen.instantiate()
	add_child(book_screen)
func unload_bookshelf():
	screen_loaded = ScreenLoaded.NOTHING
	remove_child($BookScreen)


func _unhandled_input(event):
	match screen_loaded:
		ScreenLoaded.NOTHING:
			if event.is_action_pressed("menu"):
				var player = Utils.get_player()
				if not player.is_moving:
					player.set_physics_process(false)
					menu.visible = true
					screen_loaded = ScreenLoaded.JUST_MENU
		
		ScreenLoaded.JUST_MENU:
			if event.is_action_pressed("menu") or event.is_action_pressed("x") or (event.is_action_pressed("z") and selected_option == 5):
				selected_option = 0
				update_select_box()
				var player = Utils.get_player()
				player.set_physics_process(true)
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
				match selected_option:
					0:
						Utils.get_scene_manager().transition_to_party_screen()
					1:
						pass
					2:
						Utils.get_scene_manager().transition_to_item_screen()
					3:
						Utils.get_scene_manager().transition_to_save_screen()
					4:
						Utils.get_scene_manager().transition_to_naming_screen(self)
					5:
						# Close menu (already handled above)
						pass
