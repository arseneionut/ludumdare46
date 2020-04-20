extends Node2D

var scene = preload("res://scenes/main.tscn")

func _on_Button_pressed():
	get_tree().change_scene("res://scenes/main.tscn")
