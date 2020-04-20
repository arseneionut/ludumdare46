extends Node2D

var _value = 50

func set_labels(lbl_min, lbl_max):
	$lbl_min.text = lbl_min
	$lbl_max.text = lbl_max

func set_value(value):
	_value = value
	var disp = value - 50
	var width = int(abs(disp) * 156.0 / 50.0)
	$bar.region_rect.size.x = width
	if disp <= 0:
		$bar.region_rect.position.x = 156 - width
		$bar.offset.x = 156 - width
	else:
		$bar.region_rect.position.x = 156
		$bar.offset.x = 156
