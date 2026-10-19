# Grammarite project guide

Reviewed October 18, 2026. This is a source review and working reference, not a complete playtest. Recheck relevant files before making changes; the project is actively edited.

## Project identity and entry point

The Godot project is named `Pokemon Godot`, with Godot 4.7 recorded in its features. It is a 2D, tile-based creature RPG with grammar questions integrated into combat. The viewport is 240 × 160, displayed at 1200 × 800. Custom actions use Z to confirm/interact, X to cancel, Enter for the menu, and Q for running or context-specific actions. Movement uses the built-in directional actions.

`project.godot` starts `Scenes/SceneManager.tscn`. Its persistent root contains `CurrentScene`, initially instancing `Scenes/Town.scn`, plus menu, dialogue, selection, fade transition, area label, and Grammadex notification nodes. `Autoload/utils.gd` is the sole configured autoload (`Utils`).

## Architecture

| System | Main files | Responsibilities |
| --- | --- | --- |
| Shared state and data | `Autoload/utils.gd` | JSON access, inventory, party, species, encounters, quests, recipes, discovery, money, question selection, save slots |
| Scene flow | `Scripts/SceneManager.gd` | Fade-driven scene/menu transitions, naming requests, battle entry/exit, recovery at a center |
| Movement | `Scripts/Player.gd`, `Scenes/Player.tscn` | 16-pixel tile movement, directional turning, running, raycast interactions, doors, ledge jumps, camera and animation |
| Dialogue and triggers | `Dialogue.gd`, `DialogueNode.gd`, `Hitbox.gd`, `AreaHitbox.gd` | Branching conversations, function calls, area triggers and location labels |
| Combat | `BattleManager.gd`, `BattleUI.gd`, `BattleGrammarite.gd`, `BattleStarter.gd`, `Scenes/Battle.tscn` | Turn flow, AI, PP, questions, damage, items, capture, fainting, XP, evolution |
| Menus | `Menu.gd`, `PartyScreen.gd`, `PartySlot.gd`, `SelectScene.gd` | Modal state, six-member party, summaries, moves, equipment, switching, release, selection |
| Inventory and economy | `ItemScreen.gd`, `ShopScreen.gd` | Item categories, healing and held items, capture books, purchases and shop stock |
| Storage and collection | `BookScreen.gd`, `ComputerScreen.gd` | Bookshelf deposits/withdrawals/swaps, Grammadex browsing, summaries, computer healing shortcut |
| Crafting | `HarvestScreen.gd`, `CrafterScreen.gd`, `Machine.gd` | Convert a creature into a type shard; combine two distinct shard types into an item or creature |
| Quests | `QuestScreen.gd`, `UpdateQuest.gd` | Quest board, acceptance, progress states, objectives and counters |
| World actors | `Trainer.gd`, `TrainerSideways.gd`, `GrassManager.gd`, `Door.gd`, `Sign.gd`, `Item.gd`, `GrammaritePickup.gd` | NPC approaches and interactions, encounters, transitions, pickups |
| World progression | `Wall.gd`, `Lever.gd`, `Covers.gd`, `Scripts/Specialized/*` | Obstacles, room covers, starter cutscene, username sequence, power plant progression, electrical wire puzzle |
| Presentation | `Effect.gd`, `BlowUp.gd`, `Explosion.gd`, `Streaks.gd`, `LabelForNewArea.gd`, `Shaders/*` | Temporary effects, pixel explosions, battle spectacle, location announcements, water and greyscale effects |

Most communication runs through `Utils.get_scene_manager()` and fixed node paths. Modal control is distributed between `Menu.ScreenLoaded`, individual UI state enums, player physics processing, and animation state. Changes to screen flow should trace all four.

## World and story structure

`Town.scn` is the large shared overworld, containing region labels for Homegrown Town, Tech Town, Lluvia City, Concrete Jungle, The Heights, Podunkville, and Grawaii. Its resources include multiple terrain styles, grass encounters, trainers, blockers, doors, houses and centers. Do not assume each region is a separate scene.

`Cave.scn` supplies the cave/Royal Grotto area, encounter rocks, center and castle access. Both `.scn` files are compressed binary scenes. Their resource and string contents were inspected without instantiating them; this does not verify their visual layout or every serialized property. There is also a separate `Cave.tscn`, which should not be assumed equivalent to `Cave.scn`.

Text scenes include player and rival homes, School, OaksLab, TechTownHome, ChiefStaticHome, PowerPlant, Castle, and the center interior. School's scripted office sequence handles the three starter choices (Dog of Wood, Kittebook, Moustapler), rival dialogue and opening the park blockade. The power plant uses levers, coils, trainers and cutscenes; its Destroyer updates the final-room and cave-blockade flags. Electrical boxes require a Keycard and open a three-wire matching puzzle.

Dialogue and animation tracks contain substantial gameplay logic: calls such as `begin_battle`, `pull`, `play`, `begin_from_self`, naming and player movement control live in scenes as well as scripts. A script-only search is insufficient for safely renaming functions.

`Assets/Items/test.gd` also contains a four-lane rhythm minigame with randomized speed/pattern settings and a hit/miss result. Its filename alone does not describe its behavior; verify scene integration before treating it as disposable test code.

## Data model and persistence

