extends Node2D
## Part 2: independent witness accounts and two optional-to-start, required-to-win matches.
const EVIDENCE = preload("res://Scripts/Specialized/GrawaiiEvidence.gd")
const DIALOGUE = preload("res://Scripts/DialogueNode.gd")
const TRAINERS := {"CanoeRacer": "Grawaii Canoe Racer", "TrailKeeper": "Grawaii Trail Keeper"}
const PRACTICE_MOVES := {
	"Grawaii Canoe Racer": ["Papercut", "Bite", "Leaf Lash", "Howl"],
	"Grawaii Trail Keeper": ["Lab Report", "Period Punch", "Bite", "Intellectual Impass"]
}
const CLUES := {"CanoeRacer": "racer_route", "TrailKeeper": "keeper_rockfall"}
var busy := false
var interaction_after := 0
var selected_choice := -1
var pending_actor := ""
var return_actor := ""

func _ready() -> void:
	refresh_story_actors()
	Utils.get_scene_manager().get_node("CurrentScene").child_entered_tree.connect(_on_scene_child)

func _available() -> bool:
	if busy or Time.get_ticks_msec() < interaction_after or not is_visible_in_tree(): return false
	var manager = Utils.get_scene_manager()
	var player = Utils.get_player()
	return manager.menu.screen_loaded == manager.menu.ScreenLoaded.NOTHING and player != null and player.is_physics_processing() and not player.is_moving

func _process(_delta: float) -> void:
	if not return_actor.is_empty() and _available():
		var actor := return_actor
		return_actor = ""
		_present_battle_account(actor)

func _present_battle_account(actor: String) -> void:
	busy = true
	await _say("Account recorded: %s. (%d/5)" % ["The Eastern Route" if actor == "CanoeRacer" else "The Rockfall", EVIDENCE.count_clues(EVIDENCE.progress(Utils))], "<none>")
	busy = false
	talk_to(actor)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("z") or not _available(): return
	var player = Utils.get_player()
	var facing: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][player.facing_direction]
	for actor in get_children():
		if not actor is Node2D or not actor.has_meta("witness") or not actor.is_visible_in_tree(): continue
		var offset: Vector2 = actor.global_position - player.global_position
		if offset.dot(facing) >= 4.0 and offset.dot(facing) <= 24.0 and absf(offset.cross(facing)) <= 8.0:
			get_viewport().set_input_as_handled()
			talk_to(str(actor.name))
			return

func talk_to(actor: String) -> void:
	if busy: return
	busy = true
	var story: Dictionary = EVIDENCE.progress(Utils)
	if story.get("GrawaiiStorytellerRescued", false) and actor in ["Fisherman", "CanoeRacer", "TrailKeeper"]:
		await _say("The Storyteller is safely back at the festival green. I'm glad our accounts helped you find him. We'll get ready for the celebration next.", "Trail Keeper" if actor == "TrailKeeper" else ("Fisherman" if actor == "Fisherman" else "Canoe Racer"))
		_finish()
		return
	match actor:
		"Fisherman":
			await _say("I saw the Storyteller heading toward the eastern trail this morning. Later, a Team rammarG scout went that way alone.", "Fisherman")
			await _say("They weren't traveling together. I saw the scout myself; the eruption warning is only something people have been repeating.", "Fisherman")
			await _record("fisherman_scout", "The Scout Arrived Later")
		"CanoeRacer":
			if EVIDENCE.has_clue(Utils, "racer_route"):
				await _say("After the morning bell, he carried a wrapped manuscript along the eastern trail toward the coastal archive. That's the route I saw.", "Canoe Racer")
			else:
				await _say("I saw him heading east this morning. Please pass that on now. I was timing my canoe practice when he passed.", "Canoe Racer")
				await _say("I'm joining the search along the coast. A friendly match will help us prepare our Grammarites; then I'll check my timing notes for the exact route.", "Canoe Racer")
				if await _ask("Ready for a friendly match? You can come back whenever you're ready.", "Battle", "Later", "Canoe Racer") == 0:
					if _can_battle():
						_begin_battle(actor)
					else:
						await _say("You'll need a healthy Grammarite first. Heal your party, then come back; your other accounts are safe.", "Canoe Racer")
		"TrailKeeper":
			if story.get("GrawaiiScoutDefeated", false):
				await _say("You found him tapping behind the rocks, and the scout has retreated? I'll bring tools. The entrance is southeast of this green, beyond the eastern trail sign.", "Trail Keeper")
				if await _ask("Shall I bring the tools to the archive now?", "Send help", "Later", "Trail Keeper") == 0:
					EVIDENCE.advance_archive(Utils, "help")
					await _say("I'll meet you beside the blocked doorway. Don't try to move the unstable rocks alone.", "Trail Keeper")
					refresh_story_actors()
			elif story.get("GrawaiiReconstructed", false):
				await _say("The coastal archive is southeast of the green. Go east past this sign, then south to the cliff entrance. Check the situation, then send word if you need my tools.", "Trail Keeper")
			elif EVIDENCE.has_clue(Utils, "keeper_rockfall"):
				await _say("He entered the coastal archive BEFORE the rocks fell. The rockfall blocked his way out. I can bring tools once we organize the search.", "Trail Keeper")
			else:
				await _say("I saw him enter the coastal archive. A rockfall blocked the entrance afterward. I've kept everyone off the unstable approach while we prepare tools.", "Trail Keeper")
				await _say("Before we go near that slope, let's check the evidence and make sure your Grammarites are ready to help.", "Trail Keeper")
				var answer := await _ask("He entered. THEN the rocks fell. Which account keeps that order?", "Entered before rockfall", "Entered after rockfall", "Trail Keeper")
				if answer != 0:
					await _say("He was already inside when the rocks fell. 'Before' puts his entrance first. Read the order carefully, then try again.", "Trail Keeper")
				elif await _ask("Exactly. Ready for a short practice battle before the search?", "Battle", "Later", "Trail Keeper") == 0:
					if _can_battle(): _begin_battle(actor)
					else: await _say("Heal your Grammarites before we practice. I'll stay here, and you can retry when you're ready.", "Trail Keeper")
		"TrailSign":
			if story.get("GrawaiiStorytellerRescued", false):
				await _say("COASTAL ARCHIVE SEARCH COMPLETE\nThe Storyteller is safely back at the festival green.", "<none>")
			elif story.get("GrawaiiArchiveCleared", false):
				await _say("COASTAL ARCHIVE\nThe entrance southeast of the green is clear. The search party has gone inside.", "<none>")
			elif story.get("GrawaiiReconstructed", false):
				await _say("CONFIRMED SEARCH ROUTE: COASTAL ARCHIVE\nFollow the eastern trail. Rockfall at the entrance; coordinate with the trail keeper.", "<none>")
			else:
				await _say("EASTERN TRAIL - COASTAL ARCHIVE\nRockfall reported. Speak to the trail keeper before approaching.", "<none>")
	_finish()

