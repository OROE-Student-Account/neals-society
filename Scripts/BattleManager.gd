extends Node2D
class_name BattleManager

@export var player_grammarite: Node2D 
@export var enemy_grammarite: Node2D  
@export var battle_ui: Node2D      
@export var evolve_screen: Node2D      

var trainer = "random"

# --- NEW PARTY TRACKING VARIABLES ---
var enemy_party: Array = []
var enemy_levels: Array = []
var current_enemy_index: int = 0

# --- STATUS EFFECT TRACKER ---
var status_tracker: Dictionary = {
	"player": {},
	"enemy": {}
}

# --- STAT MULTIPLIER TRACKER ---
var stat_multipliers: Dictionary = {
	"player": {},
	"enemy": {}
}

# --- TRACKING VARIABLES ---
var last_move_player: String = ""
var last_move_enemy: String = ""
var enemy_current_pp: Array = []

var multi_hit_counter = 0

signal battle_ended(player_won: bool)

enum BattleState { PLAYER_TURN, ENEMY_TURN, ANIMATING, BATTLE_END }
var current_state = BattleState.PLAYER_TURN

func _ready():
	# Initialize status trackers and stat multipliers for up to 6 party members on each side
	for i in range(6):
		status_tracker["player"][i] = []
		status_tracker["enemy"][i] = []
		
		stat_multipliers["player"][i] = {"Attack": 1.0, "Defense": 1.0, "Speed": 1.0, "Health": 1.0}
		stat_multipliers["enemy"][i] = {"Attack": 1.0, "Defense": 1.0, "Speed": 1.0, "Health": 1.0}
	
	# Connect to battle UI
	evolve_screen.visible = false
	get_parent().get_node("SemicolonAnimator").visible = false
	if battle_ui:
		battle_ui.move_selected.connect(_on_player_move_selected)
		if "random" not in trainer:
			battle_ui.get_node("Buttons/run").self_modulate = Color(0.55,0.55,0.4, 0.95)
	
	if not await on_player_grammarite_die(false):
		battle_ui.input_state = battle_ui.InputState.WAITING
		battle_ui.show_correct_menu()
		battle_ui.set_info_text("Revive your party at a Grammarite Center before fighting again.")
		await get_tree().create_timer(4.0).timeout
		end_battle(false)
		return
	
	player_grammarite.health_changed.connect(_on_grammarite_health_changed)
	enemy_grammarite.health_changed.connect(_on_grammarite_health_changed)
	
	start_battle()


func start_battle():
	setup_enemy_pp()
	
	# Use the new helper function to get the multiplier-adjusted Speed
	var player_spd = get_modified_stat(player_grammarite, "Speed")
	if player_grammarite.item == "Dash":
		player_spd *= 1.25
	elif player_grammarite.item == "Hypen":
		player_spd *= 1.15
		
	var enemy_spd = get_modified_stat(enemy_grammarite, "Speed")
	
	if player_spd > enemy_spd:
		current_state = BattleState.PLAYER_TURN
	else:
		battle_ui.input_state = battle_ui.InputState.WAITING
		battle_ui.show_correct_menu()
		await get_tree().create_timer(0.5).timeout
		# Enemy's turn
		await enemy_turn()
		
		# Check if player fainted
		if player_grammarite.health <= 0:
			if not await on_player_grammarite_die(true):
				return
		
		# to player's turn
		current_state = BattleState.PLAYER_TURN
		battle_ui.input_state = battle_ui.InputState.ACTION_BUTTONS
		battle_ui.show_correct_menu()


func setup_enemy_pp():
	enemy_current_pp.clear()
	var moves = enemy_grammarite.grammarite_info["Moves"]
	for move in moves:
		var max_pp = move.get("PP", 10) # Defaults to 10 if your move dict lacks a PP key
		# Start randomly anywhere from half empty to full
		var starting_pp = randi_range(max_pp / 2, max_pp)
		enemy_current_pp.append(starting_pp)

