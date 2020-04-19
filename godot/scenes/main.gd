extends Node2D

var QuestionEngine = load("res://scenes/question_engine.gd")
var engine
var state

func _ready():
	tests()
	initialize_engine()

func initialize_engine():
	var f = File.new()
	var y = f.open("res://resources/question.tres", File.READ)
	var content = f.get_as_text()
	f.close()
	var jsonResult = JSON.parse(content)
	engine = QuestionEngine.new(jsonResult.result)
	state = 0
	populate_ui()

func populate_ui():
	populate_question()
	populate_metrics()

func populate_question():
	if engine.is_game_over():
		populate_game_over()
	else:
		populate_current_question()

func populate_game_over():
	$party_viewer/card/btn_choice_1.visible = false
	$party_viewer/card/btn_choice_2.visible = false
	$party_viewer/card/lbl_question.visible = true
	$party_viewer/card/lbl_question.text = "GAME OVER"
	$party_viewer/card/btn_choice_3.visible = true
	$party_viewer/card/btn_choice_3.text = "Again!"
	state = 1

func populate_messages():
	$party_viewer/card/btn_choice_1.visible = false
	$party_viewer/card/btn_choice_2.visible = false
	$party_viewer/card/lbl_question.visible = true
	var messages = engine.get_latest_messages()
	var text = PoolStringArray(messages).join("\n\n")
	$party_viewer/card/lbl_question.text = text
	$party_viewer/card/btn_choice_3.visible = true
	$party_viewer/card/btn_choice_3.text = "Next"

func populate_current_question():
	state = 0
	var question = engine.get_question(engine.get_current_question_id())
	$party_viewer/card/btn_choice_1.visible = false
	$party_viewer/card/btn_choice_2.visible = false
	$party_viewer/card/btn_choice_3.visible = false
	$party_viewer/card/lbl_question.visible = true
	$party_viewer/card/lbl_question.text = question.text
	var i = 0
	while i < question.choices.size() and i < 3:
		var node = get_node("party_viewer/card/btn_choice_%d" % [i + 1])
		node.visible = true
		node.text = question.choices[i].text
		i += 1

func populate_metrics():
	var metrics = engine.get_metric_names()
	$CanvasLayer/Panel2/lbl_metric_1.visible = false
	$CanvasLayer/Panel2/lbl_metric_2.visible = false
	$CanvasLayer/Panel2/lbl_metric_3.visible = false
	$CanvasLayer/Panel2/lbl_metric_4.visible = false
	$CanvasLayer/Panel2/lbl_metric_5.visible = false
	var i = 0
	while i < metrics.size() and i < 5:
		var node = get_node("CanvasLayer/Panel2/lbl_metric_%d" % [i + 1])
		node.text = "%s: %d" % [metrics[i], engine.get_metric(metrics[i]).value]
		node.visible = true
		i += 1
	
func tests():
	var f = File.new()
	var y = f.open("res://resources/question.tres", File.READ)
	var content = f.get_as_text()
	f.close()
	var jsonResult = JSON.parse(content)
	var engine = QuestionEngine.new(jsonResult.result)
	print(engine.get_current_question_id())
	print(engine.get_question("blabla1").to_string())
	engine.make_choice(0)
	print(engine.get_metric_names())
	print(engine.get_metric("fun").value)
	print(engine.get_metric("police").value)
	print(engine.get_metric("money").value)
	print(engine.is_game_over())
	print(engine.get_latest_messages())
	print(engine.get_present_tokens())
	print(engine.get_current_question_id())


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
	populate_metrics()

func button_press_game_over():
	initialize_engine()

func button_press_continue():
	state = 1
	populate_question()
