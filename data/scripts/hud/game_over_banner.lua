local title_card = {}

local title_surface
local black_screen = sol.surface.create()
black_screen:fill_color{0,0,0}

function title_card:on_started()
  black_screen:set_opacity(0)
  title_surface = sol.surface.create("hud/game_over_banner.png")
  title_surface:fade_in()
end

function title_card:fade_out()
  title_surface:fade_out(60)
end

function title_card:fade_to_black()
  black_screen:fade_in()
end

function title_card:on_draw(dst)
  black_screen:draw(dst)
  title_surface:draw(dst, 0, 120 - 24)
end


return title_card