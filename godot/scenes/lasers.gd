extends Node2D

var counter = 2

func _ready():
	$sprite.play()

func _on_sprite_animation_finished():
	counter -= 1
	if counter <= 0:
		queue_free()
