--[[consumables.lua
	version 1.0.1
	18 Oct 2019
	GNU General Public License Version 3
	author: Llamazing

	   __   __   __   __  _____   _____________  _______
	  / /  / /  /  | /  |/  /  | /__   /_  _/  |/ / ___/
	 / /__/ /__/ & |/ , ,  / & | ,:',:'_/ // /|  / /, /
	/____/____/_/|_/_/|/|_/_/|_|_____/____/_/ |_/____/

	This hud script displays a brief popup displaying an item icon and amount whenever the
	player obtains a consumable item. Multiple popups will be stacked when the player gets
	multiple items in quick succession.
	
	Usage:
	Add an entry to hud_config.lua for this script along with the desired properties
--]]

require"scripts/multi_events"

local hud_submenu = {}

local MAX_COUNT = 5 --max number of panels to show at one time
local Y_OFFSET = 28 --vertical offset for each panel in pixels
local PANEL_IMG_ID = "menus/panel.png" --image to use for panel

--// Creates and returns new instance for hud
	--game (sol.game) - the current game
	--properties (table, key/value)
		--x (number, integer) - x coordinate of hud submenu in pixels
			--if x is negative then specifies position from right edge of screen
		--y (number, integer) - y coordinate of hud submenu in pixels
			--if y is negative then specifies position from bottom edge of screen
		--duration (number, positive integer) - duration to display each panel in ms
	--returns sol.menu to be displayed on hud
