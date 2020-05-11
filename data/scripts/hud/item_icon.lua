-- An icon that shows the inventory item assigned to a slot.

local hud_icon_builder = require("scripts/hud/hud_icon")

local item_icon_builder = {}

function item_icon_builder:new(game, config)

  local item_icon = {}
  item_icon.slot = config.slot or 1

  -- Creates the hud icon delegate.
  item_icon.hud_icon = hud_icon_builder:new(game, "item_" .. item_icon.slot, config.x, config.y)
  item_icon.hud_icon:set_background_sprite(sol.sprite.create("hud/icon_item_" .. item_icon.slot))
  
  -- Initializes the icon.
  item_icon.item_sprite = sol.sprite.create("entities/items")
  item_icon.item_sprite_w, item_icon.item_sprite_h = item_icon.item_sprite:get_size()
  item_icon.item_displayed = nil
  item_icon.item_variant_displayed = 0
  item_icon.amount_text = sol.text_surface.create{
    horizontal_alignment = "right",
    vertical_alignment = "top"
  }
  item_icon.amount_displayed = nil
  item_icon.max_amount_displayed = nil

  -- The surface used by the icon for the foreground is handled here.
  item_icon.foreground = sol.surface.create(32, 24)
  item_icon.hud_icon:set_foreground(item_icon.foreground)

  -- Draws the icon surface.
  function item_icon:on_draw(dst_surface)
    item_icon.hud_icon:on_draw(dst_surface)
  end

  -- Rebuild the foreground (called only when needed).
  function item_icon:rebuild_foreground()    
    if item_icon.item_displayed ~= nil then
      -- Clear the surface.
      item_icon.foreground:clear()

      -- Item.
      local foreground_w, foreground_h = item_icon.foreground:get_size()
      item_icon.item_sprite:draw(item_icon.foreground, foreground_w / 2, foreground_h / 2 + 4)

      -- Amount.
      if item_icon.amount_displayed ~= nil then
        item_icon.amount_text:set_text(tostring(item_icon.amount_displayed))

        -- The font color changes according to the amount.
        if item_icon.amount_displayed == item_icon.max_amount_displayed then
          item_icon.amount_text:set_font("green_digits")
        else
          item_icon.amount_text:set_font("white_digits")
        end

        item_icon.amount_text:draw(item_icon.foreground, foreground_w, foreground_h - 8)
      end
    end
  end
  
  -- Returns if the icon is enabled or disabled.
  function item_icon:is_enabled(active)
    return item_icon.hud_icon:is_enabled()
  end

  -- Set if the icon is enabled or disabled.
  function item_icon:set_enabled(enabled)
    item_icon.hud_icon:set_enabled(enabled)
  end
          
  -- Returns if the icon is active or inactive.
  function item_icon:is_active(active)
    return item_icon.hud_icon:is_active()
  end

  -- Set if the icon is active or inactive.
  function item_icon:set_active(active)
    item_icon.hud_icon:set_active(active)
  end

  -- Returns if the icon is transparent or not.
  function item_icon:is_transparent()
    return item_icon.hud_icon:set_transparent()
  end

  -- Sets if the icon is transparent or not.
  function item_icon:set_transparent(transparent)
    item_icon.hud_icon:set_transparent(transparent)
  end
  
  -- Checks periodically if the icon needs to be redrawn.
  function item_icon:check()
    local need_rebuild = false

    -- Item assigned.
    local item = game:get_item_assigned(item_icon.slot)
    if item_icon.item_displayed ~= item then
      need_rebuild = true
      item_icon.item_displayed = item
      item_icon.item_variant_displayed = nil
      if item ~= nil then
        item_icon.item_sprite:set_animation(item:get_name())
      end
    end

    if item ~= nil then
      -- Variant of the item.
      local item_variant = item:get_variant()
      if item_icon.item_variant_displayed ~= item_variant then
        need_rebuild = true
        item_icon.item_variant_displayed = item_variant
        item_icon.item_sprite:set_direction(item_variant - 1)
      end

      -- Amount.
      if item:has_amount() then
        local amount = item:get_amount()
        local max_amount = item:get_max_amount()
        if item_icon.amount_displayed ~= amount or item_icon.max_amount_displayed ~= max_amount then
          need_rebuild = true
          item_icon.amount_displayed = amount
          item_icon.max_amount_displayed = max_amount
        end
      elseif item_icon.amount_displayed ~= nil then
        need_rebuild = true
        item_icon.amount_displayed = nil
        item_icon.max_amount_displayed = nil
      end
    elseif item_icon.amount_displayed ~= nil then
      need_rebuild = true
      item_icon.amount_displayed = nil
      item_icon.max_amount_displayed = nil
    end

    -- Redraw the surface only if something has changed.
    if need_rebuild then
      item_icon:rebuild_foreground()
    end

    -- Schedule the next check.
    sol.timer.start(item_icon, 50, function()
      item_icon:check()
    end)
  end
  
  -- Update the surface each time the sprite change.
  function item_icon.item_sprite:on_frame_changed()
    item_icon:rebuild_foreground()
  end

  function item_icon:on_mouse_pressed(button, x, y)
    return item_icon.hud_icon:on_mouse_pressed(button, x, y)
  end

  function item_icon:on_mouse_released(button, x, y)
    return item_icon.hud_icon:on_mouse_released(button, x, y)
  end

  function item_icon:on_finger_pressed(finger, x, y, pressure)
    return item_icon.hud_icon:on_finger_pressed(finger, x, y, pressure)
  end

  function item_icon:on_finger_released(finger, x, y, pressure)
    return item_icon.hud_icon:on_finger_released(finger, x, y, pressure)
  end

  -- Called when the menu is started.
  function item_icon:on_started()
    item_icon:check()
  end

  -- Returns the menu.
  return item_icon
end

return item_icon_builder
