extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animate_stripes()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func animate_stripes():
	$AnimateBackground.play("bg")  # Replace "animation_name" with the actual name of your animation
	$AnimateBackground.get_animation("bg").loop = true  # Enable looping
