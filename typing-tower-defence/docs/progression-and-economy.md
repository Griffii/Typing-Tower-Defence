# Progression, unlocks, and economy

## Status and direction

This is a design plan. It does not implement saving, purchases, new spells, or the map shop. Firm direction comes from the agreed campaign design. Names, prices, reward values, and detailed balance rules below are proposals for testing.

The campaign has one persistent gold balance. Players spend it on permanent upgrades, spells, tower access, and cosmetics. Unspent gold carries between levels and play sessions. Campaign milestones make items available; buying them grants ownership.

Endless has a separate economy for each run. Its gold and upgrade ranks never enter the campaign. Encountering a campaign word pool unlocks it for Endless without a gold purchase.

See the [campaign plan](campaign-level-plan.md) and [story](story.md).

## How the player grows

| Progression | How it is earned | What persists |
|---|---|---|
| Typing skill | Practice against varied enemies and vocabulary | Player knowledge |
| Spell collection | Meet a campaign requirement, then buy the spell | Ownership and chosen loadout |
| Word Damage, Special Damage, Special Charge | Meet rank requirements, then buy each rank | Shared campaign upgrade ranks |
| Tower collection | Meet a campaign requirement, then buy the blueprint | Permission to deploy that tower |
| Tower training | Unlock and buy shared training ranks | Improvements to owned tower types |
| Cosmetics | Meet a discovery or completion requirement, then buy | Appearance options; no combat stats |
| Word pools | Encounter their vocabulary on a campaign enemy | Free selection in Endless |

Start with Fireball, Basic Magic Turret access, basic cosmetics, and a small gold grant. There is always a usable free loadout. Let players equip one special spell before a level. Word completion remains the core attack that charges the special.

Permanent upgrades apply across the player's collection. Buying a new spell should never require rebuying the same damage ranks. Tower training also applies to later tower purchases.

## Unlock and purchase states

Use four visible states: **Undiscovered → Locked → Available → Owned**.

Undiscovered items show a silhouette and a vague hint. Locked items show their requirement. Available items show their gold price and effect. Owned items can be equipped without further payment. An unaffordable item stays Available.

Completing a milestone opens access. It does not silently spend gold. Buying access to a spell or tower is a single permanent purchase. Do not charge a separate research fee before that purchase. Upgrade ranks have their own gates and prices.

For example: completing Grasslands makes Frostbolt available. Buying it grants permanent ownership. The player can then switch between Fireball and Frostbolt freely. Neither spell loses the shared Special Damage upgrades.

## Five spell types

Propose **five total types: the starter and four purchases**. These are special spells, matching the current equipped projectile system. Visual variants of a type can be sold as cosmetics. The existing four fireball definitions are not four distinct progression roles.

| Spell | Available | Proposed price | Base direct damage | Role, visual, and tradeoff |
|---|---|---|---|---|
| Fireball | Starter; owned | Free | 10 | Orange burst with the widest reliable splash. Best against dense groups. |
| Frostbolt | After level 2 | 200 | 11 | Blue ice shard. Slows its target; small splash and no broad damage burst. |
| Chain Spark | After level 3 | 400 | 12 | Yellow branching arcs. Hits separated targets through a limited chain; weaker damage on later jumps. |
| Stone Lance | After level 5 | 800 | 13 | Stone spike. Strong against armour and targets in a line; narrow aim and no radial splash. |
| Rift Pulse | After level 7 | 1,400 | 14 | Violet spatial distortion. Brief disruption in a small area; costs more special charge per cast. |

Higher base damage alone would make old spells worse versions of new ones. Keep the damage steps modest. Give each type a useful target pattern or control effect. Fireball must retain its group-damage advantage at the end of the campaign.

Proposed campaign formulas:

```text
Word damage = 10 + 2 × Word Damage rank
Special direct damage = equipped spell base damage + 4 × Special Damage rank
```

