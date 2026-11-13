
extends Node2D

var quests = []
var mapped_quests = [] 

# We will use this to remember which quest to keep open after reloading
var quest_to_reselect: String = ""

var pause = false

@onready var item_list = $Sidebar/ItemList
@onready var accept_button = $Info/AcceptButton


func _ready() -> void:
	# Connect the button signal via code so you don't have to do it in the inspector
	
	# Keep this pixel font crisp without changing fonts in other screens.
	var crisp_theme: Theme = preload("res://Assets/UI/Plain/Fonts.tres").duplicate()
	var crisp_font: FontFile = crisp_theme.default_font.duplicate()
	crisp_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	crisp_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	crisp_font.oversampling = 1.0
	crisp_theme.default_font = crisp_font
	for control in find_children("*", "Control", true, false):
		control.theme = crisp_theme
	load_itemlist()
	item_list.grab_focus()

func load_itemlist():
	item_list.clear()
	mapped_quests.clear()
	quests.clear()
	quests = Utils.load_quests()
	
	var incoming = []
	var started = []
	var completed = []
	
	for quest in quests:
		var status = quest.get("Details", {}).get("Progress", "Incoming")
		
		if status == "Incoming":
			incoming.append(quest)
		elif status == "Started":
			started.append(quest)
		elif status == "Completed":
			completed.append(quest)
			
	add_section("Incoming", incoming)
	add_section("Started", started)
	add_section("Completed", completed)
	
	# --- RE-SELECTION LOGIC ---
	if quest_to_reselect != "":
		var found = false
		for i in range(mapped_quests.size()):
			if mapped_quests[i] != null and mapped_quests[i]["Name"] == quest_to_reselect:
				item_list.select(i)
				item_list.ensure_current_is_visible()
				_on_item_list_item_selected(i)
				found = true
				break
				
		quest_to_reselect = "" # Reset it after trying to find it
		
		# If we couldn't find it for some reason, fallback to the first item
		if not found:
			select_first_valid_item()
	else:
		select_first_valid_item()

# --- HELPER: ADDS HEADERS AND ITEMS ---
func add_section(title: String, section_quests: Array):
	# If a section is empty, don't draw the header at all
	if section_quests.size() == 0:
		return
		
	# Add the Section Header
	item_list.add_item(title)
	var header_index = item_list.item_count - 1
	# Make it unclickable WITHOUT applying the grey "disabled" visual state
	item_list.set_item_selectable(header_index, false) 
	
	# Now this custom color will actually work! Feel free to change this Color.
	item_list.set_item_custom_fg_color(header_index, Color(0.0, 0.0, 0.0, 1.0)) # Example: Gold

	mapped_quests.append(null) # Store null in our map to represent a header
	
	# Add the actual quests under this header
	for quest in section_quests:
		item_list.add_item(quest["Name"])
		item_list.set_item_tooltip(item_list.item_count - 1, quest["Name"])
		mapped_quests.append(quest)

func select_first_valid_item():
	for i in range(item_list.item_count):
		if not item_list.is_item_disabled(i) and mapped_quests[i] != null:
			item_list.select(i)
			item_list.ensure_current_is_visible()
			_on_item_list_item_selected(i)
			return
			
	$Info/Details/Description.text = "You have no quests at the moment."
	$Info/Title.text = ""
	$Info/Reward.text = ""
	accept_button.visible = false

func _on_item_list_item_selected(index: int) -> void:
	if index < 0 or index >= len(mapped_quests):
		return
	
	var quest = mapped_quests[index]
	if quest == null:
		return 
	
	$Info/Details/Description.text = quest.get("Details", {}).get("CurrentObjective", quest.get("Description", ""))
	$Info/Title.text = quest.get("Name", "")
	$Info/Details.scroll_vertical = 0
	
	var status = quest.get("Details", {}).get("Progress", "Incoming")
	
	# --- HANDLE INCOMING VS STARTED/COMPLETED UI ---
	if status == "Incoming":
		$Info/Reward.text = "Reward: ??? (Accept to reveal)"
		accept_button.visible = false
	else:
		accept_button.visible = false
		var reward = quest.get("Reward", {})
		if reward.has("Type") and reward.has("Amt"):
			$Info/Reward.text = "Reward: " + ("$" if reward["Type"] == "Money" else "") + str(int(reward["Amt"])) + " " + ("Item" if reward["Type"] == "Item" else "")
		else:
			$Info/Reward.text = "Reward: None"

# --- NEW: ACCEPT BUTTON LOGIC ---
func on_accept_button_pressed() -> void:
	# Get the currently selected index from the ItemList
	var selected_items = item_list.get_selected_items()
	if selected_items.size() == 0:
		return
		
	var index = selected_items[0]
	if index < 0 or index >= mapped_quests.size(): return
	var quest = mapped_quests[index]
	
	if quest != null and quest.get("Details", {}).get("Progress", "Incoming") == "Incoming":
		# 1. Update the quest status
		quest["Details"]["Progress"] = "Started"
		
		# 2. Tell the list to remember this quest's name
		quest_to_reselect = quest["Name"]
		
		accept_button.visible = false
		Utils.set_quest_progress("Started", quest["Details"]["ID"])
		
		if quest.has("Load"):
			var obstacle_info = quest["Load"]
			Utils.update_obstacle(obstacle_info["Node"], false, obstacle_info["Scene"])
		
		# 3. Re-sort and rebuild the UI!
		load_itemlist()

func stop():
	pause = true
	await get_tree().create_timer(0.1).timeout
	pause = false

# Handle detail scrolling before the focused ItemList consumes Page Up/Down.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_page_up"):
		_unhandled_input(event)

func _unhandled_input(event: InputEvent) -> void:
	if pause or event.is_echo(): return
	if event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_page_up"):
		var bar = $Info/Details.get_v_scroll_bar()
		var direction := 1 if event.is_action_pressed("ui_page_down") else -1
		$Info/Details.scroll_vertical += int(maxf(1.0, bar.page) * direction)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("z"):
		get_viewport().set_input_as_handled()
		var selected = item_list.get_selected_items()
		if selected.is_empty(): return
		var index: int = selected[0]
		if index < 0 or index >= mapped_quests.size() or mapped_quests[index] == null: return
		var quest = mapped_quests[index]
		if accept_button.visible:
			on_accept_button_pressed()
		elif quest.get("Details", {}).get("Progress", "Incoming") == "Incoming":
			accept_button.visible = true
			stop()
	elif event.is_action_pressed("x"):
		get_viewport().set_input_as_handled()
		if accept_button.visible:
			accept_button.visible = false
		else:
			item_list.release_focus()
			Utils.get_scene_manager().transition_exit_menu("Quest")
