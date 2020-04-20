extends Node2D

func _ready():
	$animation.play()

func _on_animation_animation_finished():
	queue_free()
