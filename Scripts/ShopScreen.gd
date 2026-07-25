extends Node2D

var selected_item_index: int = 0
var pause := false

const item_name_size = 53.0
@onready var item = $Description/ItemName
@onready var select_box = $SelectBox

enum Menu { MAIN, DISPLAYING }
var current_menu = Menu.MAIN

var item_positions: Array[Vector2] = [
	Vector2(104, 35),
	Vector2(129, 35),
	Vector2(155, 35),
	Vector2(180, 35),
	Vector2(205, 35),

	Vector2(104, 60),
	Vector2(129, 60),
	Vector2(155, 60),
	Vector2(180, 60),
	Vector2(205, 60),

	Vector2(104, 85),
	Vector2(129, 85),
	Vector2(155, 85),
	Vector2(180, 85),
	Vector2(205, 85),
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
	load_shop()


func load_shop() -> void:
	var shelf = $Description
	while shelf.get_child_count() > 2:
		shelf.get_child(2).free()
	
	for i in range(len(shop_items)):
		if i > 15:
			print("ERROR, too many items to sell in shop")
			continue
		var item_name = shop_items[i]
		var sprite = Sprite2D.new()
		sprite.scale = Vector2(0.5, 0.5)
		sprite.texture = load("res://Assets/Items/"+item_name+".png")
		sprite.position = item_positions[i]
		
		shelf.add_child(sprite)

func update_item_info() -> void:
	if selected_item_index < 0 or selected_item_index >= shop_items.size():
		return
	
	
	var item_name: String = shop_items[selected_item_index]
	var item_data = Utils.get_item_data(item_name)
	
	
	# Re sizing of item name
	item.text = ""
	item.scale = Vector2.ONE
	item.set_size(Vector2(item_name_size, item.size.y))
	item.text = item_name
	item.set_size(item.get_size())
	
	var ratio =  item_name_size / item.size.x
	item.scale = Vector2(ratio, ratio)
	item.set_size(item.get_size())
	
	set_description(item_data["Description"])
	
	select_box.position = item_positions[selected_item_index]

func set_description(text: String) -> void:
	$Description/ItemDescription.text = text

func open_purchase_prompt() -> void:
	if selected_item_index < 0 or selected_item_index >= shop_items.size():
		return
	
	var item_name: String = shop_items[selected_item_index]
	var item_data = Utils.get_item_data(item_name)
	var price: int = int(item_data["Price"])
	
	current_menu = Menu.DISPLAYING
	
	set_description("Would you like to purchase "+item_name+" for $"+str(price)+"?")


func purchase_selected_item() -> void:
	pause = true
	
	var item_name: String = shop_items[selected_item_index]
	var item_data = Utils.get_item_data(item_name)
	var price: int = int(item_data["Price"])
	var current_money: int = Utils.get_money()
	
	if current_money < price:
		set_description("You don't have enough money.")
		await get_tree().create_timer(1.0).timeout
		update_item_info()
		resume_shop_input()
		current_menu = Menu.MAIN
		return
	
	Utils.set_money(current_money - price)
	Utils.add_to_inventory(item_name)
	
	shop_items.remove_at(selected_item_index)
	selected_item_index -= 1
	if selected_item_index < 0:
		selected_item_index = 0
	
	if shop_items.size() == 0:
		pause = true
		Utils.get_scene_manager().transition_exit_menu("Shop")
	
	$Money/Label.text = "$: " + str(Utils.get_money())
	resume_shop_input()
	update_item_info()
	load_shop()
	current_menu = Menu.MAIN


func _unhandled_input(event: InputEvent) -> void:
	if pause:
		return
	match current_menu:
		Menu.MAIN:
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
				
		Menu.DISPLAYING:
			if event.is_action_pressed("z"):
				purchase_selected_item()
			elif event.is_action_pressed("x"):
				current_menu = Menu.MAIN
				update_item_info()

func resume_shop_input():
	await get_tree().create_timer(0.1).timeout
	pause = false
