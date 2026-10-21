# Leximancer campaign level plan

## Direction

Plan for **10 campaign levels**, with the existing three forming the opening of the game. Keep levels short, locations and encounters varied, story scenes brisk, and rewards arriving steadily. Exact playtime targets and reward placements are still to be decided.

This document records the current first three levels and provides editable planning slots for levels 4–10. Entries marked **Current** describe the project as it exists. **TBD** fields are decisions to make, not implemented features.

The map has seven disabled `Level N / Coming soon` buttons. They reserve space only; they are not registered playable levels. Their grid positions are temporary and do not prescribe the final journey or biomes.

## Campaign overview

| # | Level | Status | Encounter format | Enemies | Completion / reward |
|---|---|---|---|---|---|
| 1 | Castle Walls | Current | Wave defence | Soldier grunts, scouts, tank, boss variant | Opens Grasslands; item reward TBD |
| 2 | Grasslands | Current | Wave defence | Soldiers and slimes | Opens Seaside Farm; item reward TBD |
| 3 | Seaside Farm | Current | Wave defence | Slimes and boss slimes | Thistle joins in dialogue; item reward TBD |
| 4 | TBD | Map placeholder | TBD | TBD | TBD |
| 5 | TBD | Map placeholder | TBD | TBD | TBD |
| 6 | TBD | Map placeholder | TBD | TBD | TBD |
| 7 | TBD | Map placeholder | TBD | TBD | TBD |
| 8 | TBD | Map placeholder | TBD | TBD | TBD |
| 9 | TBD | Map placeholder | TBD | TBD | TBD |
| 10 | TBD | Map placeholder | TBD | TBD | TBD |

## Existing shared systems

- All three levels currently allow Basic Magic Turret, Chain Lightning Tower, and Ice Tower. These are not yet distributed as campaign unlocks.
- Character pieces, colors, staffs, and four fireball spells already have loadout definitions and an item-unlock API. Many are available in the starting unlock list. Campaign completion does not currently award specific items.
- Campaign progression currently opens the next level after completing its prerequisite. Progress is reset when the campaign-progress autoload starts; persistent progression needs a separate design pass for the future unlock system.
- Existing `boss` and `boss_slime` enemies are strong enemies inside ordinary waves. They are not the proposed standalone boss encounter format.
- There is no per-level analytics implementation added by this plan.

## Level 1 — Castle Walls

| Field | Current design |
|---|---|
| Level ID | `castle_walls` |
| Entry requirement | First campaign level; no previous-level requirement |
| Setting / visual design | Castle fortifications and gate, stone paths, water, and the city perimeter |
| Objective / format | Defend the castle gate against five waves |
| Enemy roster | Soldier family: `grunt`, `scout`, `tank`, `boss` |
| Encounter pacing | 32 scheduled enemies across five waves: 5 / 6 / 6 / 7 / 8. Spawn intervals tighten from 1.6s to 1.25s. Scouts enter in wave 2; a tank and boss variant enter in wave 5. |
| Typing progression | Easy words at first, mixing in medium words as waves progress |
| Opening-level support | Level script sets enemy scale and speed multiplier to 0.7 |
| Towers | Basic Magic Turret, Chain Lightning Tower, Ice Tower |
| Music | `assets/bgm/5- The Gauntlet and the Dragon.ogg` |
| Confirmed completion unlock | Grasslands |
| Item / spell / cosmetic reward | No level-specific item award currently wired; TBD |
| Target duration / bonus objective | TBD; record measured playtime before setting a target |

Story and dialogue:

1. **Map introduction:** Jisho wakes the player and urges them to investigate trouble at the Castle Walls.
2. **Level introduction:** Saborus has sent soldiers to steal the Gem of Creation. Jisho tells the player to stop them breaking the gate.
3. **Level conclusion:** The defence succeeds, but a friendly soldier reports that Saborus breached the eastern wall and stole the gem during the battle.
4. **Map transition:** The king asks the player and Jisho to recover the gem. They follow the retreating minions east toward the grasslands.

Design role: establish the typing-and-defence loop, introduce fast and durable soldiers, and turn a local defence into the main pursuit. This is a reading of the existing content, not an additional tutorial implementation.

Sources: [level data](../campaign/levels/castle_walls.tres), [waves](../campaign/waves/castle_wall_waves.gd), [battlefield](../scenes/game/levels/castle_walls.tscn), [intro / outro dialogue folder](../data/dialogue/campaign/castle_walls/), [map dialogue folder](../data/dialogue/campaign/world_map/).

