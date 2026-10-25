extends Node2D
## Shared controller for the outdoor entrance and the enclosed archive room.
const E = preload("res://Scripts/Specialized/GrawaiiEvidence.gd")
const DIALOGUE = preload("res://Scripts/DialogueNode.gd")
const TRAINER := "Grawaii Archive Scout"
const OUTSIDE_SPAWN := Vector2(7360, 288)
const RETURN_SPAWN := Vector2(6976, 64)
const SCOUT_MOVES := ["Jargon Jumble", "Lab Report", "Bite", "Papercut"]
@export var inside := false
var busy := false
var interaction_after := 0
var selected_choice := -1
var pending_battle := false
var victory_pending := false
var heard_tapping := false
var returning_to_green := false
var story_state: Dictionary = {}
var room_refresh_after := 0.0

func _ready() -> void:
	refresh_story()
	if not inside:
		Utils.get_scene_manager().get_node("CurrentScene").child_entered_tree.connect(_on_scene_child)

func refresh_story() -> void:
	var entry: Dictionary = E.progress(Utils)
	story_state = entry
	if inside:
		$Sorted/Storyteller.visible = not entry.get("GrawaiiStorytellerRescued", false)
		$Sorted/Storyteller/Body.collision_layer = 0 if entry.get("GrawaiiStorytellerRescued", false) else 18
		$Sorted/Manuscript/Note.visible = not entry.get("GrawaiiManuscriptRecovered", false)
	else:
		var clear: bool = entry.get("GrawaiiArchiveCleared", false)
		$Rubble.visible = not clear
		$Rubble/Body.collision_layer = 0 if clear else 18
		$Entrance.collision_layer = 8 if clear else 0
		$Scout.visible = not entry.get("GrawaiiScoutDefeated", false)
		$Scout/Body.collision_layer = 0 if entry.get("GrawaiiScoutDefeated", false) else 18
		var help_here: bool = entry.get("GrawaiiArchiveHelpRequested", false) and not entry.get("GrawaiiStorytellerRescued", false)
		$Keeper.visible = help_here
		$Keeper/Body.collision_layer = 18 if help_here else 0

func _available() -> bool:
	if busy or Time.get_ticks_msec() < interaction_after or not is_visible_in_tree(): return false
	var manager = Utils.get_scene_manager()
	var player = Utils.get_player()
	return player != null and player.is_physics_processing() and not player.is_moving and manager.menu.screen_loaded == manager.menu.ScreenLoaded.NOTHING

func _process(delta: float) -> void:
	if inside:
		room_refresh_after -= delta
		if room_refresh_after <= 0.0:
			room_refresh_after = 0.25
			refresh_story()
		return
	if not _available(): return
	if victory_pending:
		victory_pending = false
		_after_victory()
		return
	if not heard_tapping and story_state.get("GrawaiiReconstructed", false) and not story_state.get("GrawaiiArchiveCleared", false):
		if Utils.get_player().global_position.distance_to($Rubble.global_position) <= 56.0:
			_tapping()

func _input(_event: InputEvent) -> void:
	# Do not let a menu interrupt the escort fade after dialogue has ended.
	if returning_to_green: get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("z") or not _available(): return
	var player = Utils.get_player()
	var facing: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][player.facing_direction]
	var actors: Array = $Sorted.get_children() if inside else get_children()
	for actor in actors:
		if not actor is Node2D or not actor.has_meta("archive_action") or not actor.is_visible_in_tree(): continue
		var offset: Vector2 = actor.global_position - player.global_position
		if offset.dot(facing) >= 4.0 and offset.dot(facing) <= 24.0 and absf(offset.cross(facing)) <= 8.0:
			get_viewport().set_input_as_handled()
			talk_to(str(actor.name))
			return

func _tapping() -> void:
	busy = true
	heard_tapping = true
	await _say("Tap... tap... tap. A voice calls from behind the fallen rocks: 'Is someone there? The entrance is blocked! Please send help!'", "<none>")
	_finish()

