extends Node2D
## Festival investigation: accounts, reconstruction, and the confirmed search route.
const EVIDENCE = preload("res://Scripts/Specialized/GrawaiiEvidence.gd")
const DIALOGUE = preload("res://Scripts/DialogueNode.gd")
const QUEST_NAME := "The Missing Storyteller"
var busy := false
var interaction_after := 0
var quest_id := -1
var intro_seen := false
var selected_choice := -1
var story_refresh_after := 0.0
var story_signature := -1
var homecoming_pending := false

func _ready() -> void:
	var definitions: Array = Utils.load_json_file("res://GrammariteData/Quests.json")
	for i in definitions.size():
		if definitions[i].get("Name", "") == QUEST_NAME:
			quest_id = i
			break
	if quest_id < 0:
		push_error("Grawaii opening: missing quest definition")
		set_process(false)
		return
	var progress := _progress()
	intro_seen = progress[quest_id].get("GrawaiiIntroSeen", false)
	_sync_story()

func _progress() -> Array:
	var progress: Array = Utils.load_json_file("res://Data/Quests.json")
	var changed := false
	while progress.size() <= quest_id:
		progress.append({"Progress": "Incoming"})
		changed = true
	if changed:
		Utils.save_json_file("res://Data/Quests.json", progress)
	return progress

func _available() -> bool:
	if busy or Time.get_ticks_msec() < interaction_after or not is_visible_in_tree():
		return false
	var manager = Utils.get_scene_manager()
	if manager.menu.screen_loaded != manager.menu.ScreenLoaded.NOTHING:
		return false
	var player = Utils.get_player()
	return player != null and player.is_physics_processing() and not player.is_moving

func _sync_story() -> void:
	var entry: Dictionary = EVIDENCE.progress(Utils)
	intro_seen = entry.get("GrawaiiIntroSeen", false)
	var signature := 0
	var flags := ["GrawaiiReconstructed", "GrawaiiScoutDefeated", "GrawaiiArchiveHelpRequested", "GrawaiiArchiveCleared", "GrawaiiStorytellerRescued", "GrawaiiHomecomingSeen"]
	for i in flags.size():
		if entry.get(flags[i], false): signature |= 1 << i
	if signature == story_signature: return
	story_signature = signature
	var rescued: bool = entry.get("GrawaiiStorytellerRescued", false)
	homecoming_pending = rescued and not entry.get("GrawaiiHomecomingSeen", false)
	$ReturnedStoryteller.visible = rescued
	$ReturnedStoryteller/Body.collision_layer = 18 if rescued else 0
	$Witnesses.refresh_story_actors()

func _process(delta: float) -> void:
	# Refresh loaded-save visuals at a modest rate, not with per-frame disk reads.
	story_refresh_after -= delta
	if story_refresh_after <= 0.0:
		story_refresh_after = 0.25
		_sync_story()
	if homecoming_pending and _available():
		if Utils.get_player().global_position.distance_to($Organizer.global_position) <= 80.0:
			_homecoming()
			return
	if quest_id < 0 or intro_seen or not _available(): return
	if Utils.get_player().global_position.distance_to($Organizer.global_position) <= 56.0:
		briefing()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("z") or not _available():
		return
	var player = Utils.get_player()
	var facing: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][player.facing_direction]
	for actor in [$Organizer, $Grammaster, $FestivalCook, $FestivalSign, $EmptyStage, $StorytellerHome/HomeSign, $ReturnedStoryteller]:
		if not actor.is_visible_in_tree(): continue
		var target_position: Vector2 = actor.global_position
		if actor == $FestivalCook:
			target_position += $FestivalCook/Sprite2D.position
		# The stage is wider than an NPC; talk from its front edge.
		if actor == $EmptyStage:
			target_position += Vector2(0, 32)
		var offset: Vector2 = target_position - player.global_position
		if offset.dot(facing) >= 4.0 and offset.dot(facing) <= 24.0 and absf(offset.cross(facing)) <= 8.0:
			get_viewport().set_input_as_handled()
			talk_to(str(actor.name))
			return

