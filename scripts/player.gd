extends CharacterBody2D
class_name Player

var move_speed: float = 100
var sprint_speed: float = 150

var attack_animation_timer: float = 0.0
var attack_animation_duration: float = 0.3

enum Direction { RIGHT, LEFT }
enum VerticalAim { UP, DOWN }
enum ActionState { 
	IDLE, ATTACK, RELOADING, RUN, WALK, 
	RUN_SHOOTING, WALK_SHOOTING, WALK_RELOADING, 
	RUN_RELOADING, DEATH 
}

var current_direction: int = Direction.RIGHT
var current_vertical_aim: int = VerticalAim.DOWN
var current_action: int = ActionState.IDLE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var death_shadow: AnimatedSprite2D = $DeathShadow
@onready var gun = $Gun
@onready var audio_player = $AudioStreamPlayer2D

@export var bullet: PackedScene

func _ready():
	update_hp_bar()
	
	gun.ammo_changed.connect(_on_ammo_changed)
	gun.started_reloading.connect(_on_started_reloading)
	gun.finished_reloading.connect(_on_finished_reloading)
	
	gun.bullet_scene = bullet

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

func _physics_process(_delta):
	move_and_slide()

func _handle_input():
	var move_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else move_speed
	velocity = move_vector * current_speed
	
	var mouse_pos = get_global_mouse_position()
	current_direction = Direction.RIGHT if mouse_pos.x > global_position.x else Direction.LEFT
	
	var angle = global_position.angle_to_point(mouse_pos)
	current_vertical_aim = VerticalAim.UP if angle < 0 else VerticalAim.DOWN
	
	if Input.is_action_pressed("shoot"):
		var shoot_direction = (mouse_pos - global_position).normalized()
		var shot_fired = gun.shoot(shoot_direction)
		
		if shot_fired:
			attack_animation_timer = attack_animation_duration
	
	if Input.is_action_just_pressed("reload"):
		gun.reload()

func _update_state():
	if current_action == ActionState.DEATH:
		return
	
	var is_moving = velocity.length() > 0
	var is_sprinting = velocity.length() >= sprint_speed * 0.8
	var is_shooting = Input.is_action_pressed("shoot") && gun.can_shoot && gun.ammo > 0
	
	if gun.is_reloading:
		if is_moving:
			if velocity.length() >= sprint_speed * 0.8:
				current_action = ActionState.RUN_RELOADING
			else:
				current_action = ActionState.WALK_RELOADING
		else:
			current_action = ActionState.RELOADING
		return
	
	if attack_animation_timer > 0:
		if is_moving:
			current_action = ActionState.RUN_SHOOTING if is_sprinting else ActionState.WALK_SHOOTING
		else:
			current_action = ActionState.ATTACK
		return
	
	if is_moving:
		if is_sprinting:
			current_action = ActionState.RUN_SHOOTING if is_shooting else ActionState.RUN
		else:
			current_action = ActionState.WALK_SHOOTING if is_shooting else ActionState.WALK
	else:
		current_action = ActionState.ATTACK if is_shooting else ActionState.IDLE

func update_animation():
	var animation_prefix = "GUN_"
	var direction_part = ""
	var action_part = ""
	
	if current_direction == Direction.RIGHT:
		direction_part = "RIGHT_" + ("UP_" if current_vertical_aim == VerticalAim.UP else "DOWN_")
	else:
		direction_part = "LEFT_" + ("UP_" if current_vertical_aim == VerticalAim.UP else "DOWN_")
	
	match current_action:
		ActionState.IDLE:
			action_part = "IDLE"
		ActionState.ATTACK:
			action_part = "ATTACK"
		ActionState.RELOADING:
			action_part = "RELOADING"
		ActionState.RUN:
			action_part = "RUN"
		ActionState.WALK:
			action_part = "WALK"
		ActionState.RUN_SHOOTING:
			action_part = "RUN_SHOOTING"
		ActionState.WALK_SHOOTING:
			action_part = "WALK_SHOOTING"
		ActionState.WALK_RELOADING, ActionState.RUN_RELOADING:
			action_part = "WALK_RELOADING"
		ActionState.DEATH:
			action_part = "DEATH"
	
	var animation_name = animation_prefix + direction_part + action_part
	
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		var fallback_name = "GUN_RIGHT_DOWN_IDLE"
		if animated_sprite.sprite_frames.has_animation(fallback_name):
			animated_sprite.play(fallback_name)
		else:
			print("Animation not found: ", animation_name, " and fallback also not found: ", fallback_name)
	
	update_gun_position()

func update_gun_position():
	if current_direction == Direction.RIGHT:
		gun.scale.x = 1
		gun.rotation_degrees = -45 if current_vertical_aim == VerticalAim.UP else 45
	else:
		gun.scale.x = -1
		gun.rotation_degrees = -135 if current_vertical_aim == VerticalAim.UP else 135

func _on_hitbox_area_2d_body_entered(body: Node2D) -> void:
	if body is Enemy:
		GameScene.player_hp -= 1
		update_hp_bar()
		if GameScene.player_hp <= 0:
			die()

func die():
	current_action = ActionState.DEATH
	death_shadow.visible = true
	var shadow_anim = "GUN_"
	if current_direction == Direction.RIGHT:
		shadow_anim += "RIGHT_"
	else:
		shadow_anim += "LEFT_"
	if current_vertical_aim == VerticalAim.UP:
		shadow_anim += "UP_"
	else:
		shadow_anim += "DOWN_"

	shadow_anim += "DEATH"
	death_shadow.play(shadow_anim)
	update_animation()
	await animated_sprite.animation_finished
	await death_shadow.animation_finished
	GameScene.player_hp = 4
	get_tree().call_deferred("reload_current_scene")

func update_hp_bar():
	var hp_animation = str(min(GameScene.player_hp, 4)) + "_hp"
	if %HPBar.sprite_frames.has_animation(hp_animation):
		%HPBar.play(hp_animation)
	else:
		print("HP animation not found: ", hp_animation)

func _on_ammo_changed(current, maximum):
	if !$CanvasLayer.has_node("AmmoCounter"):
		var ammo_label = Label.new()
		ammo_label.name = "AmmoCounter"
		ammo_label.add_theme_font_size_override("font_size", 24)
		ammo_label.position = Vector2(150, 58)
		$CanvasLayer.add_child(ammo_label)
	
	$CanvasLayer/AmmoCounter.text = str(current) + "/" + str(maximum)

func _on_started_reloading():
	if audio_player and audio_player.stream:
		#audio_player.stream = preload("res://path_to_reload_sound.wav")
		audio_player.play()
	
	if $CanvasLayer.has_node("AmmoCounter"):
		$CanvasLayer/AmmoCounter.modulate = Color(1.0, 0.5, 0.0)

func _on_finished_reloading():
	if audio_player and audio_player.stream:
		#audio_player.stream = preload("res://path_to_reload_complete_sound.wav")
		audio_player.play()
	
	if $CanvasLayer.has_node("AmmoCounter"):
		$CanvasLayer/AmmoCounter.modulate = Color(1.0, 1.0, 1.0)
