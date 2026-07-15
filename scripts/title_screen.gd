extends Control

@export var imposters_label: Label
@export var players: Button
@export var hint_button: CheckButton
@export var subtract: Button
@export var add: Button

# Called when the node enters the scene tree for the first time.
func _ready():
	imposters_label.text = str(Global.imposters)
	hint_button.button_pressed = Global.imposter_hint
	
	players.text = "Players (" + str(len(Global.players)) + ")"
	
	disable_imposter_tickers()

func disable_imposter_tickers():
	if len(Global.players) < 5:
		Global.imposters = 1
		subtract.disabled = true
		add.disabled = true
	elif len(Global.players) < 8:
		if Global.imposters == 1:
			subtract.disabled = true
			add.disabled = false
		elif Global.imposters == 2:
			subtract.disabled = false
			add.disabled = true
	else:
		if Global.imposters == 1:
			subtract.disabled = true
			add.disabled = false
		elif Global.imposters == 3:
			subtract.disabled = false
			add.disabled = true
		else:
			subtract.disabled = false
			add.disabled = false


func _on_hint_toggled(toggled_on):
	Global.imposter_hint = toggled_on


func _on_subtract_pressed():
	Global.imposters -= 1
	imposters_label.text = str(Global.imposters)
	disable_imposter_tickers()

func _on_add_pressed():
	Global.imposters += 1
	imposters_label.text = str(Global.imposters)
	disable_imposter_tickers()


func _on_start_game_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_players_pressed():
	get_tree().change_scene_to_file("res://scenes/players.tscn")


func _on_words_pressed():
	get_tree().change_scene_to_file("res://scenes/words.tscn")
