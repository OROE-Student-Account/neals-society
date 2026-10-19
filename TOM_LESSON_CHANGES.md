# Tom's punctuation lesson — changes and reversal

Implemented October 18, 2026. This adds part 2 of Quest 2; Tom alone completes the quest and pays $100.

## How to play

After accepting Static's offer, face Tom (the upper worker) from an adjacent tile and press Z. Choose Definitely to begin or Later to leave. Your current Data already marks Quest 2 Started, so that existing progress also allows the lesson.

The lesson uses your existing dialogue box and an instance of `QuestionScreen.tscn`, including its Success/Failure animations. It asks three fixed questions: correct the end punctuation in “What is your favorite animal.”, explain why a question mark belongs there, and select “Let's eat, Derek.” Tom and the player explain the punctuation and apostrophe between questions. Wrong answers show feedback and retry without losing progress. Arrow keys cycle the three options, Z answers, and X leaves while choosing an answer. Q/vitamins are hidden for this lesson.

Progress is recorded after each completed dialogue/question step. Talking to Tom again resumes an unfinished lesson. After his final thanks, Quest 2 becomes Completed and $100 is added automatically. Repeated conversations or completion callbacks do not pay again. Derek has no additional lesson. Completing the quest also prevents the opening brawl from replaying after Town reloads.

## Exact file changes

| File | Change |
| --- | --- |
| `Scenes/Town.scn` | Added a `TomLesson` node under `Sorted Stuff/Tech Town/Derek Cutscene_Quest`, with the new lesson controller. Added `TomBody/CollisionShape2D` under the upper worker to stop the player walking through him (object collision layer 16; 12×12 shape at local 0,8). Existing dialogue and cutscene nodes preserved; original binary scene UID retained. |
| `Scripts/Specialized/TechTownFightCutscene.gd` | Added `_ready()` checking whether Quest 2 is Completed, disabling the brawl trigger when it is. Other movement and quest-offer behavior retained. |
| `GrammariteData/Quests.json` | Renamed Quest 2 from Burgher Brawl to Deal with the brawl, changed its description to helping Tom, and changed its reward from $30 to $100. First quest and quest index ordering preserved. |
| New `Scripts/Specialized/TomPunctuationLesson.gd` | Handles nearby/facing-Z interaction with Tom, quest gating, temporary dialogue, question navigation, retries, cancellation/resume, completion and one-time payment. UI changes apply only to the lesson's screen instance. |
| New `GrammariteData/TomLesson.json` | Contains the 14 dialogue/question steps. Edit this file to change Tom's lesson text, answers and explanations. Answer indices are zero-based. |

No shared battle-question, question-screen, dialogue-manager, player, save-helper or inventory scripts were changed. The question screen's fourth answer box is hidden for this lesson. Its option labels and selection outline are resized locally to fit the three choices; the original scene/artwork remain unchanged.

## Runtime data

Playing the lesson writes `LessonStep`, `RewardGranted` and `Progress` on quest index 1 in `Data/Quests.json`. Finishing adds $100 to `Data/Inventory.json` through the existing money helper. These files are already included in the existing save-slot system, so lesson progress and the reward guard travel with saved games.

The implementation/checks did not alter your live Data or Saves. Existing project edits were retained in the starting scene. Tests ran in a separate temporary project copy.

## Revert this change

The complete pre-change files are in `Backups/tom-lesson-before/`, with their original directory structure and a `.before` suffix. Close the Town tab and copy these back:

1. `Scenes/Town.scn.before` → project `Scenes/Town.scn`.
2. `Scripts/Specialized/TechTownFightCutscene.gd.before` → project `Scripts/Specialized/TechTownFightCutscene.gd`.
3. `GrammariteData/Quests.json.before` → project `GrammariteData/Quests.json`.

Then reopen Town. The two new lesson files may be left unused or removed, along with any `.uid` generated for the new script. The previous brawl/Static approach implementation remains intact in these backups. Restoring whole files discards any later edits to those same files, so save later work separately first.

If you have played the lesson and also want to reverse its progress/money changes, optional pre-change snapshots of `Data/Quests.json` and `Data/Inventory.json` are included. Restoring those replaces all progress/inventory changes since the snapshot, not only this quest. Alternatively, remove quest 2's `LessonStep`/`RewardGranted`, restore its previous Progress, and subtract the $100 only if it was awarded. Saved slots written after completing the lesson keep their own progress until separately restored or edited.

## Verification

Godot 4.7.1 loaded the modified scene and compiled the lesson controller. A headless integration check used the real dialogue, player, menu and scene manager, plus the cutscene subtree. It checked nearby/facing interaction, quest gating, Later, X cancellation and resume, wrong-answer retry, all three correct answers, completion, exactly one $100 payment, repeat conversations/callbacks, save/load persistence and disabling the completed brawl trigger. It also measured every option label with the actual font to check it fits its box. Feedback animation speed was increased in the test only.

The existing brawl/Static-approach test was also rerun. Test scripts/logs and file checksums are retained beside the backups. Existing shop filename-capitalization warnings and an environment certificate warning were emitted by Godot. No visual playtest was performed; check pacing and sprite placement in the game.
