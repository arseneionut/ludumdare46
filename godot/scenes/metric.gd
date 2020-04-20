extends Node2D

var _value = 50

func set_labels(lbl_min, lbl_max):
	$lbl_min.text = lbl_min
	$lbl_max.text = lbl_max

func set_value(value):
	_value = value
	var width = int(value * 312.0 / 100.0)
	print(width, $bar.region_rect.size)
	$bar.region_rect.size.x = width
