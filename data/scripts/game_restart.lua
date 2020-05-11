game_restart = {}

function game_restart:reset_values(game)
  local hero = game:get_hero()
  hero:set_walking_speed(98)
  game:set_value("hero_dashing", false)
  game:set_value("hero_rolling", false)
  game:set_value("gameovering", false)
--  hero:set_sword_sprite_id("hero/sword1")
  sol.audio.set_music_volume(game:get_value("music_volume") or 90)
  sol.audio.set_sound_volume(game:get_value("sound_volume") or 100)
  game.stamina = game:get_value"max_stamina"
end

return game_restart