extends Node2D

func _ready():
	$lbl_count.text = "0"

func set_count(count):
	$lbl_count.text = str(count)
