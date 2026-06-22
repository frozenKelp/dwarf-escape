# Dwarven Centrifuge — Game Jam Roadmap

**Jam:** Very Serious Juniper Dev jam · **Theme:** "Spin to Win" · **Engine:** Godot 4 (2D)
**Deadline:** Sat 27 June · **Plan to submit:** Fri 26 June (the 27th is buffer only)

---

## The one rule that decides everything

A small, finished, juicy game beats a big broken one in every jam. You have ~5 days and you've never finished a project before — so the entire plan is built around **reaching a submittable game as early as possible (by Day 2)** and spending the rest of the time making it better, not bigger. If a feature isn't on the path to the MVP below, it waits.

Theme is already baked deep: the centrifuge, the slot machine, the grindwheel and the fan all *spin*. You don't need to chase the theme — protect the centrifuge and it's there.

---

## MVP — the finish line (must exist to submit)

A complete, winnable loop in a single screen:

1. **Mine** → get ore (can be one button/scroll at first).
2. **Refinery / centrifuge** → load ore in the feeder, spin the cast to hold the target band, get refined metal of a quality based on how well you held it.
3. **Delivery** → sell refined metal for money.
4. **Money pays down debt.** Debt hits zero → **you escape (win screen).**

That's the whole game. One win condition. If only this exists, you have a real entry. Everything else is upside.

---

## Shared architecture (read this before splitting work)

The trick that lets several people work at once without colliding: **agree on the interfaces first, then everyone codes against them.** Two interfaces matter — the `GameState` autoload (shared data) and a small set of signals (how systems talk). Lock these on Day 1 morning and don't change them casually.

### Scene tree (single screen)

```
Main (Node2D)
├── Map            (room backgrounds — ColorRects/Sprite/TileMapLayer)
├── Rooms
│   ├── Refinery   (Area2D + CollisionShape2D + Marker2D) → Centrifuge, SlotMachine
│   ├── Mine       (Area2D + CollisionShape2D + Marker2D)
│   ├── Bedroom    (Area2D + CollisionShape2D + Marker2D)
│   └── Delivery   (Area2D + CollisionShape2D + Marker2D) → Shop
├── Player         (Node2D + AnimatedSprite2D)
├── UI             (CanvasLayer → HUD labels, shop panel)
└── Audio          (AudioStreamPlayer)

Autoload: GameState (Node)   ← single source of truth
```

### GameState contract (the backbone — autoload, build it Day 1)

| Kind | Name | Notes |
|---|---|---|
| var | `money: int` | current cash |
| var | `debt: int` | win when this hits 0 |
| var | `ore: Dictionary` | `{ "iron": 3, ... }` |
| var | `refined: Dictionary` | `{ "frost_iron": {qty, quality}, ... }` |
| var | `upgrades: Dictionary` | bought upgrades |
| func | `add_ore(type, n)` | mine calls this |
| func | `consume_ore(type, n) -> bool` | feeder calls this; false if not enough |
| func | `add_refined(type, quality)` | centrifuge calls this on success |
| func | `add_money(n)` / `spend(n) -> bool` | shop/slot call these |
| func | `pay_debt(n)` | check win inside; emit if 0 |
| signal | `money_changed(value)` | UI listens |
| signal | `debt_changed(value)` | UI listens |
| signal | `inventory_changed()` | UI listens |
| signal | `game_won()` | Main shows escape screen |

**Rule:** systems never reach into each other. They read/write `GameState` and emit/listen to signals. This is what makes the centrifuge testable on its own and lets two people work without merge pain.

### Signals between systems (the "API")

- `Centrifuge.refined(metal, quality)` → Economy converts to inventory.
- `Room.room_selected(name)` → Main moves player, activates that station.
- `SlotMachine.jackpot()` → (hidden escape route, later).
- Shop buttons → `GameState.spend()` / `GameState.pay_debt()`.
- Mine → `GameState.add_ore()`.

---

## Workstreams (split these across people)

Each stream owns its own scenes/scripts and talks to the rest only through the contract above. A and B can start in parallel from minute one; C can start with placeholders; D needs only the GameState API.

