extends Node2D
## Tech Town's handoff to the power plant, unlocked by the brawl and signs.

const DIALOGUE_NODE = preload("res://Scripts/DialogueNode.gd")
const QUEST_COUNT := 3
const REQUIRED_QUEST_IDS := [1, 2]
const BRIEFED_KEY := "PowerPlantBriefed"
const MEETING_PROMPT_KEY := "StaticMeetingPrompted"

var busy := false
var briefed := false
var available := false
var meeting_prompted := false
var refresh_time := 0.0
var interaction_after := 0

@onready var body_shape: CollisionShape2D = $Body/CollisionShape2D

func _ready() -> void:
	_refresh_availability()

func _refresh_availability() -> void:
	var quests: Array = Utils.load_json_file("res://Data/Quests.json")
	available = quests.size() >= QUEST_COUNT
	if available:
		for i in REQUIRED_QUEST_IDS:
			available = available and quests[i].get("Progress", "Incoming") == "Completed"
	briefed = quests.size() >= QUEST_COUNT and quests[2].get(BRIEFED_KEY, false)
	meeting_prompted = quests.size() >= QUEST_COUNT and quests[2].get(MEETING_PROMPT_KEY, false)
	visible = available
	body_shape.set_deferred("disabled", not available)

func _process(delta: float) -> void:
	if busy:
		return
	refresh_time -= delta
	if refresh_time > 0.0:
		return
	refresh_time = 0.25
	_refresh_availability()
	if available and not briefed and _can_show_message():
		if not meeting_prompted:
			_prompt_meeting()
		elif _can_talk():
			start_briefing()

func _can_show_message() -> bool:
	if not is_visible_in_tree() or Time.get_ticks_msec() < interaction_after:
		return false
	var manager = Utils.get_scene_manager()
	if manager.menu.screen_loaded != manager.menu.ScreenLoaded.NOTHING:
		return false
	var player = Utils.get_player()
	return player != null and not player.is_moving and player.is_physics_processing()

func _can_talk() -> bool:
	return _can_show_message() and Utils.get_player().global_position.distance_to(global_position) <= 40.0

func _prompt_meeting() -> void:
	busy = true
	await _say("Both quests are complete! Head south to the junkyard entrance to meet Chief Static.", "<none>")
	var quests: Array = Utils.load_json_file("res://Data/Quests.json")
	quests[2][MEETING_PROMPT_KEY] = true
	Utils.save_json_file("res://Data/Quests.json", quests)
	meeting_prompted = true
	interaction_after = Time.get_ticks_msec() + 200
	busy = false

func _unhandled_input(event: InputEvent) -> void:
	if busy or not available or event.is_echo() or not event.is_action_pressed("z"):
		return
	if not _can_talk():
		return
	var player = Utils.get_player()
	var facing: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][player.facing_direction]
	if (global_position - player.global_position).dot(facing) < 4.0:
		return
	get_viewport().set_input_as_handled()
	start_briefing()

func start_briefing() -> void:
	if busy or not available or not _can_talk():
		return
	busy = true
	if not briefed:
		await _say("You've helped put Tech Town back in order. Thank you, <player>.")
		await _say("But Team rammarG is targeting our power plant. It supplies electricity to the whole region!")
		await _say("It's time we stopped them. Meet me at the power plant, just east of the junkyard.")
		var quests: Array = Utils.load_json_file("res://Data/Quests.json")
		quests[2][BRIEFED_KEY] = true
		Utils.save_json_file("res://Data/Quests.json", quests)
		briefed = true
	else:
		await _say("The power plant is just east of the junkyard. Let's stop Team rammarG before they cut the power!")
	interaction_after = Time.get_ticks_msec() + 200
	busy = false

func _say(text: String, speaker: String = "Chief Static") -> void:
	var line = DIALOGUE_NODE.new()
	line.name = "PowerPlantBriefing"
	line.text = text
	line.display = speaker
	line.is_end_node = true
	add_child(line)
	var manager = Utils.get_scene_manager()
	manager.transition_to_dialogue(line)
	await manager.get_node("DialogueBox").dialogue_ended
	line.queue_free()
