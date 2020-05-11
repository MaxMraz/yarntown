require("scripts/multi_events")

local item = ...
local game = item:get_game()

item:register_event("on_created", function(self)

  item:set_savegame_variable("possession_dandelion_charm")
  item:set_sound_when_brandished(nil)
  item:set_sound_when_picked(nil)
  item:set_shadow(nil)
end)

item:register_event("on_variant_changed", function(self, variant)
  -- The possession state of the charm determines the built-in ability "run".
  --Actually, it allows you to use the dash function programmed in the game_manager script.
--  game:set_ability("run", 1)
end)

item:register_event("on_obtaining", function(self, variant)
  sol.audio.play_sound("treasure")
  game:set_value("quest_ancient_groves", 3)
end)