func briefing() -> void:
	if busy:
		return
	busy = true
	await _say("Welcome to Grawai'i. We were just about to begin our Festival of Stories...", "Festival Organizer")
	await _say("Every year, we gather here to share the Storyteller's tales. But he never came back from his morning errand.", "Festival Organizer")
	await _say("His stage is still empty. We know every story he's ever told, but nobody knows where he went this morning.", "Festival Organizer")
	await _say("Will you help us find him? His home is northwest of this green. Start there, then ask the villagers what they saw. I'll stay here and bring their accounts together.", "Festival Organizer")
	var progress := _progress()
	if progress[quest_id].get("Progress", "Incoming") == "Incoming":
		progress[quest_id]["Progress"] = "Started"
	progress[quest_id]["GrawaiiIntroSeen"] = true
	Utils.save_json_file("res://Data/Quests.json", progress)
	intro_seen = true
	await _say("Quest started: The Missing Storyteller. Speak to the villagers and find out where he went.", "<none>")
	_finish()

func talk_to(actor: String) -> void:
	if busy:
		return
	if actor == "Organizer" and not intro_seen:
		briefing()
		return
	busy = true
	match actor:
		"Organizer":
			await _organizer()
		"ReturnedStoryteller":
			await _say("You followed the accounts all the way to the archive. Thank you for bringing me home. The original ending is safe, too.", "The Storyteller")
			await _say("An old passage mentions the book, but its meaning is hidden in the wording. The Grammaster should examine it when the festival is ready.", "The Storyteller")
		"Grammaster":
			if EVIDENCE.progress(Utils).get("GrawaiiStorytellerRescued", false):
				await _say("Our friend is safe, and the original ending has been recovered. Let him rest while we prepare the festival. There will be time to examine that passage.", "The Grammaster")
			elif EVIDENCE.progress(Utils).get("GrawaiiReconstructed", false):
				await _say("You've separated what the witnesses saw from what people are repeating. The coastal archive is our best lead. Speak to the trail keeper about the search.", "The Grammaster")
			else:
				await _say("I am the Grammaster, the third disciple. Today, though, the festival and our missing friend come first.", "The Grammaster")
				await _say("I'll coordinate the search here. Listen carefully to what people actually saw. A rumor and a memory are not the same thing.", "The Grammaster")
		"FestivalCook":
			if EVIDENCE.progress(Utils).get("GrawaiiStorytellerRescued", false):
				await _say("He's back! Thank you for finding him. I'll get the festival food ready while he catches his breath.", "Festival Cook")
				_finish()
				return
			await _say("He ate breakfast here before the morning bell. Then he went home to collect a wrapped manuscript. I saw him leave his house with it.", "Festival Cook")
			await _say("Breakfast came first, then the manuscript. I didn't see which trail he took after that; the canoe racer may have seen him.", "Festival Cook")
			if EVIDENCE.record(Utils, "cook_breakfast"):
				await _say("Account recorded: Breakfast Before the Manuscript. (%d/5)" % EVIDENCE.count_clues(EVIDENCE.progress(Utils)), "<none>")
			else:
				await _say("You've already recorded my account. The organizer can review it with you.", "Festival Cook")
		"HomeSign":
			await _say("THE STORYTELLER'S HOME\nVisitors welcome. Please leave unfinished stories on the writing desk.", "<none>")
		"FestivalSign":
			await _say("FESTIVAL OF STORIES\nGather at the green for stories, food, and friendly challenges. Opening performance: the Storyteller.", "<none>")
		"EmptyStage":
			await _say("A place has been prepared for the Storyteller. The benches face an empty stage.", "<none>")
	_finish()

func _finish() -> void:
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

func _review_accounts(entry: Dictionary) -> void:
	await _say("You've recorded %d of the five accounts. Let's review what we know." % EVIDENCE.count_clues(entry), "Festival Organizer")
	for account in EVIDENCE.summaries(entry):
		await _say(account, "Festival Organizer")

