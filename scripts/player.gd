extends CharacterBody2D
class_name Player

var move_speed: float = 100
var sprint_speed: float = 150

var ammo: int = 30
var max_ammo: int = 30
var is_reloading: bool = false
var can_shoot: bool = true

var attack_animation_timer: float = 0.0
var attack_animation_duration: float = 0.3

enum Direction { RIGHT, LEFT }
enum VerticalAim { UP, DOWN }
enum ActionState { IDLE, ATTACK, RELOADING, RUN, WALK, RUN_SHOOTING, WALK_SHOOTING, DEATH }

var current_direction: int = Direction.RIGHT
var current_vertical_aim: int = VerticalAim.DOWN
var current_action: int = ActionState.IDLE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var gun = $Gun
@onready var bullet_spawn = $Gun/BulletSpawn
@onready var reload_timer = $Gun/ReloadTimer
@onready var shoot_timer = $Gun/ShootTimer
@onready var audio_player = $AudioStreamPlayer2D

@export var bullet: PackedScene

func _process(delta):
	if GameScene.player_hp <= 0:
		current_action = ActionState.DEATH
		update_animation()
		return
	
	if attack_animation_timer > 0:
		attack_animation_timer -= delta
	
	_handle_input()
	_update_state()
	update_animation()

func _physics_process(delta):
	move_and_slide()

func _handle_input():
	var move_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else move_speed
	velocity = move_vector * current_speed
	
	var mouse_pos = get_global_mouse_position()
	if mouse_pos.x > global_position.x:
		current_direction = Direction.RIGHT
	else:
		current_direction = Direction.LEFT
	
	var angle = global_position.angle_to_point(mouse_pos)
	if angle < 0:
		current_vertical_aim = VerticalAim.UP
	else:
		current_vertical_aim = VerticalAim.DOWN
	
	if Input.is_action_pressed("shoot"):
		var shoot_direction = (get_global_mouse_position() - global_position).normalized()
		var shot_fired = gun.shoot(shoot_direction)
		
		if shot_fired:
			attack_animation_timer = attack_animation_duration
	
	if Input.is_action_just_pressed("reload"):
		gun.reload()

func _update_state():
	if current_action == ActionState.DEATH:
		return
		
	if gun.is_reloading:
		current_action = ActionState.RELOADING
		return
	
	# Dar prioridade à animação de tiro se o timer estiver ativo
	if attack_animation_timer > 0:
		if velocity.length() > 0:
			if velocity.length() >= sprint_speed * 0.8:
				current_action = ActionState.RUN_SHOOTING
			else:
				current_action = ActionState.WALK_SHOOTING
		else:
			current_action = ActionState.ATTACK
		return
		
	if velocity.length() > 0:
		if velocity.length() >= sprint_speed * 0.8:
			if Input.is_action_pressed("shoot"):
				current_action = ActionState.RUN_SHOOTING
			else:
				current_action = ActionState.RUN
		else:
			if Input.is_action_pressed("shoot"):
				current_action = ActionState.WALK_SHOOTING
			else:
				current_action = ActionState.WALK
	else:
		if Input.is_action_pressed("shoot") and gun.can_shoot and gun.ammo > 0:
			current_action = ActionState.ATTACK
		else:
			current_action = ActionState.IDLE

func update_animation():
	var animation_name = "GUN_"
	if current_direction == Direction.RIGHT:
		if current_vertical_aim == VerticalAim.UP:
			animation_name += "RIGHT_UP_"
		else:
			animation_name += "RIGHT_DOWN_"
	else:
		if current_vertical_aim == VerticalAim.UP:
			animation_name += "LEFT_UP_"
		else:
			animation_name += "LEFT_DOWN_"
	
	match current_action:
		ActionState.IDLE:
			animation_name += "IDLE"
		ActionState.ATTACK:
			animation_name += "ATTACK"
		ActionState.RELOADING:
			animation_name += "RELOADING"
		ActionState.RUN:
			animation_name += "RUN"
		ActionState.WALK:
			animation_name += "WALK"
		ActionState.RUN_SHOOTING:
			animation_name += "RUN_SHOOTING"
		ActionState.WALK_SHOOTING:
			animation_name += "WALK_SHOOTING"
		ActionState.DEATH:
			animation_name += "DEATH"
	
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		var fallback_name = "GUN_RIGHT_DOWN_IDLE"
		
		if animated_sprite.sprite_frames.has_animation(fallback_name):
			animated_sprite.play(fallback_name)
		else:
			print("Animação não encontrada: ", animation_name, " e fallback também não encontrado: ", fallback_name)
	
	update_gun_position()

func update_gun_position():
	if current_direction == Direction.RIGHT:
		gun.scale.x = 1
		if current_vertical_aim == VerticalAim.UP:
			gun.rotation_degrees = -45
		else:
			gun.rotation_degrees = 45
	else:
		gun.scale.x = -1
		if current_vertical_aim == VerticalAim.UP:
			gun.rotation_degrees = -135
		else:
			gun.rotation_degrees = 135

func _on_hitbox_area_2d_body_entered(body: Node2D) -> void:
	if body is Enemy:
		GameScene.player_hp -= 1
		update_hp_bar()
	if GameScene.player_hp <= 0:
		die()

func die():
	current_action = ActionState.DEATH
	update_animation()
	await animated_sprite.animation_finished
	GameScene.player_hp = 4
	get_tree().call_deferred("reload_current_scene")

func _ready():
	update_hp_bar()
	
	gun.ammo_changed.connect(func(current, maximum): 
		# atualizar a UI de munição
		pass
	)
	
	gun.started_reloading.connect(func():
		# Animação ou efeito de início de recarga
		pass
	)
	
	gun.finished_reloading.connect(func():
		# Animação ou efeito de fim de recarga
		pass
	)
	
	gun.bullet_scene = bullet
	
func update_hp_bar():
	var hp_animation = str(min(GameScene.player_hp, 4)) + "_hp"
	if %HPBar.sprite_frames.has_animation(hp_animation):
		%HPBar.play(hp_animation)
	else:
		print("Animação de HP não encontrada: ", hp_animation)
