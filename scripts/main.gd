extends Control

var row = 0
var col = 0
var word = "مقاتل"
var guessed_word = ["", "", "", "", ""]

func _ready() -> void:
	for i in range(28):
		var key = get_node("keyboard/GridContainer/key_" + str(i))
		key.pressed.connect(_on_key_pressed.bind(key.text))
func _process(delta: float) -> void:
	pass


func _on_key_pressed(letter : String) -> void:
	col %= 5
	get_node("words/rows").get_child(row).get_child(col).get_node("Label").text = letter
	guessed_word[col] = letter
	col += 1


func _on_check_pressed() -> void:
	if ("".join(guessed_word) == word):
		print("You win!")
	else:
		row += 1
		col = 0
		print("Wrong guess")
		if row > 5:
			print("You Lose")
