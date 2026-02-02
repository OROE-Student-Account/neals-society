extends CanvasLayer


@onready var select_arrow = $Control/NinePatchRect/TextureRect
@onready var box = $Control

enum ScreenLoaded { NOTHING, DIALOGUE }
var screen_loaded = ScreenLoaded.NOTHING

var selected_option: int = 0

func _ready():
	box.visible = false
	select_arrow.position.y = 9 + (selected_option % 2) * 16

func load_dialogue(option1, option2):
	var vbox = box.get_child(0).get_child(0)
	vbox.get_child(0).text = option1
	vbox.get_child(1).text = option2
	box.visible = true
	screen_loaded = ScreenLoaded.DIALOGUE

func _unhandled_input(event):
	if screen_loaded == ScreenLoaded.DIALOGUE:
		if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
			selected_option =  (selected_option % 2 + 1) % 2
			select_arrow.position.y = 9 + selected_option * 16
		elif event.is_action_pressed("z"):
			box.visible = false
			var player = Utils.get_player()
			player.set_physics_process(true)
			player.anim_tree.active = true
