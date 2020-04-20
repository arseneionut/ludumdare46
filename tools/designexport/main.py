import argparse
import yaml
import os
import json
import random
import datetime


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
    OVER = "game-over"
    MESSAGE = "message"
    ADD_TOKEN = "add-token"
    REMOVE_TOKEN = "remove-token"
    GAME_OVER = "game-over"

    SYMBOL_TO_TYPE_MAP = \
        {
            "+=": ADD,
            "-=": SUBTRACT,
            "=": SET,
            "add": ADD,
            "remove": REMOVE_TOKEN,
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
    def __init__(self, name, json_question_data):
        self.name = name
        self.conditions = []
        self.text = Utils.get_key_with_debug(json_question_data, 'text')
        self.choices = []
        self.next = []
        self.character = Utils.get_key_with_debug(json_question_data, 'character')
        if 'in-random-pool' in json_question_data:
            self.in_random_pool = Utils.get_key_with_debug(json_question_data, 'in-random-pool')

        if 'conditions' in json_question_data:
            if (Utils.get_key_with_debug(json_question_data, 'conditions') is not None):
                for condition in Utils.get_key_with_debug(json_question_data, 'conditions'):
                    self.conditions.append(Condition(condition))

        for choice in Utils.get_key_with_debug(json_question_data, 'choices'):
            self.choices.append(Choice(choice))

        if len(json_question_data['choices']) != 2:
            print("Question {} has wrong number of choices".format(self.name))

        if 'next' in json_question_data:
            for chance in Utils.get_key_with_debug(json_question_data, 'next'):
                self.next.append(Chance(chance))


class Character:
    def __init__(self, json_character_data):
        self.id = Utils.get_key_with_debug(json_character_data, 'id')
        self.name = Utils.get_key_with_debug(json_character_data, 'name')


class Chance:
    def __init__(self, json_chance_data):
        string_items = json_chance_data.split(' ')

        if int(json_chance_data) == 0:
            return
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
        if string_items[0].strip() == 'message':
            self.value = json_action_data
            self.key = None
            self.action_type = ActionType.MESSAGE
            return
        if json_action_data == 'game over':
            self.value = json_action_data
            self.key = None
            self.action_type = ActionType.GAME_OVER
            return

        if len(string_items) == 3:
            self.action_type = ActionType.get_action_type(string_items[1].strip())
            self.key = string_items[0].strip()
            self.value = int(string_items[2].strip())
        elif len(string_items) == 2:
            self.action_type = ActionType.get_action_type(string_items[0].strip())
            self.key = None
            self.value = string_items[1].strip()


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

    def get_questions_by_metrics(self, drink, hype, madness, tokens):
        questions_list = {}
        for question_id, question_data in self._processed_data[YMLNodes.QUESTIONS].items():
            if (len(question_data.conditions) == 0 or bool(question_data.in_random_pool)):
                questions_list[question_id] = question_data

            for condition in question_data.conditions:
                if condition.name == 'drink':
                    if not self.compare(drink, condition.value, condition.sign):
                        break
                if condition.name == 'hype':
                    if not self.compare(hype, condition.value, condition.sign):
                        break
                if condition.name == 'madness':
                    if not self.compare(madness, condition.value, condition.sign):
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
        return questions_list

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

        self.tokens = []

        self.drink = 50
        self.hype = 50
        self.madness = 50

        self.current_question = self.validator._processed_data[YMLNodes.QUESTIONS][
            self.validator._processed_data[YMLNodes.START_QUESTION]]
        self.is_game_ended = False;

        self.selected_questions = {k: 0 for k, v in self.validator._processed_data[YMLNodes.QUESTIONS].items()}

        self.game_ended_by_type = {
            'madness': 0,
            'hype': 0,
            'drink': 0
        }
        for play_session in range(0, 1000):
            self.simulate()
            self.current_question = self.validator._processed_data[YMLNodes.QUESTIONS][
                self.validator._processed_data[YMLNodes.START_QUESTION]]

            self.is_game_ended = False

        for k, v in self.selected_questions.items():
            print("{} = {}".format(k, v))
        for k, v in self.game_ended_by_type.items():
            print("{} = {}".format(k, v))

    def simulate(self):
        self.drink = 50
        self.hype = 50
        self.madness = 50
        self.selected_questions[self.validator._processed_data[YMLNodes.START_QUESTION]] += 1
        while not self.is_game_ended:
            # print("----------------------------------------------\n"
            #       "DRINKS = {}".format(self.drink),
            #       "HYPE = {}".format(self.hype),
            #       "MADNESS = {} \n".format(self.madness),
            #       "----------------------------------------------\n")
            random.seed(datetime.datetime.now().timestamp())

            choice = random.randint(0, 1)

            for action in self.current_question.choices[choice].actions:
                if action.action_type == ActionType.ADD_TOKEN:
                    self.tokens.append(action.value)
                elif action.action_type == ActionType.REMOVE_TOKEN:
                    self.tokens.remove(action.value)
                elif action.key == 'drink':
                    self.drink = self.do_operation(self.drink, action.value, action.action_type)
                elif action.key == 'hype':
                    self.hype = self.do_operation(self.hype, action.value, action.action_type)
                elif action.key == 'madness':
                    self.madness = self.do_operation(self.madness, action.value, action.action_type)
                elif action.action_type == ActionType.GAME_OVER:
                    self.is_game_ended = True

            if self.drink <= 0 or self.drink >= 100:
                self.is_game_ended = True
                self.game_ended_by_type['drink'] += 1
                return

            if self.madness >= 100 or self.madness <= 0:
                self.is_game_ended = True
                self.game_ended_by_type['madness'] += 1
                return

            if self.hype <= 0 or self.hype >= 100:
                self.is_game_ended = True
                self.game_ended_by_type['hype'] += 1
                return

            self.select_next_question()

    def select_next_question(self):
        question_pool = self.validator.get_questions_by_metrics(self.drink, self.hype, self.madness, self.tokens)

        real_chance_list = {}
        total_option_percentage = 0;

        if len(self.current_question.next) == 0:
            for question_id in question_pool.keys():
                real_chance_list[question_id] = 1 / len(question_pool)
                total_option_percentage += 1 / len(question_pool)
        for chance in self.current_question.next:
            if chance.next_question in question_pool:
                real_chance_list[chance.next_question] = chance.percentage
                total_option_percentage += chance.percentage

        # print("----------------------------------------------\n"
        #       "THIS IS THE QUESTION POOL FOR THE NEXT QUESTION\n"
        #       "{}\n".format(question_pool),
        #       "THIS IS THE FINAL CHANCES LIST\n"
        #       "{}\n".format(real_chance_list),
        #       "----------------------------------------------\n")
        random.seed(datetime.datetime.now().timestamp())
        chance = random.randint(0, 101) / 100.0

        # print("Random chance is {}".format(chance))

        if chance >= total_option_percentage:
            random.seed(datetime.datetime.now().timestamp())
            keys_view = real_chance_list.keys()
            key_iterator = iter(keys_view)
            selected_key = ""
            selected_random_key = random.randint(1, len(question_pool))
            for i in range(0, selected_random_key):
                selected_key = next(key_iterator)
            self.current_question = question_pool[selected_key]
            self.selected_questions[selected_key] += 1
        else:
            real_chance_list = {k: v for k, v in sorted(real_chance_list.items(), key=lambda item: item[1])}
            values_view = real_chance_list.values()
            value_iterator = iter(values_view)
            first_value = next(value_iterator)
            prev_kev_item = first_value
            for k, v in real_chance_list.items():
                if prev_kev_item <= chance and chance <= (prev_kev_item + v):
                    self.current_question = question_pool[k]
                    self.selected_questions[k] += 1
                    # print("Question {} was selected".format(k))
                prev_kev_item += v

    @staticmethod
    def do_operation(a, b, operation):
        if operation == ActionType.ADD:
            return a + b
        elif operation == ActionType.SUBTRACT:
            return a - b
        elif operation == ActionType.SET:
            return b


def main(ymlpath, jsonpath, test_cards):
    print(os.path.abspath(ymlpath))
    f = open(os.path.abspath(ymlpath), "r")
    document = f.read()
    json_data = yaml.load(document, Loader=yaml.FullLoader)
    f.close()

    validator = Validator(json_data)
    TestCards(validator).simulate()

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
