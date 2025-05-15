extends Node2D
class_name Gun

signal ammo_changed(current, maximum)
signal started_reloading
signal finished_reloading

@export var ammo: int = 30
@export var max_ammo: int = 30
@export var reload_time: float = 1.5
@export var fire_rate: float = 0.2
@export var bullet_scene: PackedScene

var is_reloading: bool = false
var can_shoot: bool = true

@onready var bullet_spawn = $BulletSpawn
@onready var reload_timer = $ReloadTimer
@onready var shoot_timer = $ShootTimer
@onready var audio_player = $AudioStreamPlayer2D

func _ready():
	reload_timer.wait_time = reload_time
	shoot_timer.wait_time = fire_rate
	emit_signal("ammo_changed", ammo, max_ammo)

func shoot(direction: Vector2):
	if ammo <= 0 or !can_shoot or is_reloading:
		return false
		
	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	bullet.direction = direction
	
	get_tree().root.add_child(bullet)
	
	ammo -= 1
	emit_signal("ammo_changed", ammo, max_ammo)
	
	can_shoot = false
	shoot_timer.start()
	
	audio_player.play()
	return true

func reload():
	if is_reloading or ammo == max_ammo:
		return false
		
	is_reloading = true
	emit_signal("started_reloading")
	reload_timer.start()
	return true

func _on_shoot_timer_timeout():
	can_shoot = true

func _on_reload_timer_timeout():
	ammo = max_ammo
	is_reloading = false
	emit_signal("finished_reloading")
	emit_signal("ammo_changed", ammo, max_ammo)
