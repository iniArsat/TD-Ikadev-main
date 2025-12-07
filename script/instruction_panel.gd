extends Panel

signal instruction_completed
signal skip_instructions

@onready var continue_button: Button = $HBoxContainer/ContinueButton
@onready var skip_button: Button = $HBoxContainer/SkipButton
@onready var previous_button: Button = $HBoxContainer/PreviousButton
@onready var page1: Panel = $Page1
@onready var page2: Panel = $Page2
@onready var page3: Panel = $Page3
@onready var page4: Panel = $Page4

var current_page: int = 1

func _ready():
	page1.visible = true
	page2.visible = false
	page3.visible = false
	page4.visible = false
	if previous_button:
		previous_button.visible = false
	GameSpeedManager.set_game_speed(0.0)
	_update_buttons()

func _on_continue_pressed():
	match current_page:
		1:
			page1.visible = false
			page2.visible = true
			current_page = 2
		2:
			page2.visible = false
			page3.visible = true
			current_page = 3
		3:
			page3.visible = false
			page4.visible = true
			current_page = 4
		4:
			GameSpeedManager.set_game_speed(1.0)
			instruction_completed.emit()
			return
	_update_buttons()

func _on_previous_pressed():
	match current_page:
		2:
			page2.visible = false
			page1.visible = true
			current_page = 1
		3:
			page3.visible = false
			page2.visible = true
			current_page = 2
		4:
			page4.visible = false
			page3.visible = true
			current_page = 3
	_update_buttons()
			
func _update_buttons():
	if previous_button:
		previous_button.visible = (current_page > 1)
	if continue_button:
		if current_page == 4:
			if continue_button:
				continue_button.visible = false
		else:
			if continue_button:
				continue_button.visible = true
	if skip_button:
		match current_page:
			1:
				# Page 1: Tampilkan skip button dengan text "SKIP"
				skip_button.visible = true
				skip_button.text = "SKIP"
			2, 3:
				# Page 2 dan 3: Sembunyikan skip button
				skip_button.visible = false
			4:
				# Page 4: Tampilkan skip button dengan text "GOT IT"
				skip_button.visible = true
				skip_button.text = "GOT IT"
func _on_skip_pressed():
	GameSpeedManager.set_game_speed(1.0)
	skip_instructions.emit()
