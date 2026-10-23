extends StaticBody2D


func _ready() -> void:
	var defeated_kom = Utils.check_trainer_attacked("Kom Ma-King", "Castle")
	visible = not defeated_kom
	collision_layer = 2 if visible else 0
