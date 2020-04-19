extends Node2D

onready var explosion_scene = preload("res://scenes/explosion.tscn")
onready var lasers_scene = preload("res://scenes/lasers.tscn")

func _ready():
	pass

func _on_timer_explosion_timeout():
	generate_animation("explosions", explosion_scene)

func _on_timer_lasers_timeout():
	generate_animation("lasers", lasers_scene)

func generate_animation(folder, scene):
	var pos = get_pos(folder)
	if pos == null:
		return
	var explosion = scene.instance()
	explosion.position = pos.position
	add_child(explosion)

func get_pos(folder):
	var candidates = []
	var i = 1
	while true:
		var node = get_node("%s/pos_%d" % [folder, i])
		i += 1
		if node != null:
			candidates.append(node)
		else:
			break
	candidates.shuffle()
	if candidates.size() > 0:
		return candidates[0]
	else:
		return null