func _on_player_move_selected(move_index: int):
	if current_state != BattleState.PLAYER_TURN:
		return  # Ignore if not player's turn
		
	# --- PROCESS PLAYER STATUS EFFECTS ---
	await process_turn_status(true)
	
	# Check if the player fainted from a status effect before attacking
	if player_grammarite.health <= 0:
		if not await on_player_grammarite_die(true):
			return
		return # End turn immediately if fainted
	
	if move_index == -1:
		await execute_attack(player_grammarite, enemy_grammarite, { "Name": "Struggle" })
	elif move_index == -2:
		battle_ui.set_info_text("You got the question wrong.")
		await get_tree().create_timer(1.0).timeout
	elif move_index == -3:
		print("SEMICOLON SLASH!!!")
		var semi = get_parent().get_node("SemicolonAnimator")
		
		semi.get_node("You").texture = load("res://Assets/Pokemon/Pokemon"+str(1+Utils.get_poke_num(player_grammarite.grammarite_name))+".png")
		semi.get_node("Adversary").texture = load("res://Assets/Pokemon/Pokemon"+str(1+Utils.get_poke_num(enemy_grammarite.grammarite_name))+".png")
		semi.get_node("explosion").source_texture = load("res://Assets/Pokemon/Pokemon"+str(1+Utils.get_poke_num(enemy_grammarite.grammarite_name))+".png")
		
		semi.get_node("Conductor").play("play_full")
		await get_tree().create_timer(50.0).timeout
		
		var move_info = Utils.get_move("Semicolon Slash")
		move_info["Name"] = "Semicolon Slash"
		await execute_attack(player_grammarite, enemy_grammarite, move_info)
		# SEMICOLON SLASH!!!!
	else:
		var player_move = player_grammarite.grammarite_info["Moves"][move_index]
		await execute_attack(player_grammarite, enemy_grammarite, player_move)
	
	if player_grammarite.health <= 0:
		if not await on_player_grammarite_die(true):
			return
	
	# Check if enemy fainted from player's attack
	if enemy_grammarite.health <= 0:
		# Await the swap sequence. If false, the battle is entirely over.
		if not await on_enemy_grammarite_die():
			return
		
		# Reset menu for the player's turn against the new enemy
		current_state = BattleState.PLAYER_TURN
		battle_ui.input_state = battle_ui.InputState.ACTION_BUTTONS
		battle_ui.show_correct_menu()
		return
	
	# Enemy's turn
	await enemy_turn()
	
	# Check if player fainted from enemy attack
	if player_grammarite.health <= 0:
		if not await on_player_grammarite_die(true):
			return
			
	# Check if enemy fainted from Struggle recoil during their turn
	if enemy_grammarite.health <= 0:
		if not await on_enemy_grammarite_die():
			return
	
	# Back to player's turn
	current_state = BattleState.PLAYER_TURN
	battle_ui.input_state = battle_ui.InputState.ACTION_BUTTONS
	battle_ui.show_correct_menu()


func enemy_turn():
	current_state = BattleState.ENEMY_TURN
	
	battle_ui.set_info_text("Enemy's turn")
	await get_tree().create_timer(1.0).timeout
	
	# --- PROCESS ENEMY STATUS EFFECTS ---
	await process_turn_status(false)
	
	# Check if enemy fainted from a status effect before attacking
	if enemy_grammarite.health <= 0:
		if not await on_enemy_grammarite_die():
			return
		# If they successfully swapped out, it becomes the player's turn again
		current_state = BattleState.PLAYER_TURN
		battle_ui.input_state = battle_ui.InputState.ACTION_BUTTONS
		battle_ui.show_correct_menu()
		return
	
	# --- DELEGATE TO AI BOT ---
	await choose_enemy_action()

# --- ENEMY AI BOT LOGIC ---
func choose_enemy_action():
	# 1. EVALUATE SWITCHING
	var can_switch = current_enemy_index < enemy_party.size() - 1
	var is_low_health = enemy_grammarite.health < (enemy_grammarite.max_health * 0.25)
	
	if can_switch and is_low_health:
		if randf() > 0.67: 
			await perform_enemy_switch()
			return

	# 2. EVALUATE MOVES
	var moves = enemy_grammarite.grammarite_info["Moves"]
	var best_move = null
	var best_move_index = -1
	var highest_score = -1
	
	for i in range(moves.size()):
		# Skip this move entirely if it is out of PP
		if enemy_current_pp[i] <= 0:
			continue
			
		var move = moves[i]
		var score = (move.get("Damage", 0) * max(1, move.get("Accuracy", 0))) + (move.get("PP")/5)
		
		var effectiveness = 1
		if len(player_grammarite.grammarite_info["Stats"]["Types"]) == 2:
			effectiveness = Utils.get_damage_multiplier(move["Type"], player_grammarite.grammarite_info["Stats"]["Types"][0], player_grammarite.grammarite_info["Stats"]["Types"][1])
		else:
			effectiveness =  Utils.get_damage_multiplier(move["Type"], player_grammarite.grammarite_info["Stats"]["Types"][0])
		
		if effectiveness > 1:
			score = (effectiveness*(score+1))**2
		score += randi_range(0, 5) 
		
		if score > highest_score:
			highest_score = score
			best_move = move
			best_move_index = i
			
	if best_move != null:
		# Deduct 1 PP from the chosen move
		enemy_current_pp[best_move_index] -= 1
		await execute_attack(enemy_grammarite, player_grammarite, best_move)
	else:
		# If best_move is still null, ALL moves have 0 PP. Use Struggle!
		await execute_attack(enemy_grammarite, player_grammarite, { "Name": "Struggle" })

