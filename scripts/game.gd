extends Control



class RandomHintChar:
	var letter
	var index
	
	func _init(_letter, _index) -> void:
		letter = _letter
		index = _index

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
const ATTEMPT_COUNT : int = 6
const ALPHABET_LETTER_NUMBER : int = 30

var row : int = 0
var col : int = 0
var answer : String
var guessedWordArray : Array[String] = ["", "", "", "", ""]
var statusArray = Array()

var input_blocked : bool = true
var muted : bool = false
var paused : bool = false

var dictionaryArray = Array()

var randomHintChar : RandomHintChar = RandomHintChar.new(null, null)
var localStatus : String
var remoteStatus: String
var isHost : bool
var isAnswerSet : bool = false
var playerJoined : bool = false

func _ready() -> void:
	localStatus = "يلعب"
	isHost = multiplayer.get_unique_id() == 1 
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


func _process(_delta) -> void:
	if get_other_peer_id() != multiplayer.get_unique_id():
		rpc_id(get_other_peer_id(), "displayStatus", localStatus)
	
	if isHost and (getOponnentStatus() == "فاز" or localStatus == "فاز"):
		get_node("graphics/pause menu/ButtonsContainerMargin/ButtonsContainer/replay").visible = true
		get_node("graphics/win screen/replay").visible = true
		get_node("graphics/lose screen/replay").visible = true
	
	if localStatus == "خسر" and getOponnentStatus() == "خسر":
		hideLoseScreen()
		showTieScreen()
		localStatus = "تعادل"
		if isHost:
			get_node("graphics/tie screen/VBoxContainer/replay").visible = true
	
	
	if getOponnentStatus() == "يلعب" and !playerJoined:
		input_blocked = false
		if isHost and !isAnswerSet:
			rpc("setAnswerRemote", answer)
			isAnswerSet = true
		playerJoined = true
		

func _on_key_pressed(letter : String) -> void:
	if input_blocked:
		return
	var slot = get_slot(row, col)
	slot.get_node("Label").text = letter
	slot.get_node("Slot").texture = empty
	guessedWordArray[col] = letter
	if (col != WORD_LENGTH - 1):
		col += 1
		jumpCol()
	slot = get_slot(row, col)
	slot.get_node("Slot").texture = selected
	# play click sound
	if !muted: get_node("sfx/click").play()

func _on_check_pressed() -> void:
	if input_blocked:
		return
	input_blocked = true
	var answerArray = answer.split("")
	if (randomHintChar.index != null and randomHintChar.letter):  # Ensures that user actually used hint
		guessedWordArray[randomHintChar.index] = randomHintChar.letter  # if user used hint, then the hint is stored
	var guessedWord : String = ''.join(guessedWordArray)
	# if a new dictionary is found, add this condition to the if-condition below:
	# or !dictionaryArray.has(guessedWord)
	if len(guessedWord) != 5:
		input_blocked = false
		return
	
	var rightCount : int = 0
	for i in range(WORD_LENGTH):
		# Set a new style box for each letter in the keyboard instead of them sharing the same
		# Stylebox
		var styleBox = StyleBoxTexture.new()
		styleBox.texture_margin_left = 20  # set texture margin for new style box
		styleBox.texture_margin_right = 20
		
		# the sprite of the letter slot (in the words grid)
		var slotSprite = get_slot(row, i).get_node("Slot")
		var alphabetIndex : int = getIndexInArabicAlphabet(guessedWordArray[i])  # index of the letter in Arabic Alphabet
		var charIndexInAnswer : int = answerArray.find(guessedWordArray[i], 0)  # if letter found in word it stores its index in the answer word
		
		if i == randomHintChar.index:  # if current iteration is revealed, skips
			rightCount += 1
			setStatus(styleBox, alphabetIndex, "right")
			answerArray[i] = ""
			continue  # continues on revealed
		
		await get_tree().create_timer(0.5).timeout  # time delay between each iteration
		
		# this condition is the core logic of the game
		if guessedWordArray.slice(i).count(guessedWordArray[i]) > answerArray.count(guessedWordArray[i]) and i != charIndexInAnswer:
			slotSprite.texture = wrong
			setStatus(styleBox, alphabetIndex, "wrong")
			if !muted: get_node("sfx/wrong").play()

		elif i == charIndexInAnswer:
				slotSprite.texture = right
				rightCount += 1
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
		showWinScreen()
		localStatus = "فاز"
		rpc("opponentLost")
		if !muted: get_node("sfx/win").play()
		return
	col = 0
	row += 1
	if row <= 5: jumpCol()
	if row > 5:
		showLoseScreen()
		localStatus = "خسر"
		return
	var slot = get_slot(row, col)
	slot.get_node("Slot").texture = selected
	input_blocked = false
	guessedWordArray = ["", "", "", "", ""]
	
	if rightCount == WORD_LENGTH - 1:
		get_node("HintContainer/Hint").disabled = true


func _on_erase_pressed() -> void:
	if input_blocked:
		return
	var slot = get_slot(row, col)
	slot.get_node("Label").text = ""
	slot.get_node("Slot").texture = empty
	guessedWordArray[col] = ""
	if (col != 0):
		col -= 1
		jumpCol(true)
	slot = get_slot(row, col)
	slot.get_node("Slot").texture = selected