func _can_battle() -> bool:
	for member in Utils.get_party():
		if not member.get("Name", "").is_empty() and member.get("Health", 0) > 0: return true
	return false

func _begin_battle(actor: String) -> void:
	pending_actor = actor
	# The shared defeat path resets trainer flags by exact trainer name.
	var state: Dictionary = Utils.load_json_file("res://Data/Scenes.json")
	var scene_name: String = Utils.get_scene_manager().get_node("CurrentScene").get_child(0).name
	if not state.has(scene_name): state[scene_name] = {}
	if not state[scene_name].has("Trainers"): state[scene_name]["Trainers"] = {}
	state[scene_name]["Trainers"][TRAINERS[actor]] = {"Talked": false}
	Utils.save_json_file("res://Data/Scenes.json", state)
	Utils.get_scene_manager().transition_to_battle(TRAINERS[actor])

func _on_scene_child(child: Node) -> void:
	if pending_actor.is_empty() or not child.has_node("BattleManager"): return
	var battle_manager = child.get_node("BattleManager")
	if battle_manager.trainer != TRAINERS[pending_actor]: return
	battle_manager.battle_ended.connect(_on_battle_ended, CONNECT_ONE_SHOT)
	child.ready.connect(_prepare_practice_battle.bind(child), CONNECT_ONE_SHOT)

func _prepare_practice_battle(battle: Node) -> void:
	# Most species still share a placeholder 30-damage Dragon Dance. These
	# friendly witness matches use deliberate move sets without changing species data.
	var bm = battle.get_node("BattleManager")
	var moves: Array = []
	for move_name in PRACTICE_MOVES[bm.trainer]:
		var move: Dictionary = Utils.get_move(move_name)
		move["Name"] = move_name
		moves.append(move)
	bm.enemy_grammarite.grammarite_info["Moves"] = moves
	bm.setup_enemy_pp()


func _on_battle_ended(won: bool) -> void:
	var actor := pending_actor
	pending_actor = ""
	if won and CLUES.has(actor):
		EVIDENCE.record(Utils, CLUES[actor])
		return_actor = actor

func _record(key: String, title: String) -> void:
	if EVIDENCE.record(Utils, key):
		await _say("Account recorded: %s. (%d/5)" % [title, EVIDENCE.count_clues(EVIDENCE.progress(Utils))], "<none>")
	else:
		await _say("This account is already recorded. Ask the organizer to review your evidence or check your quest log for the remaining witnesses.", "<none>")

func _choose(value: String) -> void:
	selected_choice = int(value)

func _ask(text: String, first: String, second: String, speaker: String) -> int:
	selected_choice = -1
	var pages: Array[String] = EVIDENCE.dialogue_pages(Utils, text)
	for i in pages.size() - 1:
		await _say(pages[i], speaker)
	var line = DIALOGUE.new()
	line.text = pages.back()
	line.display = speaker
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
	# Dialogue calls the selected option's function immediately after emitting.
	await get_tree().process_frame
	line.queue_free()
	return selected_choice

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

func _finish() -> void:
	busy = false
	interaction_after = Time.get_ticks_msec() + 250

func refresh_story_actors() -> void:
	var entry: Dictionary = EVIDENCE.progress(Utils)
	var away: bool = entry.get("GrawaiiArchiveHelpRequested", false) and not entry.get("GrawaiiStorytellerRescued", false)
	$TrailKeeper.visible = not away
	$TrailKeeper/Body.collision_layer = 0 if away else 18
	if get_parent().has_node("ArchiveApproach"):
		get_parent().get_node("ArchiveApproach").refresh_story()
