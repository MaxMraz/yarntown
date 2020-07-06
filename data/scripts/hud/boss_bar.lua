local menu = {}
  menu.bar_background = sol.sprite.create"hud/stamina_bar_background"
  menu.health_bar = sol.sprite.create"hud/health_bar"
  menu.w, menu.h = menu.bar_background:get_size()
  menu.bar_surface = sol.surface.create(menu.w,menu.h)

function menu:on_started()
  sol.main.get_game():register_event("on_game_over_started", function()
    if sol.menu.is_started(menu) then
      sol.menu.stop(menu)
    end
  end)
end

function menu:set_enemy(enemy)
  menu.enemy = enemy
  menu.max_life = enemy:get_life()
  sol.timer.start(menu, 100, function()
    menu:update_life()
    return true
  end)
end

function menu:update_life()
  local life_ratio = menu.w * menu.enemy:get_life() / menu.max_life
  menu.bar_surface:clear()
  menu.bar_background:draw(menu.bar_surface)
  menu.health_bar:draw_region(0, 0, life_ratio, 8, menu.bar_surface)
end


function menu:on_draw(dst)
  menu.bar_surface:draw(dst, 8, 220)
end


return menu