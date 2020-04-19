extends Node

var _failures = []
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
	
	_process_results()
	Utils.rng = old_rng

func _TEST_basic():
	_test_case("basic")
	_check_equal("blabla1", _engine.get_current_question_id())
	_check_equal(3, _engine.get_character_names().size())
	_check_equal(3, _engine.get_metric_names().size())
	
	_check_equal("santa", _engine.get_question("blabla1").character)

func _TEST_next_selection():
	_test_case("next_selection")
	_check_equal("test-1", _engine.get_current_question_id())
	
	_rng.setup(0.5)
	_engine.make_choice(0)
	_check_equal("test-2", _engine.get_current_question_id())
	
	_reset()
	_rng.setup(0.7)
	_engine.make_choice(0)
	_check_equal("test-3", _engine.get_current_question_id())

	_reset()
	_rng.setup(0.8)
	_engine.make_choice(0)
	_check_equal("test-4", _engine.get_current_question_id())

func _test_case(test_name):
	_current_test = test_name
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

func _process_results():
	if _failures.size() > 0:
		for failure in _failures:
			print(failure[0] + ": " + failure[1])
	else:
		print("ALL GOOD!")
