extends Node

signal score_changed(new_score)
signal lives_changed(new_lives)
signal game_over_triggered   # ⬅️ baru, ganti dari func game_over()

var score: int = 0
var lives: int = 3
var max_lives: int = 3
var game_started: bool = false   # ⬅️ baru, biar tutorial cuma muncul sekali

func add_score(amount: int):
	score += amount
	score_changed.emit(score)

func lose_life():
	lives -= 1
	lives = max(lives, 0)
	lives_changed.emit(lives)

	if lives <= 0:
		game_over_triggered.emit()   # ⬅️ ganti dari call_deferred("game_over")

func reset_lives():
	lives = max_lives
	lives_changed.emit(lives)
