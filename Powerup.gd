extends Area2D

signal get

export var speed = 200
var current_get_method
var linear_velocity = Vector2()


func init(get_method):
	current_get_method = get_method


func _ready():
	var status = connect("get", get_parent(), current_get_method)
	if status != OK:
		print("Error connecting powerup " + name)


func _process(delta):
	position += linear_velocity * delta


func _on_Powerup_body_entered(body):
	if body.layers & 1 != 0 && not body.is_dead:
		emit_signal("get")
		queue_free()
