local title_card = {}

local title_surface

function title_card:on_started()
  title_surface = sol.surface.create("menus/title_card.png")
  title_surface:fade_in()
end

function title_card:fade_out()
  title_surface:fade_out(60)
end

function title_card:on_draw(dst)
  title_surface:draw(dst, 208 - 56, 120 - 24)
end


return title_card