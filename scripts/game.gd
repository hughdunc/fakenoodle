extends Node3D

@export var card_1: Node3D
@export var card_2: Node3D
@export var next: Button
@export var new_game: Button

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
		elif idx < len(Global.players) and event.position.y < next.position.y - (next.size.y / 1.5):
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
		
		# Set starter player name
		box1.get_node("Player").text = Global.players.pick_random()
		box2.get_node("Player").text = Global.players.pick_random()
		
		# Change Label2 text
		box1.get_node("Label2").text = "starts the conversation"
		
		# Hide extra stuff in Sprite3D (The simple side)
		box1.get_node("HSeparator").visible = false 
		box1.get_node("Label3").visible = false
		box1.get_node("TextureRect").visible = false
		
		# Note: We removed new_game.visible = true from here so it only shows when centered
		
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
	get_tree().change_scene_to_file("res://imposter_reveal.tscn")
