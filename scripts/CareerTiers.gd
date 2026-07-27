extends RefCounted
class_name CareerTiers
## Static career-mode data: the 8-tier ladder and the bot-strength formula.
## Tiers 1-6 use fictional tournament names (one tournament each); tier 7 is
## the Grand Slams - 4 real-named events instead of one, replayed endlessly.
## Tier 8, Hall of Champions, is a single endless tournament above the Grand
## Slams, using the "elite"/"legendary" strength range from BotAI.gd - it
## unlocks the first time the player wins any Grand Slam (see
## CareerData.record_win). No instance state here, just tables and a pure
## function.

## Index 0 = tier 1 (School League) .. index 5 = tier 6 (World Tour).
## Tier 7 (Grand Slams) and tier 8 (Hall of Champions) are handled separately
## below - they aren't in this list.
const TIERS: Array[Dictionary] = [
	{"name": "School League", "rounds": ["Semifinal", "Final"]},
	{"name": "Regional Championship", "rounds": ["Quarterfinal", "Semifinal", "Final"]},
	{"name": "National Championship", "rounds": ["Quarterfinal", "Semifinal", "Final"]},
	{"name": "Satellite Tour", "rounds": ["Round of 16", "Quarterfinal", "Semifinal", "Final"]},
	{"name": "Challenger Tour", "rounds": ["Round of 16", "Quarterfinal", "Semifinal", "Final"]},
	{"name": "World Tour", "rounds": ["Round of 32", "Round of 16", "Quarterfinal", "Semifinal", "Final"]},
]

const SLAM_TIER := 7
const HALL_TIER := 8
const MAX_TIER := 8

const GRAND_SLAMS: Array[String] = ["Australian Open", "French Open", "Wimbledon", "US Open"]
const GRAND_SLAM_ROUNDS: Array = ["Round of 32", "Round of 16", "Quarterfinal", "Semifinal", "Final"]

const HALL_OF_CHAMPIONS_NAME := "Hall of Champions"
const HALL_OF_CHAMPIONS_ROUNDS: Array = ["Quarterfinal", "Semifinal", "Final"]

static func tier_name(tier: int) -> String:
	if tier >= HALL_TIER:
		return HALL_OF_CHAMPIONS_NAME
	if tier >= SLAM_TIER:
		return "Grand Slams"
	return TIERS[tier - 1]["name"]

static func rounds_for(tier: int) -> Array:
	if tier >= HALL_TIER:
		return HALL_OF_CHAMPIONS_ROUNDS
	if tier >= SLAM_TIER:
		return GRAND_SLAM_ROUNDS
	return TIERS[tier - 1]["rounds"]

## base: 0.0 at School (tier 1) up to 1.0 at Grand Slams (tier 7), same
## formula/range as before tier 8 existed - unchanged so existing Grand Slam
## difficulty doesn't shift. Within a tier's own bracket, up to another +0.25
## by the final round, so a Grand Slam Final peaks at ~1.25. Hall of
## Champions (tier 8) picks up exactly where that peak leaves off and climbs
## to ~1.6 by its own Final, into BotAI's elite/legendary anchor range - the
## ladder keeps getting harder past the Slams instead of plateauing.
static func strength_for(tier: int, round_index: int, round_count: int) -> float:
	var progress: float = float(round_index) / float(maxi(round_count - 1, 1))
	if tier >= HALL_TIER:
		return 1.25 + progress * 0.35
	var base: float = float(clampi(tier, 1, SLAM_TIER) - 1) / float(SLAM_TIER - 1)
	return base + progress * 0.25
