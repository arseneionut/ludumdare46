extends Node

func _ready():
	$metric_drink.set_labels("min", "max")
	$metric_madness.set_labels("min", "max")
	$metric_hype.set_labels("min", "max")

func update_values(dict):
	$metric_drink.set_value(dict["drink"])
	$metric_madness.set_value(dict["madness"])
	$metric_hype.set_value(dict["hype"])
