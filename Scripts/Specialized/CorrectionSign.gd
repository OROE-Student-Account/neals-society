extends "res://Scripts/Sign.gd"

@export var correction_id := "pipe_water"
var lesson: Node

func _ready() -> void:
	super._ready()
	# These signs sit halfway between the player's tile rows. The inherited
	# proximity circle and full-tile rectangle overlap the player's ray origin
	# when reading from below, trapping movement in every direction. Interaction
	# already uses distance/facing, so only the visible sign needs a blocker.
	$CollisionShape2D.disabled = true
	var blocker := RectangleShape2D.new()
	blocker.size = Vector2(16, 8)
	$CollisionShape2D2.shape = blocker
	$CollisionShape2D2.position = Vector2(8, 4)
	lesson = load("res://Scripts/Specialized/SignCorrectionLesson.gd").new()
	lesson.name = "SignLesson"
	add_child(lesson)
	refresh_text()

func refresh_text() -> void:
	var question: Dictionary = Utils.load_json_file("res://GrammariteData/SignCorrections.json")[correction_id]
	var progress: Dictionary = lesson.read_progress()
	text = question["Corrected"] if correction_id in progress.get("CorrectedSigns", []) else question["Question"]
	root_node.text = text

func _unhandled_input(event: InputEvent) -> void:
	if disabled or lesson.busy or event.is_echo() or not event.is_action_pressed("z"):
		return
	var manager = Utils.get_scene_manager()
	var player = Utils.get_player()
	if manager.menu.screen_loaded != manager.menu.ScreenLoaded.NOTHING or player.is_moving:
		return
	var offset: Vector2 = global_position - player.global_position
	var facing: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][player.facing_direction]
	if offset.length() > 32.0 or offset.dot(facing) < 4.0:
		return

	disabled = true
	get_viewport().set_input_as_handled()
	lesson.start_sign()
