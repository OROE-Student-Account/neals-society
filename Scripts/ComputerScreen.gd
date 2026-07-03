extends Node2D

enum State { MAIN, SUMMARY, MOVES }
var state = State.MAIN

var num_grammarites = 0
@onready var grammas = $Grammarites

var selected_entry = 0

var selected_move = 0

var animating = false

func _ready() -> void:
	num_grammarites = Utils.get_num_grammarites()
	
	
	for i in range(num_grammarites):
		var grammarite = Sprite2D.new()
		grammarite.centered = false
		grammarite.add_child(Label.new())
		
		
		var text = Utils.get_name_from_num(i)
		if !Utils.caught_yet(Utils.get_name_from_num(i)):
			grammarite.modulate = Color(0,0,0,1)
			text = ""
			for j in range(len(Utils.get_name_from_num(i))):
				text += "?"
		
		
		grammarite.get_child(0).theme = load("res://Assets/UI/Fonts.tres")
		grammarite.get_child(0).horizontal_alignment = 1
		grammarite.get_child(0).size.x = 64
		grammarite.get_child(0).position = Vector2(0, -16)
		
		grammarite.get_child(0).text = text
		
		grammarite.texture = load("res://Assets/Pokemon/Pokemon"+str(1+i)+".png")
		grammarite.region_enabled = true
		grammarite.region_rect = Rect2(0, 34, 64, 64)
		
		grammas.add_child(grammarite)
		grammas.get_child(i+1-1).position = Vector2(208 - 120 + 120*i, 48)



func fix_party():
	var party = Utils.get_party()
	
	for i in range(6):
		if party[i]["Name"] != "":
			var slot = party[i]
			
			# fill pp
			for j in range(4):
				slot["PP"][j] = Utils.get_move(slot["Moves"][j])["PP"]
			
			slot["Health"] = Utils.max_hp(slot["Name"], slot["Level"])
			if slot["Item"] == "Colon":
				slot["Health"] *= 1.1
				slot["Health"] = int(10 + slot["Health"])
	
	Utils.set_party(party)


func left_anim():
	if grammas.position.x > -1:
		return 
	animating = true
	grammas.get_child(0).frame = 0
	grammas.get_child(0).get_child(0).visible = false
	
	for i in range(-10, 10):
		var time = abs((i/10.0)**3)
		grammas.position.x += (1-time)/0.125
		await get_tree().create_timer(time/240).timeout
	
	if grammas.position.x > -1:
		grammas.get_child(0).frame = 1
		grammas.get_child(0).get_child(0).visible = true
		$Sprite2D2.visible = false
	$Sprite2D.visible = true
	animating = false
func right_anim():
	if grammas.position.x < -120*num_grammarites+1:
		return 
	animating = true
	grammas.get_child(0).frame = 0
	grammas.get_child(0).get_child(0).visible = false
	
	for i in range(-10, 10):
		var time = abs((i/10.0)**3)
		grammas.position.x -= (1-time)/0.125
		await get_tree().create_timer(time/240).timeout
	if grammas.position.x < -120*num_grammarites+1:
		$Sprite2D.visible = false
	$Sprite2D2.visible = true
	animating = false



func load_summary():
	var gram_num = selected_entry
	self.add_child(load("res://Scenes/SummaryScreen.tscn").instantiate())
	
	var gram_name = Utils.get_name_from_num(gram_num)
	var details = Utils.get_grammarite_details(gram_name)
	var stats = details["Stats"]
	
	# stats
	var labels = $SummaryScreen/Stats/Labels
	var HP = int(stats["Health"])
	var DEF = int(stats["Defense"])
	var SPD = int(stats["Speed"])
	var ATK = int(stats["Attack"])
	
	labels.get_child(0).text = str(HP)
	labels.get_child(1).text = str(DEF)
	labels.get_child(2).text = str(SPD)
	labels.get_child(3).text = str(ATK)
	
	# do the polygon
	var polygon = $SummaryScreen/Stats/BG/Actual.polygon
	
	# 40 / Max stat
	HP *= 0.2
	polygon[0].x = -HP
	polygon[0].y = -HP
	
	ATK *= 0.2
	polygon[1].x = ATK
	polygon[1].y = -ATK
	
	SPD *= 0.2
	polygon[2].x = SPD
	polygon[2].y = SPD
	
	DEF *= 0.2
	polygon[3].x = -DEF
	polygon[3].y = DEF
	
	$SummaryScreen/Stats/BG/Actual.polygon = polygon
	
	$SummaryScreen/Grammarite.texture = load("res://Assets/Pokemon/Pokemon"+str(1+gram_num)+".png")
	
	# types
	var info = $SummaryScreen/Info/NinePatchRect
	if len(stats["Types"]) == 1:
		info.get_child(0).get_child(0).visible = false
		info.get_child(1).visible = true
		info.get_child(1).text = str(stats["Types"][0])
	elif len(stats["Types"]) == 2:
		info.get_child(0).get_child(0).visible = true
		info.get_child(1).visible = false
		info.get_child(0).get_child(0).get_child(0).text = str(stats["Types"][0])
		info.get_child(0).get_child(0).get_child(1).text = str(stats["Types"][1])
	
	info.get_child(2).text = "LVL: 100"
	info.get_child(3).text = "XP: 0"
	
	# name and grammadex num
	info.get_child(4).text = gram_name
	info.get_child(5).text = "Grammarite # "+str(gram_num+1)
	
	# hp
	info.get_child(6).text = "MAX HP: "+str(int(Utils.max_hp(gram_name, 100)))
	
	# nickname
	info.get_child(7).text = ""

