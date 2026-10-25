extends RefCounted
## Shared witness progress. Quest entries are included in the existing save slots.
const QUEST_NAME := "The Missing Storyteller"
const KEYS := ["apprentice_note", "cook_breakfast", "fisherman_scout", "racer_route", "keeper_rockfall"]
const NAMES := ["the note in the Storyteller's home", "the festival cook at the green", "the fisherman northwest of the green", "the canoe racer southwest of the green", "the trail keeper east of the green"]
const ACCOUNTS := [
	"Note: He went to the coastal archive to retrieve the original ending.",
	"Cook: He ate breakfast, then collected a wrapped manuscript from home.",
	"Fisherman: A rammarG scout took the archive trail later, alone.",
	"Racer: After the morning bell, he carried the manuscript along the eastern trail.",
	"Keeper: He entered the archive before the rockfall blocked its entrance."
]

# Each question includes the evidence needed to answer it; no memorization required.
const RECONSTRUCTION := [
	{"Evidence": "Cook: Breakfast came first. He then went home and left with a wrapped manuscript.", "Question": "After breakfast, what did the Storyteller collect?", "Options": ["His manuscript", "The scout's warning"], "Answer": 0, "Hint": "The cook saw him leave his house with a wrapped manuscript. Nobody says he collected a warning.", "Confirmed": "He collected his manuscript after breakfast."},
	{"Evidence": "Note: He wanted the archive's original ending. Racer: He carried the manuscript along the eastern trail after the bell.", "Question": "Which route is supported by those two accounts?", "Options": ["Up the volcanic ridge", "East to the archive"], "Answer": 1, "Hint": "His note names the coastal archive, and the racer saw him take the eastern trail. Neither account sends him to the volcano.", "Confirmed": "He took the eastern trail toward the coastal archive."},
	{"Evidence": "Keeper: I saw him enter the archive. A rockfall blocked its entrance afterward.", "Question": "Which sentence preserves the keeper's order of events?", "Options": ["After he entered, rocks fell.", "Before he entered, rocks fell."], "Answer": 0, "Hint": "He was already inside when the rocks fell. 'After he entered' places his entrance first; 'before' changes the order.", "Confirmed": "He entered the archive before the rockfall blocked the entrance."},
	{"Evidence": "Fisherman: I saw the Storyteller go toward the eastern trail. Later, a rammarG scout went that way alone.", "Question": "What does the fisherman actually establish about the scout?", "Options": ["They traveled together", "The scout followed later"], "Answer": 1, "Hint": "The fisherman saw two separate journeys. The scout traveled later and alone. This does not prove who caused the rockfall.", "Confirmed": "The scout followed later, alone. Their exact arrival time at the archive is still unknown."},
	{"Evidence": "The keeper saw him enter the archive. The fisherman says people have only been repeating the eruption warning.", "Question": "Which claim is supported by a firsthand witness?", "Options": ["An eruption is certain", "He entered the archive"], "Answer": 1, "Hint": "The keeper directly saw him enter. Repeating an eruption warning does not verify it. We should check a rumor before treating it as fact.", "Confirmed": "His archive entrance is witnessed. The eruption warning is unverified."},
	{"Evidence": "He planned to fetch an ending from the archive, took the eastern trail, and entered before its entrance was blocked.", "Question": "Where should the search party look for the Storyteller?", "Options": ["The coastal archive", "The volcano summit"], "Answer": 0, "Hint": "His note, the racer, and the keeper all point to the coastal archive. The volcano rumor does not outweigh their evidence.", "Confirmed": "The coastal archive is the supported search location."}
]

static func reconstruction_step(entry: Dictionary) -> int:
	if entry.get("GrawaiiReconstructed", false): return RECONSTRUCTION.size()
	return clampi(int(entry.get("GrawaiiReconstructionStep", 0)), 0, RECONSTRUCTION.size() - 1)

static func advance_reconstruction(utils: Node, expected_step: int) -> bool:
	var id := quest_id(utils)
	if id < 0 or expected_step < 0 or expected_step >= RECONSTRUCTION.size(): return false
	var entries: Array = utils.load_json_file("res://Data/Quests.json")
	if id >= entries.size(): return false
	var entry: Dictionary = entries[id]
	if count_clues(entry) != KEYS.size() or entry.get("GrawaiiReconstructed", false) or reconstruction_step(entry) != expected_step:
		return false
	entry["GrawaiiReconstructionStep"] = expected_step + 1
	if expected_step + 1 == RECONSTRUCTION.size():
		entry["GrawaiiReconstructed"] = true
		entry["GrawaiiSearchLocation"] = "coastal_archive"
	entry["CurrentObjective"] = objective(entry)
	utils.save_json_file("res://Data/Quests.json", entries)
	return true

