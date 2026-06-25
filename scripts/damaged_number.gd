extends Node2D

@onready var label = $DamagedLabel

func setup(amount, type := "damage"):

	label.text = str(amount)

	match type:

		"damage":
			label.modulate = Color.WHITE
			label.scale = Vector2(1,1)

		"crit":
			label.modulate = Color.RED
			label.scale = Vector2(1.6,1.6)

		"heal":
			label.modulate = Color.GREEN
			label.scale = Vector2(1.2,1.2)

func _ready():

	var tween = create_tween()

	tween.tween_property(self,"position:y",position.y - 70,0.9)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(self,"modulate:a",0,0.9)

	await tween.finished
	queue_free()
