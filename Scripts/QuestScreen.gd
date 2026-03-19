extends Node2D

var quests = Utils.load_quests()

@onready var item_list = $Sidebar/ItemList

func _ready() -> void:
	load_itemlist()
	item_list.grab_focus()

func load_itemlist():
	item_list.clear()
	
	if len(quests) > 0:
		for quest in quests:
			item_list.add_item(quest["Name"])
	
	# Select first quest if any exist
	if item_list.item_count > 0:
		item_list.select(0)
		_on_item_list_item_selected(0)
	else:
		$Info/Description.text = "You have no quests at the moment."
		$Info/Title.text = ""
		$Info/Reward.text = ""


func _on_item_list_item_selected(index: int) -> void:
	if index >= len(quests):
		return
	
	var quest = quests[index]
	
	$Info/Description.text = quest["Description"]
	$Info/Title.text = quest["Name"]
	
	$Info/Reward.text = "Reward: "+quest["Reward"]["Type"]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("x"):
		item_list.release_focus()
		Utils.get_scene_manager().transition_exit_quests()
	
