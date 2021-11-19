extends RigidBody2D

signal shoot
signal hit

export var acceleration_coef = 1200
export var aim_speed = 80
export var recoil = 5000
export var hit_impulse = 800
export var shield_radius = 48
export (PackedScene) var Bullet
export var current_miss_method = ""
onready var initial_radius = $Collision.shape.radius
onready var initial_explosion_vol = $ExplosionSound.volume_db
var acceleration = Vector2()
var aim_direction = 1
var is_dead = false
var _has_shield = false


func add_shield():
	if _has_shield:
		return
	
	$Body.modulate.a *= 0.5
	$Collision.shape.radius = shield_radius
	_set_shield(true)


func _set_shield(value):
	_has_shield = value
	update()


func _process(delta):
	acceleration.x = 0
	acceleration.y = 0
	if is_dead:
		return
	
	var left_pressed = Input.is_action_pressed("ui_left")
	var right_pressed = Input.is_action_pressed("ui_right")
	var up_pressed = Input.is_action_pressed("ui_up")
	var down_pressed = Input.is_action_pressed("ui_down")
	if left_pressed and not right_pressed:
		acceleration.x = -1
	if right_pressed and not left_pressed:
		acceleration.x = 1
	if up_pressed and not down_pressed:
		acceleration.y = -1
	if down_pressed and not up_pressed:
		acceleration.y = 1
	acceleration = acceleration.normalized() * acceleration_coef
	
	var is_cannon_cold = $ShootTimer.is_stopped()
	if Input.is_action_just_pressed("ui_select") and is_cannon_cold:
		var bullet = Bullet.instance()
		bullet.init(
			$CannonPath/Aim.global_position,
			$Cannon.rotation,
			current_miss_method
		)
		get_parent().add_child(bullet)
		acceleration -= Vector2.UP.rotated($Cannon.rotation) * recoil
		aim_direction *= -1
		$CannonPath/Aim/Muzzle.restart()
		$Cannon/AnimationPlayer.play("Shoot")
		$ShootTimer.start()
		$ShotSound.play()
		emit_signal("shoot")
	
	$CannonPath/Aim.offset += aim_speed * aim_direction * delta
	$Cannon.rotation = $CannonPath/Aim.unit_offset * PI * 2


func _integrate_forces(_state):
	applied_force = acceleration


func _draw():
	if _has_shield:
		draw_circle(Vector2.ZERO, shield_radius, Color(1, 1, 1, 0.5))


func _on_Player_body_entered(body):
	if not is_dead and body.layers & 2 != 0:
		if _has_shield:
			_set_shield(false)
			$Body.modulate.a *= 2
			$Collision.shape.radius = initial_radius
			$ExplosionSound.volume_db -= 3
		else:
			var impulse = body.linear_velocity.normalized() * hit_impulse
			apply_central_impulse(impulse)
			is_dead = true
			emit_signal("hit")
			$ExplosionSound.volume_db = initial_explosion_vol
		$ExplosionSound.play()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Shoot":
		$Cannon/AnimationPlayer.play("Idle")
