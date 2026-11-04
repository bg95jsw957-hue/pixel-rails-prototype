extends Node

## Autoload bridge: owns PRWorld, exposes to UI. Rendering stays elsewhere.

var world: PRWorld

func _ready() -> void:
	world = PRWorld.new()

func reset_world() -> void:
	world = PRWorld.new()
