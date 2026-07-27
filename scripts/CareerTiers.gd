extends RefCounted
class_name CareerTiers
## Static career-mode data: the 7-tier ladder and the bot-strength formula.
## Tiers 1-6 use fictional tournament names (one tournament each); tier 7 is
## the Grand Slams - 4 real-named events instead of one, replayed endlessly.
## No instance state here, just tables and a pure function.

## Index 0 = tier 1 (School League) .. index 5 = tier 6 (World Tour).
## Tier 7 (Grand Slams) is handled separately below - it isn't in this list.
const TIERS: Array[Dictionary] = [
	{"name": "School League", "rounds": ["Semifinal", "Final"]},
	{"name": "Regional Championship", "rounds": ["Quarterfinal", "Semifinal", "Final"]},
	{"name": "National Championship", "rounds": ["Quarterfinal", "Semifinal", "Final"]},
	{"name": "Satellite Tour", "rounds": ["Round of 16", "Quarterfinal", "Semifinal", "Final"]},
	{"name": "Challenger Tour", "rounds": ["Round of 16", "Quarterfinal", "Semifinal", "Final"]},
	{"name": "World Tour", "rounds": ["Round of 32", "Round of 16", "Quarterfinal", "Semifinal", "Final"]},
]

const MAX_TIER := 7  # Grand Slams

const GRAND_SLAMS: Array[String] = ["Australian Open", "French Open", "Wimbledon", "US Open"]
const GRAND_SLAM_ROUNDS: Array = ["Round of 32", "Round of 16", "Quarterfinal", "Semifinal", "Final"]

static func tier_name(tier: int) -> String:
	if tier >= MAX_TIER:
		return "Grand Slams"
	return TIERS[tier - 1]["name"]

static func rounds_for(tier: int) -> Array:
	if tier >= MAX_TIER:
		return GRAND_SLAM_ROUNDS
	return TIERS[tier - 1]["rounds"]

## base: 0.0 at School (tier 1) up to 1.0 at Grand Slams (tier 7). Within a
## tier's own bracket, up to another +0.25 by the final round, so the last
## round of any tier is tougher than that tier's own first round, and a
## Grand Slam Final (~1.25) is meaningfully tougher than "pro" (1.0) - Career
## is meant to keep getting harder, not plateau once you reach the top.
static func strength_for(tier: int, round_index: int, round_count: int) -> float:
	var base: float = float(clampi(tier, 1, MAX_TIER) - 1) / float(MAX_TIER - 1)
	var progress: float = float(round_index) / float(maxi(round_count - 1, 1))
	return base + progress * 0.25
