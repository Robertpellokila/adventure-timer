extends Node

var kill_count = 0
var kill_label = null

func register_label(label):
	kill_label = label

func add_kill():
	kill_count += 1
	if kill_label:
		kill_label.text = "Kills: " + str(kill_count)
