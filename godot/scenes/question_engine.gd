
class_name QuestionEngine

class Metric:
	var value
	var name
	var definition
	
	func _init(name, definition):
		self.name = name
		self.definition = definition
		value = definition.start
	
	func to_string():
		return "metric '%s' with value %d" % [name, value]

class Choice:
	var text
	var actions
	
	func _init(definition):
		text = definition.text
		actions = definition.actions
	
	func to_string():
		var result = []
		result.append("choice '%s'" % [text])
		for action in actions:
			result.append("  " + action)
		return PoolStringArray(result).join("\n")

class NextQuestion:
	var probability
	var id
	
	func _init(definition):
		definition = definition.strip_edges()
		var bits = definition.split(" ")
		var filtered_bits = []
		for b in bits:
			if b.strip_edges() != "":
				filtered_bits.append(b)
		probability = int(filtered_bits[0].trim_suffix("%")) / 100.0
		id = filtered_bits[2]
	
	func to_string():
		return "%f -> %s" % [probability, id]
	

class Question:
	var id
	var conditions
	var text
	var choices
	var next

	func _init(id, definition):
		self.id = id
		self.text = definition.text
		self.conditions = definition.conditions
		choices = []
		for c in definition.choices:
			choices.append(Choice.new(c))
		next = []
		for n in definition.next:
			next.append(NextQuestion.new(n))

	func to_string():
		var result = []
		result.append("question '%s'" % [id])
		result.append("  text: %s" % [text])
		result.append("  conditions:")
		for c in conditions:
			result.append("    " + c)
		result.append("  choices:")
		for c in choices:
			result.append("    choice '%s'" % [c.text])
		result.append("  next:")
		for n in next:
			result.append("    %s" % [n.to_string()])
		return PoolStringArray(result).join("\n")

var questions
var metrics
var current_question_id
var tokens
var current_messages
var game_over

func _init(design):
	metrics = []
	for metric_name in design.metrics:
		var metric = design.metrics[metric_name]
		metrics.append(Metric.new(metric_name, metric))
	current_question_id = design["start-question"]
	questions = []
	for question_id in design.questions:
		var question = Question.new(question_id, 
									design.questions[question_id])
		questions.append(question)
	tokens = {}
	game_over = false

func get_current_question_id():
	return current_question_id

func get_question(id):
	for question in questions:
		if question.id == id:
			return question
	return null

func run_action(action):
	action = action.strip_edges()
	if action.find("message ") == 0:
		current_messages.append(action.trim_prefix("message "))
	elif action.find("add ") == 0:
		var token_name = action.trim_prefix("add ")
		tokens[token_name] = 1
	elif action.find("remove ") == 0:
		var token_name = action.trim_prefix("remove ")
		tokens.erase(token_name)

func make_choice(choice_index):
	var question = get_question(current_question_id)
	var choice = question.choices[choice_index]
	print(choice.to_string())
	current_messages = []
	for action in choice.actions:
		run_action(action)

func get_latest_messages():
	return current_messages

func get_present_tokens():
	var result = []
	for token in tokens:
		result.append(token)
	return result

func is_game_over():
	return game_over