function hud_submenu:new(game, properties)
	local menu = {}
	
	local panels = {} --(table, combo) panels currently visible on screen
		--indices (up to MAX_COUNT) have a panel instance (table) for its value
		--each panel can also be accessed using its item id (string) as the key
	local queue = {} --(table, combo) additional panels exceeding max, show when new slots free up
		--indices (unlimited) have a panel instance (table) for its value
		--each panel in the queue can be accessed using its item id (string) as the key
	local panel_img = sol.surface.create(PANEL_IMG_ID)
	local panel_width, panel_height = panel_img:get_size()
	
	local dst_x = tonumber(properties.x)
	local dst_y = tonumber(properties.y)
	assert(dst_x, "Bad property x to 'new' (number expected)")
	assert(dst_y, "Bad property y to 'new' (number expected)")
	dst_x = math.floor(dst_x)
	dst_y = math.floor(dst_y)
	local duration = tonumber(properties.duration)
	assert(duration, "Bad property duration to 'new' (number expected)")
	duration = math.floor(duration)
	assert(duration >= 0, "Bad property duration to 'new' (number must be non-negative)")
	local is_enabled = true
	
	--// Creates a movement to slide a panel horizontally on or off screen
		--is_exit (boolean, optional) true means slide off screen, false or nil slides on screen (default)
	local function new_horz_movement(is_exit)
		local is_left = dst_x < 0
		if is_exit then is_left = not is_left end
		
		local movement = sol.movement.create"straight"
		movement:set_speed(256)
		movement:set_angle(is_left and math.pi or 0)
		movement:set_max_distance(dst_x>=0 and panel_width+dst_x or -dst_x)
		
		return movement
	end
	
	 --define these functions later
	local create_panel
	local remove_panel
	
	--// adds the panel (table) to the visible list
		--must externally verify panel for the item doesn't already exist (and doesn't exceed max count)
	create_panel = function(panel)
		local name = panel.name
		table.insert(panels, panel) --add new panel
		panels[name] = panel
		
		--add horizontal slide translation to newly added panel
		panel.x = (dst_x>0 and -panel_width or 0) - dst_x --set position off-screen initially
		local movement = new_horz_movement(false)
		movement:start(panel)
		
		--create timer to remove panel
		panel.timer = sol.timer.start(menu, duration, function() remove_panel(name) end)
	end
	
	--// remove the panel corresponding to this name (string)
		--creates a movement to slide the panel offscreen and the panel is removed once movement is done
	remove_panel = function(name)
		for i,panel in ipairs(panels) do --find the index corresponding the the panel to remove
			if name == panel.name then
				local movement = new_horz_movement(true) --create movement to slide offscreen
				
				--keep track of this panel by its movement now rather than by name
				--note: picking up the same item while this panel is moving creates a new panel
				panel.movement = movement
				panel.name = nil
				panels[name] = nil
				
				--wait until movement is complete to remove panel from list
				movement:start(panel, function()
					local index --index of panel removed
					for i,panel in ipairs(panels) do --find the index corresponding the the panel to remove
						if movement == panel.movement then
							table.remove(panels, i)
							index = i  --panels here and up need vertical movement to fill gap
							break
						end
					end
					
					--move a panel from queue to active list if new slot is available
					if #panels < MAX_COUNT then
						local new_panel = table.remove(queue, 1)
						if new_panel then
							local new_name = new_panel.name
							queue[new_name] = nil
							create_panel(new_panel)
						end
					end
					
					--add vertical slide translations to fill the gap
					local target = {x=0, y=0} --target of movement (applies to multiple panels)
					local movement = sol.movement.create"straight"
					movement:set_speed(128)
					movement:set_angle(math.pi/2) --up
					movement:set_max_distance(Y_OFFSET)
					movement:start(target, function()
						--remove target from visible panels once movement is complete
						for i,panel in ipairs(panels) do
							local movements = panel.movements
							if movements and movements[target] then
								movements[target] = nil
								panel.offset = panel.offset - 1
							end
						end
					end)
					
					--apply movement to applicable panels
					for i=index,#panels do --for all panels above the one removed
						local panel = panels[i]
						panel.offset = (panel.offset or 0) + 1 --instantly move to old location
						panel.movements = panel.movements or {}
						panel.movements[target] = target
					end
				end)
				
				break
			end
		end
	end
	
	--// Replace info of existing panel with same name as the newly specified panel info
		--new_panel (table, key/value) - new panel info to use
			--info from existing panel matching new_panel.name will be replaced
		--list (table) - which list it is to be applied to (panels or queue tables)
		--returns the panel table that was updated, or nil if not found
	local function update_panel(new_panel, list)
		local new_name = new_panel.name
		local old_panel
		
		--find existing panel with matching name
		for i,panel in ipairs(list) do
			if list[new_name] == panel then --found the correct panel
				old_panel = panel
				old_panel.variant = new_panel.variant
				old_panel.amount = new_panel.amount
				old_panel.max_amount = new_panel.max_amount
				old_panel.sprite = new_panel.sprite --TODO may have sprite frame discontinuity if same sprite
				old_panel.text_surface = new_panel.text_surface
				break
			end
		end
		
		return old_panel --nil if could not find corresponding panel
	end
	
	--// Get/set the position of the hud element on the screen
		--x (number, integer) - x coordinate of where to draw the hud submenu in pixels
			--if x is negative then specifies position from right edge of screen
		--y (number, integer) - y coordinate of where to draw the hud submenu in pixels
			--if y is negative then specifies position from the bottom edge of screen
	function menu:get_dst() return dst_x, dst_y end
	function menu:set_dst(x,y)
		x = tonumber(x)
		y = tonumber(y)
		assert(type(x)=="number", "Bad argument #2 to 'set_dst' (number expected)")
		assert(type(y)=="number", "Bad argument #3 to 'set_dst' (number expected)")
		x = math.floor(x)
		y = math.floor(y)
		
		dst_x = x
		dst_y = y
	end
	
	--// Get/set visibility of the hud submenu
		--enabled (boolean) - true makes visible, false hides
	function menu:get_enabled() return is_enabled end
	function menu:set_enabled(enabled)
		assert(type(enabled)=="boolean", "Bad argument #2 to 'set_enabled' (boolean expected)")
		is_enabled = enabled
	end
	
	--// Create a new panel to be displayed for the given item and variant
		--item (sol.item) - item to display a panel with sprite and amount on hud
		--variant (number, positive integer, optional) - variant of the item (determines sprite displayed)
			--default: variant 1
	function menu:add_item(item, variant)
		local name = item:get_name()
		local amount = item:get_amount()
    --Blood vials and quicksilver bullets can be in storage
    if name == "blood_vial_user" then amount = amount + (game:get_value"stored_blood_vials" or 0)
    elseif name == "pistol" then amount = amount + (game:get_value"stored_bullets" or 0) end
		local max_amount = item:get_max_amount()
		
		--create item icon sprite
		local sprite = sol.sprite.create"entities/items"
		sprite:set_animation(name)
		local direction = variant - 1
		sprite:set_direction(direction)
		
		--create amount text surface
		local font = "enter_command"
		local text_surface = sol.text_surface.create{
			horizontal_alignment = "right",
			vertical_alignment = "top",
			text = amount,
			font = font,
      font_size = 16,
		}
		
		local panel = {
			name = name,
			variant = variant,
			amount = amount,
			max_amount = max_amount,
			sprite = sprite,
			text_surface = text_surface,
			x=0, y=0,
		}
		
		if panels[name] then --already is a panel for this item, extend its timer instead
			--abort existing timer
			local timer = panels[name].timer
			if timer then timer:stop() end
			
			--update panel info
			panel = update_panel(panel, panels)
			panel.timer = sol.timer.start(self, duration, function() remove_panel(name) end)
		elseif queue[name] then	--already is a panel for this item in queue
			--update panel info
			update_panel(panel, queue)
		elseif #panels < MAX_COUNT then --display new panel if not full
			create_panel(panel)
		else --add panel to queue to be displayed later
			table.insert(queue, panel)
			queue[name] = panel
		end
	end
	
	--// When the hud submenu is started
	function menu:on_started()
		--clear any existing data
		panels = {}
		queue = {}
	end
	
	--hide hud submenu when paused
	function menu:on_paused() is_enabled = false end
	function menu:on_unpaused() is_enabled = true end
	
	function menu:on_draw(dst_surface)
		if not is_enabled then return end --don't draw if not enabled
		
		local width, height = dst_surface:get_size()
		local x = dst_x + (dst_x < 0 and width or 0)
		local y = dst_y + (dst_y < 0 and height or 0)
		
		local offset = 0 --increment vertical offset each panel
		for _,panel in ipairs(panels) do
			local slide_y = (panel.offset or 0)*Y_OFFSET --distance to move from all movements combined
			for target in pairs(panel.movements or {}) do
				slide_y = slide_y + target.y --add up individual movements
			end
			
			--draw panel bg, item sprite and amount text
			panel_img:draw(dst_surface, x+panel.x, y+offset+panel.y+slide_y)
			local origin_x, origin_y = panel.sprite:get_origin()
			panel.sprite:draw(dst_surface, x+4+panel.x+origin_x, y+offset+4+panel.y+origin_y+slide_y)
			panel.text_surface:draw(dst_surface, x+44+panel.x, y+offset+8+panel.y+slide_y)
			offset = offset + Y_OFFSET
		end
	end
	
	return menu
end

return hud_submenu

--[[ Copyright 2019 Llamazing
  [] 
  [] This program is free software: you can redistribute it and/or modify it under the
  [] terms of the GNU General Public License as published by the Free Software Foundation,
  [] either version 3 of the License, or (at your option) any later version.
  [] 
  [] It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
  [] without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  [] PURPOSE.  See the GNU General Public License for more details.
  [] 
  [] You should have received a copy of the GNU General Public License along with this
  [] program.  If not, see <http://www.gnu.org/licenses/>.
  ]]