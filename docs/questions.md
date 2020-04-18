# Format description for questions

We can have multiple files, they are read and the content is merged.

Files are using the YAML format.

## Top Level Fields

### `metrics`

Describes the metrics found in the game. Dictionary with an entry for each
metric. Example:

```
metrics:
  fun:
    start: 50
    min: 0
    max: 100
    min_action:
      - game over
    max_action:
      - add token2
      - fun = 50
      - police += 10
```

Subkeys:

 * `start`: value at the start of the game,
 * `min`: minimum threshold for the value,
 * `max`: maximum threshold for the value,
 * `min-action`: sequence of actions to perform when the minimim level is reached and
 * `max-action`: sequence of actions to perform when the maximum level is reached.

See the section on actions for the list of possible actions.

### `start-question`

String value, the ID of the question that starts the game.

### `questions`

Dictionary of questions, each entry is a the question ID and the values are
question definitions. Example:

```
questions:
  blabla1:
    conditions:
      - police > 80
      - fun > 60
      - token1 present
      - token2 absent
    text: >-
      Some dude wants in. Seems to be nice, but a little high. Do you let him
      in?
    yes:
      - fun += 15
      - police += 10
      - money -= 5
      - add token1
      - remove token2
      - >- 
        message This guy stirred up fun conversations and he seems to be 
        very popular. Noise levels are also higher.
    no:
      - fun -= 10
      - police -= 5
      - money -= 5
      - >-
        message People are not very happy with how you handled this person.
        He seemed nice.
    next:
      - 50% -> blabla2
      - 25% -> blabla3
```

Subkeys: 

 * `conditions`: list of conditions that need to be all true for the question to be
   selected by the engine (see the section about conditions for possible conditions),
 * `text`: text of the question,
 * `yes`: list of actions to be performed if the player chooses `yes`,
 * `no`: list of actions to be performed if the player chooses `no` and
 * `next`: list of next questions, with probabilities.

See the corresponding sections in this documents for possible actions and conditions.

For `next` questions, if the sum of percentages is not 100%, then for the remaining
percents a random question from the pool of valid questions is picked. Valid questions -
questions for which the conditions are true when the evaluation is made. For the questions
with specified probabilities, i.e. `50% -> blabla2`, the conditions are also checked. If a
question does not meet the conditions, it is removed from the list.

For instance, given:

```
    next:
      - 50% -> blabla2
      - 25% -> blabla3
```

if `blabla3` does not meet the conditions, then the list becomes:

```
    next:
      - 50% -> blabla2
```

Meaning there are 50-50 chances to pick `blabla2` or any question from the pool
of valid questions.

## Actions

Actions can be one of:

### `<metric> = <value>`

Set a metric to a given value.

### `<metric> += <value>`

Adds a value to a specific metric.

### `<metric> -= <value>`

Subtracts a value from a specific metric.

### `add <token>`

Adds token to the game. Tokens are booleans, they are either present or absent.
Adding a token that's already present does nothing.

### `remove <token>`

Removes a token from the game. Tokens are booleans, they are either present or absent.
Removing an absent token does nothing.

### `game over`

Finishes the game.

### `message <message text>`

Displays the message on the game interface.

## Conditions

Conditions can be one of:

### `<metric> <operator> <value>`

True if the condition is true. Valid operators `<`, `<=`, `=`, `>=`, `>`.

### `<token> absent` or `<token> present`

True if the token is absent or present, respectively.
