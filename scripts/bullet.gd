extends Area2D
class_name Bullet

@export var speed: float = 300.0
@export var damage: int = 1
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT

func _ready():
    var timer = get_tree().create_timer(lifetime)
    timer.timeout.connect(_on_lifetime_timeout)
    
    rotation = direction.angle()

func _physics_process(delta):
    position += direction * speed * delta

func _on_body_entered(body):
    if body is Enemy and body.has_method("take_damage"):
        body.take_damage(damage)
        # Optional: Add bullet impact effects here
        queue_free() # Destroy bullet on hit

func _on_lifetime_timeout():
    queue_free()