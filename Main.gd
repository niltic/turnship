extends Node

export var enemies_per_level = 10
export (PackedScene) var Enemy
export (PackedScene) var Powerup
export var shot_shake = 2
export var enemy_hit_shake = 5
export var player_hit_shake = 10
onready var focusInitPos = $Focus.position
var score = 0
var hi_score = 0
var multiplier = 0
var is_player_first_hit = false
var is_enemy_hit = false
var level = 1
var number_of_enemies = 0
var enemies_before_powerup
var shake
const MAX_LEVEL = 5
const SAVE_FILE_PATH = "user://turnship.save"


func _ready():
	randomize()
	$Player.set_process(false)
	$HUD/Paused.set_process(false)
	_set_enemies_before_powerup()
	
	var save_file = File.new()
	if save_file.file_exists(SAVE_FILE_PATH):
		save_file.open(SAVE_FILE_PATH, File.READ)
		hi_score = save_file.get_32()
		save_file.close()
	
	$HUD/Score.text = "High Score: " + str(hi_score)


func _set_enemies_before_powerup():
	enemies_before_powerup = floor(rand_range(40, 50))


func _process(_delta):
	if $HUD/StartLayer.visible:
		_process_start_state()
	else:
		_process_game_state()


func _process_start_state():
	if Input.is_action_just_pressed("ui_select"):
		$HUD/StartLayer.visible = false
		$Player.set_process(true)
		$HUD/Paused.set_process(true)
		$StartTimer.start()
		$AcceptSound.play()

func _process_game_state():	
	$HUD/Score.text = "Score: " + str(score)
	$HUD/Multiplier.margin_left = \
		$HUD/Score.rect_position.x + $HUD/Score.get_minimum_size().x
	if (not $HUD/Multiplier/AnimationPlayer.is_playing()
			and multiplier == 0):
		$HUD/Multiplier.visible = false
	elif multiplier != 0:
		$HUD/Multiplier.text = " +" + str(multiplier)
	
	if not $ShakeTimer.is_stopped():
		$Focus.position.x = focusInitPos.x + rand_range(-shake, shake)
		$Focus.position.y = focusInitPos.y + rand_range(-shake, shake)


func _on_StartTimer_timeout():
	$SpawnTimer.start()


func _on_SpawnTimer_timeout():
	var spawned
	var spawned_dir
	if enemies_before_powerup == 0:
		spawned = Powerup.instance()
		spawned.init("_on_Powerup_get")
		_set_enemies_before_powerup()
		spawned_dir = rand_range(-PI / 12, PI / 12)
	else:
		spawned = Enemy.instance()
		spawned.init("_on_Enemy_hit")
		spawned_dir = rand_range(-PI / 4, PI / 4)
	$SpawnerPath/Spawner.offset = randi()
	spawned.position = $SpawnerPath/Spawner.position
	var spawner_rotation = $SpawnerPath/Spawner.rotation
	spawned_dir += spawner_rotation
	spawned.linear_velocity = Vector2.DOWN.rotated(spawned_dir) * spawned.speed
	add_child(spawned)
	
	number_of_enemies += 1
	if level < MAX_LEVEL and number_of_enemies == enemies_per_level:
		$SpawnTimer.wait_time *= 0.75
		number_of_enemies = 0
		level += 1
	
	enemies_before_powerup -= 1


func _on_Enemy_hit(enemy_position):
	if not $Player.is_dead:
		multiplier += 1
		score += multiplier
		$HUD/Multiplier.visible = multiplier > 1
		$HUD/Multiplier/AnimationPlayer.play("Change")
		$ExplosionSound.position = enemy_position
		$ExplosionSound.pitch_scale = 1.0 + min(10, multiplier - 1) / 10.0
		$ExplosionSound.play()
	is_enemy_hit = true
	shake = enemy_hit_shake
	$ShakeTimer.start(0.25)


func _on_Powerup_get():
	$Player.add_shield()


func _on_Player_hit():
	multiplier = 0
	$RestartTimer.start()
	shake = player_hit_shake
	$ShakeTimer.start(1)
	$BGM.stop()


func _on_Player_shoot():
	shake = shot_shake
	$ShakeTimer.start(0.1)


func _on_Bullet_miss():
	if not is_enemy_hit:
		multiplier = 0
	is_enemy_hit = false


func _on_RestartTimer_timeout():
	if score > hi_score:
		var save_file = File.new()
		save_file.open(SAVE_FILE_PATH, File.WRITE)
		save_file.store_32(score)
		save_file.close()
	
	var status = get_tree().reload_current_scene()
	if status != OK:
		print("Error reloading the scene.")


func _on_ShakeTimer_timeout():
	$Focus.position = focusInitPos
