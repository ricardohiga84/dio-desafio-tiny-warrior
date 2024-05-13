class_name Player
extends CharacterBody2D

@export_category("Movement")
@export var speed: float = 3

@export_category("Sword")
@export var sword_damage: int = 2

@export_category("Ritual")
@export var ritual_damage: int = 1
@export var ritual_interval: float = 30
@export var ritual_scene: PackedScene

@export_category("life")
@export var health: int = 100
@export var max_health: int = 100
@export var death_prefab: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitboxArea
@onready var health_progress_bar: ProgressBar = $HealthProgressBar

var input_vector: Vector2 = Vector2(0, 0)
var is_running: bool = false
var was_running: bool = false
var is_attacking: bool = false
var attack_countdown: float = 0.0
var hitbox_countdown: float = 0.0
var ritual_countdown: float = 0.0

signal meat_collected(value: int)

func _ready():
	GameManager.player = self
	meat_collected.connect(func(value: int): GameManager.meat_counter += 1)

func _process(delta):
	GameManager.player_position = position
	
	# ler input
	read_input()
	# processar ataque
	update_attack_cooldown(delta)
	if Input.is_action_just_pressed("attack"):
		attack()
	# processar animação e direção do sprite
	play_run_idle_animation()
	if not is_attacking:
		invert_sprite()
		
	# processar dano
	update_hitbox_detection(delta)
	
	# ritual
	update_ritual(delta)
	
	# atualizar health progress bar
	health_progress_bar.max_value = max_health
	health_progress_bar.value = health

func _physics_process(delta):
	# modificar a velocidade
	var target_velocity = input_vector * speed * 100.0
	if is_attacking:
		target_velocity *= 0.25
	velocity = lerp(velocity, target_velocity, 0.05)
	move_and_slide()

func update_attack_cooldown(delta: float):
	# atualizar temporizador do ataque
	if is_attacking:
		attack_countdown -= delta
		if attack_countdown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")
			
func update_ritual(delta: float):
	ritual_countdown -= delta
	if ritual_countdown > 0: return
	ritual_countdown = ritual_interval
	
	var ritual = ritual_scene.instantiate()
	ritual.damage_amount = ritual_damage
	add_child(ritual)
	

func read_input():
	# obter o input_vector
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# apagar deadzone do input vector
	var deadzone = 0.15
	if abs(input_vector.x) < 0.15:
		input_vector.x = 0.0
	if abs(input_vector.y) < 0.15:
		input_vector.y = 0.0
	
	# atualizar o is_runnig
	was_running = is_running
	is_running = not input_vector.is_zero_approx()

func play_run_idle_animation():
	# rodar animação
	if not is_attacking:	
		if was_running != is_running:
			if is_running:
				animation_player.play("run")
			else:
				animation_player.play("idle")

func invert_sprite():
	# inverter sprite
	if input_vector.x > 0:
		sprite.flip_h = false
	elif input_vector.x < 0:
		sprite.flip_h = true

func attack():
	if is_attacking:
		return
	
	# rodar animação
	animation_player.play("attack_top")
	
	# configurar temporizador
	attack_countdown = 0.6
	
	# marcar ataque
	is_attacking = true
	
	
func deal_damage_to_enemies():
	var bodies = sword_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			
			var direction_to_enemy = (enemy.position - position).normalized()
			var attack_direction: Vector2
			if sprite.flip_h:
				attack_direction = Vector2.LEFT
			else:
				attack_direction = Vector2.RIGHT
			var dot_product = direction_to_enemy.dot(attack_direction)
			if dot_product >= 0.3:
				enemy.damage(sword_damage)
				
func update_hitbox_detection(delta: float):
	# temporizador
	hitbox_countdown -= delta
	if hitbox_countdown > 0: return
	
	# frequencia
	hitbox_countdown = 0.5
	
	# detectar inimigos
	var bodies = hitbox_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var damage_amount = 1
			damage(damage_amount)

func damage(amount: int):
	if health <= 0: return
	health -= amount
	print("Player recebeu dano de ", amount, ". A vida total é de ", health)
	
	# piscar node
	modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(tween.EASE_IN)
	tween.set_trans(tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# processar morte
	if health <= 0:
		die()
		
func die():
	GameManager.end_game()
	
	if death_prefab:
		var death_object = death_prefab.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)
	
	print("Player morreu!")
	queue_free()

func heal(amount: int) -> int:
	health += amount
	if health > max_health:
		health = max_health
		print("Player recebeu cura de ", amount, ". A vida total é de ", health)
	return health
