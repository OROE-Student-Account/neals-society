extends Node2D

var selected_item_index: int = 0
var pause := false

@onready var select_box = $SelectBox

var item_positions: Array[Vector2] = [
	Vector2(96, 21),
	Vector2(121, 21),
	Vector2(147, 21),
	Vector2(172, 21),
	Vector2(197, 21),

	Vector2(96, 46),
	Vector2(121, 46),
	Vector2(147, 46),
	Vector2(172, 46),
	Vector2(197, 46),

	Vector2(96, 71),
	Vector2(121, 71),
	Vector2(147, 71),
	Vector2(172, 71),
	Vector2(197, 71),
]

var shop_items: Array[String] = [
	"Children's Book",
	"Apple",
	"Comma",
	"Dash"
]


func _ready() -> void:
	selected_item_index = 0
	
	$Money/Label.text = "$: " + str(Utils.get_money())
	update_item_info()


func update_item_info() -> void:
	if selected_item_index < 0 or selected_item_index >= shop_items.size():
		return
	
	var item_name: String = shop_items[selected_item_index]
	var item_data = Utils.get_item_data(item_name)
	
	$Description/ItemName.text = item_name
	$Description/ItemDescription.text = item_data["Description"]
	
	select_box.position = item_positions[selected_item_index]


func open_purchase_prompt() -> void:
	if selected_item_index < 0 or selected_item_index >= shop_items.size():
		return
	
	var item_name: String = shop_items[selected_item_index]
	var item_data = Utils.get_item_data(item_name)
	var price: int = int(item_data["Price"])
	
	pause = true
	
	$PurchasePrompt.text = (
		"Would you like to purchase "
		+ item_name
		+ " for $"
		+ str(price)
		+ "?"
	)
	
	$PurchasePrompt.begin_from_self()


func purchase_selected_item() -> void:
	if selected_item_index < 0 or selected_item_index >= shop_items.size():
		resume_shop_input()
		return
	
	var item_name: String = shop_items[selected_item_index]
	var item_data = Utils.get_item_data(item_name)
	var price: int = int(item_data["Price"])
	var current_money: int = Utils.get_money()
	
	if current_money < price:
		$NoMoney.begin_from_self()
		return
		resume_shop_input()
	
	Utils.set_money(current_money - price)
	Utils.add_to_inventory(item_name)
	
	$Money/Label.text = "$: " + str(Utils.get_money())
	
	print("Purchased: ", item_name)
	resume_shop_input()


func _unhandled_input(event: InputEvent) -> void:
	if pause:
		return
	
	if event.is_action_pressed("ui_right"):
		var next_index := selected_item_index + 1
		
		if selected_item_index % 5 != 4 and next_index < shop_items.size():
			selected_item_index = next_index
			update_item_info()
	
	elif event.is_action_pressed("ui_left"):
		if selected_item_index % 5 != 0:
			selected_item_index -= 1
			update_item_info()
	
	elif event.is_action_pressed("ui_down"):
		var next_index := selected_item_index + 5
		
		if next_index < shop_items.size():
			selected_item_index = next_index
			update_item_info()
	
	elif event.is_action_pressed("ui_up"):
		var previous_index := selected_item_index - 5
		
		if previous_index >= 0:
			selected_item_index = previous_index
			update_item_info()
	
	elif event.is_action_pressed("z"):
		open_purchase_prompt()
	
	elif event.is_action_pressed("x"):
		pause = true
		Utils.get_scene_manager().transition_exit_menu("Shop")

func resume_shop_input():
	await get_tree().create_timer(0.15).timeout
	pause = false
func cancel_purchase() -> void:
	resume_shop_input()
