extends CanvasLayer


func _on_AnimationPlayer_animation_finished(_anim_name):
	$Multiplier/AnimationPlayer.stop()
