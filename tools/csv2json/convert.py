
import csv
import json
import yaml

result = {
    "characters": [
        {
            "id": "santa",
            "name": "Santa Klaus"
        },
        {
            "id": "r2d2",
            "name": "R2-D2"
        },
        {
            "id": "50cent",
            "name": "50 cent"
        }
    ],
    "metrics": {
        "drink": {
            "start": 50,
            "min": 0,
            "max": 100,
            "min-action": [
                "message No booze... Your milkshake chased everybody out the yard.",
                "game over"
            ],
            "max-action": [
                "message Everyone's wasted man, that 27th shot was too much.",
                "game over"
            ]
        },
        "hype": {
            "start": 50,
            "min": 0,
            "max": 100,
            "min-action": [
                "message Snoop Lion rated the party  -4/20. You wear a bag over your face now.",
                "game over"
            ],
            "max-action": [
                "message That last image literally broke the internet. You are literally the last meme.",
                "game over"
            ]
        },
        "madness": {
            "start": 50,
            "min": 0,
            "max": 100,
            "min-action": [
                "message BOOOOrrring. Straight up snoozefes bro. Just go to bed.",
                "game over"
            ],
            "max-action": [
                "message This party is the bomb! Popo shutting the whole thing down.",
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

def make_question(row):
    new_row = {}
    for k in row.keys():
        new_row[k.lower()] = row[k]
    row = new_row
    question = {
        "id": row["name"],
        "character": row["char"],
        "text": row["txt"],
        "choices": [
            {
                "text": "yes",
                "actions": [
                    "message " + row["y_message"],
                    "drink += " + normalize(row["y_drink"]),
                    "hype += " + normalize(row["y_hype"]),
                    "madness += " + normalize(row["y_madness"]),
                ]
            },
            {
                "text": "no",
                "actions": [
                    "message " + row["n_message"],
                    "drink += " + normalize(row["n_drink"]),
                    "hype += " + normalize(row["n_hype"]),
                    "madness += " + normalize(row["n_madness"]),
                ]
            }
        ]
    }

    return question

with open("leo.csv") as csv_file:
    csv_reader = csv.DictReader(csv_file)
    for row in csv_reader:
        txt = row["txt"].strip()
        if txt != "":
            result["questions"][row["name"]] = make_question(row)
            print(row["txt"])

def spit(file_name, content):
    with open(file_name, "w") as f:
        f.write(content)

spit("leo.json", json.dumps(result, indent=2))
spit("leo.yml", yaml.dump(result))
