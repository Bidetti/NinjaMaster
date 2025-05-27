extends Area2D
class_name EnemyProjectile

@export var speed: float = 150.0
@export var damage: int = 1
@export var lifetime: float = 3.0
@export var gravity_enabled: bool = false
@export var gravity_strength: float = 98.0

var direction: Vector2 = Vector2.RIGHT
var velocity_vector: Vector2
var initial_speed: float

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	setup_projectile()
	setup_connections()
	setup_lifetime_timer()

func setup_projectile():
	initial_speed = speed
	velocity_vector = direction * speed
	rotation = direction.angle()

func setup_connections():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup_lifetime_timer():
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_timeout)

func _physics_process(delta):
	update_movement(delta)
	update_rotation()

func update_movement(delta):
	if gravity_enabled:
		apply_gravity(delta)
	
	position += velocity_vector * delta

func apply_gravity(delta):
	velocity_vector.y += gravity_strength * delta

func update_rotation():
	if gravity_enabled:
		rotation = velocity_vector.angle()

func _on_body_entered(body):
	handle_collision_with_body(body)

func _on_area_entered(area):
	handle_collision_with_area(area)

func handle_collision_with_body(body):
	if body is Player:
		destroy_projectile()
	elif body.has_method("take_damage") and not body is EnemyBase:
		destroy_projectile()
	elif not body is EnemyBase:
		destroy_projectile()

func handle_collision_with_area(area):
	if not area.get_parent() is EnemyBase:
		destroy_projectile()

func destroy_projectile():
	create_impact_effect()
	queue_free()

func create_impact_effect():
	if sprite:
		var tween = create_tween()
		tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.1)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.1)

func _on_lifetime_timeout():
	destroy_projectile()
