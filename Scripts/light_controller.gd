extends SpotLight3D

@export var actuation_percentage: float = 0.0

func execute(_percentage: float) -> void:
	print(_percentage)
	light_energy = (_percentage*100.0)
