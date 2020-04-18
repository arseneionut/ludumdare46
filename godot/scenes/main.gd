extends Node2D

var QuestionEngine = load("res://scenes/question_engine.gd")

func _ready():
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
	print(engine.get_metric_value("fun"))
	print(engine.get_metric_value("police"))
	print(engine.get_metric_value("money"))
	print(engine.is_game_over())
	print(engine.get_latest_messages())
	print(engine.get_present_tokens())
	print(engine.get_current_question_id())
