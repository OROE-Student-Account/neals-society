extends Node
## Final disciple trial only. No volcano entrance or book-recovery implementation.
const E = preload("res://Scripts/Specialized/GrawaiiEvidence.gd")
const TRAINER := "Grawaii Grammaster"
@onready var opening = get_parent()
var pending_battle := false
var return_message := ""
var money_before_battle := 0.0
var refresh_after := 0.0

func _ready() -> void:
	Utils.get_scene_manager().get_node("CurrentScene").child_entered_tree.connect(_on_scene_child)

func _process(delta: float) -> void:
	refresh_after -= delta
	if refresh_after > 0.0 or not opening._available(): return
	refresh_after = 0.25
	if Utils.get_player().global_position.distance_to(opening.get_node("Grammaster").global_position) > 64.0: return
	var entry: Dictionary = E.progress(Utils)
	if not E.trial_eligible(entry):
		return_message = ""
		return
	if return_message == "win" and not entry.get("GrawaiiGrammasterDefeated", false): return_message = ""
	if return_message == "loss" and not entry.get("GrawaiiTrialTestPassed", false): return_message = ""
	if not return_message.is_empty() or (entry.get("GrawaiiGrammasterDefeated", false) and not entry.get("GrawaiiTrialRewardSeen", false)):
		opening.talk_to("Grammaster")

func talk() -> void:
	var entry: Dictionary = E.progress(Utils)
	if not E.trial_eligible(entry):
		await opening._say("Our friend has a story to finish. Enjoy his performance first; there will be time for my trial afterward.", "The Grammaster")
		return
	if entry.get("GrawaiiGrammasterDefeated", false):
		return_message = ""
		E.claim_trial_reward(Utils)
		if not entry.get("GrawaiiTrialRewardSeen", false):
			await _reward()
		else:
			await opening._say("You have earned my token. The original ending's hidden instruction is recorded, and I can explain it again whenever you wish.", "The Grammaster")
			if await opening._ask("Read the final clue again?", "Review clue", "Later", "The Grammaster") == 0:
				await _review_clue()
		return
	if return_message == "loss":
		return_message = ""
		await opening._say("A good attempt. Your written answers remain confirmed, and your party is restored. This was a friendly trial; you keep your money. Come back for a rematch whenever you're ready.", "The Grammaster")
		return
	if not entry.get("GrawaiiTrialTestPassed", false):
		await opening._say("You found the facts. Now show me you can put them together without changing what they mean. Three questions, then a battle; you may take a break between them.", "The Grammaster")
		var step: int = E.trial_step(entry)
		if await opening._ask("Ready to begin? Your confirmed answers will stay saved." if step == 0 else "You've confirmed %d of three answers. Continue?" % step, "Begin test" if step == 0 else "Continue test", "Later", "The Grammaster") != 0: return
		if not await _test(): return
	await _offer_battle()

func _test() -> bool:
	while true:
		var entry: Dictionary = E.progress(Utils)
		if entry.get("GrawaiiTrialTestPassed", false): return true
		var step: int = E.trial_step(entry)
		var q: Dictionary = E.TRIAL_QUESTIONS[step]
		await opening._say("Evidence: " + q["Evidence"], "The Grammaster")
		var answer: int = await opening._ask(q["Question"], q["Options"][0], q["Options"][1], "The Grammaster")
		if answer != q["Answer"]:
			await opening._say(q["Hint"], "The Grammaster")
			if await opening._ask("Try again, or take a break? Your confirmed answers are saved.", "Try again", "Take a break", "The Grammaster") != 0: return false
			continue
		if not E.advance_trial_answer(Utils, step, answer): return false
		await opening._say("Answer confirmed (%d/3)." % (step + 1), "The Grammaster")
		if step + 1 == E.TRIAL_QUESTIONS.size():
			await opening._say("You've passed the written test. You won't need to repeat it if you postpone or lose our match.", "The Grammaster")
			return true
		if await opening._ask("Continue to the next question?", "Continue", "Take a break", "The Grammaster") != 0: return false
	return false

func _offer_battle() -> void:
	var team: Dictionary = Utils.get_trainer(TRAINER)
	await opening._say("My team is %s, level %d, and %s, level %d. The cook offers free healing if you need to prepare. A loss here will restore your party and cost no money." % [team["Party"][0], team["Levels"][0], team["Party"][1], team["Levels"][1]], "The Grammaster")
	if await opening._ask("Ready for the battle?", "Battle", "Later", "The Grammaster") != 0: return
	var healthy := false
	for member in Utils.get_party():
		if not member.get("Name", "").is_empty() and member.get("Health", 0) > 0: healthy = true
	if not healthy:
		await opening._say("You'll need a healthy Grammarite first. Ask the cook to restore your party, then come back. Your written test is already passed.", "The Grammaster")
		return
	_begin_battle()

func _begin_battle() -> void:
	var entry: Dictionary = E.progress(Utils)
	if pending_battle or not E.trial_eligible(entry) or not entry.get("GrawaiiTrialTestPassed", false) or entry.get("GrawaiiGrammasterDefeated", false): return
	pending_battle = true
	money_before_battle = Utils.get_money()
	var state: Dictionary = Utils.load_json_file("res://Data/Scenes.json")
	var scene_name: String = Utils.get_scene_manager().get_node("CurrentScene").get_child(0).name
	if not state.has(scene_name): state[scene_name] = {}
	if not state[scene_name].has("Trainers"): state[scene_name]["Trainers"] = {}
	state[scene_name]["Trainers"][TRAINER] = {"Talked": false}
	Utils.save_json_file("res://Data/Scenes.json", state)
	Utils.get_scene_manager().transition_to_battle(TRAINER)

func _on_scene_child(child: Node) -> void:
	if not pending_battle or not child.has_node("BattleManager"): return
	var bm = child.get_node("BattleManager")
	if bm.trainer == TRAINER: bm.battle_ended.connect(_on_battle_ended, CONNECT_ONE_SHOT)

func _on_battle_ended(won: bool) -> void:
	pending_battle = false
	if won:
		if E.record_trial_victory(Utils):
			E.claim_trial_reward(Utils)
			return_message = "win"
	else:
		# The shared loss handler resets money and selects a distant center after
		# emitting battle_ended. Defer this friendly-trial override until it finishes.
		call_deferred("_return_from_loss")

func _return_from_loss() -> void:
	Utils.set_money(money_before_battle)
	opening.get_node("Festival").heal_party()
	return_message = "loss"
	Utils.get_scene_manager().transition_exit_battle()

func _reward() -> void:
	await opening._say("Well done. You have passed both halves of my trial. Accept the Third Disciple Token as recognition of your reasoning and your Grammarites' effort.", "The Grammaster")
	await opening._say("Third Disciple Token received. The final clue is recorded with your investigation; you can ask the Grammaster to review it.", "<none>")
	await opening._say("The recovered ending contains an older instruction. Let me explain its wording.", "The Grammaster")
	await _review_clue()
	E.finish_trial_reward_dialogue(Utils)

func _review_clue() -> void:
	await opening._say(E.FINAL_CLUE, "The Grammaster")
	await opening._say("The sleeping summit points to Grawai'i's volcano. The passage is above the sea's reach. The mark that ends a sentence is a period. Keep those meanings together when you read the inscription.", "The Grammaster")
