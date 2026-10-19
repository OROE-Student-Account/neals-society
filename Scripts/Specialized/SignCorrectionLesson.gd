extends "res://Scripts/Specialized/TomPunctuationLesson.gd"
## Reuse the existing lesson question UI; sign progress belongs to quest index 2.

const SIGN_QUEST_ID := 2

func _unhandled_input(_event: InputEvent) -> void:
	# The sign owns nearby/facing interaction, rather than Tom's interaction code.
	pass

func _say(text: String, speaker: String, choices: Array = []) -> String:
	if not choices.is_empty():
		return await super._say(text, speaker, choices)
	# Signs need only a closing notification, not Tom's callback that locks
	# the player again after Dialogue.end_dialogue() has released them.
	var line = DIALOGUE_SCRIPT.new()
	line.name = "SignDialogue"
	line.text = text
	line.display = speaker
	line.is_end_node = true
	add_child(line)
	var manager = Utils.get_scene_manager()
	manager.menu.screen_loaded = manager.menu.ScreenLoaded.NOTHING
	line.begin_from_self()
	await manager.get_node("DialogueBox").dialogue_ended
	line.queue_free()
	# Dialogue consumes the closing event before emitting dialogue_ended.
	# Complete this line synchronously; never re-lock after the box closes.
	return ""

func _release_player() -> void:
	var player = Utils.get_player()
	player.stop_input = false
	player.is_moving = false
	player.input_direction = Vector2.ZERO
	player.percent_moved_to_next_tile = 0.0
	player.initial_position = player.position
	player.turning_count = 0
	super._release_player()
	player.anim_state.travel("Idle")

func read_progress() -> Dictionary:
	var quests: Array = Utils.load_json_file("res://Data/Quests.json")
	while quests.size() <= SIGN_QUEST_ID:
		quests.append({"Progress": "Incoming"})
	return quests[SIGN_QUEST_ID]

func start_sign() -> void:
	if busy:
		return
	busy = true
	var sign_node = get_parent()
	var question: Dictionary = Utils.load_json_file("res://GrammariteData/SignCorrections.json")[sign_node.correction_id]
	var progress := read_progress()
	if sign_node.correction_id in progress.get("CorrectedSigns", []):
		await _say(question["Corrected"], "<none>")
	else:
		var quests: Array = Utils.load_json_file("res://Data/Quests.json")
		if quests[1].get("Progress", "Unstarted") != "Completed":
			await _say(question["Question"], "<none>")
			await _say("Help Tom settle the brawl first, then come back to fix the signs.", "<none>")
		else:
			var correct: bool = await _ask(question)
			if correct:
				var finished := record_correction(sign_node.correction_id)
				sign_node.refresh_text()
				await _say(question["Corrected"], "<none>")
				if finished:
					await _say("Quest complete: Fix the signs!\nAll three signs are corrected.", "<none>")
	_release_player()
	busy = false
	# Prevent the closing Z press from immediately opening the sign again.
	sign_node.reset()

func record_correction(id: String) -> bool:
	var quests: Array = Utils.load_json_file("res://Data/Quests.json")
	while quests.size() <= SIGN_QUEST_ID:
		quests.append({"Progress": "Incoming"})
	var progress: Dictionary = quests[SIGN_QUEST_ID]
	var corrected: Array = progress.get("CorrectedSigns", [])
	if id not in corrected:
		corrected.append(id)
	progress["CorrectedSigns"] = corrected
	var definitions: Dictionary = Utils.load_json_file("res://GrammariteData/SignCorrections.json")
	var finished := true
	for required in definitions:
		if required not in corrected:
			finished = false
	progress["Count"] = corrected.size()
	progress["Progress"] = "Completed" if finished else "Started"
	Utils.save_json_file("res://Data/Quests.json", quests)
	return finished

func _lock_player() -> void:
	var player = Utils.get_player()
	player.set_physics_process(false)
	player.anim_state.travel("Idle")
	var menu = Utils.get_scene_manager().menu
	menu.screen_loaded = menu.ScreenLoaded.DIALOGUE
