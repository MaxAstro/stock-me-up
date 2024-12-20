require 'system.utility'

-- Main function - this looks for players with active logistics requests and adds extra filters to them
---@param event EventData.on_player_main_inventory_changed
-- Note for the above: technically event can also be EventData.on_player_cursor_stack_changed, but the two events pass identical data so it's moot for casting purposes
local function check_logistics(event)
    local player = game.players[event.player_index]
    if settings.get_player_settings(player)["stock-me-up-no-automatic-requests-setting"].value == true then
        return end              -- Skip players with automatic requests disabled
    if event.name == defines.events.on_player_main_inventory_changed then -- If we got here from main inventory changing, note that.
        storage.player_inventory_changed[event.player_index] = true
    end
    local logistic_point = return_logistic_point(player)
    if logistic_point and next(logistic_point.targeted_items_deliver) ~= nil then   -- Did we get a non-empty logistic point and are items scheduled for delivery?
        for _, logistic_item in pairs(logistic_point.targeted_items_deliver) do     -- Iterate through each item scheduled for delivery
            for _, section in pairs(logistic_point.sections) do                     -- Iterate through each section looking for the requested item
                for _, requested_item in pairs(section.filters) do
                    if requested_item.value and requested_item.value.name == logistic_item.name
                            and requested_item.value.quality == logistic_item.quality then      -- If the item is found and matches quality, then
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
    storage.player_inventory_changed[event.player_index] = true     -- Even though inventory didn't change, we want to double check if any requests need to be removed after this
    local logistic_point = return_logistic_point(player)
    local inventory = player.get_main_inventory()
    if logistic_point and inventory then
        if player.is_cursor_empty() then        -- Is the player holding an item?
            -- No, so attempt a full stock.
            local items_stocked = 0
            for _, filter in pairs(logistic_point.filters) do
                if filter.name then
                    local item_to_check = build_item_quality_pair(filter.name, filter.quality)
                    local item_count = inventory.get_item_count(item_to_check)                          -- How many of the this item does the player have?
                    local stock_ceiling = calc_stock_ceiling(player, filter, logistic_point)            -- And what is the stock ceiling for that item?
                    if stock_ceiling.min < stock_ceiling.max and item_count < stock_ceiling.max then    -- Create a stock request if we are low
                        items_stocked = items_stocked + add_stock_request(player, filter, logistic_point)
                    end
                end
            end
            if items_stocked == 0 then          -- No items were stocked, so remove the stock section instead
                destroy_request_logistic_section(logistic_point)
            player.print({"Stock-Me-Up-Messages.removed-all-requests"})
            else
                player.print({"Stock-Me-Up-Messages.request-full-stock"})
            end
        else
            -- Yes, so attempt to stock the held item, overstocking if needed.
            local requested_item = build_item_quality_pair(player.cursor_stack.name, player.cursor_stack.quality.name)
            items_stocked = add_stock_request(player, requested_item, logistic_point)
            if not items_stocked then
                if requested_item.quality ~= "normal" then
                    player.print({"Stock-Me-Up-Messages.no-request-exists-quality",prototypes.quality[requested_item.quality].localised_name,prototypes.item[requested_item.name].localised_name})
                else
                    player.print({"Stock-Me-Up-Messages.no-request-exists",prototypes.item[requested_item.name].localised_name})
                end
                return nil
            end
            if items_stocked == 0 then
                items_stocked = add_stock_request(player, requested_item, logistic_point, true)
                if requested_item.quality ~= "normal" then
                    player.print({"Stock-Me-Up-Messages.requested-overstock-quality",prototypes.quality[requested_item.quality].localised_name,prototypes.item[requested_item.name].localised_name,})
                else
                    player.print({"Stock-Me-Up-Messages.requested-overstock",prototypes.item[requested_item.name].localised_name})
                end
            else
                if requested_item.quality ~= "normal" then
                    player.print({"Stock-Me-Up-Messages.requested-stock-quality",prototypes.quality[requested_item.quality].localised_name,prototypes.item[requested_item.name].localised_name,})
                else
                    player.print({"Stock-Me-Up-Messages.requested-stock",prototypes.item[requested_item.name].localised_name})
                end
            end
        end
    end
end

-- Remove filters from the request section as their requests are filled
-- Thank you Atria for letting me adapt this code
local function cleanup_fulfilled_requests()
    for player_index, _ in pairs(storage.player_inventory_changed) do           -- Cycle through the players whose inventory has changed
        local player = game.get_player(player_index)    --[[@as LuaPlayer]]
        
        local logistic_point = return_logistic_point(player)
        local inventory = player.get_main_inventory()                           -- get_item_count is only quality aware in LuaInventory
        if logistic_point and inventory then                                    -- Find their logistic point and request section
            local request_section = get_request_logistic_section(logistic_point)
            if request_section then
                for i, requested_item in pairs(request_section.filters) do      -- I think it's okay to use pairs here instead of ipairs
                    if requested_item.value and not requested_item.max then     -- Don't remove requests that have a max set, they are overstocks
                        local item_to_check = build_item_quality_pair(requested_item.value.name, requested_item.value.quality)
                        local item_count = inventory.get_item_count(item_to_check)                        -- How many of the requested item does the player have?
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
        if settings.get_player_settings(player)["stock-me-up-aggressive-stock-checking-setting"].value == true then
            local pseudo_event = {              -- Create fake EventData to pass to check_logistics
                name = "pseudo-event",
                player_index = player_index
            }
            check_logistics(pseudo_event)       -- Run a logistics check if the setting for aggressive checking is enabled
        else
            table.remove(storage.player_inventory_changed, player_index)    -- Don't repeatedly check players otherwise
        end
    end
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
-- script.on_event("stock-me-up-full-hotkey", do_full_hotkey) -- Deprecated; selected_prototype is now quality aware, but I'm not sure this direction makes sense

script.on_nth_tick(settings.global["stock-me-up-request-cleanup-check-rate-setting"].value --[[@as integer]], cleanup_fulfilled_requests)

script.on_init(init_globals)
script.on_configuration_changed(init_globals)
script.on_event(defines.events.on_player_removed, cleanup_player_globals)