func talk_to(actor: String) -> void:
	if busy: return
	busy = true
	var entry: Dictionary = E.progress(Utils)
	match actor:
		"ArchiveSign":
			if entry.get("GrawaiiArchiveCleared", false):
				await _say("COASTAL ARCHIVE\nHistoric manuscripts and festival records. Entrance cleared by the search party.", "<none>")
			else:
				await _say("COASTAL ARCHIVE\nHistoric manuscripts and festival records. Entrance blocked by a rockfall.", "<none>")
		"Scout":
			if entry.get("GrawaiiScoutDefeated", false):
				_finish()
				return
			if not entry.get("GrawaiiReconstructed", false):
				await _say("This approach isn't safe. Check the witnesses' accounts with the festival organizer before beginning a search here.", "<none>")
			else:
				heard_tapping = true
				await _say("You hear tapping from behind the blocked doorway. Someone inside is calling for help.", "<none>")
				await _say("Stay back! The volcano could erupt any moment. There's nothing worth looking for in this archive.", "rammarG Scout")
				await _say("That alcove contains discarded manuscript pages. The scout seems more interested in searching them than leaving the area.", "<none>")
				if await _ask("The accounts point here, and someone needs help. Challenge the scout?", "Challenge", "Prepare first") == 0:
					if _can_battle(): _begin_battle()
					else: await _say("Your party needs a healthy Grammarite before this encounter. Heal first; your investigation is saved.", "<none>")
		"Rubble":
			if not entry.get("GrawaiiReconstructed", false):
				await _say("Unstable fallen rocks block the archive doorway. Compare all five accounts with the organizer before organizing a search.", "<none>")
			elif not entry.get("GrawaiiScoutDefeated", false):
				heard_tapping = true
				await _say("You hear tapping behind the rocks. Someone is alive inside! The scout is standing beside the archive; deal with them before bringing the keeper here.", "<none>")
			else:
				await _say(E.objective(entry), "<none>")
		"Keeper":
			if not entry.get("GrawaiiArchiveHelpRequested", false):
				await _say("Ask the trail keeper east of the green to bring tools after the scout retreats.", "<none>")
			elif not entry.get("GrawaiiArchiveCleared", false):
				await _say("I brought wedges and a lever. I'll brace the loose stones and clear the doorway. Stand back while I work.", "Trail Keeper")
				if await _ask("Ready for the keeper to clear the entrance?", "Clear the rocks", "Not yet") == 0:
					if E.advance_archive(Utils, "clear"):
						refresh_story()
						await _say("The keeper braces the loose stones and shifts the fallen rocks away from the doorway. The entrance is clear.", "<none>")
						await _say("Go inside and check on him. I'll keep watch here while you bring him out.", "Trail Keeper")
			else:
				await _say("The entrance is clear. Go inside and find the Storyteller; I'll keep watch here.", "Trail Keeper")
		"Storyteller":
			if not entry.get("GrawaiiArchiveCleared", false):
				await _say("The doorway is still blocked. The search party needs to clear the entrance before anyone can be escorted out.", "The Storyteller")
			elif not entry.get("GrawaiiStorytellerRescued", false):
				await _say("You found me! I came to retrieve the original ending for the festival. The rocks fell after I entered, and I couldn't move them from this side.", "The Storyteller")
				await _say("I kept tapping in the hope someone would hear. Thank you for following what actually happened instead of that warning.", "The Storyteller")
				await _say("Here is the original ending. An old passage mentions the book, but the wording puzzles me. The Grammaster may be able to interpret it.", "The Storyteller")
				await _say("Let's take the manuscript back to the festival green together.", "The Storyteller")
				if E.advance_archive(Utils, "rescue"):
					refresh_story()
					returning_to_green = true
					Utils.get_scene_manager().transition_to_scene("res://Scenes/Town.scn", RETURN_SPAWN, Vector2.UP)
					# Keep this scene locked until the fade removes it.
					Utils.get_player().set_physics_process(false)
					return
		"Manuscript":
			if entry.get("GrawaiiManuscriptRecovered", false):
				await _say("The original ending has been taken safely to the festival green. The remaining records stay here for future storytellers.", "<none>")
			else:
				await _say("Old festival endings are carefully arranged on the reading desk. The Storyteller can explain the passage he found.", "<none>")
		"Shelves":
			await _say("Festival histories, coastal charts, and handwritten stories fill these shelves. These are community records, carefully kept for future storytellers.", "<none>")
	_finish()

func _can_battle() -> bool:
	for member in Utils.get_party():
		if not member.get("Name", "").is_empty() and member.get("Health", 0) > 0: return true
	return false

func _begin_battle() -> void:
	pending_battle = true
	var state: Dictionary = Utils.load_json_file("res://Data/Scenes.json")
	var scene_name: String = Utils.get_scene_manager().get_node("CurrentScene").get_child(0).name
	if not state.has(scene_name): state[scene_name] = {}
	if not state[scene_name].has("Trainers"): state[scene_name]["Trainers"] = {}
	state[scene_name]["Trainers"][TRAINER] = {"Talked": false}
	Utils.save_json_file("res://Data/Scenes.json", state)
	Utils.get_scene_manager().transition_to_battle(TRAINER)

func _on_scene_child(child: Node) -> void:
	if not pending_battle or not child.has_node("BattleManager"): return
	var bm = child.get_node("BattleManager")
	if bm.trainer != TRAINER: return
	bm.battle_ended.connect(_on_battle_ended, CONNECT_ONE_SHOT)
	child.ready.connect(_prepare_scout.bind(child), CONNECT_ONE_SHOT)

func _prepare_scout(battle: Node) -> void:
	var bm = battle.get_node("BattleManager")
	var moves: Array = []
	for move_name in SCOUT_MOVES:
		var move: Dictionary = Utils.get_move(move_name)
		move["Name"] = move_name
		moves.append(move)
	bm.enemy_grammarite.grammarite_info["Moves"] = moves
	bm.setup_enemy_pp()

func _on_battle_ended(won: bool) -> void:
	pending_battle = false
	if won and E.advance_archive(Utils, "scout"):
		refresh_story()
		victory_pending = true

func _after_victory() -> void:
	busy = true
	await _say("Fine! I posted the warning to keep people away while I searched these pages for the book. I didn't make the rocks fall. I'm leaving!", "rammarG Scout")
	await _say("The scout retreats. Someone is still tapping behind the rocks. Ask the trail keeper east of the festival green to bring tools.", "<none>")
	_finish()

func _choose(value: String) -> void:
	selected_choice = int(value)

func _ask(text: String, first: String, second: String) -> int:
	selected_choice = -1
	var pages: Array[String] = E.dialogue_pages(Utils, text)
	for i in pages.size() - 1: await _say(pages[i], "<none>")
	var line = DIALOGUE.new()
	line.text = pages.back()
	line.display = "<none>"
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

func _say(text: String, speaker: String) -> void:
	for page in E.dialogue_pages(Utils, text):
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
