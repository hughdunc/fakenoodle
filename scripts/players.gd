extends Control

@export var item: PackedScene
@export var list: Control

func item_up(i: Node):
	if i.get_index() > 0:
		i.get_parent().move_child(i, i.get_index() - 1)

func item_down(i: Node):
	if i.get_index() < i.get_parent().get_child_count() - 1:
		i.get_parent().move_child(i, i.get_index() + 1)

func item_remove(i: Node):
	if i.get_parent().get_child_count() > 3:
		i.get_parent().remove_child(i)
		i.queue_free()

func _ready():
	for p in Global.players:
		var i = item.instantiate()
		i.get_node("LineEdit").text = p
		i.up_pressed.connect(item_up)
		i.down_pressed.connect(item_down)
		i.remove_pressed.connect(item_remove)
		list.add_child(i)

func _on_done_pressed():
	var newplayers = []
	for child in list.get_children():
		newplayers.append(child.get_node("LineEdit").text)
	for p in newplayers:
		if p.strip_edges() == "":
			return
	Global.players = newplayers
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _on_cancel_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _on_add_player_pressed():
	var i = item.instantiate()
	i.up_pressed.connect(item_up)
	i.down_pressed.connect(item_down)
	i.remove_pressed.connect(item_remove)
	list.add_child(i)
