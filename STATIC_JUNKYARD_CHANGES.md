# Chief Static at the junkyard

Added October 19, 2026. After the brawl and sign quests have Progress = Completed, Chief Static appears beside the southern path at the junkyard entrance (Town coordinates 1040, -688). The required quests are Deal with the brawl (index 1) and Fix the signs (index 2). Electrical Enterprise (index 0) is not required while its completion flow is unfinished.

After both required quests are completed, a one-time message directs the player south to meet Chief Static at the junkyard entrance. It waits for existing dialogue and menus to close and for movement to stop. StaticMeetingPrompted in quest index 2 records dismissal; players who already heard the power plant briefing skip this hint.

Approaching within 40 pixels while the player is stopped automatically starts a three-line briefing about Team rammarG targeting the region's power supply. The player retains control of travel to the power plant. The plant's encounters and subsequent Kom Ma-King sequence are not implemented by this change.

The briefing's completion is recorded as PowerPlantBriefed in quest index 2. Static remains available for a short reminder with Z, but does not automatically repeat his speech. Existing save/load copies this field. Older quest data with fewer than three entries keeps Static hidden safely.

The NPC is an editable instance at Town / Sorted Stuff / Tech Town / Chief Static - Junkyard. Its scene is Scenes/Specialized/StaticJunkyard.tscn, logic is Scripts/Specialized/StaticJunkyard.gd, and SpriteFrames are extracted from the existing Chief Static artwork into Scenes/Specialized/ChiefStaticFrames.tres. Town's original serialized nodes and signal connections are retained; one NPC instance was appended.

The pre-change Town scene is Backups/static-junkyard-before/Town.scn.before. Restoring that file removes this scene addition but also discards subsequent Town edits, so preserve later changes first.

Verification used a separate copy of working Data: all eight completion combinations, menu gating, three dialogue lines with keyboard input, saved briefing flag, no repeated automatic interruption, nearby collision clearance, actual player movement after closing, and older save data. Live Data and saved slots were not changed by these tests. Placement was inspected against the scene's tile map; no live visual playtest was performed.

The existing Utils.reset_quest_progress_in_editor toggle is currently enabled. Starting a fresh editor run resets quest progress and this briefing flag; complete the quests within that run to unlock Static, or disable that toggle when testing persistent progress.
