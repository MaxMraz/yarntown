local menu = {}

local shard_amounts = {
  3,
  5,
  8,
  24,
  30,
}

--Where to draw menu
menu.x = 268
menu.y = 134


function menu:on_started()
  menu.req_surface = sol.surface.create(48,48)
  menu.req_bg = sol.sprite.create("menus/bloodstone_requirement")
  menu.number_surface = sol.text_surface.create{font = "enter_command",font_size=16}
  menu.level_surface = sol.text_surface.create{font = "enter_command",font_size=16}

  required_amount = menu:calculate_requirement()
  local game = sol.main.get_game()
  game:start_dialog("_game.weapon_upgrade", function(answer)
    if answer == 1 then
      if game:get_item("bloodstone_shard"):get_amount() > required_amount then
        menu:upgrade_weapon()
      else
        --not enough shards
        game:start_dialog("_game.not_enough_bloodstone")
        sol.menu.stop(menu)
      end

    else --don't upgrade
      sol.menu.stop(menu)
    end

  end)
end

function menu:calculate_requirement()
  local game = sol.main.get_game()
  local required_amount = shard_amounts[game:get_value("sword_level") or 1]
  local held_amount = game:get_item("bloodstone_shard"):get_amount()

  menu.number_surface:set_text(held_amount .. "/" .. required_amount)
  if required_amount > held_amount then
    menu.number_surface:set_color_modulation{200,200,200}
  else
    menu.number_surface:set_color_modulation{255,255,255}
  end

  menu.level_surface:set_text("Lv: " .. (game:get_value("sword_level") or 1))

  return required_amount
end

function menu:upgrade_weapon()
  local game = sol.main.get_game()
  game:set_value("sword_level", (game:get_value"sword_level" or 1) + 1 )
  sol.audio.play_sound"retrieval"
  menu:on_started()
end

function menu:on_draw(dst)
  menu.req_surface:draw(dst, menu.x, menu.y)
  menu.req_bg:draw(menu.req_surface)
  menu.level_surface:draw(menu.req_surface, 4, 10)
  menu.number_surface:draw(menu.req_surface, 22, 26)
end

return menu