| Stream | Owner | Depends on | Exposes | Tasks |
|---|---|---|---|---|
| **A. Centrifuge / Refinery core** | lead (you) | nothing (own scene) | `refined(metal, quality)` signal | states (SPIN_UP/HOLD/UNSTABLE), progress + instability, feeder, allow-circle, output |
| **B. GameState + Economy + UI** | data person | nothing | the whole GameState contract | autoload, debug panel, HUD labels, shop (sell/buy/pay debt), win check |
| **C. Rooms + navigation + scene glue** | scene person | A & B scenes (can stub) | assembled `Main` scene | single screen, clickable room zones, teleport-to-marker, room backgrounds, wiring stations into rooms |
| **D. Secondary stations** | second coder | GameState API (B) | self-contained scenes | mine (scroll-wheel → ore), slot machine (spin/bet/payout/jackpot), bedroom fan |
| **E. Art / audio / juice** | artist | everything (layers on last) | sprites, sfx, screens | sprite integration, sfx, sparks/particles, screen shake, music, title + win screens, intro story |

### If you don't have 5 people

- **Solo:** do A → B → C in strict order, skip D's extras, treat the whole "cut list" as cut. Aim for the MVP and polish only.
- **2 people:** P1 = A + D. P2 = B + C. Both pitch in on E at the end.
- **3–4 people:** A, B, and C each get an owner; the 4th takes D then E. Everyone playtests Day 5.

---

## Day-by-day

**Day 1 — Mon 22 · Foundations, in parallel**
- Whole team: agree the GameState contract + signal names (30 min, do this first).
- A: finish centrifuge states + feeder + allow-circle in its own scene; emit `refined()`. Print states so you can watch EMPTY→SPIN_UP→HOLD→UNSTABLE.
- B: build GameState autoload + a debug panel (buttons: add ore, add money, pay debt) to prove it works with no UI.
- C: rough single screen — colored rectangles as rooms, click a room → player teleports to its marker.
- *End of day: three pieces that each run alone.*

**Day 2 — Tue 23 · Integration → reach the MVP**
- Wire `Centrifuge.refined` → GameState inventory.
- Wire delivery/shop: sell metal → money → pay debt → `game_won()` → escape screen.
- C slots the real centrifuge scene into the refinery room.
- *End of day: spin → refine → sell → pay debt → WIN. You now have a submittable game with 4 days left. This is the goal.*

**Day 3 — Wed 24 · Secondary stations + economy**
- Mine (scroll-wheel → ore), slot machine (gamble money, jackpot = hidden escape).
- Shop upgrades (faster spin-up, wider hold band, bigger payout).
- Balance the numbers so the loop feels fair and the debt is beatable in a session.

**Day 4 — Thu 25 · Art, audio, juice**
- Real sprites in one cohesive style; sfx (flywheel whir, clunk, jackpot, sell *cha-ching*); sparks while refining; screen shake + warning sound on UNSTABLE; music.
- Title screen, win/escape screen, and the intro that sets up the debt story.

**Day 5 — Fri 26 · Polish + SHIP**
- Fresh-eyes playtest, fix the top bugs, final balance.
- Export web + desktop builds; confirm a clean download/web build runs first try with no console errors.
- Write the jam page, record a gif + screenshots.
- **Submit today.**

**Day 6 — Sat 27 · Buffer only**
- Final fixes / resubmit if needed. Never plan to finish on deadline day — builds break at the worst moment.

---

## Cut list (only if you're ahead — otherwise these are your "with more time" notes on the jam page)

- Alloys (multi-material feeder + recipes)
- Hidden escape routes: dig out of the mine, rediscover the orichalcum ratio, bribe/kill the delivery guy
- Bedroom / day cycle with the spin-the-fan sleep mechanic
- Multiple metals (frost iron, mithril) with different target bands
- Save system

Players *love* seeing an ambitious "things I'd add" list — it signals vision without costing you the deadline.

## Assets & audio
- Use free CC0 packs so art never blocks code: **Kenney.nl** (cohesive, no attribution) and **itch.io** (filter free/CC0; search dwarf, mine, blacksmith, dungeon). Pick ONE resolution (e.g. 16×16) and palette for instant cohesion.
- Draw only the centrifuge + slot machine yourself, blocky, matching the pack palette.
- SFX from Kenney audio or freesound.org. One short looping track is enough.

## Submission checklist
- [ ] Runs first try from a fresh web/desktop build, no console errors
- [ ] Controls explained on screen or on the page (the spin gesture especially)
- [ ] "Spin to win" is unmistakable within 10 seconds of play
- [ ] Title screen + a way to restart
- [ ] Win/escape screen fires when debt hits 0
- [ ] Jam page: gif + 2–3 screenshots + short description + controls + asset credits
- [ ] Submitted on the 26th, not the 27th
