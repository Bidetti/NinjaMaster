extends Area2D
class_name EnemyProjectile

@export var speed: float = 150.0
@export var damage: int = 1
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_timeout)
	
	rotation = direction.angle()
	
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body is Player:
		queue_free()
	elif body.has_method("take_damage") and not body is EnemyBase:
		queue_free()

func _on_lifetime_timeout():
	queue_free()
