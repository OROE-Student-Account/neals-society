
extends Node

var scene_name = ""

	
func text_for_new_area(scene_name):
	$NinePatchRect.visible = true
	$NinePatchRect/Label.text = scene_name
	$AnimationPlayer.play("Moving")
	await get_tree().create_timer(3).timeout
	$NinePatchRect.visible = false
	
