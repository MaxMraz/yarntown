-- Script to draw basic text strokes and shadows in pure Lua.
-- Usage:
-- require("scripts/text_fx_helper")

local text_fx_helper = {}

-- Creates a text_surface with all same properties except the color. 
local function copy_text_surface(src_text_surface, new_color)
  -- Create a text surface with the shadow color.
  local new_surface = sol.text_surface.create{
    horizontal_alignment = src_text_surface:get_horizontal_alignment(),
    vertical_alignment = src_text_surface:get_vertical_alignment(),
    font = src_text_surface:get_font(),
    font_size = src_text_surface:get_font_size(),
    text = src_text_surface:get_text(),
    color = new_color,
  }

  return new_surface
end

-- Draws the 8 components composing the stroke.
local function draw_stroke_components(dst_surface, text_surface, x, y, delta)
  text_surface:draw(dst_surface, x - delta, y)
  text_surface:draw(dst_surface, x - delta, y - delta)
  text_surface:draw(dst_surface, x - delta, y + delta)
  text_surface:draw(dst_surface, x + delta, y)
  text_surface:draw(dst_surface, x + delta, y - delta)
  text_surface:draw(dst_surface, x + delta, y + delta)
  text_surface:draw(dst_surface, x, y - delta)
  text_surface:draw(dst_surface, x, y + delta)
end

-- Draws only the stroke.
function text_fx_helper:draw_text_stroke(dst_surface, text, stroke_color)
  -- Create a text surface with the stroke color.
  local text_stroke = copy_text_surface(text, stroke_color)

  -- Draw the 8 texts composing the stroke.
  local x, y = text:get_xy()
  draw_stroke_components(dst_surface, text_stroke, x, y, 1)
end

-- Draws the text with a stroke.
function text_fx_helper:draw_text_with_stroke(dst_surface, text, stroke_color)
  -- Draw the stroke with the stroke color.
  self:draw_text_stroke(dst_surface, text, stroke_color)

  -- Draw text above the stroke.
  text:draw(dst_surface)
end

-- Draws the text with a shadow.
function text_fx_helper:draw_text_with_shadow(dst_surface, text, shadow_color)
  -- Draw the stroke with the stroke color.
  self:draw_text_shadow(dst_surface, text, shadow_color)

  -- Draw text above the stroke.
  text:draw(dst_surface)
end

-- Draws only the shadow.
function text_fx_helper:draw_text_shadow(dst_surface, text, shadow_color)
  -- Create a text surface with the shadow color.
  local text_shadow = copy_text_surface(text, shadow_color)

  -- Draw the text composing the shadow.
  local x, y = text:get_xy()
  text_shadow:draw(dst_surface, x, y + 1)
end

-- Draws only the stroke and the shadow.
function text_fx_helper:draw_stroke_and_shadow(dst_surface, text, stroke_color, shadow_color)
  local x, y = text:get_xy()

  -- Shadow
  local text_shadow = copy_text_surface(text, shadow_color)
  draw_stroke_components(dst_surface, text_shadow, x, y + 1, 1)

  -- Stroke
  local text_stroke = copy_text_surface(text, stroke_color)
  draw_stroke_components(dst_surface, text_stroke, x, y, 1)

end

-- Draws the text with the stroke and the shadow.
function text_fx_helper:draw_text_with_stroke_and_shadow(dst_surface, text, stroke_color, shadow_color)
  self:draw_stroke_and_shadow(dst_surface, text, stroke_color, shadow_color)
  text:draw(dst_surface)
end

return text_fx_helper
