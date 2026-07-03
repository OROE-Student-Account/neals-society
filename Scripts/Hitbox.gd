extends Area2D

@export var target_node: Node
@export var target_function: String = ""

# Creates a nice list in the inspector where you can add as many strings as you want
@export var args: Array[String] = []

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node2D):
	# 1. Ensure the target node still exists
	if is_instance_valid(target_node):
		
		# 2. Ensure a function name was typed in
		if target_function != "":
			
			# 3. Ensure the target node actually has this function
			if target_node.has_method(target_function):
				
				# 4. Use callv() to execute the function AND pass the array of arguments!
				target_node.callv(target_function, args)
				
			else:
				push_warning("Area2D Trigger: Target node is missing the function '%s'" % target_function)
