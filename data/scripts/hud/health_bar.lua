-- The health bar shown in the game screen.
local health_builder = {}

function health_builder:new(game, config)

  local health = {}

  health.dst_x, health.dst_y = config.x, config.y

  health.max_width = game:get_max_life() or 500
  health.amount_displayed = game:get_life() or 500
  health.surface = sol.surface.create(400, 8)
  health.background = sol.sprite.create("hud/stamina_bar_background")
  health.bar = sol.sprite.create("hud/health_bar")
  health.end_marker = sol.sprite.create("hud/healthbar_end_marker")

  --start a timer to check if max_health is updated, to not check every part of rebuild
  sol.timer.start(game, 400, function()
    health.max_width = game:get_max_life()
    return true
  end)

  function health:check()

    local need_rebuild = false

    -- Current health
    if game:get_life() ~= health.amount_displayed then
      need_rebuild = true
      local difference = (game:get_life() or 100) - health.amount_displayed
      if difference % 10 == 0 then
        increment = 10
      else
        increment = 1
      end
      if (game:get_life() or 100) < health.amount_displayed then
        increment = increment * -1
      end
      health.amount_displayed = health.amount_displayed + increment

    end

    -- Redraw the surface only if something has changed.
    if need_rebuild then
      health:rebuild_surface()
    end

    -- Schedule the next check.
    sol.timer.start(health, 40, function()
      health:check()
    end)
  end

  function health:rebuild_surface()
    --health is drawn at 1px per DRAW_RATIO of health
    local DRAW_RATIO = 10
    health.surface:clear()
    health.background:draw_region(0, 0, health.max_width / DRAW_RATIO, 8, health.surface)
    health.bar:draw_region(0, 0, health.amount_displayed / DRAW_RATIO, 8, health.surface, 0, 0)
    health.end_marker:draw(health.surface, health.amount_displayed / DRAW_RATIO, 0)

  end

  function health:get_surface()
    return health.surface
  end

  function health:on_draw(dst_surface)

    local x, y = health.dst_x, health.dst_y
    local width, height = dst_surface:get_size()
    if x < 0 then
      x = width + x
    end
    if y < 0 then
      y = height + y
    end

    health.surface:draw(dst_surface, x, y)
  end

  function health:on_started()
    health:check()
    health:rebuild_surface()
  end

  return health
end

return health_builder
