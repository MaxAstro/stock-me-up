require 'system.utility'

-- Main function - this looks for players with active logistics requests and adds extra filters to them
---@param event EventData.on_player_main_inventory_changed
-- Note for the above: technically event can also be EventData.on_player_cursor_stack_changed, but the two events pass identical data so it's moot for casting purposes
local function check_logistics(event)
    local player = game.players[event.player_index]
    if event.name == defines.events.on_player_main_inventory_changed then -- If we got here from main inventory changing, note that.
        storage.player_inventory_changed[event.player_index] = true
    end
    local logistic_point = return_logistic_point(player)
    if logistic_point and next(logistic_point.targeted_items_deliver) ~= nil then   -- Did we get a non-empty logistic point and are items scheduled for delivery?
        for logistic_item, _ in pairs(logistic_point.targeted_items_deliver) do     -- Iterate through each item scheduled for delivery
            for _, section in pairs(logistic_point.sections) do                     -- Iterate through each section looking for the requested item
                for i, requested_item in pairs(section.filters) do
                    if requested_item.value and requested_item.value.name == logistic_item then -- If the item is found, then
                        add_stock_request(player, requested_item, logistic_point)               -- Create a stock request, if one is needed
                    end
                end
            end
        end
    end
end

-- Request stock of an item (or all items) using the main hotkey
---@param event EventData.CustomInputEvent
local function do_main_hotkey(event)
    local player = game.players[event.player_index]
    local logistic_point = return_logistic_point(player)
    local inventory = player.get_main_inventory()
    if logistic_point and inventory then
        if player.is_cursor_empty() then        -- Is the player holding an item?
            -- No, so attempt a full stock
            local items_stocked = 0
            for _, filter in pairs(logistic_point.filters) do
                if filter.name then
                    items_stocked = items_stocked + add_stock_request(player, filter, logistic_point)
                end
            end
            if items_stocked == 0 then          -- No items were stocked, so remove the stock section instead
                destroy_request_logistic_section(logistic_point)
            end
        end
    end
end

-- Remove filters from the request section as their requests are filled
-- Thank you Atria for letting me adapt this code
local function cleanup_fulfilled_requests()
    for player_index, _ in pairs(storage.player_inventory_changed) do           -- Cycle through the players whose inventory has changed
        local player = game.players[player_index]
        local logistic_point = return_logistic_point(player)
        local inventory = player.get_main_inventory()                           -- get_item_count is only quality aware in LuaInventory
        if logistic_point and inventory then                                    -- Find their logistic point and request section
            local request_section = get_request_logistic_section(logistic_point)
            if request_section then
                for i, requested_item in pairs(request_section.filters) do      -- I think it's okay to use pairs here instead of ipairs
                    if requested_item.value then                                -- Value will be nil if there is a hole in the logistics section
                        local item_to_check = build_item_quality_pair(requested_item.value.name, requested_item.value.quality)
                        local item_count = inventory.get_item_count(item_to_check)                          -- How many of the requested item does the player have?
                        local stock_ceiling = calc_stock_ceiling(player, requested_item, logistic_point)  -- And what is the stock ceiling for that item?
                        if item_count >= stock_ceiling.min then                                           -- If we are at the ceiling, remove the request
                            request_section.clear_slot(i)
                        end
                    end
                end
                -- If all requests are filled, remove the request section
                if request_section.filters_count == 0 then
                    logistic_point.remove_section(request_section.index)
                end
            end
        end
    end                                 -- We checked all players whose inventory changed since last time
storage.player_inventory_changed = {}   -- So it's safe to clear the storage variable
end

-- Initialize the storage variable used to track when a player's inventory changes
-- Thank you Atria for letting me use this code
local function init_globals()
    if storage.player_inventory_changed == nil then
        storage.player_inventory_changed = {}
    end
end

-- Remove a player from the storage variable if they are deleted from the game
-- Thank you Atria for letting me use this code
local function cleanup_player_globals(event)
    storage.player_inventory_changed[event.player_index] = nil
end


script.on_event(defines.events.on_player_main_inventory_changed, check_logistics)
script.on_event(defines.events.on_player_cursor_stack_changed, check_logistics)

script.on_event("stock-me-up-main-hotkey", do_main_hotkey)
-- script.on_event("stock-me-up-full-hotkey", do_full_hotkey) -- Deprecated until selected_prototype is quality aware

script.on_nth_tick(60, cleanup_fulfilled_requests)

script.on_init(init_globals)
script.on_configuration_changed(init_globals)
script.on_event(defines.events.on_player_removed, cleanup_player_globals)