extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var hearts: Array = [$HBoxContainer/Heart1, $HBoxContainer/Heart2, $HBoxContainer/Heart3]

@onready var start_screen: Control = $StartScreen
@onready var start_button: Button = $StartScreen/VBox/StartButton

@onready var game_over_screen: Control = $GameOverScreen
@onready var final_score_label: Label = $GameOverScreen/VBox/FinalScoreLabel
@onready var start_again: Button = $GameOverScreen/VBox/StartAgain


var level_manager = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS   # HUD tetap aktif walau game di-pause

	Global.lives_changed.connect(_on_lives_changed)
	Global.game_over_triggered.connect(_on_game_over)
	_on_lives_changed(Global.lives)

	game_over_screen.visible = false
	start_button.pressed.connect(_on_start_pressed)
	start_again.pressed.connect(_on_restart_pressed)

	if Global.game_started:
		start_screen.visible = false
		get_tree().paused = false
	else:
		start_screen.visible = true
		get_tree().paused = true

	await get_tree().process_frame
	level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		level_manager.score_changed.connect(_on_score_changed)
		_on_score_changed(level_manager.score)

func _on_score_changed(new_score):
	score_label.text = "Score: %d" % new_score

func _on_lives_changed(new_lives):
	for i in hearts.size():
		hearts[i].visible = i < new_lives

func _on_start_pressed():
	Global.game_started = true
	start_screen.visible = false
	get_tree().paused = false

func _on_game_over():
	if level_manager:
		final_score_label.text = "Score Akhir: %d" % level_manager.score
	game_over_screen.visible = true
	get_tree().paused = true

func _on_restart_pressed():
	Global.reset_lives()
	get_tree().paused = false
	get_tree().reload_current_scene()
