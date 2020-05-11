-- The stamina bar shown in the game screen.
local stamina_builder = {}

function stamina_builder:new(game, config)

  local stamina = {}

  stamina.dst_x, stamina.dst_y = config.x, config.y

  stamina.max_width = game:get_value("max_stamina") or 100
  stamina.amount_displayed = stamina.max_width
  stamina.surface = sol.surface.create(100, 8)
  stamina.background = sol.sprite.create("hud/stamina_bar_background")
  stamina.bar = sol.sprite.create("hud/stamina_bar")
  stamina.end_marker = sol.sprite.create("hud/healthbar_end_marker")

  --start a timer to check if max_stamina is updated, to not check every part of rebuild
  sol.timer.start(game, 400, function()
    stamina.max_width = game:get_value("max_stamina")
    return true
  end)

  function stamina:check()

    local need_rebuild = false

    -- Current stamina
    if game.stamina ~= stamina.amount_displayed then
      need_rebuild = true
      local difference = (game.stamina or 100) - stamina.amount_displayed
      if difference % 10 == 0 then
        increment = 5
      else
        increment = 1
      end
      if (game.stamina or 100) < stamina.amount_displayed then
        increment = increment * -1
      end
      stamina.amount_displayed = stamina.amount_displayed + increment

    end

    -- Redraw the surface only if something has changed.
    if need_rebuild then
      stamina:rebuild_surface()
    end

    -- Schedule the next check.
    sol.timer.start(stamina, 40, function()
      stamina:check()
    end)
  end

  function stamina:rebuild_surface()

    stamina.surface:clear()
    stamina.background:draw_region(0, 0, stamina.max_width / 2, 8, stamina.surface)
    stamina.bar:draw_region(0, 0, stamina.amount_displayed / 2, 8, stamina.surface, 0, 0)
    stamina.end_marker:draw(stamina.surface, stamina.amount_displayed/2, 0)

  end

  function stamina:get_surface()
    return stamina.surface
  end

  function stamina:on_draw(dst_surface)

    local x, y = stamina.dst_x, stamina.dst_y
    local width, height = dst_surface:get_size()
    if x < 0 then
      x = width + x
    end
    if y < 0 then
      y = height + y
    end

    stamina.surface:draw(dst_surface, x, y)
  end

  function stamina:on_started()
    stamina:check()
    stamina:rebuild_surface()
  end

  return stamina
end

return stamina_builder
