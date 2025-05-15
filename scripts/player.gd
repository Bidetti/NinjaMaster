extends CharacterBody2D
class_name Player

var move_speed: float = 100
var sprint_speed: float = 150

var ammo: int = 30
var max_ammo: int = 30
var is_reloading: bool = false
var can_shoot: bool = true

enum Direction { RIGHT, LEFT }
enum VerticalAim { UP, DOWN }
enum ActionState { IDLE, ATTACK, RELOADING, RUN, WALK, RUN_SHOOTING, WALK_SHOOTING, DEATH }

var current_direction: int = Direction.RIGHT
var current_vertical_aim: int = VerticalAim.DOWN
var current_action: int = ActionState.IDLE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var gun = $Gun
@onready var bullet_spawn = $Gun/BulletSpawn
@onready var reload_timer = $ReloadTimer
@onready var shoot_timer = $ShootTimer
@onready var audio_player = $AudioStreamPlayer

@export var bullet_scene: PackedScene

func _process(delta):
	if GameScene.player_hp <= 0:
		current_action = ActionState.DEATH
		update_animation()
		return
		
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
	
	if Input.is_action_just_pressed("shoot") and can_shoot and !is_reloading and ammo > 0:
		shoot()
	
	if Input.is_action_just_pressed("reload") and !is_reloading and ammo < max_ammo:
		reload()

func _update_state():
	if current_action == ActionState.DEATH:
		return
		
	if is_reloading:
		current_action = ActionState.RELOADING
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
		if Input.is_action_pressed("shoot") and can_shoot and ammo > 0:
			current_action = ActionState.ATTACK
		else:
			current_action = ActionState.IDLE

func update_animation():
	var animation_name = "GUN_"
	
	animation_name += "RIGHT" if current_direction == Direction.RIGHT else "LEFT"
	animation_name += "_" + ("UP" if current_vertical_aim == VerticalAim.UP else "DOWN")
	
	match current_action:
		ActionState.IDLE:
			animation_name += "_IDLE"
		ActionState.ATTACK:
			animation_name += "_ATTACK"
		ActionState.RELOADING:
			animation_name += "_RELOADING"
		ActionState.RUN:
			animation_name += "_RUN"
		ActionState.WALK:
			animation_name += "_WALK"
		ActionState.RUN_SHOOTING:
			animation_name += "_RUN_SHOOTING"
		ActionState.WALK_SHOOTING:
			animation_name += "_WALK_SHOOTING"
		ActionState.DEATH:
			animation_name = "GUN_" + ("RIGHT" if current_direction == Direction.RIGHT else "LEFT") + "_" + ("UP" if current_vertical_aim == VerticalAim.UP else "DOWN") + "_DEATH"
	
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		print("Animação não encontrada: ", animation_name)
		var fallback_name = ""
		
		if current_action == ActionState.DEATH:
			fallback_name = "GUN_" + ("RIGHT" if current_direction == Direction.RIGHT else "LEFT") + "_DEATH"
		else:
			fallback_name = "GUN_" + ("RIGHT" if current_direction == Direction.RIGHT else "LEFT") + "_" + ("UP" if current_vertical_aim == VerticalAim.UP else "DOWN") + "_IDLE"
		
		if animated_sprite.sprite_frames.has_animation(fallback_name):
			animated_sprite.play(fallback_name)
		else:
			print("Fallback também não encontrado: ", fallback_name)
	
	update_gun_position()

func update_gun_position():
	if current_direction == Direction.RIGHT:
		gun.scale.x = 1
		if current_vertical_aim == VerticalAim.UP:
			gun.rotation_degrees = -45
		elif current_vertical_aim == VerticalAim.DOWN:
			gun.rotation_degrees = 45
		else:
			gun.rotation_degrees = 0
	else:
		gun.scale.x = -1
		if current_vertical_aim == VerticalAim.UP:
			gun.rotation_degrees = -135
		elif current_vertical_aim == VerticalAim.DOWN:
			gun.rotation_degrees = 135
		else:
			gun.rotation_degrees = 180

func shoot():
	if ammo <= 0 or !can_shoot or is_reloading:
		return
		
	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	
	var shoot_direction = (get_global_mouse_position() - global_position).normalized()
	bullet.direction = shoot_direction
	
	get_tree().root.add_child(bullet)
	
	ammo -= 1
	can_shoot = false
	shoot_timer.start()
	
	audio_player.play()

func reload():
	is_reloading = true
	reload_timer.start()

func _on_shoot_timer_timeout():
	can_shoot = true

func _on_reload_timer_timeout():
	ammo = max_ammo
	is_reloading = false

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
	
func update_hp_bar():
	var hp_animation = str(min(GameScene.player_hp, 4)) + "_hp"
	if %HPBar.sprite_frames.has_animation(hp_animation):
		%HPBar.play(hp_animation)
	else:
		print("Animação de HP não encontrada: ", hp_animation)
