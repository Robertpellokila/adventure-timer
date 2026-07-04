extends Node2D

signal score_changed(new_score)
signal level_completed   # ⬅️ baru

@export var enemy_scene: PackedScene
@export var target_score := 100   
@onready var spawn_points: Node2D = $EnemySpawnPoints

var score := 0
var alive_enemy = null

func _ready():
	add_to_group("level_manager")
	spawn_enemy()

func spawn_enemy():
	if score >= target_score:
		return
	var points = spawn_points.get_children()
	if points.is_empty():
		print("Tidak ada spawn point enemy.")
		return
	var enemy = enemy_scene.instantiate()
	var spawn_point = points.pick_random()
	add_child(enemy)
	enemy.global_position = spawn_point.global_position
	enemy.died.connect(_on_enemy_died)
	alive_enemy = enemy

func _on_enemy_died(points):
	score += points
	score_changed.emit(score)
	print("Score:", score)
	alive_enemy = null
	if score >= target_score:
		level_completed.emit()  
	else:
		await get_tree().create_timer(1.0).timeout
		spawn_enemy()