func hideLoseScreen():
	get_node("graphics/lose screen").visible = false
	get_node("graphics/shader layers/lose layer").visible = false
	
	
func showLoseScreen():
	get_node("graphics/lose screen/answer").text = "الإجابة: " + answer
	get_node("graphics/lose screen").visible = true
	get_node("graphics/shader layers/lose layer").visible = true


func showWinScreen():
	get_node("graphics/win screen").visible = true
	get_node("graphics/shader layers/win layer").visible = true
	

func showTieScreen():
	get_node("graphics/tie screen/VBoxContainer/answer").text = "الإجابة: " + answer
	get_node("graphics/tie screen").visible = true
	get_node("graphics/shader layers/tie layer").visible = true
	

func jumpCol(backwards = false):
	if col == randomHintChar.index:   # if the current slot is the hint char, jump one column
		if (backwards):
			if col == 0: col += 1
			else: col -= 1
			get_slot(row, col).get_node("Slot").texture = selected
		else:
			if col == WORD_LENGTH - 1: col -= 1
			else: col += 1
			get_slot(row, col).get_node("Slot").texture = selected
	
	
func getIndexInArabicAlphabet(letter) -> int:
	
	const ALPHABET : String = "ابتثجحخدذرزسشصضطظعغفقكلمنهويةء"
	var alphabetIndex : int = ALPHABET.find(letter)  # index of the letter in Arabic Alphabet
	return alphabetIndex
	
	
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


func isLetterAlreadySolved(letterIndex) -> bool:  # is letter already solved by user
	for i in range(ATTEMPT_COUNT):
		for j in range(WORD_LENGTH):
			if (get_slot(i, j).get_node("Slot").texture == right and j == letterIndex):  # if at any row, the slot is green and the index of that slot is the same as
				return true																 # letter index, then it is already solved, so find another hint
	return false

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
	rpc("replay")

func _on_hint_pressed() -> void:
	if input_blocked:
		return
		
	get_node("HintContainer/Hint").disabled = true
	
	var styleBox = StyleBoxTexture.new()
	styleBox.texture_margin_left = 20  # set texture margin for new style box
	styleBox.texture_margin_right = 20
	
	var randomLetterIndex : int = randi() % WORD_LENGTH
	var hintRandomLetter = answer[randomLetterIndex]
	while (isLetterAlreadySolved(randomLetterIndex)):
		randomLetterIndex = randi() % WORD_LENGTH
		hintRandomLetter = answer[randomLetterIndex]
	
	var alphabetIndex = getIndexInArabicAlphabet(hintRandomLetter)
	randomHintChar.letter = hintRandomLetter
	randomHintChar.index = randomLetterIndex
	
	for i in range(row, ATTEMPT_COUNT):
		var slot = get_slot(i, randomLetterIndex)
		slot.get_node("Label").text = hintRandomLetter
		slot.get_node("Slot").texture = right
	
	setStatus(styleBox, alphabetIndex, "right")
	
	var keyboardKey = get_keyboard_key(alphabetIndex)
	keyboardKey.add_theme_stylebox_override("normal", styleBox)
	keyboardKey.add_theme_stylebox_override("pressed", styleBox)
	keyboardKey.add_theme_stylebox_override("hover", styleBox)
	if !muted: get_node("sfx/hint").play()
	jumpCol()  # jumps one column if the selected slot is equal to the hint letter slot
	
signal fill_input_fields_signal

# Multiplayer related functions
func emitFillInputSignal() -> void:
	emit_signal("fill_input_fields_signal")
	# Emits a signal when replay is pressed so user doesn't have to refill fields
	# manually


func setStatusLabelColor(status : String):
	if status == "يلعب":
		get_node("MultiplayerStatus/Label").add_theme_color_override("font_color", Color(1, 1, 1, 1))
	elif status == "فاز":
		get_node("MultiplayerStatus/Label").add_theme_color_override("font_color", Color(0.824, 0.149, 0.0, 1))
	elif status == "خسر":
		get_node("MultiplayerStatus/Label").add_theme_color_override("font_color", Color(0.314, 0.588, 0.0, 1))
	else: # disconnected
		get_node("MultiplayerStatus/Label").add_theme_color_override("font_color", Color(0.378, 0.378, 0.378, 1))
		
func getOponnentStatus():
	return $MultiplayerStatus/Label.text.trim_prefix("حالة الخصم: ")

@rpc("any_peer")
func displayStatus(status):
	get_node("MultiplayerStatus/Label").text = 'حالة الخصم: ' + str(status)
	setStatusLabelColor(status)


@rpc("any_peer", "call_local")
func replay():
	get_tree().reload_current_scene()
	emitFillInputSignal()

@rpc("any_peer")
func opponentLost():
	get_node("graphics/lose screen/answer").text = answer
	get_node("graphics/lose screen").visible = true
	get_node("graphics/shader layers/lose layer").visible = true
	localStatus = "خسر"
	

@rpc("any_peer")
func setAnswerRemote(remoteAnswer: String):
	answer = remoteAnswer
	
	
func get_other_peer_id() -> int:
	for peer_id in multiplayer.get_peers():
		if peer_id != multiplayer.get_unique_id():
			return peer_id
	return 1  # fallback (host)
		
		
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		set_responsive_size()
