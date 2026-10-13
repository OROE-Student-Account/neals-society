extends Control

signal puzzle_exited
signal puzzle_completed

var correct_solution = { 0: 2, 1: 0, 2: 1 }
var current_connections = { 0: -1, 1: -1, 2: -1 }

var cursor_index: int = 0
var cursor_on_left_side: bool = true
var selected_wire: int = -1 

# --- VISUAL COORDINATES ---
var left_positions = [Vector2(40, 40), Vector2(40, 80), Vector2(40, 120)]
var right_positions = [Vector2(200, 40), Vector2(200, 80), Vector2(200, 120)]
# --- NODE REFERENCES ---
var active_wire_line: Line2D
var connection_lines: Array = []
var cursor_rect: ReferenceRect

func _ready() -> void:
	set_process_unhandled_input(true)
	set_anchors_preset(PRESET_FULL_RECT)
	
	_build_nodes()
	_update_visuals()

# --- 1. BUILD ALL NODES ON STARTUP ---
func _build_nodes() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.1, 0.95)
	bg.size = Vector2(240, 160)
	add_child(bg)
	
	# Confirmed Connection Lines (3 of them)
	for i in range(3):
		var line = Line2D.new()
		line.width = 8.0
		line.default_color = Color(0.2, 0.8, 0.2)
		line.visible = false # Hidden until connected
		add_child(line)
		connection_lines.append(line)
		
	# Active Held Wire Line
	active_wire_line = Line2D.new()
	active_wire_line.width = 4.0
	active_wire_line.default_color = Color(0.9, 0.8, 0.1)
	active_wire_line.visible = false
	add_child(active_wire_line)
	
	# Sockets (Squares instead of circles for ColorRects)
	var socket_size = Vector2(32, 20)
	var offset = socket_size / 2.0 # Used to center the squares on the coordinates
	
	var colors = [Color(randf(),randf(),randf()),Color(randf(),randf(),randf()),Color(randf(),randf(),randf()),]
	
	var flipped: Dictionary = {}

	for key in correct_solution:
		flipped[correct_solution[key]] = key
	
	for i in range(3):
		# Left Sockets
		var left_socket = ColorRect.new()
		left_socket.size = socket_size
		left_socket.position = left_positions[i] - offset
		left_socket.color = colors[i]
		add_child(left_socket)
		
		# Right Sockets
		var right_socket = ColorRect.new()
		right_socket.size = socket_size
		right_socket.position = right_positions[i] - offset
		right_socket.color = colors[flipped[i]]
		add_child(right_socket)
		
	# Cursor (A hollow box that wraps around the selected socket)
	cursor_rect = ReferenceRect.new()
	cursor_rect.size = Vector2(48, 48)
	cursor_rect.editor_only = false # Forces it to show up in-game!
	cursor_rect.border_color = Color.WHITE
	cursor_rect.border_width = 4.0
	add_child(cursor_rect)


# --- 2. INPUT LOGIC ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("q"):
		emit_signal("puzzle_exited")
		print("EMIT")
		exit() 
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_up"):
		cursor_index = max(0, cursor_index - 1)
		_update_visuals()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_down"):
		cursor_index = min(2, cursor_index + 1)
		_update_visuals()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		cursor_on_left_side = !cursor_on_left_side
		_update_visuals()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("z"):
		_handle_selection()
		get_viewport().set_input_as_handled()

func _handle_selection() -> void:
	if selected_wire == -1:
		selected_wire = cursor_index
		if not cursor_on_left_side:
			selected_wire += 3
			
			for key in current_connections:
				if current_connections[key] == cursor_index:
					current_connections[key] = -1
		else:
			current_connections[cursor_index] = -1
	else:
		if (selected_wire <= 2 and !cursor_on_left_side) or (selected_wire >= 3 and cursor_on_left_side):
			
			var index = cursor_index
			var val = selected_wire-3
			if not cursor_on_left_side:
				index = selected_wire
				val = cursor_index
				
				for key in current_connections:
					if current_connections[key] == cursor_index:
						current_connections[key] = -1
			
			current_connections[index] = val
			selected_wire = -1 
			_check_win_condition()
		else:
			selected_wire = cursor_index
			if not cursor_on_left_side:
				selected_wire += 3
	_update_visuals()

func _check_win_condition() -> void:
	var won = true
	for left_wire in correct_solution.keys():
		if current_connections[left_wire] != correct_solution[left_wire]:
			won = false
			break
			
	if won:
		print("PUZZLE SOLVED!")
		# ---> PUT YOUR SUCCESS CODE HERE <---
		
		emit_signal("puzzle_completed")
		exit() 


# --- 3. UPDATE THE NODES ---
func _update_visuals() -> void:
	# Update Confirmed Lines
	for left_idx in current_connections.keys():
		var right_idx = current_connections[left_idx]
		var line = connection_lines[left_idx]
		
		if right_idx != -1:
			line.visible = true
			line.clear_points()
			line.add_point(left_positions[left_idx])
			line.add_point(right_positions[right_idx])
		else:
			line.visible = false
			
	# Update Active (Yellow) Line
	# don't draw line if seleected wire is on same side as cursor
	if selected_wire != -1 and ((selected_wire <= 2 and !cursor_on_left_side) or (selected_wire >= 3 and cursor_on_left_side)):
		active_wire_line.visible = true
		active_wire_line.clear_points()
		
		var start_pos = left_positions[selected_wire] if not cursor_on_left_side else right_positions[selected_wire-3]
		var end_pos = right_positions[cursor_index] if not cursor_on_left_side else left_positions[cursor_index]
		
		active_wire_line.add_point(start_pos)
		active_wire_line.add_point(end_pos)
	else:
		active_wire_line.visible = false

	# Update Cursor Position
	var target_pos = left_positions[cursor_index] if cursor_on_left_side else right_positions[cursor_index]
	# Offset it by half its size (24) so it perfectly centers over the socket
	cursor_rect.position = target_pos - Vector2(24, 24)


func exit():
	var player = Utils.get_player()
	player.set_physics_process(true)
	get_parent().queue_free() 