func perform_enemy_switch():
	current_state = BattleState.ANIMATING
	
	battle_ui.set_info_text(trainer + " withdrew " + enemy_grammarite.grammarite_name + "!")
	enemy_grammarite.visible = false
	await get_tree().create_timer(1.5).timeout
	
	# Move to the next Grammarite in the list
	current_enemy_index += 1
	var next_name = enemy_party[current_enemy_index]
	var next_level = enemy_levels[current_enemy_index]
	
	battle_ui.set_info_text(trainer + " sent out " + next_name + "!")
	
	enemy_grammarite.grammarite_name = next_name
	enemy_grammarite.level = next_level
	
	if enemy_grammarite.has_method("setup"):
		enemy_grammarite.setup()
	
	setup_enemy_pp()
	
	enemy_grammarite.visible = true
	await get_tree().create_timer(1.5).timeout
	
	# Return control to the player (the enemy used their turn to switch)
	current_state = BattleState.PLAYER_TURN
	battle_ui.input_state = battle_ui.InputState.ACTION_BUTTONS
	battle_ui.show_correct_menu()


# --- STATUS EFFECT LOGIC HANDLERS ---
func process_turn_status(is_player: bool):
	var side = "player" if is_player else "enemy"
	# The player's active grammarite is always index 0 because of swap logic!
	var index = 0 if is_player else current_enemy_index
	var target_node = player_grammarite if is_player else enemy_grammarite
	
	var current_effects = status_tracker[side][index]
	var remaining_effects = []
	
	for effect in current_effects:
		
		# Await in case your function plays animations or text!
		await apply_status_effects(target_node, effect)
		
		effect["duration"] -= 1
		
		# Only keep it if the duration hasn't hit zero
		if effect["duration"] > 0:
			remaining_effects.append(effect)
		else:
			if effect["name"] == "Sleep":
				battle_ui.set_info_text(target_node.grammarite_name + " woke up!")
				await get_tree().create_timer(1.0).timeout
			elif effect["name"] == "Confusion":
				battle_ui.set_info_text(target_node.grammarite_name + " is no longer confused!")
				await get_tree().create_timer(1.0).timeout
			elif effect["name"] == "Burn":
				battle_ui.set_info_text(target_node.grammarite_name + " is no longer engulfed in flames!")
				await get_tree().create_timer(1.0).timeout
			elif effect["name"] == "Poison":
				battle_ui.set_info_text(target_node.grammarite_name + " recovered from poison!")
				await get_tree().create_timer(1.0).timeout
			elif effect["name"] == "Blind":
				battle_ui.set_info_text(target_node.grammarite_name + " can see again!")
				await get_tree().create_timer(1.0).timeout
	
	status_tracker[side][index] = remaining_effects

