extends Node
## Quest-local lesson. Reuses QuestionScreen without changing battle questions.

signal line_finished(choice: String)
signal answer_selected(index: int)

const QUEST_ID := 1
const QUESTION_SCREEN = preload("res://Scenes/QuestionScreen.tscn")
const DIALOGUE_SCRIPT = preload("res://Scripts/DialogueNode.gd")

var busy := false
var accepting_answers := false
var selected := 0
var option_count := 0
var question_ui: Node2D
var overlay: CanvasLayer
var temporary_dialogue: Node

func _unhandled_input(event: InputEvent) -> void:
	if busy or not event.is_action_pressed("z") or event.is_echo():
		return
	var manager = Utils.get_scene_manager()
	var player = Utils.get_player()
	if manager.menu.screen_loaded != manager.menu.ScreenLoaded.NOTHING or get_parent().active or player.is_moving:
		return
	var tom: Node2D = get_parent().get_node("Tom")
	# Compare the actors' feet, rather than a point 16 pixels to the player's
	# right, so interaction works equally from all four approach directions.
	var offset: Vector2 = tom.global_position + Vector2(8, 8) - (player.global_position + Vector2(8, 8))
	var facing: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][player.facing_direction]
	if offset.length() > 32.0 or offset.dot(facing) < 4.0:
		return
	get_viewport().set_input_as_handled()
	start_lesson()

func start_lesson() -> void:
	if busy:
		return
	busy = true
	var quest: Dictionary = _quest()
	if quest.get("Progress", "Unstarted") == "Completed":
		await _say("Let's eat, Derek! Thanks again for helping me with punctuation.", "Tom")
	elif quest.get("Progress", "Unstarted") != "Started":
		await _say("Chief Static needs to talk to you about our argument first.", "Tom")
	else:
		var steps: Array = Utils.load_json_file("res://GrammariteData/TomLesson.json")
		var index: int = int(quest.get("LessonStep", 0))
		var finished := true
		while index < steps.size():
			var step: Dictionary = steps[index]
			if step.has("Question"):
				if not await _ask(step):
					finished = false
					break
			else:
				var choice: String = await _say(step["Text"], step["Speaker"], step.get("Choices", []))
				if choice == "Later":
					finished = false
					break
			index += 1
			_save_step(index)
		if finished:
			_complete_quest()
			await _say("Quest complete: Deal with the brawl!\nYou received $100.", "<none>")
	_release_player()
	busy = false

func _quest() -> Dictionary:
	return Utils.load_json_file("res://Data/Quests.json")[QUEST_ID]

func _save_step(index: int) -> void:
	var quests: Array = Utils.load_json_file("res://Data/Quests.json")
	quests[QUEST_ID]["LessonStep"] = index
	Utils.save_json_file("res://Data/Quests.json", quests)

func _complete_quest() -> void:
	var quests: Array = Utils.load_json_file("res://Data/Quests.json")
	if quests[QUEST_ID].get("Progress", "") == "Completed":
		return
	Utils.set_money(Utils.get_money() + 100)
	quests[QUEST_ID]["Progress"] = "Completed"
	quests[QUEST_ID]["RewardGranted"] = true
	Utils.save_json_file("res://Data/Quests.json", quests)
	get_parent().completed = true
	get_parent().get_node("Hitbox").set_deferred("monitoring", false)

func _say(text: String, speaker: String, choices: Array = []) -> String:
	_lock_player()
	temporary_dialogue = DIALOGUE_SCRIPT.new()
	temporary_dialogue.name = "TomLessonDialogue"
	temporary_dialogue.text = text
	temporary_dialogue.display = speaker
	add_child(temporary_dialogue)
	if choices.is_empty():
		temporary_dialogue.is_end_node = true
		temporary_dialogue.function = "_finish_line"
		temporary_dialogue.func_node = self
	else:
		for choice in choices:
			var option = DIALOGUE_SCRIPT.new()
			option.option_name = choice
			option.is_end_node = true
			option.function = "_finish_line"
			option.func_node = self
			option.args.append(str(choice))
			temporary_dialogue.add_child(option)
	var menu = Utils.get_scene_manager().menu
	menu.screen_loaded = menu.ScreenLoaded.NOTHING
	temporary_dialogue.begin_from_self()
	var result: String = await line_finished
	temporary_dialogue.queue_free()
	temporary_dialogue = null
	return result

