local menu = {}

menu.bg_surface = sol.surface.create()
menu.bg_image = sol.surface.create"menus/levelup_bg.png"
menu.cursor = sol.sprite.create"menus/arrow"
menu.cursor.x = 47
local TOP_INDEX_CURSOR_Y = 132
local MAX_INDEX = 4

--Create all the labels
menu.title = sol.text_surface.create({font = "enter_command", font_size = 16,})
menu.title:set_text("Level Up")
menu.title:draw(menu.bg_image, 65, 39)

menu.level_label = sol.text_surface.create({font = "enter_command", font_size = 16,})
menu.level_label:set_text("Level")
menu.level_label:draw(menu.bg_image, 68, 71)

menu.total_echoes_label = sol.text_surface.create({font = "enter_command", font_size = 16,})
menu.total_echoes_label:set_text("Echoes")
menu.total_echoes_label:draw(menu.bg_image, 68, 87)

menu.required_echoes_label = sol.text_surface.create({font = "enter_command", font_size = 16,})
menu.required_echoes_label:set_text("Required")
menu.required_echoes_label:draw(menu.bg_image, 68, 103)

menu.vitality_label = sol.text_surface.create({font = "enter_command", font_size = 16,})
menu.vitality_label:set_text("Vitality")
menu.vitality_label:draw(menu.bg_image, 68, 135)

menu.endurance_label = sol.text_surface.create({font = "enter_command", font_size = 16,})
menu.endurance_label:set_text("Endurance")
menu.endurance_label:draw(menu.bg_image, 68, 151)

menu.strength_label = sol.text_surface.create({font = "enter_command", font_size = 16,})
menu.strength_label:set_text("Strength")
menu.strength_label:draw(menu.bg_image, 68, 167)

menu.skill_label = sol.text_surface.create({font = "enter_command", font_size = 16,})
menu.skill_label:set_text("Skill")
menu.skill_label:draw(menu.bg_image, 68, 183)




function menu:on_started()
  local game = sol.main.get_game()
  game:set_suspended(true)
  game:get_hud():set_enabled(false)

  --Set initial cursor location
  menu.cursor.index = 0
  menu.cursor.y = TOP_INDEX_CURSOR_Y

  --Set all initial values
  menu:set_numbers()

end



function menu:set_numbers()
  local game = sol.main.get_game()

  menu.bg_surface:clear()

  menu.level = sol.text_surface.create({font = "enter_command", font_size = 16,})
  menu.level:set_text(game:get_value"player_level")
  menu.level:draw(menu.bg_surface, 145, 71)

  menu.echoes = sol.text_surface.create({font = "enter_command", font_size = 16,})
  menu.echoes:set_text(game:get_money())
  menu.echoes:draw(menu.bg_surface, 145, 87)

  --Required echoes is a lot to calculate
  local level = game:get_value"player_level"
  menu.required_echoes_amount = math.floor(0.02 * (level ^3) + 3.06 * (level ^2) + (105.6 * level) - 895)
  menu.required_echoes = sol.text_surface.create({font = "enter_command", font_size = 16,})
  menu.required_echoes:set_text(menu.required_echoes_amount)
  --move number left if too big
  local req_echoes_text_x = 145
  if menu.required_echoes_amount > 999 then req_echoes_text_x = 137
  elseif menu.required_echoes_amount > 9999 then req_echoes_text_x = 129
  elseif menu.required_echoes_amount > 99999 then req_echoes_text_x = 121
  elseif menu.required_echoes_amount > 999999 then req_echoes_text_x = 113
  elseif menu.required_echoes_amount > 9999999 then req_echoes_text_x = 105
  elseif menu.required_echoes_amount > 99999999 then req_echoes_text_x = 97
  end
  if game:get_money() < menu.required_echoes_amount then
    menu.required_echoes:set_color_modulation{255, 50, 50}
  end
  menu.required_echoes:draw(menu.bg_surface, req_echoes_text_x, 103)

  menu.vitality = sol.text_surface.create({font = "enter_command", font_size = 16,})
  menu.vitality:set_text(game:get_value"vitality")
  menu.vitality:draw(menu.bg_surface, 145, 135)

  menu.endurance = sol.text_surface.create({font = "enter_command", font_size = 16,})
  menu.endurance:set_text(game:get_value"endurance")
  menu.endurance:draw(menu.bg_surface, 145, 151)

  menu.strength = sol.text_surface.create({font = "enter_command", font_size = 16,})
  menu.strength:set_text(game:get_value"strength")
  menu.strength:draw(menu.bg_surface, 145, 167)

  menu.skill = sol.text_surface.create({font = "enter_command", font_size = 16,})
  menu.skill:set_text(game:get_value"skill")
  menu.skill:draw(menu.bg_surface, 145, 183)
end


function menu:on_command_pressed(command)
  local handled = false
  if command == "down" then
    sol.audio.play_sound"cursor"
    menu.cursor.index = (menu.cursor.index + 1) % MAX_INDEX
    handled = true
  elseif command == "up" then
    sol.audio.play_sound"cursor"
    menu.cursor.index = (menu.cursor.index - 1) % MAX_INDEX
    handled = true
  elseif command == "action" then
    menu:process_selection()
    handled = true
  elseif command == "attack" then
    sol.menu.stop(menu)
    handled = true
  elseif command == "pause" then
    sol.menu.stop(menu)
    handled = true

  end
  menu.cursor.y = TOP_INDEX_CURSOR_Y + menu.cursor.index * 16

  return handled
end


function menu:process_selection()
  local game = sol.main.get_game()
  local stats = {
    "vitality",
    "endurance",
    "strength",
    "skill",
  }
  if game:get_money() < menu.required_echoes_amount then
    sol.audio.play_sound"wrong"
    return
  end
  game:remove_money(menu.required_echoes_amount)
  game:set_value(stats[menu.cursor.index + 1], game:get_value(stats[menu.cursor.index + 1]) + 1)
  game:set_value("player_level", game:get_value("player_level") + 1)
  menu:process_stat_update(stats[menu.cursor.index + 1])
  menu:set_numbers()
end



function menu:process_stat_update(stat_updated)
  local game = sol.main.get_game()

  if stat_updated == "vitality" then
    --each vitality level, max hp goes up by (vitality * .6)+14 
    game:set_max_life(game:get_max_life() + (game:get_value"vitality" * .6)+14 )
    game:set_life(game:get_max_life())

  elseif stat_updated == "endurance" then
    --max stamina = endurance * 2.5 + 65
    game:set_value("max_stamina", game:get_value"endurance" * 2.5 + 65)

  elseif stat_updated == "strength" then
    --Strength is a temp formula:
    game:set_value("sword_damage", game:get_value"strength" * 4)

  elseif stat_updated == "skill" then

  end
end



function menu:on_finished()
  sol.main.get_game():get_hud():set_enabled(true)
  sol.main.get_game():set_suspended(false)
end


function menu:on_draw(dst)
  menu.bg_image:draw(dst)
  menu.bg_surface:draw(dst)
  menu.cursor:draw(dst, menu.cursor.x, menu.cursor.y)
end

return menu