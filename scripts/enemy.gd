extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var hp_bar: ProgressBar = $HpBar


const SPEED = 80
var player = null

var max_hp = 100
var hp = 100
var is_dead = false

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
	attack_area.body_entered.connect(_on_attack_hit)
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	


func _physics_process(delta):
	if player and current_state != State.DEAD:
		var direction = player.global_position - global_position
		anim.flip_h = direction.x < 0

	if is_dead:
		return

	match current_state:
		State.IDLE:
			anim.play("idle")

		State.CHASE:
			chase_player(delta)

		State.ATTACK:
			pass

		State.HIT:
			pass

		State.DEAD:
			pass


# =========================
# DETECTION
# =========================

func _on_player_detected(body):
	print("detected")
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASE


func _on_player_lost(body):
	print("no detect")
	if body == player:
		player = null
		current_state = State.IDLE


# =========================
# CHASE
# =========================
func face_player():

	if player:
		var direction = player.global_position - global_position
		anim.flip_h = direction.x > 0

func chase_player(delta):

	if player == null:
		current_state = State.IDLE
		return

	var direction = (player.global_position - global_position).normalized()

	velocity = direction * SPEED
	move_and_slide()

	anim.play("run")

	face_player()

	if global_position.distance_to(player.global_position) < 20:
		start_attack()

# =========================
# ATTACK
# =========================

func start_attack():

	face_player()

	current_state = State.ATTACK
	velocity = Vector2.ZERO
	anim.play("attack")

	await anim.animation_finished

	if not is_dead:
		current_state = State.CHASE

func _on_attack_hit(body):
	if current_state == State.ATTACK and body.name == "Player":
		body.take_damage(10)


# =========================
# DAMAGE SYSTEM
# =========================

func take_damage(amount, attacker_position = null):

	if is_dead:
		return

	hp -= amount
	print("Enemy HP:", hp)
	hp_bar.value = hp

	if hp <= 0:
		die()
	else:
		hit()


func hit():
	current_state = State.HIT
	velocity = Vector2.ZERO
	anim.play("hit")

	await anim.animation_finished

	if not is_dead:
		current_state = State.CHASE


func die():
	is_dead = true
	current_state = State.DEAD
	velocity = Vector2.ZERO
	anim.play("death")

	await anim.animation_finished
	queue_free()
