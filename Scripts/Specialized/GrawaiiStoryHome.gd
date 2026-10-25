extends Node2D
## First witness: read the Storyteller's note and preserve its exact account.
const EVIDENCE = preload("res://Scripts/Specialized/GrawaiiEvidence.gd")
const DIALOGUE = preload("res://Scripts/DialogueNode.gd")
const QUEST_NAME := "The Missing Storyteller"
const CLUE_KEY := "apprentice_note"
var quest_id := -1
var busy := false
var interaction_after := 0

func _ready() -> void:
	var definitions: Array = Utils.load_json_file("res://GrammariteData/Quests.json")
	for i in definitions.size():
		if definitions[i].get("Name", "") == QUEST_NAME:
			quest_id = i
			break
	if quest_id < 0:
		push_error("Storyteller home: missing quest definition")

func _progress() -> Array:
	var progress: Array = Utils.load_json_file("res://Data/Quests.json")
	while progress.size() <= quest_id:
		progress.append({"Progress": "Incoming"})
	return progress

func _has_clue() -> bool:
	return _progress()[quest_id].get("GrawaiiClues", {}).get(CLUE_KEY, false)

func _unhandled_input(event: InputEvent) -> void:
	if quest_id < 0 or busy or event.is_echo() or not event.is_action_pressed("z") or Time.get_ticks_msec() < interaction_after:
		return
	var manager = Utils.get_scene_manager()
	var player = Utils.get_player()
	if manager.menu.screen_loaded != manager.menu.ScreenLoaded.NOTHING or not player.is_physics_processing() or player.is_moving:
		return
	var facing: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][player.facing_direction]
	for actor in [$Sorted/Apprentice, $Sorted/WritingDesk]:
		var offset: Vector2 = actor.global_position - player.global_position
		if offset.dot(facing) >= 4.0 and offset.dot(facing) <= 24.0 and absf(offset.cross(facing)) <= 8.0:
			get_viewport().set_input_as_handled()
			talk_to(str(actor.name))
			return

func talk_to(actor: String) -> void:
	if busy or quest_id < 0:
		return
	busy = true
	if actor == "WritingDesk" and EVIDENCE.progress(Utils).get("GrawaiiStorytellerRescued", false):
		await _say("The note that started the search is still on the desk. The Storyteller and the original ending are now safely back at the festival green.", "<none>")
		interaction_after = Time.get_ticks_msec() + 250
		busy = false
		return
	if actor == "Apprentice" and EVIDENCE.progress(Utils).get("GrawaiiStorytellerRescued", false):
		await _say("He's home! Thank you for following his note and bringing him back. You'll find him at the festival green with the original ending.", "Storyteller's Apprentice")
		interaction_after = Time.get_ticks_msec() + 250
		busy = false
		return
	if actor == "Apprentice":
		if _has_clue():
			await _say("He went to the coastal archive to fetch the original ending. That's what his note says, but it doesn't tell us what happened after he left.", "Storyteller's Apprentice")
			await _say(EVIDENCE.objective(EVIDENCE.progress(Utils)), "Storyteller's Apprentice")
		else:
			await _say("I'm the Storyteller's apprentice. He promised I'd help with tonight's closing story, but he hasn't come home.", "Storyteller's Apprentice")
			await _say("He left a note on his writing desk. Please read it; I don't want to guess and send the search in the wrong direction.", "Storyteller's Apprentice")
			var progress := _progress()
			progress[quest_id]["GrawaiiApprenticeSpoken"] = true
			if progress[quest_id].get("Progress", "Incoming") == "Incoming":
				progress[quest_id]["Progress"] = "Started"
			if not _has_clue():
				progress[quest_id]["CurrentObjective"] = "Read the note on the writing desk in the Storyteller's home."
			Utils.save_json_file("res://Data/Quests.json", progress)
	elif actor == "WritingDesk":
		await _say("A handwritten note lies beside an unfinished story.", "<none>")
		await _say("I've gone to the coastal archive to fetch the original ending for tonight's story. I'll be back before the festival. - The Storyteller", "Storyteller's Note")
		if not _has_clue():
			EVIDENCE.record(Utils, CLUE_KEY)
			await _say("Account recorded: The Original Ending. (%d/5)" % EVIDENCE.count_clues(EVIDENCE.progress(Utils)), "<none>")
		else:
			await _say("You already recorded this clue. The note tells you his destination, but not why he hasn't returned.", "<none>")
	interaction_after = Time.get_ticks_msec() + 250
	busy = false

func _say(text: String, speaker: String) -> void:
	for page in EVIDENCE.dialogue_pages(Utils, text):
		var line = DIALOGUE.new()
		line.text = page
		line.display = speaker
		line.is_end_node = true
		add_child(line)
		var manager = Utils.get_scene_manager()
		manager.transition_to_dialogue(line)
		await manager.get_node("DialogueBox").dialogue_ended
		line.queue_free()
