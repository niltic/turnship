extends RigidBody2D

signal hit

export var speed = 100
var current_hit_method


func init(hit_method):
	current_hit_method = hit_method


func _ready():
	var status = connect("hit", get_parent(), current_hit_method)
	if status != OK:
		print("Error connecting enemy " + name)


func _on_VisibilityNotifier2D_screen_exited():
	queue_free()


func _on_Enemy_body_entered(body):
	$Body.hide()
	$Collision.set_deferred("disabled", true)
	$DeathExplosion.restart()
	$DeathTimer.start()
	emit_signal("hit", position)
	if body.name in "Bullet":
		body.queue_free()


func _on_DeathTimer_timeout():
	queue_free()
