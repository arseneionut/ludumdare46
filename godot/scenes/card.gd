extends Node2D

signal state_updated
signal new_game
signal game_over
signal new_card
signal button_press

var engine
var state

func init(engine):
	self.engine = engine
	state = 0

func populate_ui():
	populate_question()

func populate_question():
	emit_signal("new_card")
	state = 0
	var question = engine.get_question(engine.get_current_question_id())
	$character.visible = true
	$character.texture = load("res://assets/graphics/Characters/icon_%s.png" % question.character)
	var character = engine.get_character(question.character)
	if character != null:
		$lbl_character_name.text = character.name
	else:
		$lbl_character_name.text = ""
	$btn_choice_1.visible = false
	$btn_choice_2.visible = false
	$lbl_question.visible = true
	$lbl_question.text = question.text
	var i = 0
	hide_metric_icons()
	while i < question.choices.size() and i < 2:
		var choice = question.choices[i]
		i += 1
		var node = get_node("btn_choice_%d" % i)
		node.visible = true
		node.text = choice.text
		print(choice.to_string())
		var affected_metrics = choice.get_affected_metrics()
		print(affected_metrics)
		var j = 0
		while j < 3 and j < affected_metrics.size():
			var metric = affected_metrics[j]
			j += 1
			var icon = get_node("btn_choice_%d/metric_%d" % [i, j])
			icon.texture = load(
				"res://assets/graphics/Metrics/icons/icon_%s.png" % metric)
			icon.visible = true

func hide_metric_icons():
	$btn_choice_1/metric_1.visible = false
	$btn_choice_1/metric_2.visible = false
	$btn_choice_1/metric_3.visible = false
	$btn_choice_2/metric_1.visible = false
	$btn_choice_2/metric_2.visible = false
	$btn_choice_2/metric_3.visible = false

func populate_messages():
	$btn_choice_1.visible = false
	$lbl_question.visible = true
	var messages = engine.get_latest_messages()
	var text = PoolStringArray(messages).join("\n\n")
	$lbl_question.text = text
	$btn_choice_2.visible = true
	hide_metric_icons()
	if engine.is_game_over():
		$btn_choice_2.text = "Play again?"
	else:
		$btn_choice_2.text = "Next"

func _on_btn_choice_1_pressed():
	button_press(0)

func _on_btn_choice_2_pressed():
	button_press(1)

func button_press(button):
	emit_signal("button_press")
	match state:
		0:
			button_press_answer(button)
		1:
			button_press_continue()

func button_press_answer(button):
	engine.make_choice(button)
	if engine.is_game_over():
		emit_signal("game_over")
	state = 1
	populate_messages()
	emit_signal("state_updated")

func button_press_continue():
	if engine.is_game_over():
		emit_signal("new_game")
	else:
		state = 0
		populate_question()
