extends Node2D

var QuestionEngine = load("res://scenes/question_engine.gd")
var engine
var card

func _ready():
	#tests()
	card = $party_viewer/card
	card.connect("state_updated", self, "_on_card_state_updated")
	card.connect("new_game", self, "_on_card_new_game")
	card.connect("game_over", self, "_on_card_game_over")
	card.connect("new_card", self, "_on_card_new_card")
	card.connect("button_press", self, "_on_card_button_press")
	initialize_engine()

func _on_card_state_updated():
	populate_metrics()

func _on_card_new_game():
	initialize_engine()

func _on_card_game_over():
	play_game_over()

func _on_card_new_card():
	play_new_card()

func _on_card_button_press():
	play_button_press()

func initialize_engine():
	$sounds/pause_timer.start()
	var f = File.new()
	var y = f.open("res://resources/question.tres", File.READ)
	var content = f.get_as_text()
	f.close()
	var jsonResult = JSON.parse(content)
	engine = QuestionEngine.new(jsonResult.result)
	card.init(engine)
	populate_metrics()
	card.populate_ui()

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


func _on_background_1_finished():
	$sounds/background_1.stop()
	if not engine.is_game_over():
		$sounds/pause_timer.start()

func _on_background_2_finished():
	$sounds/background_2.stop()
	if not engine.is_game_over():
		$sounds/pause_timer.start()

func _on_pause_timer_timeout():
	stop_all_background_music()
	if Utils.rng.randf() > 0.5:
		$sounds/background_1.play()
	else:
		$sounds/background_2.play()

func play_game_over():
	stop_all_background_music()
	$sounds/game_over.play()

func stop_all_background_music():
	$sounds/background_1.stop()
	$sounds/background_2.stop()
	
func play_new_card():
	if Utils.rng.randf() > 0.5:
		$sounds/new_card_1.play()
	else:
		$sounds/new_card_2.play()

func play_button_press():
	$sounds/button_press.play()