static func advance_archive(utils: Node, event: String) -> bool:
	var prerequisites := {
		"scout": ["GrawaiiReconstructed", "GrawaiiScoutDefeated"],
		"help": ["GrawaiiScoutDefeated", "GrawaiiArchiveHelpRequested"],
		"clear": ["GrawaiiArchiveHelpRequested", "GrawaiiArchiveCleared"],
		"rescue": ["GrawaiiArchiveCleared", "GrawaiiStorytellerRescued"],
		"homecoming": ["GrawaiiStorytellerRescued", "GrawaiiHomecomingSeen"]
	}
	if not prerequisites.has(event): return false
	var id := quest_id(utils)
	var entries: Array = utils.load_json_file("res://Data/Quests.json")
	if id < 0 or id >= entries.size(): return false
	var entry: Dictionary = entries[id]
	var pair: Array = prerequisites[event]
	if count_clues(entry) != KEYS.size() or not entry.get(pair[0], false) or entry.get(pair[1], false): return false
	entry[pair[1]] = true
	if event == "rescue": entry["GrawaiiManuscriptRecovered"] = true
	entry["CurrentObjective"] = objective(entry)
	utils.save_json_file("res://Data/Quests.json", entries)
	return true

static func quest_id(utils: Node) -> int:
	var definitions: Array = utils.load_json_file("res://GrammariteData/Quests.json")
	for i in definitions.size():
		if definitions[i].get("Name", "") == QUEST_NAME: return i
	return -1

static func progress(utils: Node) -> Dictionary:
	var id := quest_id(utils)
	if id < 0: return {}
	var entries: Array = utils.load_json_file("res://Data/Quests.json")
	if id >= entries.size(): return {"Progress": "Incoming"}
	return entries[id]

static func has_clue(utils: Node, key: String) -> bool:
	return progress(utils).get("GrawaiiClues", {}).get(key, false)

static func count_clues(entry: Dictionary) -> int:
	var count := 0
	for key in KEYS:
		if entry.get("GrawaiiClues", {}).get(key, false): count += 1
	return count

static func objective(entry: Dictionary) -> String:
	if entry.get("GrawaiiStorytellerRescued", false):
		return "Storyteller rescued! Meet him at the festival green with the recovered original ending."
	if entry.get("GrawaiiArchiveCleared", false):
		return "The archive entrance is clear. Go inside and find the Storyteller."
	if entry.get("GrawaiiArchiveHelpRequested", false):
		return "Meet the trail keeper at the coastal archive entrance to clear the fallen rocks."
	if entry.get("GrawaiiScoutDefeated", false):
		return "Scout defeated. Ask the trail keeper east of the festival green to bring tools."
	if entry.get("GrawaiiReconstructed", false):
		return "Search the coastal archive southeast of the green. The trail keeper can guide you."
	if count_clues(entry) == KEYS.size() and reconstruction_step(entry) > 0:
		return "Timeline: %d/6 confirmed. Return to the festival organizer to continue comparing accounts." % reconstruction_step(entry)
	var count := count_clues(entry)
	if count == KEYS.size():
		return "Accounts: 5/5. Return to the organizer at the festival green to compare the accounts."
	for i in KEYS.size():
		if not entry.get("GrawaiiClues", {}).get(KEYS[i], false):
			var action: String = "Read " if i == 0 else "Speak to "
			return "Accounts: %d/5. Next: %s%s." % [count, action, NAMES[i]]
	return "Return to the festival organizer."

static func record(utils: Node, key: String) -> bool:
	if key not in KEYS: return false
	var id := quest_id(utils)
	if id < 0: return false
	var entries: Array = utils.load_json_file("res://Data/Quests.json")
	while entries.size() <= id: entries.append({"Progress": "Incoming"})
	var entry: Dictionary = entries[id]
	var clues: Dictionary = entry.get("GrawaiiClues", {})
	var is_new: bool = not clues.get(key, false)
	clues[key] = true
	entry["GrawaiiClues"] = clues
	if entry.get("Progress", "Incoming") == "Incoming": entry["Progress"] = "Started"
	entry["CurrentObjective"] = objective(entry)
	utils.save_json_file("res://Data/Quests.json", entries)
	return is_new

static func summaries(entry: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for i in KEYS.size():
		if entry.get("GrawaiiClues", {}).get(KEYS[i], false): result.append(ACCOUNTS[i])
	return result

static func dialogue_pages(utils: Node, text: String) -> Array[String]:
	# The shared dialogue label shows only three lines. Fit pages using its font.
	var label: Label = utils.get_scene_manager().get_node("DialogueBox/Control/NinePatchRect/Text")
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	var lines: Array[String] = []
	for paragraph in text.split("\n"):
		var line := ""
		for word in paragraph.split(" ", false):
			var candidate: String = word if line.is_empty() else line + " " + word
			if not line.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x - 1:
				lines.append(line)
				line = word
			else: line = candidate
		lines.append(line)
	var pages: Array[String] = []
	var limit: int = maxi(1, label.max_lines_visible)
	for i in range(0, lines.size(), limit):
		pages.append("\n".join(lines.slice(i, i + limit)))
	return pages
