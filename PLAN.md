# CALAMITY — Expansion Plan (locked 2026-07-04)

Execution order: A → B → C → D → E → F → G. Each phase committed + pushed separately.

## Phase A — IMPACT: destruction physics + feel
- Directional toppling: tall buildings fall sideways as rotating slabs (away from the killing blow),
  crushing units/people/cars in the arc, slamming neighbors → chain topples (damage falloff cap)
- Structural integrity: carve out a building's base band → it fails and topples toward the wound
  even above 0 hp ("cut the legs")
- Lethal debris: tumbling frags kill people, damage units, crack facades they hit
- Rubble mounds: dead buildings = jagged heaps with embedded chunks + night embers, units slowed crossing
- Dynamic fire light: burning buildings cast flickering light pools (pooled PointLight2D, cap 6);
  lightning strikes flash-light the scene
- Impact frames: 1-2 white/black full-screen frames on citadel falls + topple landings
- Layered SFX: every big hit = sub-thump + crack + debris tail (multi-pass synth); new topple groan, crush
- CUT: heat shimmer (needs fire mask in screen space; cost > payoff at 640×360)

## Phase B — CHARACTER IDENTITY
- 2–4 frame animation cycles for all five gods (walk/fly/idle breathing/attack)
- Swarm rework: real locust sprites boiling in the mass; scatter + reform on hit
- Per-god aura FX: keraunos idle arc + gathering storm overhead; tzitzi feather trail + dimming;
  drowned drip + leaping fish; rider fog withers lamps/grass it touches
- Per-god SFX kits: locust buzz loop (scales with size), scythe shing, distance-delayed thunder,
  madden whisper, eclipse drone, REAPING bell
- Unit anims: soldier walk, tank recoil, 2-frame death flips

## Phase C — LIVING WORLD
- Weather per city: Maren rain + wet reflections, Ashport ash flurries, Thornspire fog banks, Teotl fireflies
- Ambient beds per city: gulls/swell, industrial drone, wind + far bells, jungle insects, traffic hum
- City events: chained gas mains, news chopper (feeds fear), bells on threat spikes, evac sirens
- Foreground silhouette layer: wires/poles/fences sliding in front

## Phase D — MUSIC
- Threat-layered stems: dark ambient base → percussion at tier 3 → full dread at 5; LAST RESORT cue;
  menu + map themes. Synced AudioStreamPlayers, crossfade on tier change.

## Phase E — SYSTEMS DEPTH
- New army answers: flamethrower crews (anti-swarm), priests (bless/heal), named hero champions
  (mini-boss humans with health bars at high threat)
- Capstone evolution: one ultimate node per branch (tier-4 pick)
- Skirmish mutators: night start, glass city, double army, daily seed
- End-of-run stats screen + local bests
- Map: node shows objective before committing
- Balance pass after user playtest notes

## Phase F — ROGUE ROADS (FTL-style Act 2 map)
- Node fates: every non-city node rolls a visible modifier at crusade start — route choice = build choice.
  Pool: RICH FEEDING (+essence), GARRISONED (+defense/+tribute), CULT SHRINE (small permanent ally),
  ROAR BEACON (+Roar), REFUGEE COLUMN (crowds everywhere), STORM CROSSING (weather + charge diets feast),
  QUIET ROADS (−World Alert), HUNTER'S TRAIL (Stalker herald closes faster), RELIC RUMOR, TITHE ROAD (+tribute)
- Travel events (deck ~12): text card, two choices, real trade-offs
  (eat the pilgrim caravan: +essence +alert / let it pass: −alert; a lesser beast offers fealty: ally / eat it: essence…)
- All rolls seeded per crusade → every run's map plays different

## Phase G — THE ROAR + HERALDS (power attracts power)
- THE ROAR: campaign-wide signal meter fed by everything devoured, never resets, visible on map.
  Thresholds pull heralds down. Devouring the 3rd herald's heart = Act 3 trigger.
- Per crusade: 3 heralds drawn RANDOM from a pool of 10 (mid-Act-2 interception, late roamer, post-capital gate).
  Each grants a GRAFT (permanent ability outside the evolution tree) + growth-cap raise (1.75 → 2.2 → 2.6).
- Duels are three-way: the army shoots you both. Cities remain the arena — collateral scores, toppled
  buildings are weapons.

### Herald roster (10)
1. THE GRAZER — sky-fallen grazer-kaiju; eats YOUR buildings; race or duel.
   Graft: GRAVITY MAW — orbit a block's rubble, release as shrapnel storm.
2. THE STALKER — void predator; roams the map razing nodes until intercepted; hunts only you.
   Graft: PREDATOR SHIFT — blink with a counter window.
3. THE HOLLOW KING — hollow earth; erupts from below, burrows, opens chasms that swallow buildings.
   Graft: FAULTLINE — slam opens a chasm that devours units/buildings for essence.
4. THE GATECRASH — other dimension; enters through a tear, teleports, portals spit lesser horrors.
   Graft: RIFT STEP — place a tear pair; you and your allies pass through.
5. THE ECHO — YOUR future self; mirror duel with your own god, kit and branch turned against you.
   Graft: PARADOX — summon your echo as a temporary ally.
6. THE SERAPH ASCENDANT — heaven's answer; smiting light columns, wards districts.
   Graft: HALO OF RUIN — stolen smite column.
7. THE TIDE OF TEETH — rival deep-space horde; out-swarms you with thousands.
   Graft: SPAWN BROOD — kills spawn broodling allies.
8. THE RUST SAINT — machine god seed; converts the city into armored machine-self as it grows.
   Graft: ASSIMILATE — devoured mass armors you (temporary shield).
9. THE MOURNING VEIL — psychic leech; feeds on the fear YOU generate; deny or burst it.
   Graft: DREAD MANTLE — panic near you knits your body (fear lifesteal).
10. THE FIRSTBORN CALAMITY — the original apocalypse, woken to put down the pretender; colossal phase fight.
    Graft: OLD CROWN — +growth cap, all diets +15%.

## Act 3 (parked)
Galaxy map reuses crusade-map architecture: star systems as nodes, themed worlds as cities,
apex beings as garrisons, grafts as base kit. Endgame: what the heralds served.
