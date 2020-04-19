extends Node2D

var QuestionEngine = load("res://scenes/question_engine.gd")
var engine
var card

func _ready():
	tests()
	card = $party_viewer/card
	card.connect("state_updated", self, "_on_card_state_updated")
	card.connect("new_game", self, "_on_card_new_game")
	initialize_engine()

func _on_card_state_updated():
	populate_metrics()

func _on_card_new_game():
	initialize_engine()

func initialize_engine():
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
