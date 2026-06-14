extends Node2D

var scaler = 0


func smooth_transition():
	scaler = 0
	const min = 10
	const max = 40
	const time = 3.5
	var children = get_children()
	
	for i in range(time*100):
		scaler = min + (i/(time*100.0)) * (max - min)
		for child in children:
			child.scale_amount_min = scaler
			child.scale_amount_max = scaler
		await get_tree().create_timer(0.01).timeout
