extends Node

var _failures = []
var _passed = 0
var _failed = 0
var _fail = false
var _engine
var _current_test
var _rng

class MockRng:
	
	var _value
	
	func setup(value):
		_value = value

	func randf():
		return _value

func _ready():
	# don't run tests if this is not a debug build
	if OS.has_feature("standalone"):
		return

	var old_rng = Utils.rng
	_rng = MockRng.new()
	Utils.rng = _rng
	
	_TEST_basic()
	_TEST_next_selection()
	_TEST_action_1()
	_TEST_action_2()
	_TEST_action_3()
	_TEST_condition_1()
	_TEST_condition_2()
	_TEST_condition_3()
	_TEST_metric_min()
	_TEST_metric_max()
	_TEST_metric_loop()
	_TEST_next_selection_conditions()
	_TEST_pool_selection_conditions()
	_TEST_in_random_pool()
	
	_process_results()
	Utils.rng = old_rng

func _TEST_basic():
	_test_case("basic")
	_check_equal("blabla1", _engine.get_current_question_id())
	_check_equal(3, _engine.get_character_names().size())
	_check_equal(3, _engine.get_metric_names().size())
	
	var question = _engine.get_question("blabla1")
	_check_equal(true, question.in_random_pool)
	_check_equal("santa", question.character)
	
	var metrics_1 = question.choices[0].get_affected_metrics()
	_check_equal(2, metrics_1.size())
	_check_equal("fun", metrics_1[0])
	_check_equal("police", metrics_1[1])

	var metrics_2 = question.choices[1].get_affected_metrics()
	_check_equal(2, metrics_2.size())
	_check_equal("fun", metrics_2[0])
	_check_equal("money", metrics_2[1])
	_end_test()

func _TEST_next_selection():
	_test_case("next_selection")
	_check_equal("test-1", _engine.get_current_question_id())
	
	_rng.setup(0.5)
	_engine.make_choice(0)
	_check_equal("test-2", _engine.get_current_question_id())
	_check_equal(false, _engine.is_game_over())
	
	_reset()
	_rng.setup(0.7)
	_engine.make_choice(0)
	_check_equal("test-3", _engine.get_current_question_id())
	_check_equal(false, _engine.is_game_over())

	_reset()
	_rng.setup(0.8)
	_engine.make_choice(0)
	_check_equal("test-4", _engine.get_current_question_id())
	_check_equal(false, _engine.is_game_over())
	_end_test()

func _TEST_action_1():
	_test_case("action_1")
	
	_engine.make_choice(1)
	_check_equal("test-2", _engine.get_current_question_id())
	_check_equal(false, _engine.is_game_over())
	_check_equal(60, _engine.get_metric("money").value)
	
	_reset()
	_engine.make_choice(0)
	_check_equal("test-1", _engine.get_current_question_id())
	_check_equal(true, _engine.is_game_over())
	_check_equal(50, _engine.get_metric("money").value)
	_end_test()

func _TEST_action_2():
	_test_case("action_2")
	
	_engine.make_choice(1)
	_check_equal("test-2", _engine.get_current_question_id())
	_check_equal(false, _engine.is_game_over())
	_check_equal(40, _engine.get_metric("money").value)
	var messages = _engine.get_latest_messages()
	_check_equal(1, messages.size())
	_check_equal("You lost money.", messages[0])

	_reset()
	_engine.make_choice(0)
	_check_equal("test-2", _engine.get_current_question_id())
	_check_equal(false, _engine.is_game_over())
	_check_equal(35, _engine.get_metric("money").value)
	var tokens = _engine.get_present_tokens()
	_check_equal(1, tokens.size())
	_check_equal("token-1", tokens[0])
	_end_test()

func _TEST_action_3():
	_test_case("action_3")
	
	_engine.make_choice(0)
	_check_equal("test-2", _engine.get_current_question_id())
	_check_equal(false, _engine.is_game_over())
	var tokens = _engine.get_present_tokens()
	_check_equal(1, tokens.size())
	_check_equal("token-1", tokens[0])
	
	_engine.make_choice(0)
	_check_equal("test-1", _engine.get_current_question_id())
	_check_equal(false, _engine.is_game_over())
	tokens = _engine.get_present_tokens()
	_check_equal(0, tokens.size())
	_end_test()