func update_move_box():
	$MovesScreen/SelectBox.size.y = 15
	$MovesScreen/SelectBox.position.y = 20 + selected_move*16
	if selected_move == 1:
		$MovesScreen/SelectBox.size.y = 14
	elif selected_move > 1:
		$MovesScreen/SelectBox.position.y -= 1
	
	var move_nodes = $MovesScreen/Moves.get_children()
	for i in range(len(move_nodes)):
		var box = move_nodes[i]
		if i != selected_move:
			for j in range(5):
				if j != 0 and j != 3:
					box.get_child(j).visible = false
		else:
			for j in range(5):
				if j != 0 and j != 3:
					box.get_child(j).visible = true

func load_moves():
	var gram_num = selected_entry
	selected_move = 0
	self.add_child(load("res://Scenes/MovesPartyScreen.tscn").instantiate())
	
	
	var gram_name = Utils.get_name_from_num(gram_num)
	var stats = Utils.get_grammarite_details(gram_name)
	
	$MovesScreen/Grammarite.texture = load("res://Assets/Pokemon/Pokemon"+str(1+gram_num)+".png")
	# types
	var info = $MovesScreen/Info
	if len(stats["Stats"]["Types"]) == 1:
		info.get_child(0).get_child(0).visible = false
		info.get_child(1).visible = true
		info.get_child(1).text = str(stats["Types"][0])
	elif len(stats["Stats"]["Types"]) == 2:
		info.get_child(0).get_child(0).visible = true
		info.get_child(1).visible = false
		info.get_child(0).get_child(0).get_child(0).text = str(stats["Stats"]["Types"][0])
		info.get_child(0).get_child(0).get_child(1).text = str(stats["Stats"]["Types"][1])
	
	info.get_child(2).text = gram_name
	# nickname
	info.get_child(3).text = ""
	
	
	var moves = stats["Moves"]
	
	var move_nodes = $MovesScreen/Moves.get_children()
	for i in range(len(move_nodes)):
		var box = move_nodes[i]
		box.get_child(0).text = moves[i]["Name"]
		box.get_child(1).text = moves[i]["Type"]
		box.get_child(2).text = str(int(moves[i]["PP"]))
		box.get_child(3).text = str(int(moves[i]["Damage"]))
		box.get_child(4).text = str(int(100 * moves[i]["Accuracy"])) + "%"
	
	update_move_box()



func _unhandled_input(event: InputEvent) -> void:
	if animating: return
	match state:
		State.MAIN:
			if event.is_action_pressed("z"):
				selected_entry = abs(int((grammas.position.x-1)/120))-1+1
				if Utils.caught_yet(Utils.get_name_from_num(selected_entry)):
					state = State.SUMMARY
					load_summary()
					animating = true
					await get_tree().create_timer(0.1).timeout
					animating = false
				else:
					selected_entry = 0
			
			elif event.is_action_pressed("ui_right"):
				right_anim()	
			elif event.is_action_pressed("ui_left"):
				left_anim()
				
			elif event.is_action_pressed("x"):
				# Exit
				Utils.get_scene_manager().transition_exit_menu("Computer")
		State.SUMMARY:
			if event.is_action_pressed("x"):
				state = State.MAIN
				$SummaryScreen.queue_free()
				animating = true
				await get_tree().create_timer(0.1).timeout
				animating = false
			elif event.is_action_pressed("z"):
				state = State.MOVES
				$SummaryScreen.queue_free()
				load_moves()
				animating = true
				await get_tree().create_timer(0.1).timeout
				animating = false
		State.MOVES:
			if event.is_action_pressed("x"):
				state = State.MAIN
				$MovesScreen.queue_free()
				animating = true
				await get_tree().create_timer(0.1).timeout
				animating = false
			elif event.is_action_pressed("z"):
				state = State.SUMMARY
				$MovesScreen.queue_free()
				load_summary()
				animating = true
				await get_tree().create_timer(0.1).timeout
				animating = false
			elif event.is_action_pressed("ui_up") and selected_move != 0:
				selected_move -= 1
				update_move_box()
			elif event.is_action_pressed("ui_down") and selected_move != 3:
				selected_move += 1
				update_move_box()
