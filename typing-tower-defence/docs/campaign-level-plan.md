# Leximancer campaign level plan

## Direction

Plan for **9 campaign levels**, with the existing three forming the opening of the game. Keep levels short, locations and encounters varied, story scenes brisk, and rewards arriving steadily. Exact playtime targets and reward placements are still to be decided.

Saborus steals the Gem of Creation to investigate the true nature of reality. His experiments grow from creating life to rewriting the world's fundamental rules. The Player and Jisho follow the damage across the kingdom without initially knowing his intentions. When Saborus discovers their world is a simulation, he decides to erase it, believing he is freeing everyone. The finale affirms that lives, relationships, and experiences still have meaning within an artificial world. See the [story direction](story.md) for his motivation and the reveal arc.

This document records the current first three levels and the planned direction for levels 4–9. **Current** entries describe implemented content. **Planned** entries describe story and setting direction. **Proposed** encounters are starting points for design. **TBD** fields remain open decisions.

The map has six disabled buttons named for levels 4–9. They reserve space only; they are not registered playable levels. Their grid positions are temporary and do not prescribe the final journey.

The [progression and economy plan](progression-and-economy.md) covers persistent campaign gold, milestone access followed by purchases, five spell types, tower blueprints, cosmetics, enemy-themed vocabulary, and the separate Endless economy. Its prices and reward schedule are proposals for testing.

## Campaign overview

| # | Level | Environment | What Saborus is testing | Encounter / status |
|---|---|---|---|---|
| 1 | Castle Walls | Medieval castle siege | Stealing the Gem | Current wave defence; soldiers and a boss variant |
| 2 | Grasslands | Old church, green plains | Creating new life | Current wave defence; soldiers and slimes |
| 3 | Seaside Farm | Coastal goblin farm | Whether creations can act independently | Current wave defence; slimes and boss slimes |
| 4 | Dark Woods | Twisted magical forest | Rewriting living organisms | Planned; proposed boss finale |
| 5 | The Bent Quarry | Mountains, mines, floating terrain | Manipulating matter, gravity, and space | Planned; proposed wave defence with changing routes |
| 6 | Stillday Village | Picturesque village stuck in a loop | Rewriting previous states and causality | Planned; proposed loop-based defence |
| 7 | World's Edge Observatory | Ancient mountaintop observatory | Breaking the boundaries of reality | Planned; proposed boss finale and simulation reveal |
| 8 | The Unfinished World | Broken, incomplete simulation | Accessing the underlying system | Planned; proposed defence across unstable fragments |
| 9 | The Final Rewrite | Collapsing fragments of the world | Erasing reality itself | Planned; final confrontation with Saborus |

Proposed dedicated boss fights sit within levels 4, 7, and 9. They do not add levels to the nine-level total. Boss identities and mechanics remain open, except for Saborus as the final antagonist.

## Existing shared systems

- All three levels currently allow Basic Magic Turret, Chain Lightning Tower, and Ice Tower. These are not yet distributed as campaign unlocks.
- Character pieces, colors, staffs, and four fireball spells already have loadout definitions and an item-unlock API. Many are available in the starting unlock list. Campaign completion does not currently award specific items.
- Campaign progression currently opens the next level after completing its prerequisite. Progress is reset when the campaign-progress autoload starts. Persistent saving and unlock management are planned in the progression document.
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
4. **Continuity for level 4:** The existing story points toward Dark Woods and now includes Thistle. Enemies, encounter details, and rewards remain to be designed.

Planned story emphasis: the missing soldiers and the slimes' behaviour raise the question of whether created life can act independently. Show an observable choice by a creation in future dialogue or encounter design. The current scenes do not yet establish that answer.

Design role: shift to a slime-focused encounter, add a new setting and supporting cast, and establish the next story destination without committing to its gameplay yet.

Sources: [level data](../campaign/levels/seaside_farm.tres), [waves](../campaign/waves/seaside_farm_waves.gd), [battlefield](../scenes/game/levels/seaside_farm.tscn), [intro / outro dialogue folder](../data/dialogue/campaign/seaside_farm/), [current end-of-content map dialogue](../data/dialogue/campaign/world_map/map_after_seaside_farm_dialogue.tres).

## Level 4 — Dark Woods

**Planned setting:** A twisted magical forest. Saborus is rewriting living organisms rather than creating new ones.

Proposed story beats:

1. Follow the goblins' lead inland with Thistle in the party.
2. Encounter familiar plants and animals changed into bizarre forms. Show the cost to existing life.
3. Discover evidence that the changes are deliberate experiments. Saborus's wider purpose remains unclear.
4. Follow the disturbances toward the mountain mines.

**Proposed encounter:** Defend a forest refuge, then face a transformed creature as the first dedicated boss. Explore changes of form with clear attack windows. Keep words readable and give each form a clear visual cue.

**Design role:** Make the pursuit more unsettling. Establish that altered lives still matter. Boss identity, enemy roster, typing difficulty, rewards, and duration are TBD.

## Level 5 — The Bent Quarry

**Planned setting:** Mountains, mines, and floating terrain. Saborus is manipulating matter, gravity, and space.

Proposed story beats:

