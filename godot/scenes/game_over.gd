extends Node2D

signal new_game

func _ready():
	pass # Replace with function body.

func show_game_over(metrics_dict, messages):
	print(metrics_dict)
	self.visible = true
	if metrics_dict["hype"] == 0:
		$background.texture = load("res://assets/graphics/GameOver/boring.png")
	elif metrics_dict["hype"] == 100:
		$background.texture = load("res://assets/graphics/GameOver/exhausted.png")
	elif metrics_dict["drink"] == 0:
		$background.texture = load("res://assets/graphics/GameOver/sober.png")
	elif metrics_dict["drink"] == 100:
		$background.texture = load("res://assets/graphics/GameOver/wasted.png")
	elif metrics_dict["madness"] == 0:
		$background.texture = load("res://assets/graphics/GameOver/exposed.png")
	elif metrics_dict["madness"] == 100:
		$background.texture = load("res://assets/graphics/GameOver/supervised.png")
	$background/lbl_messages.text = PoolStringArray(messages).join("\n")

func hide_game_over():
	self.visible = false

func _on_Button_pressed():
	emit_signal("new_game")