func apply_status_effects(target: Node2D, effect_data: Dictionary):
	if effect_data["name"] == "Burn":
		# The target parameter lets us hurt the correct Grammarite!
		var damage = (0.1)*int(calc_stat(100, target.level) + target.level + 5)
		target.update_health(-damage)
		
		# We can also use it to pull their specific name for the UI
		battle_ui.set_info_text(target.grammarite_name + " is still writing from a burn!")
		
		# Wait for the player to read it
		await get_tree().create_timer(1.0).timeout
	elif effect_data["name"] == "Blind":
		var damage = (effect_data["Duration"]*0.1)*int(calc_stat(100, target.level) + target.level + 5)
		target.update_health(-damage)
		
		# We can also use it to pull their specific name for the UI
		battle_ui.set_info_text(target.grammarite_name + " is blinded!")
		
		# Wait for the player to read it
		await get_tree().create_timer(1.0).timeout
	elif effect_data["name"] == "Radiation" && effect_data["Duration"] == 1:
		target.update_health(0)
		battle_ui.set_info_text(target.grammarite_name + " died from radiation poisoning!")
		
		# Wait for the player to read it
		await get_tree().create_timer(1.0).timeout
	elif effect_data["name"] == "Poison":
		var side = "player" if target == player_grammarite else "enemy"
		var index = 0 if side == "player" else current_enemy_index
		
		stat_multipliers[side][index]["Defense"] /= 2.0
		
		# We can also use it to pull their specific name for the UI
		battle_ui.set_info_text(target.grammarite_name + " is poisoned!")
		
		# Wait for the player to read it
		await get_tree().create_timer(1.0).timeout
	
	
	
	elif effect_data["name"] == "Procrastinate":
		var side = "player" if target == player_grammarite else "enemy"
		var index = 0 if side == "player" else current_enemy_index
		
		stat_multipliers[side][index]["Speed"] *= 2.0
		stat_multipliers[side][index]["Attack"] /= 2.0
		
		if effect_data["Duration"] == 1:
			stat_multipliers[side][index]["Speed"] /= 4.0
			stat_multipliers[side][index]["Attack"] *= 4.0


# --- NEW FUNCTION FOR ENEMY FAINTING / SWAPPING ---
func on_enemy_grammarite_die() -> bool:
	# --- NEW: ENEMY RED STAMP CHECK ---
	if enemy_grammarite.item == "Red Stamp":
		battle_ui.set_info_text(enemy_grammarite.grammarite_name + "'s Red Stamp activates!")
		await get_tree().create_timer(1.0).timeout
		
		# Take down the player
		player_grammarite.health = 0
		await on_player_grammarite_die(true)
		return false # Stop here, the player's death function will handle the UI
	
	
	enemy_grammarite.visible = false
	battle_ui.set_info_text("Enemy " + enemy_grammarite.grammarite_name + " fainted!")
	await get_tree().create_timer(1.5).timeout

	current_enemy_index += 1
	
	# Check if there are more grammarites in the array
	if current_enemy_index < enemy_party.size():
		var next_name = enemy_party[current_enemy_index]
		var next_level = enemy_levels[current_enemy_index]
		
		battle_ui.set_info_text(trainer+" sent out " + next_name + "!")
		
		# Update the node
		enemy_grammarite.grammarite_name = next_name
		enemy_grammarite.level = next_level
		
		# Trigger your node's internal stat recalculation
		if enemy_grammarite.has_method("setup"):
			enemy_grammarite.setup()
		
		setup_enemy_pp()
		
		enemy_grammarite.visible = true
		
		await get_tree().create_timer(1.5).timeout
		return true # Returning true means the battle continues!
	else:
		# If the index is out of bounds, the trainer is fully defeated
		end_battle(true)
		return false # Returning false stops the combat loop


func on_player_grammarite_die(in_battle: bool):
	# return = battle continuing
	var party = Utils.get_party()
	
	var living_index = -1
	for i in range(len(party)):
		if party[i]["Health"] != 0: 
			living_index = i
			break
	
	# living index = location of alive grammarite
	
	if living_index == -1:
		# all dead
		if in_battle:
			end_battle(false)
		return false
	else:
		# Swap party array members
		var temp = party[0]
		party[0] = party[living_index]
		party[living_index] = temp
		Utils.set_party(party)
		
		# --- SWAP STATUS EFFECTS TO MATCH PARTY POSITIONS ---
		var temp_status = status_tracker["player"][0]
		status_tracker["player"][0] = status_tracker["player"][living_index]
		status_tracker["player"][living_index] = temp_status
		
		# --- SWAP STAT MULTIPLIERS TO MATCH PARTY POSITIONS ---
		var temp_mult = stat_multipliers["player"][0]
		stat_multipliers["player"][0] = stat_multipliers["player"][living_index]
		stat_multipliers["player"][living_index] = temp_mult
		
		get_parent().get_node("Grammarite").setup()
		
		if temp["Item"] == "Red Stamp":
			battle_ui.set_info_text(temp["Name"]+" used a red stamp!")
			await get_tree().create_timer(1.0).timeout
			
			# Kill the enemy instead of instantly ending the battle
			enemy_grammarite.health = 0 
			if in_battle:
				await on_enemy_grammarite_die()
			
			
			return false
		
		if in_battle:
			battle_ui.set_info_text(temp["Name"]+" died, go "+player_grammarite.grammarite_name+"!")
			await get_tree().create_timer(1.5).timeout
		return true