- `GrammariteData/` contains authored definitions: 36 species, 78 moves, 38 items, 11 types, evolutions, base moves, trainers, recipes, shops, questions, quests and center locations.
- `Data/` is mutable working state: inventory/party, bookshelf, discovery flags, quest progress, scene flags, shop stock and miscellaneous progress.
- `Saves/1`, `Saves/2`, `Saves/3` contain slot snapshots. Six files are copied by the save helpers: Bookshelf, Inventory, OtherStuff, Quests, Scenes and Grammadex. Shop is excluded.
- Party members use `Name`, `Nickname`, `Level`, `Health`, `Item`, `Moves`, `PP`. Most code assumes exactly six party slots and four moves/PP values for occupied slots. Empty slots use an empty name, and some constructors differ in their empty move arrays.
- The fractional part of `Level` stores XP progress; battle presentation casts the level to an integer. Do not replace fractional levels with integers in persisted data.
- `Names.json` establishes species index. Sprite files use `Assets/Pokemon/Pokemon{index + 1}.png`. Evolution checks use parallel index-based arrays and advance to the next species in this ordered list.
- Scene state is indexed by root scene name, category (`Items`, `Trainers`, `Obstacles`), then exact node name. Renaming an actor can break lookups or existing saves.
- Several authored JSON files have trailing commas. Strict external JSON parsers reject those files; do not equate this alone with a confirmed Godot runtime failure.

`Utils._ready()` runs `reset_scenes()`, resetting item/trainer/obstacle flags, hiding quest-gated obstacles and restoring shop stock. Ordinary runtime operations also write into `res://Data/`, and slot operations write into `res://Saves/`. Launching the game is therefore not a read-only verification step. File access and JSON parsing currently lack failure handling. Exported persistence should be reviewed separately before distribution.

## Combat and questions

Wild battles encode species and a three-digit level into a `random...` trainer string. Trainer battles load named party/level arrays. The scene manager hides the overworld while adding the battle, then restores it after victory or escape; defeat routes to the last center.

The active player creature is party index zero. BattleManager maintains separate per-slot status and stat multiplier dictionaries. Initial speed determines which side begins; subsequent action handling generally alternates. AI scores moves by damage, accuracy, PP, type effectiveness and randomness, and may advance to another enemy when health is low. Damage includes type effectiveness, same-type and native-move bonuses, critical hits, held-item effects and randomness.

Fight selects a move, asks a question, and emits a move index on success, `-1` for Struggle when PP is exhausted, `-2` for a wrong answer, or `-3` for the Semicolon special attack. Capture books work during wild battles and add creatures to the party or bookshelf. Victory grants fractional-level XP and trainer money; evolution follows species ordering.

Question banks contain Vocabulary, Syntax and Punctuation categories. Grade 3 and Grade 4 each have 250 entries; Grade 5 has 150. The legacy bank has 38 entries and generates distractors. The current battle UI explicitly requests Grade 5. The grade-based selector tracks used IDs in memory and returns an empty dictionary when exhausted.

## Existing issues to account for

These are observations from source inspection, not changes made or an exhaustive bug list.

1. **Question result mismatch:** `BattleUI.ask_question()` displays a grade-based question, but ordinary answer submission passes a fresh `Utils.get_question()` result to `handle_question_result()`. Wrong-answer explanations can therefore describe a different question. The grade selector's empty result is also indexed without a guard.
2. **Status dictionary casing:** attack effects are appended with `Name`/`Duration`, while several status-processing paths read `name`/`duration`. Other paths read uppercase duration. These schemas need reconciliation before relying on status behavior.
3. **Save loading:** `SaveScreen.gd` calls `transition_exit_save_screen()`, which is absent from the inspected SceneManager script. Slot clearing constructs quest entries with `Progess: None`, whereas quest readers expect `Progress` and states such as `Unstarted`.
4. **Storage limits:** the bookshelf screen displays 25 slots and current working data has 25 entries, but `Utils.add_to_bookshelf()` scans only the first 12, and clearing a save initializes 12 slots.
5. **Discovery length:** current `Data/Grammadex.json` has 35 entries for 36 species; discovery helpers index it directly by species number.
6. **Resource references:** `ComputerScreen.gd` requests `Assets/UI/Fonts.tres`; the inspected font resource is `Assets/UI/Plain/Fonts.tres`. `Cave.tscn` references absent `Scenes/Town.tscn`; the actual overworld is `Town.scn`. Shop preload capitalization differs from the on-disk `shopscreen.tscn`, which matters on case-sensitive systems.
7. **Identifier spelling:** battle checks include `Hypen` and `Glasses`, while authored item names include `Hyphen` and `Reading Glasses`. `Commander Isold` has two party entries but three level entries; trainer arrays should be checked together when editing encounters.
8. **Battle switching:** faint-driven swaps exchange status/stat dictionaries, but manual switching in BattleUI only swaps party members and refreshes the creature. Enemy switching advances through the party and initializes the replacement; do not assume it preserves a conventional switch-back roster.
9. **Quest wiring:** completion helpers can set `Rewarding`, while the quest board explicitly groups Incoming, Started and Completed. The electrical puzzle emits completion but its box callback currently just resets interaction; no quest counter update is present there.
10. **Intentional/testing behavior needs clarification before balancing:** player attack accuracy is forced very high; legacy questions force Shakespeare difficulty; battle questions hard-code Grade 5; the computer Q action heals the party. These may be development choices rather than accidental bugs.

## Safe change workflow for this project

Before a change, inspect its script, owning scene, animation method tracks, signal connections and associated JSON keys. Preserve Godot resource UIDs, species ordering, sprite numbering and state-key names unless deliberately migrating every reference. Keep binary scenes in their native format unless conversion is explicitly needed.

Protect working progress and save data before playtesting. Use a disposable copy for runtime checks when possible, and inspect resulting diffs. Validate a focused gameplay path after edits: movement/interaction, dialogue exit, submenu exit, battle return, or save/load as relevant. Source inspection cannot substitute for those runtime checks.

At review time, pre-existing local modifications were present in `Data/Inventory.json`, `Data/Scenes.json`, `GrammariteData/Evolutions.json` and `Scenes/Town.scn`. They were preserved. No gameplay files or save data were edited for this review.
