extends Node2D

func _ready():
	$sprite.play()

func _on_sprite_animation_finished():
	queue_free()