func _organizer() -> void:
	var entry: Dictionary = EVIDENCE.progress(Utils)
	if entry.get("GrawaiiStorytellerRescued", false):
		await _say("The Storyteller is home, and the original ending has been recovered. We'll prepare the festival next. You can meet him just south of the stage.", "Festival Organizer")
		if await _ask("Would you like to review the accounts that led us to him?", "Review accounts", "Later") == 0:
			await _review_accounts(entry)
		return
	if EVIDENCE.count_clues(entry) < EVIDENCE.KEYS.size():
		await _review_accounts(entry)
		await _say(EVIDENCE.objective(entry), "Festival Organizer")
		return
	if entry.get("GrawaiiReconstructed", false):
		await _say("We've confirmed the route: home, eastern trail, coastal archive, then the rockfall. The Storyteller may be trapped inside.", "Festival Organizer")
		await _say("The scout followed later, alone. We still don't know who caused the rockfall or wrote the warning. Let's keep those questions separate from the facts.", "Festival Organizer")
		if await _ask("Would you like to read the five recorded accounts again?", "Review accounts", "Later") == 0:
			await _review_accounts(entry)
		await _say(EVIDENCE.objective(entry), "Festival Organizer")
		return
	var step: int = EVIDENCE.reconstruction_step(entry)
	var prompt := "All five accounts are here. Ready to put the story together?"
	if step > 0: prompt = "You've confirmed %d of the six deductions. Ready to continue?" % step
	if await _ask(prompt, "Compare accounts" if step == 0 else "Continue puzzle", "Review accounts") == 1:
		await _review_accounts(entry)
		if await _ask("Ready to compare the accounts? You can take a break and return later.", "Compare accounts", "Later") != 0: return
	await _reconstruct()

func _reconstruct() -> void:
	while true:
		var entry: Dictionary = EVIDENCE.progress(Utils)
		if entry.get("GrawaiiReconstructed", false): return
		var step: int = EVIDENCE.reconstruction_step(entry)
		var question: Dictionary = EVIDENCE.RECONSTRUCTION[step]
		await _say("Evidence: " + question["Evidence"], "Festival Organizer")
		var answer: int = await _ask(question["Question"], question["Options"][0], question["Options"][1])
		if answer != question["Answer"]:
			await _say(question["Hint"], "Festival Organizer")
			if await _ask("Try this deduction again, or take a break? Your confirmed steps are saved.", "Try again", "Take a break") != 0: return
			continue
		if not EVIDENCE.advance_reconstruction(Utils, step):
			await _say("Let's check the accounts again before continuing. Your recorded clues are safe.", "Festival Organizer")
			return
		await _say("Confirmed (%d/6): %s" % [step + 1, question["Confirmed"]], "Festival Organizer")
		if step + 1 == EVIDENCE.RECONSTRUCTION.size():
			await _say("We've reconstructed his route. He may be trapped in the coastal archive; the eruption rumor is not proof that he went to the volcano.", "Festival Organizer")
			await _say("Search route recorded: coastal archive, via the eastern trail. Speak to the trail keeper about preparing the search.", "<none>")
			return
		if await _ask("Continue to the next deduction? Your confirmed steps are saved.", "Continue", "Take a break") != 0: return

func _choose(value: String) -> void:
	selected_choice = int(value)

func _ask(text: String, first: String, second: String) -> int:
	selected_choice = -1
	var pages: Array[String] = EVIDENCE.dialogue_pages(Utils, text)
	for i in pages.size() - 1:
		await _say(pages[i], "Festival Organizer")
	var line = DIALOGUE.new()
	line.text = pages.back()
	line.display = "Festival Organizer"
	for i in 2:
		var option = DIALOGUE.new()
		option.option_name = first if i == 0 else second
		option.is_end_node = true
		option.function = "_choose"
		option.func_node = self
		option.args.assign([str(i)])
		line.add_child(option)
	add_child(line)
	var manager = Utils.get_scene_manager()
	manager.transition_to_dialogue(line)
	await manager.get_node("DialogueBox").dialogue_ended
	await get_tree().process_frame
	line.queue_free()
	return selected_choice

func _homecoming() -> void:
	homecoming_pending = false
	busy = true
	await _say("You found him! Welcome home. We were so worried when you didn't return.", "Festival Organizer")
	await _say("The original ending is safe. Your careful search brought us both back. Give me a moment to rest; then we can prepare our festival story.", "The Storyteller")
	EVIDENCE.advance_archive(Utils, "homecoming")
	homecoming_pending = false
	_finish()
