# res://data/campaign/campaign_level_registry.gd
extends RefCounted

const LEVELS: Array[CampaignLevelData] = [
	preload("res://campaign/levels/castle_walls.tres"),
	preload("res://campaign/levels/grasslands.tres"),
	preload("res://campaign/levels/seaside_farm.tres"),
]