# --- NEW HELPER FOR STAT MULTIPLIERS ---
func get_modified_stat(grammarite_node: Node2D, stat_name: String) -> float:
	# 1. Figure out if this is the player or the enemy
	var side = "player" if grammarite_node == player_grammarite else "enemy"
	var index = 0 if side == "player" else current_enemy_index
	
	# 2. Get the base calculated stat (using your original formula)
	var base_val = calc_stat(grammarite_node.grammarite_info["Stats"][stat_name], grammarite_node.level)
	
	# 3. Apply the current multiplier from the tracker
	var multiplier = stat_multipliers[side][index][stat_name]
	
	return base_val * multiplier


func execute_attack(attacker: Node2D, defender: Node2D, move: Dictionary):
	current_state = BattleState.ANIMATING
	
	# --- PRE-ATTACK STATUS CHECK ---
	if not await pre_attack_status_check(attacker):
		# We still need to update the party array in case they hit themselves in confusion
		var party = Utils.get_party()
		party[0]["Health"] = player_grammarite.health
		Utils.set_party(party)
		return # Stop the attack immediately
	
	# --- RECORD THE LAST MOVE ---
	if attacker == player_grammarite:
		last_move_player = move["Name"]
	else:
		last_move_enemy = move["Name"]
	
	battle_ui.set_info_text(attacker.grammarite_name+" used "+move["Name"]+"!")
	
	await get_tree().create_timer(0.9).timeout
	
	if move["Name"] != "Struggle":
		# --- LAB REPORT AUTO MISS ---
		if move["Name"] == "Lab Report" and attacker.item == "Red Stamp":
			battle_ui.set_info_text(attacker.grammarite_name + "'s Red Stamp ruined the Lab Report!")
			await get_tree().create_timer(1.0).timeout
			return
		
		# Check accuracy
		var accuracy = move.get("Accuracy", 0) # If no accuracy included, auto miss
		
		# Lab Report + Sticker Accuracy Buff
		if move["Name"] == "Lab Report" and attacker.item == "Sticker":
			accuracy *= 2.0
		
		if attacker.item == "Glasses": accuracy += 0.25
		
		# biases accuracy for player
		if attacker == enemy_grammarite:
			accuracy =  (accuracy - 0.05)*0.95
		
		var hit_roll = randf()
		# --- USE HELPER FUNCTION FOR DEFENSE AND SPEED ---
		var defense_stat = get_modified_stat(defender, "Defense")
		var spd = get_modified_stat(attacker, "Speed")
		
		if player_grammarite.item == "Dash":
			spd *= 1.25
		elif player_grammarite.item == "Hypen":
			spd *= 1.15
			
		var max_stat = calc_stat(200, 100)
		accuracy *= (1 + (spd/(5*max_stat)))
		accuracy *= (1 - (defense_stat/(1.35*max_stat)))
		
		if hit_roll > accuracy:
			battle_ui.set_info_text("The attack missed!")
			await get_tree().create_timer(1.0).timeout
			return
		
		attacker.anim_player.play("Attack")
		
		var crit = false
		
		# Calculate damage
		var attack_level = attacker.level
		var base_damage = move.get("Damage", 0) # if no damage included, no damage
		
		# --- USE HELPER FUNCTION FOR ATTACK ---
		var attack_stat = get_modified_stat(attacker, "Attack")
		
		var effectiveness = 1
		if len(defender.grammarite_info["Stats"]["Types"]) == 2:
			effectiveness = Utils.get_damage_multiplier(move["Type"], defender.grammarite_info["Stats"]["Types"][0], defender.grammarite_info["Stats"]["Types"][1])
		else:
			effectiveness =  Utils.get_damage_multiplier(move["Type"], defender.grammarite_info["Stats"]["Types"][0])
		
		# custom formula
		var damage =  (base_damage*0.1)*int(attack_stat + attack_level + 5)
		# Makes the type chart matter
		damage *= effectiveness
		
		# --- NEW MOVES DAMAGE MODIFIERS ---
		if move["Name"] == "Lab Report" and attacker.item == "Sticker":
			damage *= 2.0
		
		# same type attack bonus
		if len(attacker.grammarite_info["Stats"]["Types"]) == 2:
			if move["Type"] == attacker.grammarite_info["Stats"]["Types"][0] or move["Type"] == attacker.grammarite_info["Stats"]["Types"][1]:
				damage *= 1.5
		else:
			if move["Type"] == attacker.grammarite_info["Stats"]["Types"][0]:
				damage *= 1.5
		
		# born with move bonus
		for i in Utils.get_grammarite_details(attacker.grammarite_name)["Moves"]:
			if i["Name"] == move["Name"]:
				damage *= 1.5
				break
		
		# crit
		if randf() > 0.95:
			damage *= 2.0
			crit = true
		
		
		# items
		if attacker.item == "Exclamation Mark": damage *= 1.25
		if defender.item == "Period": damage *= 0.8
		elif defender.item == "Comma": damage *= 0.9
		
		# Add some randomness (85% to 100% of calculated damage)
		damage = damage * randf_range(0.85, 1.0)
		
		# no negative damage
		damage = max(0, int(damage)) 
		
		# Apply damage
		defender.update_health(-int(damage))
		
		if crit:
			battle_ui.set_info_text("It crits!")
		elif effectiveness > 1:
			battle_ui.set_info_text("It is super effective!")
		elif effectiveness < 1:
			battle_ui.set_info_text("It is not very effective.")
		else:
			battle_ui.set_info_text("It hits!")
		
		if move["Name"] == "Punctuation Powerhouse":
			attacker.update_health(20)
		
		
		elif move["Name"] == "Peer Review":
			var side = "player" if attacker == player_grammarite else "enemy"
			var index = 0 if side == "player" else current_enemy_index
			stat_multipliers[side][index]["Speed"] *= 2.0
			stat_multipliers[side][index]["Attack"] *= 2.0
		elif move["Name"] == "Book Barrage":
			multi_hit_counter += 1
			if multi_hit_counter < 3:
				execute_attack(attacker, defender, move)
			else:
				multi_hit_counter = 0
		elif move["Name"] == "Library Lecture":
			var side = "player" if defender == player_grammarite else "enemy"
			var index = 0 if side == "player" else current_enemy_index
			status_tracker[side][index].append({"Name": "Sleep", "Duration": 3})
		elif move["Name"] == "Metaphor Misdirect":
			var side = "player" if defender == player_grammarite else "enemy"
			var index = 0 if side == "player" else current_enemy_index
			status_tracker[side][index].append({"Name": "Confusion", "Duration": 2})
		elif move["Name"] == "Alliteration Allure":
			var side = "player" if defender == player_grammarite else "enemy"
			var index = 0 if side == "player" else current_enemy_index
			status_tracker[side][index].append({"Name": "Blind", "Duration": 3})
		
		
		elif move["Name"] == "Homework Help":
			var heal_amount = int(attacker.max_health * 0.25)
			attacker.update_health(heal_amount)
		elif move["Name"] == "Study Guide":
			var side = "player" if attacker == player_grammarite else "enemy"
			var index = 0 if side == "player" else current_enemy_index
			stat_multipliers[side][index]["Attack"] *= 2
			stat_multipliers[side][index]["Speed"] *= 2
		elif move["Name"] == "Procrastinate":
			var side = "player" if attacker == player_grammarite else "enemy"
			var index = 0 if side == "player" else current_enemy_index
			status_tracker[side][index].append({"Name": "Procrastinate", "Duration": 2})
		elif move["Name"] == "LOCK IN":
			var side = "player" if attacker == player_grammarite else "enemy"
			var index = 0 if side == "player" else current_enemy_index
			status_tracker[side][index].clear()
		
	else:
		attacker.update_health(-int(15*randf_range(0.85, 1.0)))
		defender.update_health(-int(7*randf_range(6.0/7.0, 1.1))) # 6 or 7 damage 
		
		attacker.anim_player.play("Attack")
		
		battle_ui.set_info_text(attacker.grammarite_name+ " hurts itself.")
	
	var party = Utils.get_party()
	party[0]["Health"] = player_grammarite.health
	Utils.set_party(party)
	# Wait for animation and message display
	await get_tree().create_timer(0.9).timeout

