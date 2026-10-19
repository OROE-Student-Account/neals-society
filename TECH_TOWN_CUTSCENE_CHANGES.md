# Tech Town fight interruption

## Latest revision: Static approaches the player for the quest offer

Updated October 18, 2026, after your dialogue edits. This revision supersedes the original sequence below.

The original seven worker lines and their approach are unchanged. Static enters and says your edited `ChiefInterruption` line. Dismissing it now calls `begin_quest_offer`: Derek returns to `(544, 104)` over 0.6 seconds, while Static remains visible beside the workers. Static then walks horizontally and vertically to a position beside the player's actual location at 48 pixels/second, faces the player, and opens your existing `ChiefWarning` dialogue. Player movement and menus stay locked between these stages.

Your current interruption, punctuation explanation, Yes choice, and dismissal text were preserved exactly. Selecting Yes now calls `accept_quest`, which marks zero-based quest index 1 as Started unless already Started, Rewarding, or Completed, then opens your existing dismissal. After dismissal, Static walks back to his entrance and hides; player control returns. Tom/Derek lessons and rewards are not implemented by this revision.

Changed files:

- `Scenes/Town.scn`: changed `ChiefInterruption` Function to `begin_quest_offer` and Func Node to `..`; changed `ChiefWarning/Yes` Function to `accept_quest` and Func Node to `../..`. Original scene UID and existing node IDs retained.
- `Scripts/Specialized/TechTownFightCutscene.gd`: added worker-retreat/player-approach sequencing, walking frame/facing control, and quest acceptance; final exit now starts from Static's actual location instead of replaying Derek's retreat.
- `Scenes/Specialized/TechTownFightAnimations.tres`: added `workers_step_back`, containing only the two Derek tracks from `settle_down`, shortened to 0.6 seconds. The original animation clips remain available.

**Reverse just this revision:** close the Town tab and restore all three `.before` files in `Backups/tech-town-quest-offer-before/` to their corresponding paths above: `Town.scn.before` → `Scenes/Town.scn`, `TechTownFightCutscene.gd.before` → `Scripts/Specialized/TechTownFightCutscene.gd`, and `TechTownFightAnimations.tres.before` → `Scenes/Specialized/TechTownFightAnimations.tres`. Reopen Town afterward. These backups include your dialogue edits from immediately before this revision. Restoring replaces any later edits to those files. The original implementation's backup below remains available separately.

Validated in an isolated temporary project using Godot 4.7.1 and the real scene manager, dialogue, menu and player: all seven worker steps, interruption-before-retreat order, Derek's return, Static's approach to an offset player position, original Yes choice, transition from Incoming to Started in the temporary quest data, Static's exit, restored controls, and replay prevention passed. The test script/log and checksums are in the new backup directory. Live Data/Saves were not modified by the test. No visual playtest was performed.

## Original implementation record

Implemented October 18, 2026. Backup taken immediately before this change, including your latest Z-through dialogue edits.

## Result

Entering Derek's existing Hitbox starts your original seven dialogue lines. After dismissing “Lets tussle” with Z, the bottom man walks from local `(544, 104)` to `(544, 80)` over 0.6 seconds. Chief Static becomes visible on the right and walks from `(608, 80)` to `(568, 80)`. After a short pause, his dialogue starts. Z advances each of his three lines:

1. “Enough! This is Tech Town, not a boxing ring. Both of you, stand down.”
2. “He meant, 'Let's eat, Derek.' A comma would have saved us all this trouble.”
3. “Now take a breath and get back to work. There will be no fighting in my town.”

After the final line, the bottom man returns to his original spot and Chief Static walks away and hides. Player control returns. The sequence is guarded against repeating during the same visit; leaving and reloading Town allows it again. No persistent quest completion, quest rewards, battle, or save flag is added.

## Files changed

### `Scenes/Town.scn`

Kept the binary scene format and original scene resource UID (`5863571715962722006`). Within `Sorted Stuff/Tech Town/Derek Cutscene_Quest`:

- Attached `Scripts/Specialized/TechTownFightCutscene.gd` to the existing parent.
- Changed Hitbox's Target Node from `../Dialogue Derek/1` to `..`, and Target Function from `begin_from_self` to `start_cutscene` so the controller can prevent repeated activation.
- Added Function `begin_confrontation` and Func Node `../..` to `Dialogue Derek/7`. Its existing text and End Node setting remain intact.
- Added `ChiefStatic`, a plain AnimatedSprite2D using the existing Chief Static sprite frames. It has no trainer script or battle trigger and starts hidden.
- Added `CutsceneAnimation`, an AnimationPlayer using the new animation library.
- Added three sibling dialogue nodes: `ChiefInterruption`, `ChiefWarning`, `ChiefDismissal`. They chain with the same end-node/function approach as your seven original lines. Display is `Chief Static`; the final callback is `finish_cutscene` on the cutscene parent.

### New `Scripts/Specialized/TechTownFightCutscene.gd`

Local controller for trigger guards, finishing a player tile before dialogue, animation sequencing, and player/menu locking. It switches the menu state back to NOTHING immediately before starting Chief Static's dialogue because SceneManager rejects a new dialogue while the state is DIALOGUE. This happens synchronously, without unlocking player movement between animation and dialogue.

### New `Scenes/Specialized/TechTownFightAnimations.tres`

An editable AnimationLibrary with `break_up_fight` (2.4 seconds) and `settle_down` (1.8 seconds). Tracks control bottom-man position/frame and Chief Static position/frame/visibility/facing. Select `CutsceneAnimation` in Godot to edit them. Edit the three new dialogue nodes' Text fields to change Chief Static's words.

## Backup and exact reversal

`Backups/tech-town-cutscene-before/Town.scn.before` is the complete original scene. The `.before` suffix prevents Godot importing a second scene with the same UID. Its SHA-256 is recorded in `checksums.txt` beside it.

To reverse this implementation:

1. Close the Town scene tab, saving any later work separately if you want to retain it.
2. Copy `Backups/tech-town-cutscene-before/Town.scn.before` over `Scenes/Town.scn` (destination filename must be `Town.scn`).
3. Reopen Town in Godot. The new script and animation library may be left unused, or deleted along with any `.uid` files Godot generates for them.

Restoring the backup replaces the entire scene with its pre-implementation version, so it also discards any Town edits made afterward. To keep later work, manually reverse the three existing-node changes listed above and remove the five added nodes instead.

No shared dialogue, player, trainer, SceneManager, inventory, quest or save files were changed. Existing local edits in Inventory, Scenes data, Evolutions and Town were preserved in the backed-up starting state.

## Verification

Built with the installed Godot 4.7.1 in a temporary project copy. A headless integration check used the real player, menu, dialogue and scene manager, with the cutscene extracted into a small world to isolate it from unrelated overworld events. It verified all seven original Z-through steps, movement endpoints, Chief visibility and three dialogue steps, player/menu locks, return positions, restored controls, disabled trigger and replay prevention. It passed.

The test script and successful log are preserved as `flow-check.gd.txt` and `flow-check.log.txt` in the backup directory. Existing shop filename capitalization warnings and the environment's certificate warning appeared during the check. No visual playtest was performed; check sprite placement and pacing in the editor. Test execution used a temporary copy so startup resets and runtime writes did not touch your live Data or Saves.