Define splash, chains, and damage-over-time from that same upgraded special damage with explicit effect multipliers. Apply each hit and kill reward once. Shared upgrades must improve secondary effects too. Special Charge improves charge earned per completed word, with a cap. Rift Pulse's greater charge requirement remains meaningful at that cap.

Do not grant blanket immunity to early spells. Compare damage per charge, crowd damage, and control value. Test every spell against late campaign enemies and boss windows. Exact radii, charge costs, durations, and multipliers remain open.

## Towers and cosmetics

Basic Magic Turret access is owned at the start. Propose Chain Lightning access after level 1 for 180 gold. Propose Ice Tower access after level 3 for 300 gold. A fourth support tower could become available after level 6 for 600 gold. Its role and implementation remain open; do not require it for progression.

Separate **owning a blueprint** from **placing a tower**. The blueprint is a permanent purchase. Each placement spends campaign gold during a level and uses its existing build slots. That spending is nonrefundable. Towers provide temporary assistance and do not carry to the next map.

Propose shared tower training with four gated ranks. Damage towers gain damage. Control towers gain a capped control benefit instead. Preserve the existing distinction between damage towers and the zero-damage Ice Tower. Do not add individual tower levelling to the first progression pass.

Cosmetics share the campaign wallet. Offer small purchases throughout the journey and expensive prestige items later. Suggested starting bands are 40–100 gold for colours, 100–250 for pieces or spell visuals, and 400–800 for prestige sets. Cosmetic staffs have no hidden combat stats. Make this clear before purchase.

## Campaign reward schedule

These are proposed availability milestones. They do not award the listed purchases for free. Each level also offers themed cosmetics. Word pools unlock separately on encounter.

| Milestone | New shop access | Permanent rank ceiling |
|---|---|---|
| Start | Fireball and Basic Magic Turret owned; starter appearance | Word / Special Damage 1; Special Charge 1 |
| 1. Castle Walls cleared | Chain Lightning blueprint; castle cosmetics | Word / Special Damage 2; tower training 1 |
| 2. Grasslands cleared | Frostbolt; creation-themed cosmetics | No new rank ceiling |
| 3. Seaside Farm cleared | Chain Spark; Ice Tower blueprint; farm cosmetics | Word / Special Damage 3; Special Charge 2; tower training 2 |
| 4. Dark Woods cleared | Forest cosmetics and spell visuals | No new rank ceiling |
| 5. The Bent Quarry cleared | Stone Lance; quarry cosmetics | Word / Special Damage 4; Special Charge 3; tower training 3 |
| 6. Stillday Village cleared | Optional fourth tower blueprint; village cosmetics | Word / Special Damage 5 |
| 7. World's Edge Observatory cleared | Rift Pulse; observatory cosmetics | Special Charge 4; tower training 4 |
| 8. The Unfinished World cleared | Unfinished-world cosmetics | Word / Special Damage 6 |
| 9. The Final Rewrite cleared | Finale prestige cosmetics | Full collection remains available for replay |

Unlock gates use the highest completed milestone. Replaying an early level never lowers a ceiling. Prices depend on the purchase or rank, not the currently selected level.

## Persistent campaign gold

Earn gold from enemy defeats and level rewards. Credit kills once regardless of whether typing, a spell, or a tower delivers the final blow. Keep earned gold and permanent purchases after victory, defeat, retry, or returning to the map. Persist across app restarts too.

Tower deployment is a permanent expense for temporary assistance. Other spending rules below remain proposals:

- Deduct tower placement costs from the campaign wallet immediately. No gold returns when a tower is removed or when an attempt ends in victory, defeat, retry, or abandonment. Restarting the app does not restore spent deployment gold.
- Do not offer tower selling for gold. Blueprint ownership persists, but each new deployment requires another payment. Permanent-purchase refunds never include deployment spending.
- Repairs are consumables for the current attempt. Base HP resets for a new attempt. A proposed capped repair allowance is refunded on a failed attempt to prevent repeated defeats consuming all progress; exact allowance needs testing.
- Offer full-price refunds of permanent combat purchases from the map shop. Refund upgrade ranks in reverse order. Do not refund an item while its dependent purchases remain owned. This lets players recover from a build that does not suit them.

