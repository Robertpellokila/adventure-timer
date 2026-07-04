extends CharacterBody2D

signal died(points)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var hp_bar: ProgressBar = $HpBar

const SPEED = 80
const ACCEL = 500
const ATTACK_RANGE = 32.0
const ATTACK_DAMAGE = 10
const ATTACK_COOLDOWN = 0.8
const POINTS = 100

var player: Node2D = null
var max_hp = 100
var hp = 100
var is_dead = false
var can_attack = true

enum State {
	IDLE,
	CHASE,
	ATTACK,
	HIT,
	DEAD
}

var current_state = State.IDLE


func _ready():
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)

	hp_bar.max_value = max_hp
	hp_bar.value = hp


func _physics_process(delta):
	if is_dead:
		return

	if player and current_state != State.DEAD:
		face_player()

	match current_state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, ACCEL * delta)
			move_and_slide()
			anim.play("idle")

		State.CHASE:
			chase_player(delta)

		State.ATTACK:
			pass

		State.HIT:
			pass

		State.DEAD:
			pass


func _on_player_detected(body):
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASE


func _on_player_lost(body):
	if body == player:
		player = null
		current_state = State.IDLE


func face_player():
	if player == null:
		return

	var direction = player.global_position - global_position

	# Kalau sprite enemy default menghadap kanan:
	anim.flip_h = direction.x > 0

	# Kalau ternyata masih kebalik, ubah jadi:
	# anim.flip_h = direction.x > 0

func chase_player(delta):
	if player == null:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)

	if distance <= ATTACK_RANGE and can_attack:
		start_attack()
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = velocity.move_toward(direction * SPEED, ACCEL * delta)
	move_and_slide()

	anim.play("run")


func start_attack():
	if not can_attack or current_state == State.ATTACK or is_dead:
		return

	can_attack = false
	current_state = State.ATTACK
	velocity = Vector2.ZERO
	move_and_slide()

	face_player()
	anim.play("attack")

	# Sesuaikan angka ini dengan frame saat pedang/serangan enemy benar-benar mengenai player.
	await get_tree().create_timer(0.25).timeout
	deal_attack_damage()

	await anim.animation_finished

	if not is_dead and current_state == State.ATTACK:
		current_state = State.CHASE if player else State.IDLE

	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true


func deal_attack_damage():
	if current_state != State.ATTACK or is_dead:
		return

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE, global_position)
			break


func take_damage(amount, attacker_position = null):
	if is_dead:
		return

	hp -= amount
	hp = max(hp, 0)
	hp_bar.value = hp

	print("Enemy HP:", hp)

	if hp <= 0:
		die()
	else:
		hit()


func hit():
	if is_dead:
		return

	current_state = State.HIT
	velocity = Vector2.ZERO
	anim.play("hit")

	await anim.animation_finished

	if not is_dead:
		current_state = State.CHASE if player else State.IDLE


func die():
	if is_dead:
		return

	is_dead = true
	current_state = State.DEAD
	velocity = Vector2.ZERO

	died.emit(POINTS)

	anim.play("death")
	await anim.animation_finished

	queue_free()