## Level 2 — Grasslands

| Field | Current design |
|---|---|
| Level ID | `grasslands` |
| Entry requirement | Complete Castle Walls |
| Setting / visual design | Open countryside, an old church, grassy ground, paths, and water |
| Objective / format | Protect the church against five waves |
| Enemy roster | Soldier and slime families: `grunt`, `scout`, `tank`, `boss`, `slime` |
| Encounter pacing | 39 scheduled enemies: 7 / 7 / 9 / 8 / 8. Spawn intervals tighten from 1.35s to 0.95s. Slimes appear alongside soldiers in wave 1; tanks arrive in wave 2; a boss variant appears in wave 5. |
| Typing progression | Easy and medium initially; hard words enter in wave 3 and dominate the final wave, with some easier individual enemies retained |
| Towers | Basic Magic Turret, Chain Lightning Tower, Ice Tower |
| Audio | Wind ambience: `assets/bgm/ambience/wind-blowing-nature-ambience.mp3` |
| Confirmed completion unlock | Seaside Farm |
| Item / spell / cosmetic reward | No level-specific item award currently wired; TBD |
| Target duration / bonus objective | TBD |

Story and dialogue:

1. **Level introduction:** Jisho notices minions approaching an old church. Slimes accompanying the soldiers suggest Saborus is already using the gem to create creatures.
2. **Level conclusion:** The church was empty and there are no surviving minions to question. Jisho wonders whether Saborus can fully control his creations yet.
3. **Map transition:** A large slime trail leads toward the coast. Jisho speculates about giant merged slimes, magical slimes, and slime jelly while the player remains unimpressed.

Design role: expand the enemy mix, increase typing pressure, and show the stolen gem affecting the world while retaining the comic contrast between Jisho and the player.

Sources: [level data](../campaign/levels/grasslands.tres), [waves](../campaign/waves/grasslands_waves.gd), [battlefield](../scenes/game/levels/grasslands.tscn), [intro / outro dialogue folder](../data/dialogue/campaign/grasslands/), [map dialogue folder](../data/dialogue/campaign/world_map/).

## Level 3 — Seaside Farm

| Field | Current design |
|---|---|
| Level ID | `seaside_farm` |
| Entry requirement | Complete Grasslands |
| Setting / visual design | Goblin sheep farm beside the sea, with farm paths, fencing, sheep, and animated goblins |
| Objective / format | Defend the sheep pen against five waves |
| Enemy roster | Slime family: `slime`, `boss_slime`; no soldier enemies scheduled |
| Encounter pacing | 44 scheduled enemies: 9 / 9 / 9 / 9 / 8. Spawn intervals tighten from 1.2s to 0.8s. Boss slimes appear from wave 2; wave 5 contains three. |
| Typing progression | Mixed easy / medium / hard assignments; medium is the main wave pool, with a medium / hard pool in wave 2 |
| Towers | Basic Magic Turret, Chain Lightning Tower, Ice Tower |
| Audio | Beach ambience: `assets/bgm/ambience/beach_ambience.mp3`; sheep baa effects |
| Confirmed completion result | Current final playable campaign level; Thistle joins the party in the story |
| Item / spell / cosmetic reward | No level-specific item award currently wired. Thistle is a narrative companion here, not an implemented unlockable ability. |
| Target duration / bonus objective | TBD |

Story and dialogue:

1. **Level introduction:** A goblin begs the player and Jisho to protect the sheep. Only slimes are approaching; Jisho wonders what happened to the soldiers.
2. **Level conclusion:** The grateful goblin reports that Saborus's creatures headed inland toward the dark woods. The goblin offers Thistle, a sheep, as thanks. Jisho accepts him as a potential tactical distraction.
3. **Current map return:** A temporary end-of-content conversation thanks the player and points to Endless Mode and custom word lists. Replace this scene's role when the campaign continues beyond level 3.
4. **Continuity for level 4:** The existing story points toward dark woods and now includes Thistle. The next level's name, enemies, encounter format, and rewards remain TBD.

Design role: shift to a slime-focused encounter, add a new setting and supporting cast, and establish the next story destination without committing to its gameplay yet.