Players choose between relying on their typing ability and spending savings for assistance now. Using towers delays permanent upgrades or collection purchases. Balance every campaign level for a viable clear without towers. Towers should ease pressure without becoming a compulsory expense.

Use a proposed 150-gold starting grant once per campaign save. A penniless player can still enter any unlocked level, type, use Fireball, and earn gold. No level should require owning a specific paid spell or tower. A no-gold retry must remain viable.

## Price and income scaling

Replace the current linear upgrade prices with increasing rank prices. Use content gates to prevent early farming from buying the whole campaign's power. Do not raise prices just because the player has saved gold.

Proposed prices below are the cost of each rank, not cumulative totals:

| Upgrade | Rank 1 | Rank 2 | Rank 3 | Rank 4 | Rank 5 | Rank 6 |
|---|---|---|---|---|---|---|
| Word Damage | 60 | 110 | 200 | 360 | 650 | 1,170 |
| Special Damage | 80 | 145 | 260 | 470 | 850 | 1,530 |
| Special Charge | 70 | 140 | 280 | 560 | — | — |
| Tower training | 100 | 200 | 400 | 800 | — | — |

Word and Special Damage prices grow by about 1.8× per rank. Charge and tower training prices double. Keep effects and maximum ranks explicit. The campaign rank caps and values are separate from Endless tuning.

Proposed gross income targets for a full first clear:

| Level | Target gold | Cumulative gold, excluding starting grant |
|---|---|---|
| 1 | 400 | 400 |
| 2 | 550 | 950 |
| 3 | 700 | 1,650 |
| 4 | 900 | 2,550 |
| 5 | 1,150 | 3,700 |
| 6 | 1,450 | 5,150 |
| 7 | 1,800 | 6,950 |
| 8 | 2,200 | 9,150 |
| 9 | 2,700 | 11,850 |

These are new balance targets, not measured current rewards. Start by assigning roughly 70% to repeatable kill and clear rewards and 30% to a one-time first-clear bonus. Replays retain repeatable rewards. Failed attempts retain earned kill gold but receive no clear bonus. First-clear rewards must be granted once per save.

Tune rewards against measured completion time as well as enemy count. An early level cleared instantly should not outperform later levels in gold per minute. Replaying for savings is allowed. Balance the main path for one clear per level, without compulsory farming or accuracy bonuses.

A sample full-campaign spending path costs 9,445 gold: Word Damage 6 (2,550), Special Damage 4 (955), Special Charge 2 (210), tower training 2 (300), four spells (2,800), three tower blueprints (1,080), cosmetics (350), net repairs (300), and tower deployments (900). Against 12,000 total income including the starting grant, this leaves 2,555 for other ranks or cosmetics. The deployment allowance is illustrative, not a required spend or a promise that any tower setup fits it. Verify affordability at each milestone, including repeat deployment costs after failed attempts.

A player who skips those deployments saves the full 900 gold for permanent purchases. A player who uses towers frequently may buy fewer upgrades, delay cosmetics, or replay levels to earn more gold. Tune placement prices against the pressure they relieve and the permanent purchases they delay. Do not balance the main path around spending the entire wallet on towers.

Propose removing Gold Gain from campaign purchases. A permanent income multiplier risks becoming the compulsory first purchase and makes replay farming harder to balance. Retain a separately tuned Gold Gain option within Endless runs. If campaign Gold Gain is retained later, cap it and model its payback before setting a price.

Enemy HP, movement, word length, spawn density, and boss windows must scale together. Do not multiply all five pressures at every level. Set expected damage ranks for each encounter and test a weaker build too. Increased power should reduce words needed to defeat familiar enemies; later enemies introduce new decisions rather than cancelling every upgrade with matching HP growth.

