extends Node2D

enum { PLAYING, GAME_OVER }

var counter
var count_down_level
var state = PLAYING
var log_base = 1.4

onready var explosion_scene = preload("res://scenes/explosion.tscn")
onready var smoke_heart_scene = preload("res://scenes/smoke_heart.tscn")

func _ready():
	counter = 1
	state = PLAYING

func new_game():
	counter = 1
	state = PLAYING
	_redisplay()

func new_card():
	counter += 1
	_redisplay()

func game_over():
	count_down_level = int(clamp(log(counter) / log(log_base), 1, 15))
	state = GAME_OVER
	$game_over_timer.start()

func _redisplay():
	var level = int(clamp(log(counter) / log(log_base), 1, 15))
	show_level(level)

func show_level(level):
	var i = 1
	while i <= 15:
		var node = get_node("buildings_%d" % i)
		node.visible = false
		i += 1
	get_node("buildings_%d" % level).visible = true

func _on_game_over_timer_timeout():
	if state != GAME_OVER:
		$game_over_timer.stop()
		return
	count_down_level -= 1
	if count_down_level < 1:
		$game_over_timer.stop()
		return
	show_level(count_down_level)

func _on_timer_timeout():
	if state == PLAYING:
		if Utils.rng.randf() > 0.5:
			show_effect(explosion_scene, "explosions")
		else:
			show_effect(smoke_heart_scene, "hearts")
	$effects/timer.wait_time = Utils.rng.randi_range(5, 15)

func show_effect(scene, folder):
	var idx = Utils.rng.randi_range(1, 5)
	var pos = get_node("effects/%s/pos_%d" % [folder, idx])
	var effect = scene.instance()
	effect.position = pos.position
	add_child(effect)