Sources: [level data](../campaign/levels/seaside_farm.tres), [waves](../campaign/waves/seaside_farm_waves.gd), [battlefield](../scenes/game/levels/seaside_farm.tscn), [intro / outro dialogue folder](../data/dialogue/campaign/seaside_farm/), [current end-of-content map dialogue](../data/dialogue/campaign/world_map/map_after_seaside_farm_dialogue.tres).

## Level 4 — TBD

- **Name / biome / visual design:** TBD. Existing story lead: inland toward the dark woods.
- **Format / objective / target duration:** TBD.
- **Enemies / new mechanic / typing difficulty:** TBD.
- **Art / music / sound:** TBD.
- **Intro / encounter / outro / map story beats:** TBD. Account for Thistle joining the party.
- **Unlocks / bonuses / reward condition:** TBD.
- **Connection to next level:** TBD.

## Level 5 — TBD

- **Name / biome / visual design:** TBD.
- **Format / objective / target duration:** TBD.
- **Enemies / new mechanic / typing difficulty:** TBD.
- **Art / music / sound:** TBD.
- **Intro / encounter / outro / map story beats:** TBD.
- **Unlocks / bonuses / reward condition:** TBD.
- **Connection to next level:** TBD.

## Level 6 — TBD

- **Name / biome / visual design:** TBD.
- **Format / objective / target duration:** TBD.
- **Enemies / new mechanic / typing difficulty:** TBD.
- **Art / music / sound:** TBD.
- **Intro / encounter / outro / map story beats:** TBD.
- **Unlocks / bonuses / reward condition:** TBD.
- **Connection to next level:** TBD.

## Level 7 — TBD

- **Name / biome / visual design:** TBD.
- **Format / objective / target duration:** TBD.
- **Enemies / new mechanic / typing difficulty:** TBD.
- **Art / music / sound:** TBD.
- **Intro / encounter / outro / map story beats:** TBD.
- **Unlocks / bonuses / reward condition:** TBD.
- **Connection to next level:** TBD.

## Level 8 — TBD

- **Name / biome / visual design:** TBD.
- **Format / objective / target duration:** TBD.
- **Enemies / new mechanic / typing difficulty:** TBD.
- **Art / music / sound:** TBD.
- **Intro / encounter / outro / map story beats:** TBD.
- **Unlocks / bonuses / reward condition:** TBD.
- **Connection to next level:** TBD.

## Level 9 — TBD

- **Name / biome / visual design:** TBD.
- **Format / objective / target duration:** TBD.
- **Enemies / new mechanic / typing difficulty:** TBD.
- **Art / music / sound:** TBD.
- **Intro / encounter / outro / map story beats:** TBD.
- **Unlocks / bonuses / reward condition:** TBD.
- **Connection to next level:** TBD.

## Level 10 — TBD

- **Name / biome / visual design:** TBD.
- **Format / objective / target duration:** TBD.
- **Enemies / new mechanic / typing difficulty:** TBD.
- **Art / music / sound:** TBD.
- **Intro / encounter / outro / ending story beats:** TBD.
- **Unlocks / bonuses / reward condition:** TBD.
- **Campaign resolution / postgame:** TBD.

## Future planning decisions

- **Reward distribution:** Assign character sprite pieces, spells, wands / staffs, towers, and abilities across the ten levels. Decide starter equipment, completion rewards, optional bonuses, and whether any rewards require replaying a level. Keep the intended steady cadence without making repeat clears compulsory for core progression.
- **Boss encounters:** Decide which slots use a dedicated single-antagonist encounter, and whether boss fights count within the ten levels or sit between them. Define the different typing interactions and encounter rhythm before building the system. No slot is assigned a boss fight yet.
- **Story expansion:** Preserve the Saborus / Gem of Creation pursuit, Jisho's exuberance, the player's restrained responses, and Thistle's arrival. Plan dialogue scenes alongside each level rather than filling the gaps with longer exposition.
- **Analytics:** Plan average WPM per level, accuracy, active typing time, clear duration, and attempt outcome. Decide how WPM is calculated, which pauses / dialogue are excluded, and whether results stay local or are sent anywhere. Tracking is future work.
- **Pacing:** Choose short playtime targets after measuring the existing levels. Introduce variety through enemy behavior, environments, encounters, and rewards rather than simply adding more waves.

Supporting definitions: [campaign progression](../scripts/CampaignProgress.gd), [player loadout / starting unlocks](../scenes/game/player/player_loadout.gd), [tower definitions](../data/towers/tower_definitions.gd), [enemy definitions](../data/enemies/enemy_definitions.gd).
