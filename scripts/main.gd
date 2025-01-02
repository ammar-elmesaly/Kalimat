extends Control

@onready var empty = preload("res://resources/empty_slot.png")
@onready var misplaced = preload("res://resources/misplaced_slot.png")
@onready var right = preload("res://resources/right_slot.png")
@onready var selected = preload("res://resources/selected_slot.png")
@onready var wrong = preload("res://resources/wrong_slot.png")
const WORD_LENGTH : int = 5
const ALPHABET_LETTER_NUMBER : int = 30

var row : int = 0
var col : int = 0
var word : String = "طاووس"
var guessedWordArray = ["", "", "", "", ""]
var statusArray = Array()

func _ready() -> void:
	statusArray.resize(ALPHABET_LETTER_NUMBER)  # This sets the array for keeping keyboard buttons status
	statusArray.fill("empty")					# (Yellow, Green, Dark Gray)
	get_node("words/rows").get_child(row).get_child(col).get_node("Slot").texture = selected
	for i in range(30):
		var key = get_node("keyboard/GridContainer/key_" + str(i))
		key.pressed.connect(_on_key_pressed.bind(key.text))  # This sets the buttons for listenting and binds the text as an argument

func _on_key_pressed(letter : String) -> void:
	var slot = get_node("words/rows").get_child(row).get_child(col)
	slot.get_node("Label").text = letter
	slot.get_node("Slot").texture = empty
	guessedWordArray[col] = letter
	if (col != WORD_LENGTH - 1):
		col += 1
	slot = get_node("words/rows").get_child(row).get_child(col)
	slot.get_node("Slot").texture = selected


func _on_check_pressed() -> void:
	
	const alphabet = "ابتثجحخدذرزسشصضطظعغفقكلمنهويةء"
	var wordArray = word.split("")
	
	for i in range(WORD_LENGTH):
		# Set a new style box for each letter in the keyboard instead of them sharing the same 
		# Stylebox
		var styleBox = StyleBoxTexture.new()
		styleBox.texture_margin_left = 20  # set texture margin for new style box
		styleBox.texture_margin_right = 20
		
		# the sprite of the letter slot (in the words grid)
		var slotSprite = get_node("words/rows").get_child(row).get_child(i).get_node("Slot")
		var alphabetIndex : int = alphabet.find(guessedWordArray[i])  # index of the letter in Arabic Alphabet
		
		var charIndexInAnswer : int = wordArray.find(guessedWordArray[i], i)  # if letter found in word it stores its index in the answer word
		var charIndexInGuessedWord : int = guessedWordArray.find(guessedWordArray[i], i+1)
		if (charIndexInGuessedWord != -1 or charIndexInAnswer == -1) and i != charIndexInAnswer:
			slotSprite.texture = wrong
			setStatus(styleBox, alphabetIndex, "wrong")
			
		elif i == charIndexInAnswer:
				slotSprite.texture = right
				setStatus(styleBox, alphabetIndex, "right")
		else:
			slotSprite.texture = misplaced
			setStatus(styleBox, alphabetIndex, "misplaced")
			
		# The keyboard key node
		var keyboardKey = get_node("keyboard/GridContainer").get_child(alphabetIndex)
		
		keyboardKey.add_theme_stylebox_override("normal", styleBox)
		keyboardKey.add_theme_stylebox_override("pressed", styleBox)
		keyboardKey.add_theme_stylebox_override("hover", styleBox)
		
	if ("".join(guessedWordArray) == word):
		print("You win!")
		return
	
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

func setStatus(styleBox : StyleBoxTexture, index : int, status : String) -> void:
	if status == "right":
		statusArray[index] = "right"
	elif status == "misplaced" and statusArray[index] != "right":
		statusArray[index] = "misplaced"
	elif status == "wrong" and statusArray[index] != "right" and statusArray[index] != "misplaced":
		statusArray[index] = "wrong"
	
	if statusArray[index] == "right":
		styleBox.texture = right
	elif statusArray[index] == "misplaced":
		styleBox.texture = misplaced
	elif statusArray[index] == "wrong":
		styleBox.texture = wrong
	else:
		styleBox.texture = empty
