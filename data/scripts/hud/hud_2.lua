-- Script that creates a head-up display for a game.

-- Usage:
-- require("scripts/hud/hud")

require("scripts/multi_events")
local hud_config = require("scripts/hud/hud_config")

-- Creates and runs a HUD for the specified game.
local function initialize_hud_features(game)

  -- Set up the HUD.
  local hud = {
    enabled = false,
    elements = {},
  }

  for _, element_config in ipairs(hud_config) do
    local element_builder = require(element_config.menu_script)
    local element = element_builder:new(game, element_config)
    if element.set_dst_position ~= nil then
      -- Compatibility with old HUD element scripts
      -- whose new() method don't take a config parameter.
      element:set_dst_position(element_config.x, element_config.y)
    end
    hud.elements[#hud.elements + 1] = element
    if element_config.id then hud.elements[element_config.id] = element end
  end

  -- Destroys the HUD.
  function hud:quit()

    if hud:is_enabled() then
      -- Stop all HUD elements.
      hud:set_enabled(false)
    end
  end

  -- Returns whether the HUD is currently enabled.
  function hud:is_enabled()
    return hud.enabled
  end

  -- Enables or disables the HUD.
  function hud:set_enabled(enabled)

    if enabled ~= hud.enabled then
      hud.enabled = enabled

      for _, menu in ipairs(hud.elements) do
        if enabled then
          -- Start each HUD element.
          sol.menu.start(game, menu)
        else
          -- Stop each HUD element.
          sol.menu.stop(menu)
        end
      end
    end
  end

  -- Returns whether the HUD is currently shown.
  function game:is_hud_enabled()
    return hud:is_enabled()
  end

  -- Enables or disables the HUD.
  function game:set_hud_enabled(enable)
    return hud:set_enabled(enable)
  end

  -- Returns the HUD
  function game:get_hud() return hud end

  -- Call this function to notify the HUD that the current map has changed.
  local function hud_on_map_changed(game, map)

    if hud:is_enabled() then
      for _, menu in ipairs(hud.elements) do
        if menu.on_map_changed ~= nil then
          menu:on_map_changed(map)
        end
      end
    end
  end

  -- Call this function to notify the HUD that the game was just paused.
  local function hud_on_paused(game)

    if hud:is_enabled() then
      for _, menu in ipairs(hud.elements) do
        if menu.on_paused ~= nil then
          menu:on_paused()
        end
      end
    end
  end

  -- Call this function to notify the HUD that the game was just unpaused.
  local function hud_on_unpaused(game)

    if hud:is_enabled() then
      for _, menu in ipairs(hud.elements) do
        if menu.on_unpaused ~= nil then
          menu:on_unpaused()
        end
      end
    end
  end

  game:register_event("on_map_changed", hud_on_map_changed)
  game:register_event("on_paused", hud_on_paused)
  game:register_event("on_unpaused", hud_on_unpaused)

  -- Start the HUD.
  hud:set_enabled(true)
end

-- Set up the HUD features on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_hud_features)
return true