# --- SIGNAL RECEIVER: WAKE UP FROM DAMAGE ---
func _on_grammarite_health_changed(target_node: Node2D, change_amount: int):
	# If the change is positive (healing) or 0, do nothing!
	if change_amount >= 0:
		return
		
	var side = "player" if target_node == player_grammarite else "enemy"
	var index = 0 if side == "player" else current_enemy_index
	
	var current_effects = status_tracker[side][index]
	var remaining_effects = []
	var woke_up = false
	
	for effect in current_effects:
		if effect["name"] == "Sleep":
			woke_up = true
		else:
			# Keep all other status effects like Burn or Poison
			remaining_effects.append(effect)
			
	if woke_up:
		status_tracker[side][index] = remaining_effects
		battle_ui.set_info_text(target_node.grammarite_name + " woke up from the damage!")
		await get_tree().create_timer(1.0).timeout

# --- VOLATILE STATUS CHECK (SLEEP / CONFUSION) ---
func pre_attack_status_check(attacker: Node2D) -> bool:
	var side = "player" if attacker == player_grammarite else "enemy"
	var index = 0 if side == "player" else current_enemy_index
	
	var current_effects = status_tracker[side][index]
	
	for effect in current_effects:
		if effect["name"] == "Sleep":
			battle_ui.set_info_text(attacker.grammarite_name + " is fast asleep.")
			await get_tree().create_timer(1.0).timeout
			return false # Returning false cancels the attack
			
		if effect["name"] == "Confusion":
			battle_ui.set_info_text(attacker.grammarite_name + " is confused!")
			await get_tree().create_timer(1.0).timeout
			
			# Basic self-damage calculation
			var attack_stat = get_modified_stat(attacker, "Attack")
			
			var type = attacker.grammarite_info["Stats"]["Types"].pick_random()
			var effectiveness = 1
			if len(attacker.grammarite_info["Stats"]["Types"]) == 2:
				effectiveness = Utils.get_damage_multiplier(type, attacker.grammarite_info["Stats"]["Types"][0], attacker.grammarite_info["Stats"]["Types"][1])
			else:
				effectiveness =  Utils.get_damage_multiplier(type, attacker.grammarite_info["Stats"]["Types"][0])
			
			var self_damage = (1.5 * 0.1) * int(attack_stat + attacker.level + 5) * effectiveness
			attacker.update_health(-int(self_damage))
			
			# attacker.anim_player.play("Attack") 
			await get_tree().create_timer(1.0).timeout
			
			return false # Attack is canceled because they hit themselves
	
	return true # No blocking status effects found, proceed to attack!

