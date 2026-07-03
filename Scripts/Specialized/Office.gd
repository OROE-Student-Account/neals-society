extends Node2D


func _ready():
	$"Dog of Wood".picked_up_grammarite.connect(_on_gram_pickup)
	$Kittebook.picked_up_grammarite.connect(_on_gram_pickup)
	$Moustapler.picked_up_grammarite.connect(_on_gram_pickup)

func _on_gram_pickup():
	for node in [$"Dog of Wood", $Kittebook, $Moustapler]:
		if node:
			node.queue_free()
	$Rival/DialogueRoot2.begin_from_self()


func break_down_later():
	Utils.update_obstacle("Cutscene", true, "School")
	Utils.update_obstacle("ParkBlockade", true, "Town")
