# Fix the signs — implementation and reversal

Implemented October 19, 2026.

## Play flow

After completing Tom's brawl lesson, face a correction sign and press Z. The existing question-screen artwork, selection UI, and Success/Failure animations are reused. Choose with the arrow keys and answer with Z. Wrong answers explain the correction and retry; X leaves the question without fixing the sign.

The three corrections are:

- Its bad to drink the pipe water → It's bad to drink the pipe water
- Were staying safe → We're staying safe
- Please dont run → Please, don't run

A correct answer immediately saves that sign's corrected text. Reading it again shows the corrected sentence instead of another quiz. Fixing all three completes the new third quest, Fix the signs. No additional money/item reward was specified, so this quest does not award one. The existing Electrical Enterprise and brawl quests keep their indices and rewards.

## Scene changes

In `Scenes/Town.scn`, under `Sorted Stuff/Tech Town`:

- Existing `Rearrange Sign quest` at local `(232, -120)` now uses `CorrectionSign.gd`, with correction ID `pipe_water`.
- Added `Staying Safe Sign` at `(280, -120)` with ID `staying_safe`.
- Added `Please Dont Run Sign` at `(328, -120)` with ID `please_run`.

Both new signs instance the existing `Scenes/Sign.tscn`. They sit 48 pixels apart beside the existing sign and can be repositioned in the editor. Existing signs, quest dialogue, and the original Town resource UID were retained. The pre-existing unused DialogueTreeNode under the pipe-water sign remains in place.

## Files

Modified:

- `Scenes/Town.scn`: sign wiring and two added signs, as above.
- `GrammariteData/Quests.json`: appended Fix the signs, with RequiredCount 3. Existing definitions unchanged.
- `Autoload/utils.gd`: `load_quests()` now appends missing Incoming quest entries when reading older working data/save slots. This prevents the quest board indexing past the end when a save has only two quests. Existing progress is preserved.

Added:

- `GrammariteData/SignCorrections.json`: three questions, answers, explanations and corrected sentences. Answer indices are zero-based.
- `Scripts/Specialized/CorrectionSign.gd`: local sign behavior, facing/distance interaction and corrected text refresh. Ordinary `Scripts/Sign.gd` is unchanged.
- `Scripts/Specialized/SignCorrectionLesson.gd`: reuses the existing Tom lesson's question and dialogue helpers, overrides interaction/locking, and records corrections under quest index 2. Tom's lesson script and battle UI are unchanged.

Runtime progress lives in the third entry of `Data/Quests.json`: `CorrectedSigns` contains the unique IDs, `Count` tracks fixed signs, and `Progress` becomes Started then Completed. Missing entries are handled for older saves. Existing save/load already copies Quests.json, so corrections persist with each slot. Startup's scene reset does not clear these quest fields.

## Revert

Pre-change copies are in `Backups/sign-quest-before/`, preserving the original paths with `.before` appended.

1. Close Town in Godot.
2. Restore `Scenes/Town.scn.before` over project `Scenes/Town.scn`.
3. Restore `GrammariteData/Quests.json.before` over project `GrammariteData/Quests.json`.
4. Restore `Autoload/utils.gd.before` over project `Autoload/utils.gd`.
5. Reopen Town. The three new files may remain unused or be removed, along with any generated script `.uid` files.

Restoring whole files also discards any later edits to those files; save later work separately first. If you also want to undo gameplay progress, `Data/Quests.json.before` is provided as an optional snapshot. Restoring it replaces all quest changes since the snapshot. Alternatively, remove just the third quest entry, including its CorrectedSigns/Count fields. Previously saved slots retain their own quest data until restored or reset separately.

## Verification

Built and tested using Godot 4.7.1 in a temporary project copy. The integration test used the actual sign, dialogue, menu, player and question UI. It checked older two-quest saves, quest-board migration, gating until Tom's quest is Completed, X cancellation, nearby/facing interaction, wrong-answer retries for all three signs, permanent corrected text, unique counting, final completion, save/load and answer-text fit using the real font. All passed. Animation playback was accelerated for the test only.

Test script/log and checksums are retained with the backup. The usual existing shop filename-capitalization and environment certificate warnings appeared. No visual playtest was performed; check the two new signs' placement in your map. Test execution did not change live Data/Saves.
