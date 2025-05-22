extends CharacterBody2D
class_name EnemyBase

signal enemy_died(enemy)

@export var max_hp: int = 3
@export var move_speed: float = 50
@export var damage: int = 1
@export var points_value: int = 10

var current_hp: int
var player_ref: Player
var is_dead: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $HitBox
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready():
	current_hp = max_hp
	player_ref = get_tree().get_first_node_in_group("player")
	
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta):
	if is_dead or not player_ref:
		return
	
	move_towards_player(delta)
	move_and_slide()

func move_towards_player(delta):
	if player_ref and not is_dead:
		var direction = (player_ref.global_position - global_position).normalized()
		velocity = direction * move_speed
		
		update_sprite_direction(direction)

func update_sprite_direction(direction: Vector2):
	pass

func take_damage(amount: int):
	if is_dead:
		return
	
	current_hp -= amount
	
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	if current_hp <= 0:
		die()

func die():
	if is_dead:
		return
	
	is_dead = true
	collision_shape.set_deferred("disabled", true)
	
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	
	enemy_died.emit(self)
	queue_free()

func _on_hitbox_body_entered(body):
	if body is Player and not is_dead:
		pass

func special_behavior():
	pass