## Spelling within the world

Proposed lore: Spelling reads and disrupts the magical patterns that hold a creature's form together. Its displayed words express its nature, training, or altered state. Completing a word destabilises that pattern. A surviving enemy reveals another word from the same vocabulary.

Early vocabulary sounds natural to the kingdom. Abstract language appears as Saborus's experiments reach deeper rules. Do not use simulation terminology on early enemies or reveal undiscovered late pools by name in menus.

| First planned appearance | Enemy or phenomenon | Pool theme | Example words |
|---|---|---|---|
| Castle Walls | Grunts, scouts, tanks, commanders | Soldier vocabulary, with subtype tags | guard, march, flank, shield, command |
| Grasslands | Slimes | New life and fluid forms | ooze, gel, divide, absorb |
| Seaside Farm | Independent slime variants | Instinct and choice | seek, wander, choose, evade |
| Dark Woods | Altered plants and animals | Growth and transformation | root, thorn, graft, mutate |
| The Bent Quarry | Matter or gravity constructs | Stone, force, and space | ore, mass, drift, orbit, fracture |
| Stillday Village | Repeated or restored creatures | Time and causality | echo, repeat, before, restore |
| World's Edge Observatory | Boundary creatures | Astronomy and limits | star, lens, horizon, boundary |
| The Unfinished World | Incomplete constructs | Underlying structure | mesh, state, instance, buffer |
| The Final Rewrite | Erasure constructs and Saborus | Creation and erasure | undo, erase, null, persist |

The later enemy types and all new pool names are proposals. A biome does not force every enemy into its pool. A soldier in the forest still uses soldier vocabulary unless it is an explicitly transformed variant.

Keep theme and difficulty as separate fields. Each pool needs short, medium, and long words where possible. Select by enemy identity first, then the encounter's difficulty band. Scouts can use short movement words; tanks can use longer defensive words. Do not make every thematic word difficult.

Use the same selection rules for initial words and replacement words. Prevent ambiguous simultaneous targets where possible. Keep target words readable through visual distortions. A missing or empty difficulty band falls back to nearby approved words in the same theme, then to a safe generic pool. Log the missing content for correction. A fallback does not count as encountering the intended pool.

## Word discoveries and Endless

Mark a pool encountered when an active campaign enemy first displays a valid word drawn from it. Merely loading the level, preloading an enemy, or reading a preview does not count. Save the discovery immediately. Defeat does not revoke it. One word unlocks the whole thematic pool for Endless, including its difficulty bands.

Show a brief “Vocabulary discovered” notice and add the pool to the player's grimoire. The grimoire records its source enemy, theme, and available difficulty bands. Discovery is knowledge, so no gold fee applies.

Keep starter generic lists available. Keep custom word lists available without campaign gates. Separate these from discoverable campaign vocabulary. Existing noncampaign lists need an explicit migration classification; do not silently lock a user's custom content.

Endless offers an enemy-themed setting using discovered pools and a custom setting using selected available lists. In enemy-themed play, filter out enemy variants whose required pool has not been discovered. If there are no valid pools, offer starter generic play. Custom lists can override enemy themes because the player explicitly selected that mode.

## Endless economy boundaries

Every new Endless run starts with its own configured gold grant and zero purchased upgrade ranks. Gold, repairs, tower placements, and run upgrades end with that run. Neither mode transfers gold to the other. Training also stays outside campaign finance and discoveries.

Propose allowing campaign-owned spells, tower blueprints, and cosmetics as Endless loadout options. Campaign mastery ranks and tower training do not apply. Any upgrades bought in Endless are temporary and cannot buy permanent ownership.

This means Endless has equal starting finances, but campaign progression can expand its available loadouts. Record the equipped spell, tower access, difficulty, pool selection, and balance version with scores. If a fully equal-access competitive mode is added, define it separately. Do not promise identical score conditions across different collections.

## World-map shop and replays

