extends Control

@onready var empty = preload("res://resources/empty_slot.png")
@onready var misplaced = preload("res://resources/misplaced_slot.png")
@onready var right = preload("res://resources/right_slot.png")
@onready var selected = preload("res://resources/selected_slot.png")
@onready var wrong = preload("res://resources/wrong_slot.png")
@onready var volumeOff = preload("res://resources/volume-mute.svg")
@onready var volumeUp = preload("res://resources/volume-up.svg")

@onready var statusDict = {
	"empty" : empty,
	"misplaced" : misplaced,
	"right" : right,
	"wrong" : wrong
}

const WORD_LENGTH : int = 5
const ALPHABET_LETTER_NUMBER : int = 30

var row : int = 0
var col : int = 0
var answer : String
var guessedWordArray : Array[String] = ["", "", "", "", ""]
var statusArray = Array()

var input_blocked : bool = false
var muted : bool = false
var paused : bool = false

var dictionarySet : Dictionary

func _ready() -> void:
	dictionarySet = loadDictionary()
	answer = randomWord(dictionarySet)
	statusArray.resize(ALPHABET_LETTER_NUMBER)  # This sets the array for keeping keyboard buttons status
	statusArray.fill("empty")					# (Yellow, Green, Dark Gray)
	get_node("game/words/rows").get_child(row).get_child(col).get_node("Slot").texture = selected
	for i in range(30):
		var key = get_node("game/keyboard/GridContainer/key_" + str(i))
		key.pressed.connect(_on_key_pressed.bind(key.text))  # This sets the buttons for listenting and binds the text as an argument

func _on_key_pressed(letter : String) -> void:
	if input_blocked:
		return
	var slot = get_node("game/words/rows").get_child(row).get_child(col)
	slot.get_node("Label").text = letter
	slot.get_node("Slot").texture = empty
	guessedWordArray[col] = letter
	if (col != WORD_LENGTH - 1):
		col += 1
	slot = get_node("game/words/rows").get_child(row).get_child(col)
	slot.get_node("Slot").texture = selected
	# play click sound
	if !muted: get_node("game/sfx/click").play()

func _on_check_pressed() -> void:
	if input_blocked:
		return
	input_blocked = true
	const alphabet : String = "ابتثجحخدذرزسشصضطظعغفقكلمنهويةء"
	var answerArray = answer.split("")
	var guessedWord : String = ''.join(guessedWordArray)
	# if a new dictionary is found, add this condition to the if-condition below:
	# or !dictionarySet.has(guessedWord)
	if len(guessedWord) != 5:
		input_blocked = false
		return
		
	for i in range(WORD_LENGTH):
		await get_tree().create_timer(0.5).timeout  # time delay between each iteration
		# Set a new style box for each letter in the keyboard instead of them sharing the same 
		# Stylebox
		var styleBox = StyleBoxTexture.new()
		styleBox.texture_margin_left = 20  # set texture margin for new style box
		styleBox.texture_margin_right = 20
		
		# the sprite of the letter slot (in the words grid)
		var slotSprite = get_node("game/words/rows").get_child(row).get_child(i).get_node("Slot")
		var alphabetIndex : int = alphabet.find(guessedWordArray[i])  # index of the letter in Arabic Alphabet
		
		var charIndexInAnswer : int = answerArray.find(guessedWordArray[i], 0)  # if letter found in word it stores its index in the answer word
		# this condition is the core logic of the game
		if guessedWordArray.slice(i).count(guessedWordArray[i]) > answerArray.count(guessedWordArray[i]) and i != charIndexInAnswer:
			slotSprite.texture = wrong
			setStatus(styleBox, alphabetIndex, "wrong")
			if !muted: get_node("game/sfx/wrong").play()
			
		elif i == charIndexInAnswer:
				slotSprite.texture = right
				setStatus(styleBox, alphabetIndex, "right")
				answerArray[i] = ""
				if !muted: get_node("game/sfx/right").play()
		else:
			slotSprite.texture = misplaced
			setStatus(styleBox, alphabetIndex, "misplaced")
			if !muted: get_node("game/sfx/wrong").play()
			
		# The keyboard key node
		var keyboardKey = get_node("game/keyboard/GridContainer").get_child(alphabetIndex)
		
		keyboardKey.add_theme_stylebox_override("normal", styleBox)
		keyboardKey.add_theme_stylebox_override("pressed", styleBox)
		keyboardKey.add_theme_stylebox_override("hover", styleBox)
		
		while paused:  # this stops for loop while pausing
			await get_tree().process_frame
		
	if ("".join(guessedWordArray) == answer):
		get_node("win screen").visible = true
		get_node("shader layers/win layer").visible = true
		if !muted: get_node("game/sfx/win").play()
		return
	col = 0
	row += 1
	if row > 5:
		get_node("lose screen/answer").text += answer
		get_node("lose screen").visible = true
		get_node("shader layers/lose layer").visible = true
		return
	var slot = get_node("game/words/rows").get_child(row).get_child(col)
	slot.get_node("Slot").texture = selected
	input_blocked = false
	guessedWordArray = ["", "", "", "", ""]
	
func _on_erase_pressed() -> void:
	if input_blocked:
		return
	var slot = get_node("game/words/rows").get_child(row).get_child(col)
	slot.get_node("Label").text = ""
	slot.get_node("Slot").texture = empty
	guessedWordArray[col] = ""
	if (col != 0):
		col -= 1
	slot = get_node("game/words/rows").get_child(row).get_child(col)
	slot.get_node("Slot").texture = selected

func setStatus(styleBox : StyleBoxTexture, index : int, status : String) -> void:
	if status == "right":
		statusArray[index] = "right"
	elif status == "misplaced" and statusArray[index] != "right":
		statusArray[index] = "misplaced"
	elif status == "wrong" and statusArray[index] != "right" and statusArray[index] != "misplaced":
		statusArray[index] = "wrong"
	
	styleBox.texture = statusDict[statusArray[index]]

func loadDictionary() -> Dictionary:
	var file = FileAccess.open('res://resources/arabic_dict.txt', FileAccess.READ)
	var dict : Dictionary = {}
	if file:
		while !file.eof_reached():
			var word = file.get_line()
			dict[word] = null
	return dict

func randomWord(dict : Dictionary) -> String:
	var dictSize : int = dict.size()
	var randomIndex : int = randi() % dictSize
	var i : int = 0
	for word in dict:
		if i == randomIndex:
			return word
		i += 1
	return ""


func _on_mute_pressed() -> void:
	var styleBox = StyleBoxTexture.new()
	
	if muted == false:
		styleBox.texture = volumeOff
		muted = true
	else:
		styleBox.texture = volumeUp
		muted = false
	
	get_node("game/controls/mute").add_theme_stylebox_override("normal", styleBox)
	get_node("game/controls/mute").add_theme_stylebox_override("pressed", styleBox)
	get_node("game/controls/mute").add_theme_stylebox_override("hover", styleBox)


func _on_pause_pressed() -> void:
	get_node("shader layers/pause layer").visible = true
	get_node("pause menu").visible = true
	paused = true

func _on_unpause_pressed() -> void:
	get_node("shader layers/pause layer").visible = false
	get_node("pause menu").visible = false
	paused = false

func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()
