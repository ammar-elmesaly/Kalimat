extends Node

func map(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
	return (value - in_min) / (in_max - in_min) * (out_max - out_min) + out_min
