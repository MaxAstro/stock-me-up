-- Locates or creates a special logistic section for the mod to use
-- Thank you Atria for letting me adapt this code
local function get_request_logistic_section(logistic_point, create_new)
    ---@cast logistic_point LuaLogisticPoint
    ---@cast create_new boolean
    create_new = create_new or false    -- Default create_new to false if unspecified
    local section_name = "Stock Me Up"
    for _, section in pairs(logistic_point.sections) do     -- Iterate through all logistic sections to find ours and return it
        if section.group == section_name then
            return section --[[@as LuaLogisticSection]]
        end
    end

    -- If we got here then the section doesn't exist yet; are we allowed to create it? If not, simply return that it doesn't exist
    if not create_new then return nil end
    -- Otherwise create the new section and return it
    local section = logistic_point.add_section(section_name)
    ---@cast section LuaLogisticSection
    -- The above cast is because it should be impossible for add_section to return nil at this point
    -- We already checked to make sure the section doesn't already exist
    for i = 1, section.filters_count do
        section.clear_slot(i)
    end
    return section
end

-- Sums up the total amount of potential stock requests for an item, not counting the request section
local function calc_request_ceiling(logistic_point, name)
    ---@cast logistic_point LuaLogisticPoint
    ---@cast name string
    local request_section = get_request_logistic_section(logistic_point)
    local request_ceiling = 0
    for _, section in pairs(logistic_point.sections) do
        if not request_section or section.group ~= request_section.group then   -- If this is called when the request section doesn't exist, it's safe to not check for it.
            for _, filter_slot in pairs(section.filters) do
                if filter_slot.value.name == name then
                    local increment = filter_slot.max - filter_slot.min
                    request_ceiling = request_ceiling + increment
                end
            end
        end
    end
    return request_ceiling
end


-- Determines if a filter for a specific item exists in a given section
local function find_filter_in_section(name, section)
    ---@cast name string
    ---@cast section LuaLogisticSection
    for i, filter_slot in pairs(section.filters) do
        if filter_slot.value and filter_slot.value.name == name then
            return i
        end
    end
    return nil
end

-- Locates the number of the first empty slot in a given section
local function find_empty_slot(section)
    ---@cast section LuaLogisticSection
    if section.filters_count == 0 then return 1 end
    local slot_number = 0
    for i, filter_slot in ipairs(section.filters) do
        slot_number = i
        if not filter_slot.value then
            return slot_number
        end
    end
    return slot_number+1
end

-- Main function - this looks for players with active logistics requests and adds extra filters to them
local function check_logistics(event)
    ---@cast event EventData.on_player_main_inventory_changed
    -- Note that technically event can also be EventData.on_player_cursor_stack_changed, but the two events pass identical data so it's moot
    local player = game.players[event.player_index]
    if event.name == defines.events.on_player_main_inventory_changed then -- If we got here from main inventory changing, note that.
        storage.player_inventory_changed[player] = true
    end
    -- Pinpoint the logistic point of the player.character that triggered the inventory event
    if player and player.valid and player.character and player.character.valid then
        local logistic_point = player.character.get_logistic_point(defines.logistic_member_index.character_requester)
        ---@cast logistic_point LuaLogisticPoint
        if logistic_point and logistic_point.targeted_items_deliver ~= { } then         -- Did we get a non-empty logistic point and are items scheduled for delivery?
            for logistic_item, _ in pairs(logistic_point.targeted_items_deliver) do     -- Iterate through each item scheduled for delivery
                for _, section in pairs(logistic_point.sections) do                     -- Iterate through each section looking for the requested item
                    for i, requested_item in pairs(section.filters) do
                        if requested_item.value and requested_item.value.name == logistic_item and requested_item.max ~= nil and requested_item.max > requested_item.min then
                                                                                                                            -- If the item is found and max is greater than the min but not infinite, then
                            local request_amount = requested_item.max - requested_item.min                                  -- Calculate the amount of items needed
                            local stock_section = get_request_logistic_section(logistic_point, true)                -- Find or create the stock-up section
                            ---@cast stock_section LuaLogisticSection
                            local target_slot = find_filter_in_section(requested_item.value.name, stock_section)            -- If a request for that item already exists, use that slot
                            if target_slot then                                                                             -- Increase the existing request if not already at the cap      
                                request_ceiling = calc_request_ceiling(logistic_point, requested_item.value.name)
                                if stock_section.get_slot(target_slot).min < request_ceiling then
                                    local filter = stock_section.get_slot(target_slot)
                                    filter.min = filter.min + request_amount
                                    if filter.min > request_ceiling then filter.min = request_ceiling end               -- Don't go over the cap.
                                    stock_section.set_slot(target_slot, filter)
                                end
                            else                                                                                        -- If no request for the item exists in the stock-up section then
                                target_slot = find_empty_slot(stock_section)                                            -- Find the first empty slot
                                stock_section.set_slot(target_slot, {                                                   -- Create a request for the items
                                    value = requested_item.value.name,
                                    min = request_amount
                                })
                            end
                            local output = calc_request_ceiling(logistic_point, requested_item.value.name)
                            --local output = stock_section.get_slot(target_slot).min                                      -- Debug code
                            player.create_local_flying_text({text = output, create_at_cursor = true})
                        end
                    end
                end
            end
        end
    end
end

-- Remove filters from the request section as their requests are filled
-- Thank you Atria for letting me use this code
local function cleanup_fulfilled_requests()
    for player_index, _ in pairs(storage.player_inventory_changed) do   -- Cycle through the players whose inventory has changed
        local player = game.players[player_index]
        if player and player.valid and player.character and player.character.valid then
            local logistic_point = player.character.get_logistic_point(defines.logistic_member_index.character_requester)

            if logistic_point then
                local section = get_request_logistic_section(player, logistic_point)
                if section then
                    for i, request in pairs(section.filters) do    -- I think it's okay to use pairs here instea of ipairs
                        -- TODO check quality
                        local item_count = player.get_item_count(request.value.name)
                        request_ceiling = calc_request_ceiling(logistic_point, request.value.name)
                        if item_count >= request_ceiling then
                            section.clear_slot(i)
                        end
                    end

                    if section.filters_count == 0 then
                        logistic_point.remove_section(section.index)
                    end
                end
            end
        end
    end
    storage.player_inventory_changed = {}
end

-- Initialize the storage variable used to track when a player's inventory changes
-- Thank you Atria for letting me use this code
local function init_globals()
    if storage.player_inventory_changed == nil then
        storage.player_inventory_changed = {}
    end
end

local function cleanup_player_globals(event)
    storage.player_inventory_changed[event.player_index] = nil
end


script.on_event(defines.events.on_player_main_inventory_changed, check_logistics)
script.on_event(defines.events.on_player_cursor_stack_changed, check_logistics)

script.on_nth_tick(60, cleanup_fulfilled_requests)

script.on_init(init_globals)
script.on_configuration_changed(init_globals)
script.on_event(defines.events.on_player_removed, cleanup_player_globals)