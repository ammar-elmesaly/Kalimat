extends Control

@onready var empty = preload("res://resources/empty_slot.png")
@onready var misplaced = preload("res://resources/misplaced_slot.png")
@onready var right = preload("res://resources/right_slot.png")
@onready var selected = preload("res://resources/selected_slot.png")
@onready var wrong = preload("res://resources/wrong_slot.png")
const WORDLENGTH = 5

var row = 0
var col = 0
var word = "طاووس"
var guessedWordArray = ["", "", "", "", ""]

func _ready() -> void:
	get_node("words/rows").get_child(row).get_child(col).get_node("Slot").texture = selected
	for i in range(30):
		var key = get_node("keyboard/GridContainer/key_" + str(i))
		key.pressed.connect(_on_key_pressed.bind(key.text))
func _process(delta: float) -> void:
	pass


func _on_key_pressed(letter : String) -> void:
	var slot = get_node("words/rows").get_child(row).get_child(col)
	slot.get_node("Label").text = letter
	slot.get_node("Slot").texture = empty
	guessedWordArray[col] = letter
	if (col != WORDLENGTH - 1):
		col += 1
	slot = get_node("words/rows").get_child(row).get_child(col)
	slot.get_node("Slot").texture = selected


func _on_check_pressed() -> void:
	var guessedWord = "".join(guessedWordArray)
	const alphabet = "ابتثجحخدذرزسشصضطظعغفقكلمنهوي"
	
	for i in range(WORDLENGTH):
		var slotSprite = get_node("words/rows").get_child(row).get_child(i).get_node("Slot")
		var alphabetIndex = alphabet.find(guessedWordArray[i])
		if word.contains(guessedWordArray[i]):
			if i == word.find(guessedWordArray[i], i):
				slotSprite.texture = right
			else:
				slotSprite.texture = misplaced
		else:
			slotSprite.texture = wrong
	if (guessedWord == word):
		print("You win!")
		
	col = 0
	row += 1
	if row > 5:
		print("you lose")
		return
	var slot = get_node("words/rows").get_child(row).get_child(col)
	slot.get_node("Slot").texture = selected

func _on_erase_pressed() -> void:
	var slot = get_node("words/rows").get_child(row).get_child(col)
	slot.get_node("Label").text = ""
	slot.get_node("Slot").texture = empty
	if (col != 0):
		col -= 1
	slot = get_node("words/rows").get_child(row).get_child(col)
	slot.get_node("Slot").texture = selected
