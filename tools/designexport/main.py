import argparse
import yaml
import os
import json


class Utils:
    @staticmethod
    def get_key_with_debug(dictionary, key):
        if key not in dictionary:
            print("Key {} could not be found in {}".format(key, dictionary))
            return "0"  # this is so that it does not stop
        return dictionary[key]


class ActionType:
    ADD = "add"
    SUBTRACT = "subtract"
    SET = "set"
    REMOVE = "remove"
    OVER = "over"

    SYMBOL_TO_TYPE_MAP = \
        {
            "+=": ADD,
            "-=": SUBTRACT,
            "=": SET,
            "add": ADD,
            "remove": REMOVE,
            "game": OVER
        }

    @staticmethod
    def get_action_type(type_symbol):
        return Utils.get_key_with_debug(ActionType.SYMBOL_TO_TYPE_MAP, type_symbol)


class ConditionTypes:
    METRIC = 'metric'
    TOKEN = 'token'


class ConditionSigns:
    GREATER_THAN = ">"
    LESSER_THAN = "<"
    EQUAL = "="
    GREATER_OR_EQUAL = ">="
    LESSER_OR_EQUAL = "<="


class YMLNodes:
    METRICS = "metrics"
    START_QUESTION = "start-question"
    QUESTIONS = "questions"
    CHARACTERS = "characters"


class Question:
    def __init__(self,name, json_question_data):
        self.name = name
        self.conditions = []
        self.text = Utils.get_key_with_debug(json_question_data, 'text')
        self.choices = []
        self.next = []
        self.character = Utils.get_key_with_debug(json_question_data, 'character')
        self.in_random_pool = Utils.get_key_with_debug(json_question_data, 'in-random-pool')
        if(Utils.get_key_with_debug(json_question_data, 'conditions') is not None):
            for condition in Utils.get_key_with_debug(json_question_data, 'conditions'):
                self.conditions.append(Condition(condition))

        for choice in Utils.get_key_with_debug(json_question_data, 'choices'):
            self.choices.append(Choice(choice))

        if len(json_question_data['choices']) != 2:
            print("Question {} has wrong number of choices".format(self.name))

        for chance in Utils.get_key_with_debug(json_question_data, 'next'):
            self.next.append(Chance(chance))


class Character:
    def __init__ (self, json_character_data):
        self.id = Utils.get_key_with_debug(json_character_data, 'id')
        self.name = Utils.get_key_with_debug(json_character_data, 'name')


class Chance:
    def __init__(self, json_chance_data):
        string_items = json_chance_data.split(' ')

        if len(string_items) == 3:
            self.percentage = int(string_items[0].strip()[:-1]) / 100.0
            self.next_question = string_items[2].strip()

            if self.percentage > 1:
                print("Percentace is above 100% for the {} next question chance".format(self.next_question))
            elif self.percentage < 0:
                print("Percentage is negative for the {} next question chance".format(self.next_question))
        else:
            print("Chance is fucked up: {}".format(json_chance_data))


class Condition:
    def __init__(self, json_choice_data):
        string_items = json_choice_data.split(' ')

        if len(string_items) == 3:
            self.type = ConditionTypes.METRIC
            self.name = string_items[0].strip()
            self.sign = string_items[1].strip()
            self.value = string_items[2].strip()

        elif len(string_items) == 2:
            self.type = ConditionTypes.TOKEN
            self.name = string_items[0].strip()
            self.token_presence = True if string_items[0].strip() == 'present' else False
            self.sign = None
            self.value = None


class Choice:
    def __init__(self, json_data):
        self.text = Utils.get_key_with_debug(json_data, 'text')
        self.actions = self.populate_actions(Utils.get_key_with_debug(json_data, 'actions'))

    @staticmethod
    def populate_actions(actions):
        action_array = []
        for action in actions:
            action_array.append(Action(action))
        return action_array


class Action:
    def __init__(self, json_action_data):
        string_items = json_action_data.split(' ')

        if len(string_items) == 3:
            if string_items[0].strip() != 'message':
                self.action_type = ActionType.get_action_type(string_items[1].strip())
                self.key = string_items[0].strip()
                self.value = int(string_items[2].strip())
            else:
                self.value = json_action_data

        elif len(string_items) == 2:
            self.action_type = ActionType.get_action_type(string_items[0].strip())
            self.key = None
            self.value = string_items[1].strip()

        else:
            self.value = json_action_data


