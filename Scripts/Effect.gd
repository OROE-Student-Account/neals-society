extends AnimatedSprite2D


func _ready():
	frame = 0
func _on_Effect_animation_finished():
	queue_free()
