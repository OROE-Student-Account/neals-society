extends Node2D

const PROMPT_RECT := Rect2(30, 18, 180, 46)
const ANSWER_SIZE := Vector2(104, 22)
const WRAP_FLAGS := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
var pixel_font: FontFile

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pixel_font = $Question.get_theme_font("font").duplicate()
	pixel_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	pixel_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	pixel_font.oversampling = 1.0
	for label in find_children("*", "Label", true, false):
		label.add_theme_font_override("font", pixel_font)
		label.add_theme_constant_override("line_spacing", 0)

# Both battles and lessons use the same text interiors of the original artwork.
func set_question_text(prompt: String, options: Array) -> void:
	$Question.text = prompt
	_fit($Question, PROMPT_RECT, 12)
	var answer_font_size := 12
	for i in 4:
		var box = get_node("Options/NinePatchRect" + str(i + 1))
		box.position = Vector2(10 + (i % 2) * 116, 86 + floori(i / 2.0) * 34)
		box.size = ANSWER_SIZE
		var label: Label = box.get_node("Label")
		label.text = str(options[i]) if i < options.size() else ""
		_fit(label, Rect2(Vector2.ZERO, ANSWER_SIZE), 12)
		if not label.text.is_empty():
			answer_font_size = mini(answer_font_size, label.get_theme_font_size("font_size"))
	# Keep all answer choices the same size, even when one needs more room.
	for i in 4:
		get_node("Options/NinePatchRect" + str(i + 1) + "/Label").add_theme_font_size_override("font_size", answer_font_size)

func _fit(label: Label, bounds: Rect2, largest: int) -> void:
	label.scale = Vector2.ONE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	var font_size := largest
	while font_size > 6:
		var measured := pixel_font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, bounds.size.x, font_size, -1, WRAP_FLAGS)
		if measured.x <= bounds.size.x and measured.y <= bounds.size.y:
			break
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)
	label.position = bounds.position
	label.size = bounds.size

signal result_continued
var result_panel: NinePatchRect
var result_details: Label
var result_pages: Array[Dictionary] = []
var result_page_index := 0
var result_active := false
var continue_after := 0
var previous_visibility: Dictionary = {}

func show_result(correct: bool, question: Dictionary, selected: int) -> void:
	if result_panel == null:
		_build_result_panel()
	previous_visibility.clear()
	for path in ["Question", "Options", "TextureRect", "Vitamins"]:
		var node = get_node(path)
		previous_visibility[path] = node.visible
		node.hide()
	$Animation.hide()
	var options: Array = question["Options"]
	var correct_answer := str(options[int(question["Answer"])])
	var chosen := str(options[selected]) if selected >= 0 and selected < options.size() else ""
	var summary := ("Your answer:\n" + chosen + "\n\n" if not correct else "") + "Correct answer:\n" + correct_answer
	result_pages.clear()
	_append_pages("Correct!" if correct else "Not quite", summary, Color("226035") if correct else Color("8b3027"))
	var explanation := str(question.get("Explanation", "")).strip_edges()
	if not explanation.is_empty():_append_pages("Explanation", explanation, Color("332015"))
	result_page_index = 0
	_display_result_page()
	result_panel.show()
	result_active = true

func _append_pages(title: String, text: String, color: Color) -> void:
	var page := ""
	for word in text.split(" ", false):
		var candidate := page + (" " if not page.is_empty() else "") + word
		var measured := pixel_font.get_multiline_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, 188, 12, -1, WRAP_FLAGS)
		if not page.is_empty() and measured.y > 82:
			result_pages.append({"Title": title, "Text": page, "Color": color})
			page = word
		else:
			page = candidate
	if not page.is_empty():result_pages.append({"Title": title, "Text": page})
	# The last page uses the same heading color as the preceding pages.
	result_pages[-1]["Color"] = color

func _display_result_page() -> void:
	var page: Dictionary = result_pages[result_page_index]
	var title: Label = result_panel.get_node("Heading")
	title.text = page.Title
	title.add_theme_color_override("font_color", page.Color)
	result_details.text = page.Text
	var next_is_explanation: bool = result_page_index + 1 < result_pages.size() and result_pages[result_page_index + 1].Title == "Explanation" and page.Title != "Explanation"
	result_panel.get_node("Continue").text = "Z: Explanation" if next_is_explanation else "Z: Continue"
	continue_after = Time.get_ticks_msec() + 150

func hide_result() -> void:
	result_active = false
	if result_panel:result_panel.hide()
	for path in previous_visibility:get_node(path).visible = previous_visibility[path]

func _build_result_panel() -> void:
	result_panel = NinePatchRect.new()
	result_panel.name = "ResultPanel"
	var parchment := AtlasTexture.new()
	parchment.atlas = $Background.texture
	parchment.region = Rect2(26, 10, 188, 60)
	result_panel.texture = parchment
	result_panel.position = Vector2(2, 4)
	result_panel.size = Vector2(236, 152)
	result_panel.patch_margin_left = 10
	result_panel.patch_margin_right = 10
	result_panel.patch_margin_top = 10
	result_panel.patch_margin_bottom = 10
	add_child(result_panel)
	var heading := _result_label("Heading", 12)
	heading.position = Vector2(24, 10)
	heading.size = Vector2(188, 18)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_panel.add_child(heading)
	result_details = _result_label("Details", 12)
	result_details.position = Vector2(24, 34)
	result_details.size = Vector2(188, 82)
	result_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_details.clip_text = true
	result_panel.add_child(result_details)
	var hint := _result_label("Continue", 12)
	hint.text = "Z: Continue"
	hint.position = Vector2(24, 131)
	hint.size = Vector2(188, 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_panel.add_child(hint)

func _result_label(node_name: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("332015"))
	return label

func _input(event: InputEvent) -> void:
	if not result_active:return
	if event.is_action_pressed("z"):
		get_viewport().set_input_as_handled()
		if event.is_echo() or Time.get_ticks_msec() < continue_after:return
		if result_page_index + 1 < result_pages.size():
			result_page_index += 1
			_display_result_page()
		else:
			result_active = false
			result_continued.emit()