Add a **Shop** tab fixed to the right edge of the screen. It stays in place while the map pans. Opening it shows campaign gold and sections for Upgrades, Spells, Tower Blueprints, and Cosmetics. The map shop sells permanent tower access; it provides no build menu or placement controls.

Hide Repair, Build Mode, and Next Wave in map context. Provide Close and return focus to the tab. Prevent map dragging and level launch while the shop is open. Disable opening it during story dialogue. The between-wave shop uses the same prices, ownership, and campaign wallet, plus its battlefield repair and build controls.

Show current rank, next effect, price, and milestone requirement before buying. Preview spells and cosmetics. Require an explicit purchase action rather than charging on selection. Explain permanent blueprint access separately from nonrefundable deployment costs. The build interface must make clear that placement spends campaign savings for this attempt only.

Earlier campaign levels retain their original encounter difficulty. Players can replay them with new spells and stronger upgrades. Save personal best scores with the loadout, upgrade ranks, difficulty, and score rules version. Give replayable clear rewards, but never repeat first-clear rewards or ownership grants.

## Saving and implementation order

Save campaign gold, completions, first-clear claims, available and owned catalog IDs, upgrade ranks, vocabulary discoveries, equipped items, and personal bests. Use stable IDs and a versioned save. Preserve existing owned cosmetics and spells during migration. Do not infer a purchase from a default starter list.

Treat spending gold and granting an item as one saved transaction. Save reward claims with the credit that they grant. Persist tower deployment charges immediately and apply each charge once. Recovering from an interrupted attempt must not restore spent deployment gold or charge it again. Autosave after purchases, rewards, discoveries, and attempt settlement. Do not maintain independent mutable gold balances in the map and combat scenes.

Suggested implementation order:

1. Add versioned campaign saving and one authoritative wallet. Remove automatic campaign reset at startup. Preserve Endless and training isolation.
2. Add catalog states, purchase validation, rank gates, and refunds. Route combat purchases through the same service.
3. Add the right-side map shop and its context controls.
4. Make equipped spell base damage participate in special damage. Add spell roles and shared tower training.
5. Add themed pools, spawn and replacement rules, discovery saving, and Endless selection filters.
6. Tune rewards, prices, difficulty, and score recording against complete campaign paths.

Required validation includes save/reload; defeat and retry; abandoning a level; interrupted deployment recovery; duplicate reward callbacks; map and battlefield purchases; switching to Endless and back; retaining a discovery after defeat; and importing an old loadout save. Verify that deployment spending remains deducted on every exit path and that campaign levels remain viable without tower spending.

Measure gold earned and spent per level, time to afford the next meaningful purchase, upgrade choices, words per kill, clear rate, and replay income per minute. Check a spell-focused build, a tower-focused build, a cosmetic spender, and a player who buys no optional content. Test chronological affordability and recovery from a failed attempt. Final numbers need playtesting.

## Current implementation reference

Campaign upgrade ranks already carry between levels in memory. Campaign progress resets on startup. Combat gold resets per run. Player loadout ownership has a separate save. Upgrade prices are linear. All three current towers and four fireball variants are broadly available.

Equipped spell data currently supplies projectile visuals and effects, but player special firing overwrites its base damage with CombatManager's special damage. The new base values need one authoritative damage calculation before they affect play.

Existing word assignment supports list IDs per enemy and per wave. It does not yet provide the planned themed discovery system.

Relevant files: [campaign progress](../scripts/CampaignProgress.gd), [combat manager](../scripts/managers/combat_manager.gd), [shop definitions](../data/shop/shop_definitions.gd), [shop overlay](../scenes/menus/shop_menu_overlay.gd), [loadout](../scenes/game/player/player_loadout.gd), [spell definitions](../data/player/spell_definitions.gd), [player special](../scenes/game/player/player.gd), [tower definitions](../data/towers/tower_definitions.gd), [spawn manager](../scripts/managers/spawn_manager.gd), and [word-list manager](../scripts/WordListManager.gd).
