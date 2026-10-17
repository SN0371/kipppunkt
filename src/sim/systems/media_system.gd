class_name MediaSystem
extends RefCounted
## Media houses: reach, credibility and tone towards the party (rechenmodell.md section 5.6).

## Credibility a house tends towards at independence 0.
const CREDIBILITY_FLOOR := 20.0
## Credibility gained per point of newsroom independence.
const CREDIBILITY_PER_INDEPENDENCE := 0.7


## Returns the credibility a house converges to for a given newsroom independence (Ziel_Glaub_m).
static func target_credibility(independence: float) -> float:
	return CREDIBILITY_FLOOR + CREDIBILITY_PER_INDEPENDENCE * independence
