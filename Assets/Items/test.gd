extends Control

const LANES = ["ui_left", "ui_down", "ui_up", "ui_right"]

#fun stuff
var NOTE_SPEED = 200.0
var SPAWN_INTERVAL = 0.5
var HIT_WINDOW = 40.0

var current_pattern = []
var pattern_index = 0

# also fun I suppose
var patterns = [
	[0, 1, 0, 1],      # left-right alternation
	[2, 2, 3, 3],      # up-up-right-right
	[0, 2, 1, 3],      # cross pattern
	[3, 2, 1, 0],      # reverse sweep
	[1, 1, 2],         # small repeat
	[0, 3, 0],         # bounce
]

var lane_width
var notes = []
var spawn_timer = 0.0
var game_started = false

var patterns_to_play := 5
var patterns_completed := 0

var hits := 0
var misses := 0

var game_result := false

func begin_game() -> bool:
	game_started = true
	
	anchor_right = 1
	anchor_bottom = 1
	lane_width = size.x / 4.0

	create_lanes()

	
	patterns_completed = 0

	hits = 0
	misses = 0

	spawn_timer = 0
	current_pattern = []
	pattern_index = 0

	for note_data in notes:
		note_data["node"].queue_free()
	notes.clear()
	
	var strategy = randi()%4
	# strategy = 2 # testing
	
	if strategy == 0:
		NOTE_SPEED = 200.0
		SPAWN_INTERVAL = 0.5
		HIT_WINDOW = 40.0
		patterns_to_play = 5
	if strategy == 1:
		NOTE_SPEED = 300.0
		SPAWN_INTERVAL = 0.6
		HIT_WINDOW = 50.0
		patterns_to_play = 4
	if strategy == 2:
		NOTE_SPEED = 125.0
		SPAWN_INTERVAL = 0.35
		HIT_WINDOW = 30.0
		patterns_to_play = 10
	if strategy == 3:
		NOTE_SPEED = 220.0
		SPAWN_INTERVAL = 0.42
		HIT_WINDOW = 35.0
		patterns_to_play = 7
	
	
	while game_started:
		await get_tree().process_frame

	return game_result # will be updated when game end
func end_game():
	game_started = false

	game_result = hits > misses

func create_lanes():
	for i in range(4):
		var lane = ColorRect.new()
		lane.color = Color(0.1, 0.1, 0.1, 0.6)
		lane.position = Vector2(i * lane_width, 0)
		lane.size = Vector2(lane_width, size.y)
		add_child(lane)

	# Hit line
	var hit_line = ColorRect.new()
	hit_line.color = Color(1, 1, 1)
	hit_line.size = Vector2(size.x, 5)
	hit_line.position = Vector2(0, 0.9*size.y-10)
	add_child(hit_line)

func _process(delta):
	if not game_started:
		return

	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0
		spawn_note()

	move_notes(delta)

func spawn_note():
	# Pick a new pattern if needed
	if current_pattern.is_empty() or pattern_index >= current_pattern.size():
		patterns_completed += 1

		# END GAME if done
		if patterns_completed > patterns_to_play:
			end_game()
			return

		if randf() < 0.3 and not current_pattern.is_empty():
			current_pattern = current_pattern.duplicate()
		else:
			current_pattern = patterns[randi() % patterns.size()]

		pattern_index = 0

	var lane_index = current_pattern[pattern_index]

	# 20% chance to slightly vary
	if randf() < 0.2:
		lane_index = randi() % 4
	pattern_index += 1
	
	# --- your existing note code ---
	var note = ColorRect.new()
	match lane_index:
		0: note.color = Color(0.2, 0.8, 0.)
		1: note.color = Color(0.8, 0.2, 0.2)
		2: note.color = Color(0.2, 0.2, 0.8)
		3: note.color = Color(0.8, 0.8, 0.2)
	
	note.size = Vector2(lane_width - 10, 20)
	note.position = Vector2(
		lane_index * lane_width + 5,
		-20
	)

	add_child(note)

	# --- arrow ---
	var arrow = Polygon2D.new()
	arrow.color = Color.WHITE
	arrow.polygon = PackedVector2Array([
		Vector2(0, -10),
		Vector2(8, 10),
		Vector2(-8, 10)
	])
	arrow.position = note.size / 2

	match lane_index:
		0: arrow.rotation_degrees = -90
		1: arrow.rotation_degrees = 180
		2: arrow.rotation_degrees = 0
		3: arrow.rotation_degrees = 90

	note.add_child(arrow)

	notes.append({
		"node": note,
		"lane": lane_index
	})

func move_notes(delta):
	for note_data in notes:
		var note = note_data["node"]
		note.position.y += NOTE_SPEED * delta

	# cleanup off-screen notes
	notes = notes.filter(func(n):
		if n["node"].position.y > size.y + 50:
			misses += 1
			n["node"].queue_free()
			return false
		return true
	)

func _input(event):
	for i in range(4):
		if event.is_action_pressed(LANES[i]):
			check_hit(i)

func check_hit(lane_index):
	var hit_y = size.y * 0.9

	for note_data in notes:
		if note_data["lane"] != lane_index:
			continue

		var note = note_data["node"]
		var distance = abs(note.position.y - hit_y)

		if distance <= HIT_WINDOW:
			hits += 1
			note.queue_free()
			notes.erase(note_data)
			return

	misses += 1
