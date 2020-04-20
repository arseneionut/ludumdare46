
import csv
import json
import yaml

result = {
    "characters": [
        {
            "id": "50cent",
            "name": "50 cent"
        },
        {
            "id": "alien",
            "name": "Alien"
        },
        {
            "id": "astronaut",
            "name": "Astronaut"
        },
        {
            "id": "boomer1",
            "name": "Boomer 1"
        },
        {
            "id": "boomer2",
            "name": "Boomer 2"
        },
        {
            "id": "cena",
            "name": "John Cena"
        },
        {
            "id": "cowboy",
            "name": "Cowboy"
        },
        {
            "id": "deadpool",
            "name": "Deadpool"
        },
        {
            "id": "disco1",
            "name": "Disco 1"
        },
        {
            "id": "disco2",
            "name": "Disco 2"
        },
        {
            "id": "dog",
            "name": "Buddy"
        },
        {
            "id": "dork1",
            "name": "Dork 1"
        },
        {
            "id": "dork2",
            "name": "Dork 2"
        },
        {
            "id": "dude",
            "name": "The Dude"
        },
        {
            "id": "dwight",
            "name": "Dwight"
        },
        {
            "id": "flint",
            "name": "Flint"
        },
        {
            "id": "freddy",
            "name": "Freddy"
        },
        {
            "id": "gabe",
            "name": "Gabe"
        },
        {
            "id": "gothgirl",
            "name": "Goth Girl"
        },
        {
            "id": "jesus",
            "name": "Jesus"
        },
        {
            "id": "karen",
            "name": "Karen"
        },
        {
            "id": "karen2",
            "name": "Karen 2"
        },
        {
            "id": "magician",
            "name": "Magician"
        },
        {
            "id": "marley",
            "name": "Bob Marley"
        },
        {
            "id": "mime",
            "name": "Mime"
        },
        {
            "id": "obama",
            "name": "Barack Obama"
        },
        {
            "id": "partygirl",
            "name": "Party Girl"
        },
        {
            "id": "partygirl2",
            "name": "Party Girl 2"
        },
        {
            "id": "partyguy",
            "name": "Party Guy"
        },
        {
            "id": "police1",
            "name": "Police 1"
        },
        {
            "id": "police2",
            "name": "Police 2"
        },
        {
            "id": "punk1",
            "name": "Punk 1"
        },
        {
            "id": "punk2",
            "name": "Punk 2"
        },
        {
            "id": "r2d2",
            "name": "R2-D2"
        },
        {
            "id": "raveguy",
            "name": "Rave Guy"
        },
        {
            "id": "rickmorty",
            "name": "Rick & Morty"
        },
        {
            "id": "rockstar",
            "name": "Rock Star"
        },
        {
            "id": "samuel",
            "name": "Samuel"
        },
        {
            "id": "santa",
            "name": "Santa Claus"
        },
        {
            "id": "satan",
            "name": "Satan"
        },
        {
            "id": "sheen",
            "name": "Charlie Sheen"
        },
        {
            "id": "skinny",
            "name": "Skinny"
        },
        {
            "id": "snoop",
            "name": "Snoop Dogg"
        },
        {
            "id": "tigerking",
            "name": "Tiger King"
        }
    ],
    "metrics": {
        "drink": {
            "start": 50,
            "min": 0,
            "max": 100,
            "min-action": [
                "message @No booze... Your milkshake chased everybody out the yard.",
                "game over"
            ],
            "max-action": [
                "message @Everyone's wasted man, that 27th shot was too much.",
                "game over"
            ]
        },
        "hype": {
            "start": 50,
            "min": 0,
            "max": 100,
            "min-action": [
                "message @Snoop Lion rated the party  -4/20. You wear a bag over your face now.",
                "game over"
            ],
            "max-action": [
                "message @That last image literally broke the internet. You are literally the last meme.",
                "game over"
            ]
        },
        "madness": {
            "start": 50,
            "min": 0,
            "max": 100,
            "min-action": [
                "message @BOOOOrrring. Straight up snoozefes bro. Just go to bed.",
                "game over"
            ],
            "max-action": [
                "message @This party is the bomb! Popo shutting the whole thing down.",
                "game over"
            ]
        },
    },
    "start-question": "question_0",
    "questions": {}
}

def normalize(v):
    v = v.strip()
    if v == "":
        return "0"
    else:
        return v

def character_present(char_id):
    if char_id == "n/a":
        return True
    for char in result["characters"]:
        if char["id"] == char_id:
            return True
    return False

def make_question(row):
    new_row = {}
    for k in row.keys():
        new_row[k.lower()] = row[k]
    row = new_row
    if row["y_message"].strip() == "":
        print("question '%s': empty y_message" % row["name"])
    if row["n_message"].strip() == "":
        print("question '%s': empty n_message" % row["name"])
    char = row["char"].strip()
    if not character_present(char):
        print("question '%s': character '%s' not found" % (row["name"], char))
    question = {
        "id": row["name"],
        "character": char,
        "text": row["txt"],
        "choices": [
            {
                "text": "yes",
                "actions": [
                    "message " + row["y_message"],
                    "drink += " + normalize(row["y_drinks"]),
                    "hype += " + normalize(row["y_hype"]),
                    "madness += " + normalize(row["y_madness"]),
                ]
            },
            {
                "text": "no",
                "actions": [
                    "message " + row["n_message"],
                    "drink += " + normalize(row["n_drinks"]),
                    "hype += " + normalize(row["n_hype"]),
                    "madness += " + normalize(row["n_madness"]),
                ]
            }
        ]
    }
    if question["id"] == "question_0":
        question["conditions"] = [
            "tutorial absent"
        ]
        question["choices"][0]["actions"].append("add tutorial")
        question["choices"].pop()
    return question

with open("leo.csv") as csv_file:
    csv_reader = csv.DictReader(csv_file)
    for row in csv_reader:
        txt = row["txt"].strip()
        if txt != "":
            result["questions"][row["name"]] = make_question(row)

def spit(file_name, content):
    with open(file_name, "w") as f:
        f.write(content)

spit("leo.json", json.dumps(result, indent=2))
spit("leo.yml", yaml.dump(result))