func _TEST_condition_1():
	_test_case("condition_1")
	
	_engine.make_choice(0)
	_check_equal("test-3", _engine.get_current_question_id())	
	_check_equal(false, _engine.is_game_over())
	_end_test()

func _TEST_condition_2():
	_test_case("condition_2")
	
	_engine.make_choice(0)
	_check_equal("test-3", _engine.get_current_question_id())	
	_check_equal(false, _engine.is_game_over())
	_end_test()

func _TEST_condition_3():
	_test_case("condition_3")
	
	_engine.make_choice(0)
	_check_equal("test-3", _engine.get_current_question_id())	
	_check_equal(false, _engine.is_game_over())
	_end_test()

func _TEST_metric_min():
	_test_case("metric_min")
	
	_engine.make_choice(0)
	_check_equal(true, _engine.is_game_over())
	var messages = _engine.get_latest_messages()
	_check_equal(1, messages.size())
	_check_equal("You're broke.", messages[0])
	_end_test()

func _TEST_metric_max():
	_test_case("metric_max")
	
	_engine.make_choice(0)
	_check_equal(true, _engine.is_game_over())
	var messages = _engine.get_latest_messages()
	_check_equal(1, messages.size())
	_check_equal("You skipped town with all the cash. Party over.", messages[0])
	_end_test()

# Test that we don't execute min/max-actions multiple times
func _TEST_metric_loop():
	_test_case("metric_loop")
	
	_check_equal("test-1", _engine.get_current_question_id())	
	_engine.make_choice(0)
	_check_equal(false, _engine.is_game_over())
	var messages = _engine.get_latest_messages()
	_check_equal(1, messages.size())
	_check_equal("You skipped town with all the cash.", messages[0])
	
	_check_equal("test-2", _engine.get_current_question_id())
	_engine.make_choice(0)
	_check_equal(false, _engine.is_game_over())
	messages = _engine.get_latest_messages()
	_check_equal(1, messages.size())
	_check_equal("You're broke.", messages[0])
	
	_check_equal("test-1", _engine.get_current_question_id())	
	_engine.make_choice(0)
	_check_equal(false, _engine.is_game_over())
	messages = _engine.get_latest_messages()
	_check_equal(1, messages.size())
	_check_equal("You skipped town with all the cash.", messages[0])

	_end_test()

func _TEST_next_selection_conditions():
	_test_case("next_selection_conditions")
	_check_equal("test-1", _engine.get_current_question_id())
	
	_rng.setup(0.25)
	_engine.make_choice(0)
	_check_equal("test-3", _engine.get_current_question_id())
	_check_equal(false, _engine.is_game_over())
	
	_reset()
	_rng.setup(0.7)
	_engine.make_choice(0)
	_check_equal("test-4", _engine.get_current_question_id())
	_check_equal(false, _engine.is_game_over())

	_end_test()

func _TEST_pool_selection_conditions():
	_test_case("pool_selection_conditions")
	_check_equal("test-1", _engine.get_current_question_id())
	
	_engine.make_choice(0)
	_check_equal("test-2", _engine.get_current_question_id())
	_check_equal(false, _engine.is_game_over())
	
	_end_test()

func _TEST_in_random_pool():
	_test_case("in_random_pool")
	_check_equal("test-1", _engine.get_current_question_id())
	
	_engine.make_choice(0)
	_check_equal("test-2", _engine.get_current_question_id())
	_check_equal(false, _engine.is_game_over())
	
	_end_test()

func _test_case(test_name):
	_current_test = test_name
	_fail = false
	_reset()

func _reset():
	var content = \
		Utils.read_content("res://resources/tests/%s.tres" % _current_test)
	var jsonResult = JSON.parse(content)
	_engine = QuestionEngine.new(jsonResult.result)

func _check_equal(expected, actual):
	if expected != actual:
		var message = \
			"Expected '%s' but got '%s'" % [ str(expected), str(actual) ]
		_failures.append([_current_test, message])
		_fail = true

func _process_results():
	if _failures.size() > 0:
		for failure in _failures:
			print(failure[0] + ": " + failure[1])
		print("PASS: %d FAIL %d TOTAL %d" % [_passed, _failed, _passed + _failed])
	else:
		print("PASS: %d FAIL %d TOTAL %d" % [_passed, _failed, _passed + _failed])
		print("ALL GOOD!")

func _end_test():
	if _fail:
		_failed += 1
	else:
		_passed += 1
