extends KinematicBody2D

signal miss

export var speed = 800
var velocity
var current_miss_method


func init(bullet_global_position, bullet_rotation, miss_method):
	global_position = bullet_global_position
	rotation = bullet_rotation
	velocity = speed * Vector2.UP.rotated(rotation)
	current_miss_method = miss_method


func _ready():
	var status = connect("miss", get_parent(), current_miss_method)
	if status != OK:
		print("Error connecting bullet " + name)


func _physics_process(_delta):
	velocity = move_and_slide(velocity, Vector2.UP)


func _on_VisibilityNotifier2D_screen_exited():
	emit_signal("miss")
	queue_free()