1. Reach a quarry where stone and mining routes no longer obey familiar physical rules.
2. Protect people caught among the displaced terrain.
3. Jisho begins to recognise a pattern: Saborus is testing the world's rules themselves.
4. Trace the next disturbance to a village where time behaves strangely.

**Proposed encounter:** Wave defence around floating quarry routes. Introduce a small number of clearly signalled route or gravity changes between waves. Give players time to understand the new paths.

**Design role:** Expand the experiments beyond biology. Add spatial variety without making typing targets hard to follow. Exact mechanics, enemies, rewards, and duration are TBD.

## Level 6 — Stillday Village

**Planned setting:** A picturesque village stuck in a loop. Saborus is testing whether he can rewrite previous states and causality.

Proposed story beats:

1. Arrive in an apparently peaceful village and notice events repeating.
2. Discover that Saborus is restoring earlier states to test different outcomes.
3. Help the villagers escape the loop. Their experiences give the party another reason to protect this world.
4. Find a lead to the ancient observatory, where Saborus is investigating reality's boundaries.

**Proposed encounter:** Short repeated defence segments with a changing condition each cycle. Clearly show what resets and what the player retains. Avoid requiring a full level replay for each loop.

**Design role:** Move from physical rules to cause and effect. Who remembers each loop, how it ends, enemy behaviour, rewards, and duration are TBD.

## Level 7 — World's Edge Observatory

**Planned setting:** An ancient mountaintop observatory. Saborus is trying to break the boundaries of reality.

Proposed story beats:

1. Reach instruments and records that point toward limits in the world.
2. Witness Saborus's experiments expose a breach beyond those limits.
3. Reveal that their world is an artificial simulation. Show Saborus's disillusionment as a response to this discovery.
4. Pursue him through the breach into an unfinished region.

**Proposed encounter:** Defend the observatory during a breach, then fight a boss shaped by the boundary experiments. Boss identity and its relationship to the observatory remain open.

**Design role:** Deliver the major revelation after six levels of escalating clues. The exact reveal scene, boss mechanics, rewards, and duration are TBD.

## Level 8 — The Unfinished World

**Planned setting:** A broken, incomplete simulation. Saborus is accessing the underlying system.

Proposed story beats:

1. Follow Saborus into unfinished spaces where parts of the world are missing or incomplete.
2. Learn that he now intends to erase everything. He believes this will free its inhabitants from a meaningless existence.
3. The Player and Jisho reject his conclusion. Recall people and creations whose lives they have protected.
4. Reach the point where Saborus begins the final rewrite.

**Proposed encounter:** Defend stable fragments while incomplete terrain and creatures become active. Signal changes before they affect paths or targets. Keep the controls and typing feedback dependable.

**Design role:** Turn the pursuit to recover the Gem into a fight to preserve the world. System visuals, enemies, exact objectives, rewards, and duration are TBD.

## Level 9 — The Final Rewrite

**Planned setting:** Collapsing fragments of the world. Saborus is erasing reality itself.

Proposed story beats:

1. Bring together fragments of earlier locations and reminders of the lives at stake.
2. Confront Saborus as he tries to complete the erasure.
3. Stop the rewrite. Through their choices and shared experiences, the Player and Jisho demonstrate that their world's artificial origin does not erase its meaning.
4. Show the consequences for the kingdom and the party. Keep the simulation revelation true.

**Proposed encounter:** A dedicated final boss fight against Saborus. Use distinct phases that recall earlier experiments, with recovery moments for brief dialogue. Exact phase mechanics remain open.

**Design role:** Resolve the pursuit and its central theme through action as well as dialogue. Saborus's fate, the Gem's fate, the extent of restoration, rewards, duration, and postgame are TBD.

## Future planning decisions

- **Progression balance:** Playtest the availability milestones, purchase prices, and income targets in the [progression plan](progression-and-economy.md). Campaign completion opens shop access; purchases grant ownership. Vocabulary discovery grants free Endless pool access. Keep the main path viable without compulsory replay farming.
- **Boss encounters:** Review the proposed fights within levels 4, 7, and 9. Define their typing interactions and encounter rhythm before building the system. Existing wave boss variants remain separate from this proposed format.
- **Story expansion:** Write the planned scenes alongside each level. Preserve Jisho's exuberance, the Player's restrained responses, and Thistle's arrival. Replace the temporary post-Seaside Farm end-of-content scene when level 4 becomes playable. Keep early dialogue unaware of the simulation and Saborus's eventual erasure plan.
- **Analytics:** Plan average WPM per level, accuracy, active typing time, clear duration, and attempt outcome. Decide how WPM is calculated, which pauses / dialogue are excluded, and whether results stay local or are sent anywhere. Tracking is future work.
- **Pacing:** Choose short playtime targets after measuring the existing levels. Introduce variety through enemy behavior, environments, encounters, and rewards rather than simply adding more waves.

Supporting definitions: [campaign progression](../scripts/CampaignProgress.gd), [player loadout / starting unlocks](../scenes/game/player/player_loadout.gd), [tower definitions](../data/towers/tower_definitions.gd), [enemy definitions](../data/enemies/enemy_definitions.gd).
