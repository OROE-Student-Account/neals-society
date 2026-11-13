extends Node2D
## Festival presentation and optional healing. The opening owns the dialogue lock.
const E = preload("res://Scripts/Specialized/GrawaiiEvidence.gd")
const REUNION_SPAWN := Vector2(6976, 64)
const FESTIVAL_SPAWN := Vector2(7056, 96)
const REUNION_POSITION := Vector2(-80, -16)
const FOOD = preload("res://Assets/Decoration/Grawaii/Food stand.png")
@onready var opening = get_parent()
var original_positions: Dictionary = {}
var original_tables: Dictionary = {}
var music: AudioStreamPlayer2D

func _ready() -> void:
	for actor in ["Fisherman", "CanoeRacer", "TrailKeeper"]:
		original_positions[actor] = opening.get_node("Witnesses/" + actor).position
	for table in ["FestivalTable", "FestivalTable2"]:
		original_tables[table] = opening.get_node(table + "/Sprite2D").texture
	music = AudioStreamPlayer2D.new()
	music.name = "FestivalMusic"
	music.stream = preload("res://Assets/Sound/GrawaiiFestival.wav")
	music.volume_db = -15.0
	music.max_distance = 300.0
	music.attenuation = 1.4
	add_child(music)
	refresh(E.progress(Utils))

func refresh(entry: Dictionary) -> void:
	# Opening._ready runs after this child's _ready; all references are ready here.
	var active: bool = entry.get("GrawaiiFestivalOpen", false)
	$Celebration.visible = active
	var storyteller = opening.get_node("ReturnedStoryteller")
	storyteller.position = Vector2(8, -32) if active else REUNION_POSITION
	# The performer must draw above the stage artwork, independent of Y sorting.
	storyteller.z_index = 1 if active else 0
	storyteller.get_node("Body").collision_layer = 0 if active or not entry.get("GrawaiiStorytellerRescued", false) else 18
	var spots := {"Fisherman": Vector2(-16, 96), "CanoeRacer": Vector2(48, 96), "TrailKeeper": Vector2(96, 96)}
	for actor in original_positions:
		opening.get_node("Witnesses/" + actor).position = spots[actor] if active else original_positions[actor]
	for table in original_tables:
		opening.get_node(table + "/Sprite2D").texture = FOOD if active else original_tables[table]
	if active and not music.playing: music.play()
	elif not active: music.stop()

func _process(_delta: float) -> void:
	# Dialogue keeps the music; menus and battles pause it with the hidden world.
	music.stream_paused = not opening.is_visible_in_tree() or Utils.get_scene_manager().menu.screen_loaded not in [Utils.get_scene_manager().menu.ScreenLoaded.NOTHING, Utils.get_scene_manager().menu.ScreenLoaded.DIALOGUE]

func organizer() -> void:
	var entry: Dictionary = E.progress(Utils)
	if not entry.get("GrawaiiFestivalOpen", false):
		await opening._say("The Storyteller has rested, and the original ending is ready. Shall we open the Festival of Stories?", "Festival Organizer")
		if await opening._ask("You can begin whenever you're ready.", "Open festival", "Later") != 0: return
		if not await opening.get_node("Staging").fade_to(_open_festival, FESTIVAL_SPAWN): return
		await opening._say("The food stalls are open! Everyone, gather by the stage. Our Storyteller has come home.", "Festival Organizer")
		await perform()
	elif not entry.get("GrawaiiFestivalEndingSeen", false):
		if await opening._ask("The Storyteller is ready to finish the closing story. Join him?", "Join the story", "Later") == 0:
			await perform()
	else:
		if entry.get("GrawaiiTrialRewardClaimed", false):
			await opening._say("Our Storyteller is home, the festival is open, and you've earned the Grammaster's token. Enjoy the celebration! He can review his clue whenever you need it.", "Festival Organizer")
		else:
			await opening._say("The Festival of Stories is open! Enjoy the food and music. The cook can restore your party for free, and the Grammaster would like a word when you're ready.", "Festival Organizer")
		if await opening._ask("Would you like to review the accounts that brought our Storyteller home?", "Review accounts", "Later") == 0:
			await opening._review_accounts(entry)

func place_reunion() -> bool:
	opening._sync_story()
	return true

func _open_festival() -> bool:
	if not E.advance_festival(Utils, "open"): return false
	opening._sync_story()
	return true

func perform() -> void:
	var entry: Dictionary = E.progress(Utils)
	if not entry.get("GrawaiiFestivalOpen", false): return
	if entry.get("GrawaiiFestivalEndingSeen", false):
		await opening._say("A story grows clearer when we listen to one another. Thank you for helping us finish ours. Enjoy the celebration!", "The Storyteller")
		return
	await opening._say("Once, a village heard a bell beyond a dark hill. One voice said it meant danger; another said it meant someone was waiting.", "The Storyteller")
	await opening._say("Each neighbor held one piece of the story. They listened, put the pieces in order, and found a traveler who needed help.", "The Storyteller")
	await opening._say("Here is our original ending. Help me connect its final lines without changing what they mean.", "The Storyteller")
	while true:
		await opening._say("The neighbors listened to one another. ___, they understood the whole story.", "The Storyteller")
		var answer: int = await opening._ask("Which phrase connects listening with the understanding it helped bring about?", "As a result", "Before that", "The Storyteller")
		if answer == 0: break
		await opening._say("'Before that' places understanding before the listening. In this story, listening helped them understand, so the connection must show that result.", "The Storyteller")
		if await opening._ask("Try the ending again, or enjoy the festival and return later?", "Try again", "Take a break", "The Storyteller") != 0: return
	await opening._say("The neighbors listened to one another. As a result, they understood the whole story. And no traveler had to face the dark alone.", "The Storyteller")
	await opening._say("You did more than collect words. You listened carefully enough to bring someone home. This celebration belongs to all of us.", "The Storyteller")
	if E.advance_festival(Utils, "ending"):
		opening._sync_story()
		await opening._say("The closing story is complete! Enjoy the festival. Visit the cook for free healing, then speak to the Grammaster about his next trial.", "<none>")

func feast() -> void:
	await opening._say("A warm meal for the person who brought our Storyteller home! I can restore your whole party's health and move points, free of charge.", "Festival Cook")
	if await opening._ask("Rest and share a festival meal?", "Heal my party", "Later", "Festival Cook") != 0: return
	if heal_party():
		await opening._say("Your party's health and move points are restored. Come back whenever you need another meal!", "Festival Cook")
	else:
		await opening._say("You don't have any Grammarites in your party yet. You're still welcome to enjoy the celebration!", "Festival Cook")

func heal_party() -> bool:
	if not E.progress(Utils).get("GrawaiiFestivalOpen", false): return false
	var party: Array = Utils.get_party()
	var healed := false
	for member in party:
		if member.get("Name", "").is_empty(): continue
		healed = true
		member["Health"] = Utils.max_hp(member["Name"], member["Level"])
		# Match the existing party-healing bonus for a held Colon.
		if member.get("Item", "") == "Colon":
			member["Health"] = int(10 + member["Health"] * 1.1)
		var moves: Array = member.get("Moves", [])
		var pp: Array = member.get("PP", []).duplicate()
		while pp.size() < moves.size(): pp.append(0)
		for i in moves.size():
			pp[i] = 0 if str(moves[i]).is_empty() else Utils.get_move(moves[i])["PP"]
		member["PP"] = pp
	if healed: Utils.set_party(party)
	return healed

func grammaster() -> void:
	await opening.get_node("GrammasterTrial").talk()
