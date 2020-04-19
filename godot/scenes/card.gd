extends Node2D

signal state_updated
signal new_game

var engine
var state

func init(engine):
	self.engine = engine
	state = 0

func populate_ui():
	populate_question()

func populate_question():
	if engine.is_game_over():
		populate_game_over()
	else:
		populate_current_question()

func populate_game_over():
	$btn_choice_1.visible = false
	$btn_choice_2.visible = false
	$lbl_question.visible = true
	$lbl_question.text = "GAME OVER"
	$btn_choice_3.visible = true
	$btn_choice_3.text = "Again!"
	state = 1

func populate_messages():
	$btn_choice_1.visible = false
	$btn_choice_2.visible = false
	$lbl_question.visible = true
	var messages = engine.get_latest_messages()
	var text = PoolStringArray(messages).join("\n\n")
	$lbl_question.text = text
	$btn_choice_3.visible = true
	$btn_choice_3.text = "Next"

func populate_current_question():
	state = 0
	var question = engine.get_question(engine.get_current_question_id())
	$btn_choice_1.visible = false
	$btn_choice_2.visible = false
	$btn_choice_3.visible = false
	$lbl_question.visible = true
	$lbl_question.text = question.text
	var i = 0
	while i < question.choices.size() and i < 3:
		var node = get_node("btn_choice_%d" % [i + 1])
		node.visible = true
		node.text = question.choices[i].text
		i += 1

func _on_btn_choice_1_pressed():
	button_press(0)

func _on_btn_choice_2_pressed():
	button_press(1)

func _on_btn_choice_3_pressed():
	button_press(2)

func button_press(button):
	match state:
		0:
			button_press_answer(button)
		1:
			button_press_game_over()
		2:
			button_press_continue()

func button_press_answer(button):
	engine.make_choice(button)
	state = 2
	populate_messages()
	emit_signal("state_updated")

func button_press_game_over():
	emit_signal("new_game")

func button_press_continue():
	state = 0
	populate_question()
