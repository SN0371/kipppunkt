class_name SimMath
extends RefCounted
## Small numeric helpers shared by the simulation systems.


## Moves a value towards a target by a fraction of the difference (rechenmodell.md section 0).
static func approach(value: float, target: float, rate: float) -> float:
	return value + rate * (target - value)


## Clamps a value to the default range of most indicators, 0..100.
static func clamp100(value: float) -> float:
	return clampf(value, 0.0, 100.0)


## Returns a point uniformly distributed in a disc of the given radius around the origin.
static func random_point_in_disc(radius: float, rng: RandomNumberGenerator) -> Vector2:
	var angle := rng.randf() * TAU
	var distance := radius * sqrt(rng.randf())
	return Vector2.from_angle(angle) * distance


## Returns true with the given probability.
static func chance(probability: float, rng: RandomNumberGenerator) -> bool:
	return rng.randf() < probability
