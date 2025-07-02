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

var dictionaryArray = Array()

func _ready() -> void:
	dictionaryArray = loadDictionary()
	answer = randomWord(dictionaryArray)
	statusArray.resize(ALPHABET_LETTER_NUMBER)  # This sets the array for keeping keyboard buttons status
	# This basically initializes the status of the 30 letters to be empty (the letters you click to choose from)
	# and these letters have 4 states: (Yellow, Green, Dark Gray, Empty)
	statusArray.fill("empty")
	get_slot(row, col).get_node("Slot").texture = selected
	for i in range(30):
		var key = get_keyboard_key(i)
		key.pressed.connect(_on_key_pressed.bind(key.text))  # This sets the buttons for listenting and binds the text as an argument
	
	set_responsive_size()
	
func _on_key_pressed(letter : String) -> void:
	if input_blocked:
		return
	var slot = get_slot(row, col)
	slot.get_node("Label").text = letter
	slot.get_node("Slot").texture = empty
	guessedWordArray[col] = letter
	if (col != WORD_LENGTH - 1):
		col += 1
	slot = get_slot(row, col)
	slot.get_node("Slot").texture = selected
	# play click sound
	if !muted: get_node("sfx/click").play()

func _on_check_pressed() -> void:
	if input_blocked:
		return
	input_blocked = true
	const ALPHABET : String = "ابتثجحخدذرزسشصضطظعغفقكلمنهويةء"
	var answerArray = answer.split("")
	var guessedWord : String = ''.join(guessedWordArray)
	# if a new dictionary is found, add this condition to the if-condition below:
	# or !dictionaryArray.has(guessedWord)
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
		var slotSprite = get_slot(row, i).get_node("Slot")
		var alphabetIndex : int = ALPHABET.find(guessedWordArray[i])  # index of the letter in Arabic Alphabet

		var charIndexInAnswer : int = answerArray.find(guessedWordArray[i], 0)  # if letter found in word it stores its index in the answer word
		# this condition is the core logic of the game
		if guessedWordArray.slice(i).count(guessedWordArray[i]) > answerArray.count(guessedWordArray[i]) and i != charIndexInAnswer:
			slotSprite.texture = wrong
			setStatus(styleBox, alphabetIndex, "wrong")
			if !muted: get_node("sfx/wrong").play()

		elif i == charIndexInAnswer:
				slotSprite.texture = right
				setStatus(styleBox, alphabetIndex, "right")
				answerArray[i] = ""
				if !muted: get_node("sfx/right").play()
		else:
			slotSprite.texture = misplaced
			setStatus(styleBox, alphabetIndex, "misplaced")
			if !muted: get_node("sfx/wrong").play()

		# The keyboard key node
		var keyboardKey = get_keyboard_key(alphabetIndex)

		keyboardKey.add_theme_stylebox_override("normal", styleBox)
		keyboardKey.add_theme_stylebox_override("pressed", styleBox)
		keyboardKey.add_theme_stylebox_override("hover", styleBox)

		while paused:  # this stops for loop while pausing
			await get_tree().process_frame

	if ("".join(guessedWordArray) == answer):
		get_node("graphics/win screen").visible = true
		get_node("graphics/shader layers/win layer").visible = true
		if !muted: get_node("sfx/win").play()
		return
	col = 0
	row += 1
	if row > 5:
		get_node("graphics/lose screen/answer").text += answer
		get_node("graphics/lose screen").visible = true
		get_node("graphics/shader layers/lose layer").visible = true
		return
	var slot = get_slot(row, col)
	slot.get_node("Slot").texture = selected
	input_blocked = false
	guessedWordArray = ["", "", "", "", ""]


func _on_erase_pressed() -> void:
	if input_blocked:
		return
	var slot = get_slot(row, col)
	slot.get_node("Label").text = ""
	slot.get_node("Slot").texture = empty
	guessedWordArray[col] = ""
	if (col != 0):
		col -= 1
	slot = get_slot(row, col)
	slot.get_node("Slot").texture = selected


