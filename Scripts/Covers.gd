extends Control

func _ready():
	# Loop through every room child (RoomA, RoomB, etc.)
	for room in get_children():
		
		# Find the Area2D inside this specific room
		# Adjust the "Area2D" string if you named the node differently
		var area = room.get_node("Area2D") 
		
		if area and area is Area2D:
			# Connect the signal, and BIND the current room node to it.
			# This passes the 'room' variable into the function automatically!
			area.body_entered.connect(_on_room_entered.bind(room))


func _on_room_entered(_body: Node2D, entered_room: Node):
	# 1. Ensure it's actually the player triggering this, not an enemy or bullet
	# (Assumes your player node is in a group called "player")
	
	# 2. Loop through all rooms to update their visibility
	for room in get_children():
		if room == entered_room:
			# Hide the cover for the room we just walked into
			room.visible = false
		else:
			# Show the covers for all other rooms
			room.visible = true