func calc_stat(base, level):
	return 5 + level + 0.01 * level * base

func throw_book(book_name):
	if current_state != BattleState.PLAYER_TURN or "random" not in trainer: return
	current_state = BattleState.ANIMATING
	
	
	battle_ui.set_info_text("You threw a "+book_name+"!")
	
	get_parent().get_node("BookAnimation/AnimationPlayer").play("ThrowBook")
	
	await get_tree().create_timer(0.6).timeout
	
	get_parent().get_node("BookAnimation/AnimationPlayer").play("BookShake")
	
	await get_tree().create_timer(0.6).timeout
	
	
	var base_chance = float(enemy_grammarite.max_health) / float(enemy_grammarite.max_health + 3.0 * enemy_grammarite.health)
	var caught = randf()
	
	
	if book_name == "Chapter Book":
		base_chance *= 1.5
	elif book_name == "Textbook":
		base_chance *= 2.0
	elif book_name == "Children's Book":
		base_chance += 0.2 - 0.01*enemy_grammarite.level
		
		if Utils.can_evolve(enemy_grammarite.grammarite_name, 100) == -1000:
			base_chance = 0
		elif !Utils.can_evolve(Utils.get_name_from_num(Utils.get_poke_num(enemy_grammarite.grammarite_name) - 1), 100):
			base_chance *= 0.75
		else:
			base_chance *= 1.25 
		
	
	
	if caught < base_chance:
		battle_ui.set_info_text("You caught it!")
		enemy_grammarite.visible = false
		await get_tree().create_timer(1.6).timeout
		# enemy_grammarite goes to your storage
		
		var found = false # flag for if there is room in inventory
		
		# sets up the grammarite
		var g_name = enemy_grammarite.grammarite_name
		var details = Utils.get_grammarite_details(g_name)
		var grammarite = {
			"Health": enemy_grammarite.health,
			"Item": "",
			"Level": enemy_grammarite.level,
			"Moves": [],
			"Name": g_name,
			"Nickname": "",
			"PP": []
		}
		for i in range(4):
			grammarite["Moves"].append(details["Moves"][i]["Name"])
			grammarite["PP"].append(details["Moves"][i]["PP"])
		
		# checks party for a spot
		var party = Utils.get_party()
		for i in range(6):
			if party[i]["Name"] == "":
				party[i] = grammarite
				found = true
				Utils.set_party(party)
				break
		
		if not found:
			# checks for room on bookshelf
			if not Utils.add_to_bookshelf(grammarite):
				battle_ui.set_info_text("Uh oh, it ran away because no space.")
				await get_tree().create_timer(2.0).timeout
		
		
		end_battle(true)
		return
	
	battle_ui.set_info_text("It broke free.")
	await get_tree().create_timer(0.6).timeout
	
	
	
	# Enemy's turn
	await enemy_turn()
	
	# Check if player fainted
	if player_grammarite.health <= 0:
		if not await on_player_grammarite_die(true):
			return
	
	# Back to player's turn
	current_state = BattleState.PLAYER_TURN
	battle_ui.input_state = battle_ui.InputState.ACTION_BUTTONS
	battle_ui.show_correct_menu()

