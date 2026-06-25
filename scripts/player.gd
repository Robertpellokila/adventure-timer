extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var invincible_timer: Timer = $InvincibleTimer
@onready var skill_hitbox: Area2D = $AttackArea
@onready var hp_bar: ProgressBar = $HpBar
@onready var fade_timer: Timer = $FadeTimer

const SPEED = 150
const ACCEL = 800

var max_hp = 100
var hp = 100
var is_dead = false
var is_invincible = false

var damage_scene = preload("res://scenes/damaged_number.tscn")

# Knockback
var knockback_force = 250
var knockback_velocity = Vector2.ZERO

# Skill Damage
var skill_damage = {
	"skill1": 5,
	"skill2": 10,
	"skill3": 20
}

var current_skill = ""
var facing_right = true
var last_direction = Vector2.DOWN

enum State {
	MOVE,
	BLOCK,
	SKILL,
	HURT,
	DEAD
}

var current_state = State.MOVE

var crit_chance = 0.2

# =====================================================
# READY
# =====================================================

func _ready():
	skill_hitbox.body_entered.connect(_on_skill_hit)
	skill_hitbox.monitoring = false
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	fade_timer.wait_time = 2.0
	fade_timer.one_shot = true
	fade_timer.timeout.connect(_on_fade_timeout)


# =====================================================
# MAIN LOOP
# =====================================================

func _physics_process(delta):

	if current_state == State.DEAD:
		return

	if current_state == State.HURT:
		handle_knockback(delta)
		return

	match current_state:
		State.MOVE:
			handle_movement(delta)
			handle_actions()

		State.BLOCK:
			handle_block()

		State.SKILL:
			pass


# =====================================================
# MOVEMENT
# =====================================================

func handle_movement(delta):

	var raw_x = Input.get_axis("left", "right")
	var raw_y = Input.get_axis("up", "down")

	var input_dir = Vector2(raw_x, raw_y)

	velocity = velocity.move_toward(input_dir.normalized() * SPEED, ACCEL * delta)
	move_and_slide()

	update_facing(raw_x)

	# === ANIMATION DIRECTION ===
	if input_dir == Vector2.ZERO:
		anim.play("side_idle")

	else:
		if abs(raw_y) > abs(raw_x):

			if raw_y < 0:
				anim.play("back_walk")   # jalan ke atas

			elif raw_y > 0:
				anim.play("front_walk")  # jalan ke bawah

		else:
			anim.play("side_walk")     # kiri kanan
			
func update_facing(raw_x: float):
	if raw_x > 0 and not facing_right:
		facing_right = true
		anim.flip_h = false
	elif raw_x < 0 and facing_right:
		facing_right = false
		anim.flip_h = true


# =====================================================
# ACTIONS
# =====================================================

func handle_actions():

	if Input.is_action_pressed("block"):
		start_block()
		return

	if Input.is_action_just_pressed("skill_1"):
		start_skill("skill1")

	elif Input.is_action_just_pressed("skill_2"):
		start_skill("skill2")

	elif Input.is_action_just_pressed("skill_3"):
		start_skill("skill3")


func start_block():
	current_state = State.BLOCK
	velocity = Vector2.ZERO
	anim.play("block")


func handle_block():
	if not Input.is_action_pressed("block"):
		current_state = State.MOVE


func update_hp():
	hp_bar.value = hp
	if hp == max_hp:
		hp_bar.visible = false
	else:
		hp_bar.visible = true
		hp_bar.modulate.a = 1.0
		fade_timer.start()
		
func _on_fade_timeout():
	var tween = create_tween()
	tween.tween_property(hp_bar, "modulate:a", 0.0, 0.5)
# =====================================================
# SKILL SYSTEM
# =====================================================

func start_skill(skill_name: String):

	if current_state == State.HURT or current_state == State.DEAD:
		return

	current_state = State.SKILL
	current_skill = skill_name
	velocity = Vector2.ZERO

	anim.play(skill_name)

	skill_hitbox.monitoring = true

	await anim.animation_finished

	skill_hitbox.monitoring = false

	if current_state != State.DEAD:
		current_state = State.MOVE


func _on_skill_hit(body):

	if current_state != State.SKILL:
		return

	if body.has_method("take_damage"):
		body.take_damage(
			skill_damage[current_skill],
			global_position
		)


# =====================================================
# DAMAGE SYSTEM
# =====================================================

func show_damage(amount, type := "damage"):

	var dmg = damage_scene.instantiate()

	add_child(dmg)

	var random_x = randf_range(-20,20)

	dmg.position = Vector2(random_x,-50)

	dmg.setup(amount, type)

func take_damage(amount, attacker_position = null):

	if is_dead or is_invincible:
		return

	var damage_type = "damage"

	# CRITICAL HIT
	if randf() < crit_chance:
		amount *= 2
		damage_type = "crit"

	if current_state == State.BLOCK:
		amount /= 2
		anim.play("block")
	else:
		current_state = State.HURT
		anim.play("hurt")

	hp -= amount
	print("HP:", hp)
	hp_bar.value = hp

	show_damage(amount, damage_type)

	# Knockback
	if attacker_position:
		var direction = (global_position - attacker_position).normalized()
		knockback_velocity = direction * knockback_force

	start_invincibility()

	if hp <= 0:
		die()
	else:
		await anim.animation_finished
		if not is_dead:
			current_state = State.MOVE
# =====================================================
# KNOCKBACK
# =====================================================

func handle_knockback(delta):

	velocity = knockback_velocity
	move_and_slide()

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1000 * delta)

	if knockback_velocity.length() < 10:
		knockback_velocity = Vector2.ZERO


# =====================================================
# KNOCKBACK
# =====================================================
func heal(amount):

	hp = min(hp + amount, max_hp)

	hp_bar.value = hp

	show_damage("+" + str(amount), "heal")
	
# =====================================================
# INVINCIBILITY
# =====================================================

func start_invincibility():
	is_invincible = true
	anim.modulate.a = 0.5
	invincible_timer.start()


func _on_InvincibleTimer_timeout():
	is_invincible = false
	anim.modulate.a = 1


# =====================================================
# DEATH
# =====================================================

func die():
	is_dead = true
	current_state = State.DEAD
	velocity = Vector2.ZERO

	anim.play("death")
	await anim.animation_finished

	print("PLAYER DEAD")
