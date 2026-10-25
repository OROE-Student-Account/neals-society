extends Node2D
const E = preload("res://Scripts/Specialized/GrawaiiEvidence.gd")
func _ready() -> void:
	visible = E.progress(Utils).get("GrawaiiStorytellerRescued", false)
	$Body.collision_layer = 18 if visible else 0
