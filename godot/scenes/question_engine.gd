
class_name QuestionEngine

class Metric:
	var value
	var name
	var min_value
	var max_value
	var min_actions
	var max_actions
	var min_already_triggered
	var max_already_triggered
	
	func _init(name, definition):
		self.name = name
		value = definition.start
		min_value = Utils.safe_get(definition, "min", -10000000)
		max_value = Utils.safe_get(definition, "max", 10000000)
		min_actions = Utils.safe_get(definition, "min-action", [])
		max_actions = Utils.safe_get(definition, "max-action", [])
		clear()
	
	func clear():
		min_already_triggered = false
		max_already_triggered = false
	
	func to_string():
		return "metric '%s' with value %d" % [name, value]
	
	func set_value(value, action_list):
		self.value = value
		if value < min_value:
			value = min_value
		if value > max_value:
			value = max_value
		if value == min_value and not min_already_triggered:
			for action in min_actions:
				action_list.append(action)
			min_already_triggered = true
		if value == max_value and not max_already_triggered:
			for action in max_actions:
				action_list.append(action)
			max_already_triggered = true

class Choice:
	var text
	var actions
	
	func _init(definition):
		text = definition.text
		actions = Utils.safe_get(definition, "actions", [])
	
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
		var bits = Utils.split_and_clean(definition, " ")
		probability = int(bits[0].trim_suffix("%")) / 100.0
		id = bits[2]
	
	func to_string():
		return "%f -> %s" % [probability, id]

class Character:
	var id
	var name
	func _init(definition):
		id = definition.id
		name = Utils.safe_get(definition, "name", id)
	
	func to_string():
		return "character '%s': %s" % [id, name]

class Question:
	var id
	var conditions
	var text
	var choices
	var next
	var character
	var in_random_pool

	func _init(id, definition):
		self.id = id
		self.text = definition.text
		self.conditions = Utils.safe_get(definition, "conditions", [])
		self.character = Utils.safe_get(definition, "character", null)
		self.in_random_pool = Utils.safe_get(definition, "in-random-pool", true)
		choices = []
		for c in Utils.safe_get(definition, "choices", []):
			choices.append(Choice.new(c))
		next = []
		for n in Utils.safe_get(definition, "next", []):
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

var _questions
var _metrics
var _characters
var _current_question_id
var _tokens
var _current_messages
var _game_over

func _init(design):
	_characters = []
	for character in Utils.safe_get(design, "characters", []):
		_characters.append(Character.new(character))
	_metrics = []
	for metric_name in design.metrics:
		var metric = design.metrics[metric_name]
		_metrics.append(Metric.new(metric_name, metric))
	_current_question_id = design["start-question"]
	_questions = []
	for question_id in design.questions:
		var question = Question.new(question_id, 
									design.questions[question_id])
		_questions.append(question)
	_tokens = {}
	_game_over = false

func get_metric_names():
	var result = []
	for metric in _metrics:
		result.append(metric.name)
	return result

func get_character_names():
	var result = []
	for ch in _characters:
		result.append(ch.name)
	return result

func get_character(character_name):
	for ch in _characters:
		if ch.name == character_name:
			return ch
	return null

func get_current_question_id():
	return _current_question_id

func get_question(id):
	for question in _questions:
		if question.id == id:
			return question
	return null

func get_metric(metric_name):
	for metric in _metrics:
		if metric.name == metric_name:
			return metric
	return null

func make_choice(choice_index):
	if _game_over:
		return
	for metric in _metrics:
		metric.clear()
	var question = get_question(_current_question_id)
	var choice = question.choices[choice_index]
	_current_messages = []
	var actions = Utils.copy_array(choice.actions)
	var i = 0
	while i < actions.size():
		var action = actions[i]
		_run_action(action, actions)
		if _game_over:
			break
		i += 1
	if not _game_over:
		_choose_next_question()

func get_latest_messages():
	return _current_messages

func get_present_tokens():
	var result = []
	for token in _tokens:
		result.append(token)
	return result

func is_game_over():
	return _game_over

# private helper functions

func _choose_next_question():
	var question = get_question(_current_question_id)
	var explicit_next = _build_explicit_next(question.next)
	var random = Utils.rng.randf()
	var selection = null
	for n in explicit_next:
		if random < n.probability:
			selection = n.id
			break
		else:
			random -= n.probability
	if selection == null:
		var explicit_others = _build_explicit_others(explicit_next)
		if explicit_others.size() > 0:
			selection = explicit_others[0].id
	if selection == null:
		_current_messages.append("No more things to do!")
		_game_over = true
	else:
		_current_question_id = selection

func _run_action(action, actions):
	action = action.strip_edges()
	if action.find("message ") == 0:
		_current_messages.append(action.trim_prefix("message "))
	elif action.find("add ") == 0:
		var token_name = action.trim_prefix("add ")
		_tokens[token_name] = 1
	elif action.find("remove ") == 0:
		var token_name = action.trim_prefix("remove ")
		_tokens.erase(token_name)
	elif action == "game over":
		_game_over = true
	else:
		var bits = Utils.split_and_clean(action, " ")
		match bits[1]:
			"=":
				_set_metric(bits[0], bits[2], actions)
			"-=":
				_decrease_metric(bits[0], bits[2], actions)
			"+=":
				_increase_metric(bits[0], bits[2], actions)

func _set_metric(metric_name, value, actions):
	var metric = get_metric(metric_name)
	metric.set_value(value, actions)

func _decrease_metric(metric_name, value, actions):
	var metric = get_metric(metric_name)
	metric.set_value(metric.value - int(value), actions)

func _increase_metric(metric_name, value, actions):
	var metric = get_metric(metric_name)
	metric.set_value(metric.value + int(value), actions)

func _build_explicit_next(next):
	var result = []
	for n in next:
		var question = get_question(n.id)
		if _eval_conditions(question.conditions):
			result.append(n)
	return result

func _build_explicit_others(next):
	var result = []
	var next_dict = {}
	for n in next:
		next_dict[n.id] = 1
	for question in _questions:
		if not question.in_random_pool:
			continue
		if not _eval_conditions(question.conditions):
			continue
		if next_dict.has(question.id):
			continue
		if question.id == _current_question_id:
			continue
		result.append(question)
	result.shuffle()
	return result

func _eval_conditions(conditions):
	for condition in conditions:
		if not _eval_condition(condition):
			return false
	return true

func _eval_condition(condition):
	var bits = Utils.split_and_clean(condition, " ")
	if bits.size() == 2:
		if bits[1] == "absent":
			return !_tokens.has(bits[0])
		elif bits[1] == "present":
			return _tokens.has(bits[0])
	elif bits.size() == 3:
		var metric_value = get_metric(bits[0]).value
		var value = int(bits[2])
		match bits[1]:
			"=":
				return metric_value == value
			"<":
				return metric_value < value
			">":
				return metric_value > value
			"<=":
				return metric_value <= value
			">=":
				return metric_value >= value
	return true