func _finish_line(choice: String = "") -> void:
	_lock_player()
	# Finish handling the Z event before opening the next dialogue or question.
	call_deferred("emit_signal", "line_finished", choice)

func _ask(question: Dictionary) -> bool:
	_lock_player()
	overlay = CanvasLayer.new()
	overlay.layer = 50
	add_child(overlay)
	question_ui = QUESTION_SCREEN.instantiate()
	question_ui.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay.add_child(question_ui)
	question_ui.scale = get_viewport().get_visible_rect().size / Vector2(240, 160)
	question_ui.get_node("Vitamins").hide()
	question_ui.get_node("Question").text = question["Question"]
	option_count = question["Options"].size()
	selected = 0
	for i in range(4):
		var box = question_ui.get_node("Options/NinePatchRect" + str(i + 1))
		box.visible = i < option_count
		box.position = Vector2(16 + (i % 2) * 112, 78 + (i / 2) * 36)
		box.size = Vector2(100, 32)
		var label: Label = box.get_node("Label")
		label.position = Vector2.ZERO
		label.size = box.size
		if i < option_count:
			label.text = question["Options"][i]
	var arrow: TextureRect = question_ui.get_node("TextureRect")
	var outline := AtlasTexture.new()
	outline.atlas = arrow.texture
	# Crop to the actual gold border, excluding the atlas's empty padding.
	outline.region = Rect2(26, 80, 115, 32)
	arrow.texture = outline
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.size = Vector2(115, 32)
	var hint := Label.new()
	hint.text = "Arrows: choose   Z: answer   X: leave"
	hint.position = Vector2(4, 148)
	hint.add_theme_font_override("font", question_ui.get_node("Question").get_theme_font("font"))
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color.BLACK)
	question_ui.add_child(hint)
	var animation: AnimationPlayer = question_ui.get_node("AnimationPlayer")
	var explanation: Label = question_ui.get_node("Animation/Failure/Explanation")
	explanation.text = question["Explanation"]
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Keep the scene's normal font sizes and crisp pixel edges. Duplicate the
	# font so this screen does not change text elsewhere in the game.
	var font: FontFile = question_ui.get_node("Question").get_theme_font("font").duplicate()
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.oversampling = 1.0
	for label in question_ui.find_children("*", "Label", true, false):
		label.add_theme_font_override("font", font)
	while true:
		_update_selection()
		accepting_answers = true
		var answer: int = await answer_selected
		accepting_answers = false
		if answer < 0:
			overlay.queue_free()
			return false
		animation.play("Success" if answer == question["Answer"] else "Failure")
		await animation.animation_finished
		if answer == question["Answer"]:
			overlay.queue_free()
			return true
		animation.play("RESET")
		await animation.animation_finished
	return false

func _input(event: InputEvent) -> void:
	if not accepting_answers or event.is_echo():
		return
	if event.is_action_pressed("x"):
		accepting_answers = false
		answer_selected.emit(-1)
	elif event.is_action_pressed("z"):
		accepting_answers = false
		answer_selected.emit(selected)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		selected = (selected + 1) % option_count
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		selected = (selected + option_count - 1) % option_count
	else:
		return
	get_viewport().set_input_as_handled()
	if accepting_answers:
		_update_selection()

func _update_selection() -> void:
	# The visible boxes are baked into Battle Ui1.png. Align to that artwork,
	# rather than the separate label rectangles used for answer text.
	var outline_positions := [Vector2(4, 80), Vector2(120, 80), Vector2(4, 114), Vector2(120, 114)]
	question_ui.get_node("TextureRect").position = outline_positions[selected]

func _lock_player() -> void:
	get_parent()._lock_player()

func _release_player() -> void:
	var player = Utils.get_player()
	player.player_state = player.PlayerState.IDLE
	player.anim_tree.active = true
	player.set_physics_process(true)
	var menu = Utils.get_scene_manager().menu
	menu.screen_loaded = menu.ScreenLoaded.NOTHING