class Metric:
    def __init__(self, name, json_data):
        self.name = name
        self.start = Utils.get_key_with_debug(json_data, "start")
        self.min = Utils.get_key_with_debug(json_data, "min")
        self.max = Utils.get_key_with_debug(json_data, "max")
        self.min_actions = self.populate_actions(Utils.get_key_with_debug(json_data, "min-action"))
        self.max_actions = self.populate_actions(Utils.get_key_with_debug(json_data, "max-action"))

    @staticmethod
    def populate_actions(actions):
        action_array = []
        for action in actions:
            action_array.append(Action(action))
        return action_array


class Validator:
    def __init__(self, json_data):
        self._data = json_data
        self._processed_data = {}
        self.process_data()

    def process_data(self):
        for node, node_data in self._data.items():
            if node == YMLNodes.METRICS:
                self._processed_data[YMLNodes.METRICS] = []
                for metric_name, metric_data in node_data.items():
                    self._processed_data[YMLNodes.METRICS].append(Metric(metric_name, metric_data))
            elif node == YMLNodes.START_QUESTION:
                self._processed_data[YMLNodes.START_QUESTION] = node_data
            elif node == YMLNodes.QUESTIONS:
                self._processed_data[YMLNodes.QUESTIONS] = {}
                for question_name, question_data in node_data.items():
                    self._processed_data[YMLNodes.QUESTIONS][question_name] = Question(question_name, question_data)
            elif node == YMLNodes.CHARACTERS:
                self._processed_data[YMLNodes.CHARACTERS] = []
                for character in node_data:
                    self._processed_data[YMLNodes.CHARACTERS].append(Character(character))

        print("Question Count: {}".format(len(self._processed_data[YMLNodes.QUESTIONS])))
        print("Metrics Count: {}".format(len(self._processed_data[YMLNodes.METRICS])))

    def get_questions_by_metrics(self, fun, police, tokens):
        questions_list = {}
        for question_id, question_data in self._processed_data[YMLNodes.QUESTIONS].items():
            for condition in question_data.conditions:
                if condition.name == 'fun':
                    if not self.compare(fun, condition.value, condition.sign):
                        break
                if condition.name == 'police':
                    if not self.compare(police, condition.value, condition.sign):
                        break
                if condition.type == ConditionTypes.TOKEN:
                    has_token = False
                    for index in range(0, len(tokens)):
                        if condition.token_presence:
                            if tokens[index] == condition.name:
                                has_token = True;
                            if not has_token and index == len(tokens) - 1:
                                break
                        if not condition.token_presence:
                            if tokens[index] == condition.name:
                                has_token = True
                            if has_token and index == len(tokens) - 1:
                                break
            questions_list[question_id] = question_data

    @staticmethod
    def compare(a, b, sign):
        if sign == ConditionSigns.GREATER_THAN:
            return a > b
        elif sign == ConditionSigns.LESSER_THAN:
            return a < b
        elif sign == ConditionSigns.GREATER_OR_EQUAL:
            return a >= b
        elif sign == ConditionSigns.LESSER_OR_EQUAL:
            return a <= b
        elif sign == ConditionSigns.EQUAL:
            return a == b


class TestCards:
    def __init__(self, validator):
        self.validator = validator

        self.fun = 0
        self.police = 0



def main(ymlpath, jsonpath, test_cards):
    print(os.path.abspath(ymlpath))
    f = open(os.path.abspath(ymlpath), "r")
    document = f.read()
    json_data = yaml.load(document, Loader=yaml.FullLoader)
    f.close()

    Validator(json_data)

    if test_cards:
        print("will pass through all the cards")

    nf = open(os.path.abspath(jsonpath + "\\output.json"), "w+")
    nf.write(json.dumps(json_data))
    nf.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Validate the YAML')
    parser.add_argument('--ymlpath', metavar='ymlpath', required=True,
                        help='the path to the *yml file')
    parser.add_argument('--jsonpath', metavar='jsonpath', required=True,
                        help='the path to export the json to')
    parser.add_argument('--testcards', metavar='testcards', required=False,
                        help='test the cards')
    args = parser.parse_args()

    main(ymlpath=args.ymlpath, jsonpath=args.jsonpath, test_cards=args.testcards)
