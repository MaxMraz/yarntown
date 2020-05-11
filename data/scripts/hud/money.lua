-- The money counter shown in the game screen.

local rupees_builder = {}

function rupees_builder:new(game, config)

  local rupees = {}

  rupees.dst_x, rupees.dst_y = config.x, config.y

  rupees.surface = sol.surface.create(48, 12)
  rupees.digits_text = sol.text_surface.create{
    font = "8_bit",
    horizontal_alignment = "left",
  }
  rupees.digits_text:set_text(game:get_money())
  rupees.rupee_icons_img = sol.surface.create("hud/rupee_icon.png")
  rupees.rupee_bag_displayed = game:get_item("money_bag"):get_variant()
  rupees.money_displayed = game:get_money()

  function rupees:check()

    local need_rebuild = false
    local rupee_bag = game:get_item("money_bag"):get_variant()
    local money = game:get_money()

    -- Max money.
    if rupee_bag ~= rupees.rupee_bag_displayed then
      need_rebuild = true
      rupees.rupee_bag_displayed = rupee_bag
    end

    -- Current money.
    if money ~= rupees.money_displayed then
      need_rebuild = true
      local increment
      if money > rupees.money_displayed then
        increment = 1
      else
        increment = -1
      end
      rupees.money_displayed = rupees.money_displayed + increment

      -- Play a sound if we have just reached the final value.
      if rupees.money_displayed == money then
        sol.audio.play_sound("picked_money")

      -- While the counter is scrolling, play a sound every 3 values.
      elseif rupees.money_displayed % 3 == 0 then
        sol.audio.play_sound("picked_money")
      end
    end

    -- Redraw the surface only if something has changed.
    if need_rebuild then
      rupees:rebuild_surface()
    end

    -- Schedule the next check.
    sol.timer.start(rupees, 40, function()
      rupees:check()
    end)
  end

  function rupees:rebuild_surface()

    rupees.surface:clear()

    -- Max money (icon).
    rupees.rupee_icons_img:draw_region((rupees.rupee_bag_displayed - 1) * 12, 0, 12, 12, rupees.surface)

    -- Current rupee (counter).
    local max_money = game:get_max_money()
    if rupees.money_displayed == max_money then
      rupees.digits_text:set_font("8_bit")
    else
      rupees.digits_text:set_font("8_bit")  -- TODO show in a different color
    end
    rupees.digits_text:set_text(rupees.money_displayed)
    rupees.digits_text:draw(rupees.surface, 16, 5)
  end

  function rupees:get_surface()
    return rupees.surface
  end

  function rupees:on_draw(dst_surface)

    local x, y = rupees.dst_x, rupees.dst_y
    local width, height = dst_surface:get_size()
    if x < 0 then
      x = width + x
    end
    if y < 0 then
      y = height + y
    end

    rupees.surface:draw(dst_surface, x, y)
  end

  function rupees:on_started()
    rupees:check()
    rupees:rebuild_surface()
  end

  return rupees
end

return rupees_builder
