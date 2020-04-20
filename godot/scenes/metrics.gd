extends Node

func _ready():
	$metric_drink.set_labels("sober", "wasted")
	$metric_madness.set_labels("exposed", "supervised")
	$metric_hype.set_labels("boooooring!", "hyped!")

func update_values(dict):
	print(dict)
	$metric_drink.set_value(dict["drink"])
	$metric_madness.set_value(dict["madness"])
	$metric_hype.set_value(dict["hype"])