func end_battle(player_won: bool):
	current_state = BattleState.BATTLE_END
	
	if player_won:
		Utils.catch(enemy_grammarite.grammarite_name)
		enemy_grammarite.visible = false
		battle_ui.set_info_text("You won!")
		await get_tree().create_timer(1.65).timeout
		var party = Utils.get_party()
		var xp = 1.0
		
		if "random" not in trainer:
			var train = Utils.get_trainer(trainer)
			xp = train["XP"]
			Utils.set_money(Utils.get_money()+train["Money"])
		else:
			xp = enemy_grammarite.level
		
		# random increase in xp, weighted closer to 1, up to 1.25
		xp *= (1 + (randf()/2)**2)
		
		# scale xp based on level, keep within range of 10-100 xp
		# for same level grammarites, get 50 xp upon victory
		xp = min(100, max(10, int( 50 * (xp / int(party[0]["Level"])) )))
		
		if fmod(party[0]["Level"], 1.0) + xp*0.01 > 1.0:
			battle_ui.set_info_text("Your Grammarite leveled up!")
			await get_tree().create_timer(1.5).timeout
			if Utils.can_evolve(player_grammarite.grammarite_name, player_grammarite.level) >= 0:
				var old_name = party[0]["Name"]
				var new_name = Utils.get_name_from_num(1 + Utils.get_poke_num(old_name))
				party[0]["Name"] = new_name
				
				evolve_screen.visible = true
				evolve_screen.get_node("NinePatchRect/Label").text ="WHAT? "+old_name+" is evolving!"
				evolve_screen.get_node("Sprite2D").texture = load("res://Assets/Pokemon/Pokemon"+str(Utils.get_poke_num(old_name)+1)+".png")
				evolve_screen.get_node("AnimationPlayer").play("Evolve")
				await get_tree().create_timer(1.4).timeout
				
				evolve_screen.get_node("Sprite2D").texture = load("res://Assets/Pokemon/Pokemon"+str(Utils.get_poke_num(new_name)+1)+".png")
				evolve_screen.get_node("NinePatchRect/Label").text = old_name+" evolved into "+new_name+"!"
				Utils.catch(new_name)
				await get_tree().create_timer(3.0).timeout
		
		party[0]["Level"] += 0.01 * xp
		if party[0]["Level"] > 100: party[0]["Level"] = 100
		Utils.set_party(party)
		
		
		battle_ended.emit(player_won)
		Utils.get_scene_manager().transition_exit_battle()
	else:
		player_grammarite.visible = false
		battle_ui.set_info_text("You lost!")
		if "random" not in trainer:
			var scene = get_node("/root/SceneManager/CurrentScene").get_child(0).name
			Utils.update_trainer_attacked(trainer, false, scene)
		await get_tree().create_timer(2.5).timeout
		
		battle_ended.emit(player_won)
		var party = Utils.get_party()
		Utils.set_money(0)
		Utils.set_party(party)
		Utils.get_scene_manager().transition_to_grammarite_center()
