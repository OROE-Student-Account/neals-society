# Tom and Derek collision setup

Updated October 19, 2026 after inspecting the user's edited Town scene.

Kept the user's Tom rename, TomBody and DerekBody nodes, body rectangles, detection areas, and cleaned-up cutscene _ready() method. Player.gd is unchanged and uses its original raycast movement.

Both character origins now represent the top-left of a movement tile, matching the current Town player spawn grid. Sprites match the working Trainer setup: centered=false and offset (0, -3). The 32-pixel atlas frames only contain about 19 visible character pixels, so the unused bottom portion must not be treated as visible body height. Local positions under Derek Cutscene_Quest are Tom (536, 56) and Derek (536, 88). Each body has position (0, 0), layer 5, mask none, and one 16x16 rectangle at local (8, 8). Each HitBox has layer none, mask Player, and its existing DetectPlayer circle at (8, 8). Detection areas therefore do not block movement. Cutscene Y-sorting is enabled in the scene and existing controller script.

TomPunctuationLesson.gd references the renamed Tom node and compares both actors' tile centers at (8, 8). All other lesson logic is preserved.

Derek position tracks are (536,88) to (536,72) for break_up_fight, and the reverse for settle_down and workers_step_back. A fresh embedded animation library preserves the Chief Static and frame tracks while saving these six position keys correctly. Scene node and signal counts are preserved.

Backups before this pass are in Backups/npc-standardization-before/. Reload Town.scn from disk in Godot after external edits; an older editor copy should not overwrite the saved scene.

Verification ran with separate working Data. It checked blocking and retreat from all four sides of both NPCs using original raycast movement, Tom dialogue from all sides, sideways exit from the space between both NPCs, nonblocking detection areas, and the full brawl/quest-offer/Chief-exit flow. The cutscene test confirmed restored player control and both characters' final positions and footprints. No live visual playtest was performed.

Follow-up visual verification used each actual saved atlas frame and alpha bounds, confirming that both visible feet end exactly at the blocking rectangle bottom. A CPU-rendered overlay is in /tmp/sign-debug/npc_bounds.png. Movement tests also found a separate OldmanBench2 blocker east of Tom; an alternate escape remains open. Full cutscene and interaction tests passed after the sprite-padding correction.