func setStatus(styleBox : StyleBoxTexture, index : int, status : String) -> void:
	if status == "right":
		statusArray[index] = "right"
	elif status == "misplaced" and statusArray[index] != "right":
		statusArray[index] = "misplaced"
	elif status == "wrong" and statusArray[index] != "right" and statusArray[index] != "misplaced":
		statusArray[index] = "wrong"

	styleBox.texture = statusDict[statusArray[index]]


func loadDictionary() -> Array:
	var file = FileAccess.open('res://resources/dicts/arabic_dict.txt', FileAccess.READ)
	var dict = Array()
	
	if file:
		while !file.eof_reached():
			var word = file.get_line()
			dict.append(word)
	return dict


func randomWord(dict : Array) -> String:
	var dictSize : int = dict.size()
	var randomIndex : int = randi() % dictSize
	return dict[randomIndex]


func get_slot(slotRow, slotCol):
	return get_node("GameContainer/game/WordsMarginContainer/words/GridContainer").get_child(slotCol + slotRow * 5)


func get_slot_with_index(index):
	return get_node("GameContainer/game/WordsMarginContainer/words/GridContainer").get_child(index)

func get_keyboard_key(key_index):
	return get_node("GameContainer/game/KeyboardMarginContainer/keyboard/key_" + str(key_index))


func set_responsive_size():
	var screenScale = get_viewport().size.y / 900.0
	var theme_ui = preload("res://themes/theme_ui.tres")  # This theme basically contains font size
	theme_ui.default_font_size = clamp(int(40 * screenScale), 25, 40)
	theme = theme_ui
	var scaleSlot = Utils.map(screenScale, 0, 2, 1, 2.2)
	var slotSeparation = Utils.map(screenScale, 0, 2, 50, 120)
	separateSlots(slotSeparation)  # Separates letters slots (the slots you enter letters in)
	separateGameContainers(get_viewport().size.y)
	setTopGameMargin(get_viewport().size.y)
	
	if (get_viewport().size.x <= 790):
		get_node("GameContainer/game/KeyboardMarginContainer/keyboard").columns = 6
	else:
		get_node("GameContainer/game/KeyboardMarginContainer/keyboard").columns = 8
	
	for i in range(30):
		get_slot_with_index(i).get_node("Slot").scale = Vector2(scaleSlot, scaleSlot)  # Applies scales to each slot
		
		
func separateSlots(separation : int):
	get_node("GameContainer/game/WordsMarginContainer/words/GridContainer").add_theme_constant_override("h_separation", separation)
	get_node("GameContainer/game/WordsMarginContainer/words/GridContainer").add_theme_constant_override("v_separation", separation)


func separateGameContainers(height : int):
	var separation = int(0.234 * height + 248)  # Linear equation for separation
	get_node("GameContainer/game").add_theme_constant_override("separation", separation)


func setTopGameMargin(height : int):
	const MARGIN_MIN = 100
	var margin = int(0.24 * height - 130)
	margin = MARGIN_MIN if margin < MARGIN_MIN else margin  # Ensures margin is not less than 100
	get_node("GameContainer/game/WordsMarginContainer").add_theme_constant_override("margin_top", margin)
	
func _on_mute_pressed() -> void:
	var styleBox = StyleBoxTexture.new()

	if muted == false:
		styleBox.texture = volumeOff
		muted = true
	else:
		styleBox.texture = volumeUp
		muted = false

	get_node("ControlsContainer/controls/mute").add_theme_stylebox_override("normal", styleBox)
	get_node("ControlsContainer/controls/mute").add_theme_stylebox_override("pressed", styleBox)
	get_node("ControlsContainer/controls/mute").add_theme_stylebox_override("hover", styleBox)


	

func _on_pause_pressed() -> void:
	get_node("graphics/shader layers/pause layer").visible = true
	get_node("graphics/pause menu").visible = true
	paused = true


func _on_unpause_pressed() -> void:
	get_node("graphics/shader layers/pause layer").visible = false
	get_node("graphics/pause menu").visible = false
	paused = false


func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		set_responsive_size()
