extends Node3D

@export var card_1: Node3D
@export var card_2: Node3D
@export var next: Button
@export var new_game: Button
@export var exit: Button

var pressing = false
var enabled = true
var idx = 0

func _ready():
	# Force every Sprite3D to broadcast its OWN SubViewport
	card_1.get_node("Sprite3D").texture = card_1.get_node("Sprite3D/SubViewport").get_texture()
	card_1.get_node("Sprite3D2").texture = card_1.get_node("Sprite3D2/SubViewport").get_texture()
	
	card_2.get_node("Sprite3D").texture = card_2.get_node("Sprite3D/SubViewport").get_texture()
	card_2.get_node("Sprite3D2").texture = card_2.get_node("Sprite3D2/SubViewport").get_texture()
	
	new_game.visible = false 
	
	randomize()
	Global.decide_imposters()
	Global.decide_word()
	
	card_1.global_position.x = 0.0
	card_2.global_position.x = 5.0
	
	update_card(card_1, idx)
	update_card(card_2, idx + 1)


func _input(event):
	if event is InputEventScreenTouch:
		if not event.pressed:
			pressing = false
		elif idx < len(Global.players) and event.position.y < next.position.y - (next.size.y / 1.5) and event.position.y > exit.position.y + exit.size.y:
			pressing = true


func _process(delta):
	var wishpos = 0.0
	var wishrot = 0.0
	if pressing and enabled and idx < len(Global.players):
		wishpos = 0.25
		wishrot = PI
		next.visible = true
	
	card_1.global_position.z = lerp(card_1.global_position.z, wishpos, 0.1)
	card_1.global_rotation.y = lerp_angle(card_1.global_rotation.y, wishrot, 0.1)
	
	
	if not enabled:
		next.visible = false
		card_1.global_position.x = lerp(card_1.global_position.x, -5.0, 0.1)
		
		if idx + 1 <= len(Global.players):
			card_2.global_position.x = lerp(card_2.global_position.x, 0.0, 0.1)
		
		var card_1_done = abs(card_1.global_position.x + 5.0) < 0.01
		var card_2_done = true
		if idx + 1 <= len(Global.players):
			card_2_done = abs(card_2.global_position.x) < 0.01
			
		if card_1_done and card_2_done:
			if idx < len(Global.players):
				card_1.global_position.x = 5.0
				var temp = card_1
				card_1 = card_2
				card_2 = temp
				idx += 1
				update_card(card_2, idx + 1)
				enabled = true
				
				# If we just slid into the final Summary card, show the button
				if idx == len(Global.players):
					new_game.visible = true
					


func update_card(card: Node3D, player_idx: int):
	var box1 = card.get_node("Sprite3D/SubViewport/Button/VBoxContainer")
	var box2 = card.get_node("Sprite3D2/SubViewport/Button/VBoxContainer")
	
	# Scenario A: Final Summary Card
	if player_idx == len(Global.players):
		card.visible = true
		
		# --- PERFECT PROBABILITY MATH ---
		var player_count = len(Global.players)
		var imposter_count = Global.imposter_indexes.size()
		var normal_count = player_count - imposter_count
		
		# Convert 100.0 into 1.0, 50.0 into 0.5, etc.
		var chance_multiplier = clampf(Global.imposter_starting_chance / 100.0, 0.0, 1.0)
		
		var imposter_prob = 0.0
		var normal_prob = 0.0
		
		if normal_count > 0:
			# 1. Figure out what the fair baseline chance is (e.g. 25% for 4 players)
			var base_chance = 1.0 / float(player_count)
			
			# 2. Scale the imposter's chance by the user setting (e.g. 50% of 25% = 12.5%)
			imposter_prob = base_chance * chance_multiplier
			
			# 3. Figure out how much probability is leftover
			var total_imposter_prob = imposter_prob * imposter_count
			var remaining_prob = 1.0 - total_imposter_prob
			
			# 4. Divide all remaining probability evenly among the normal players
			normal_prob = remaining_prob / float(normal_count)
		else:
			# Fallback just in case you somehow make a game of ONLY imposters
			imposter_prob = 1.0 / float(player_count)
			
		var weights = []
		for i in range(player_count):
			if i in Global.imposter_indexes:
				weights.append(imposter_prob)
			else:
				weights.append(normal_prob)
				
		# Roll a random number from 0 to 1
		var roll = randf()
		var current_weight = 0.0
		var starter_idx = 0
		
		# Figure out who won the roll
		for i in range(len(weights)):
			current_weight += weights[i]
			if roll <= current_weight:
				starter_idx = i
				break
				
		var starter_name = Global.players[starter_idx]
		
		# Set starter player name
		box1.get_node("Player").text = starter_name
		box2.get_node("Player").text = starter_name
		
		# Change Label2 text
		box1.get_node("Label2").text = "starts the conversation"
		
		# Hide extra stuff in Sprite3D (The simple side)
		box1.get_node("HSeparator").visible = false 
		box1.get_node("Label3").visible = false
		box1.get_node("TextureRect").visible = false
		
	# Scenario B: Standard active player card
	elif player_idx < len(Global.players):
		card.visible = true
		
		box1.get_node("Player").text = Global.players[player_idx]
		box2.get_node("Player").text = Global.players[player_idx]
		
		# Ensure extra stuff is visible in Sprite3D
		box1.get_node("HSeparator").visible = true
		box1.get_node("Label3").visible = true
		box1.get_node("TextureRect").visible = true
		
		if player_idx in Global.imposter_indexes:
			box2.get_node("PanelContainer/Word").text = "YOU ARE THE IMPOSTER!"
			box2.get_node("Hint").text = "Hint: " + Global.hint
			box2.get_node("Hint").visible = Global.imposter_hint
		else:
			box2.get_node("PanelContainer/Word").text = Global.word
			box2.get_node("Hint").visible = false
			
		new_game.visible = false
	else:
		card.visible = false


func _on_next_pressed():
	enabled = false
	pressing = false


func _on_finish_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _on_reveal_pressed():
	get_tree().change_scene_to_file("res://scenes/imposter_reveal.tscn")


func _on_exit_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
