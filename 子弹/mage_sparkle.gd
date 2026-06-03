extends GPUParticles2D

@onready var cleanup_timer: Timer = $CleanupTimer

func _ready():
	emitting = true
	cleanup_timer.start(lifetime + 0.5)

func _on_cleanup_timer_timeout():
	queue_free()
