-- This file contains utility functions for comparing or examing filter slots or generally manipulating logistics

-- Get a player's logistic point; unlike character.get_logistic_point, this nil checks and doesn't require providing the character
---@param player LuaPlayer
---@return LuaLogisticPoint?
function return_logistic_point(player)
    if player and player.valid and player.character and player.character.valid then
        local logistic_point = player.character.get_logistic_point(defines.logistic_member_index.character_requester)
        return logistic_point
    end
end

-- Locates or creates a special logistic section for the mod to use
-- Thank you Atria for letting me adapt this code
---@param logistic_point LuaLogisticPoint
---@param create_new? boolean
---@return LuaLogisticSection?
function get_request_logistic_section(logistic_point, create_new)
    create_new = create_new or false    -- Default create_new to false if unspecified
    local section_name = "Stock Me Up"
    for _, section in pairs(logistic_point.sections) do     -- Iterate through all logistic sections to find ours and return it
        if section.group == section_name then
            return section
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

-- Clean out the special logistic section, if it exists
---@param logistic_point LuaLogisticPoint
function destroy_request_logistic_section(logistic_point)
    request_section = get_request_logistic_section(logistic_point)
    if request_section then
        for i, _ in pairs(request_section.filters) do
            request_section.clear_slot(i)
        end
        logistic_point.remove_section(request_section.index)
    end
end

-- Determines if two filter slots contain items with the same name and quality, or if a single filter slot contains a specified item and quality
-- Works with LogisticFilter, CompiledLogisticFilter, or ItemIDAndQualityIDPair and can mix and match!
---@param first_slot LogisticFilter|CompiledLogisticFilter|ItemIDAndQualityIDPair
---@param second_slot LogisticFilter|CompiledLogisticFilter|ItemIDAndQualityIDPair
---@return boolean
function compare_filters(first_slot, second_slot)
    if first_slot.value then            -- Standardize the formatting
        first_slot.name = first_slot.value.name
        first_slot.quality = first_slot.value.quality
    end
    if second_slot.value then            -- Standardize the formatting
        second_slot.name = second_slot.value.name
        second_slot.quality = second_slot.value.quality
    end
    return first_slot.name == second_slot.name
            and first_slot.quality == second_slot.quality
end

-- Sums up the total potential stock request for an item, subtracting whatever is already requested from the stock section
-- Providing the logistic point is optional, in case it has already been acquired
---@param player LuaPlayer
---@param requested_item LogisticFilter|CompiledLogisticFilter|ItemIDAndQualityIDPair
---@param logistic_point LuaLogisticPoint?
---@return integer?
function calc_request_ceiling(player, requested_item, logistic_point)
    if not logistic_point then
        logistic_point = return_logistic_point(player)
        if not logistic_point then
            return 0        -- How did we get here? Who knows, but bail.
        end
    end
    local request_section = get_request_logistic_section(logistic_point)
    local request_amount = 0
    local found_filter = false      -- If not filter exists for an item outside of the stock section, don't touch it
    for _, section in pairs(logistic_point.sections) do
        if not request_section or section.group ~= request_section.group then   -- If this is called when the request section doesn't exist, it's safe to not check for it.
            for _, filter_slot in pairs(section.filters) do
                if compare_filters(filter_slot, requested_item) then
                    found_filter = true                                         -- Note if a filter was found at all, in case an overstock is desired
                    if filter_slot.max then                                     -- But don't increment the request amount unless a max is set
                        local increment = filter_slot.max - filter_slot.min
                        request_amount = request_amount + increment
                    end
                end
            end
        end
        if request_section and section.group == request_section.group then      -- If the request section does exist, subtract any existing requests
            for _, filter_slot in pairs(section.filters) do
                if compare_filters(filter_slot, requested_item) then
                    request_amount = request_amount - filter_slot.min
                end
            end
        end
    end
    if found_filter then
        return request_amount
    else
        return nil
    end
end

-- Sums up the total actual requested stock for an item, min and max, including the request section
-- Providing the logistic point is optional, in case it has already been acquired
---@param player LuaPlayer
---@param requested_item LogisticFilter|CompiledLogisticFilter|ItemIDAndQualityIDPair
---@param logistic_point LuaLogisticPoint?
---@return stock_ceiling
function calc_stock_ceiling(player, requested_item, logistic_point)
    ---@class (exact) stock_ceiling
    ---@field min integer
    ---@field max integer
    local stock_ceiling = {min = 0, max = 0}
    if not logistic_point then
        logistic_point = return_logistic_point(player)
        if not logistic_point then
            stock_ceiling.min = 0
            stock_ceiling.max = 0
            return stock_ceiling      -- How did we get here? Who knows, but bail.
        end
    end
    for _, section in pairs(logistic_point.sections) do
        for _, filter_slot in pairs(section.filters) do
            if compare_filters(filter_slot, requested_item) then
                stock_ceiling.min = stock_ceiling.min + filter_slot.min
                if filter_slot.max then
                    stock_ceiling.max = stock_ceiling.max + filter_slot.max
                else
                    stock_ceiling.max = stock_ceiling.max + filter_slot.min     -- Max should never be less than min
                end
            end
        end
    end
    return stock_ceiling
end

-- Determines if a filter for a specific item exists in a given section and returns the slot number
---@param requested_item LogisticFilter|CompiledLogisticFilter|ItemIDAndQualityIDPair
---@param section LuaLogisticSection
---@return integer?
function find_filter_in_section(requested_item, section)
    for i, filter_slot in pairs(section.filters) do
        if compare_filters(filter_slot, requested_item) then
            return i
        end
    end
    return nil
end

-- Locates the number of the first empty slot in a given section
---@param section LuaLogisticSection
---@return integer
function find_empty_slot(section)
    if section.filters_count == 0 then return 1 end
    local slot_number = 0
    for i, filter_slot in ipairs(section.filters) do
        slot_number = i
        if not filter_slot.value then
            return slot_number
        end
    end
    return slot_number+1    -- If every existing slot is full, return the index of the next slot
end

-- Turns an item name and quality name into an ItemIDAndQualityIDPair
---@param item_name ItemID
---@param quality_name QualityID
---@return ItemIDAndQualityIDPair
function build_item_quality_pair(item_name, quality_name)
    local item_quality_pair = {
        name = item_name,
        quality = quality_name
    }
    return item_quality_pair
end

-- Pushes a request to the stock section
-- Providing the logistic point is optional, in case it has already been acquired
-- Setting overstock = true will ignore the stock ceiling and request an extra stack of the item
---@param player LuaPlayer
---@param requested_item LogisticFilter|CompiledLogisticFilter|ItemIDAndQualityIDPair
---@param logistic_point LuaLogisticPoint?
---@param overstock boolean?
---@return integer?
function add_stock_request(player, requested_item, logistic_point, overstock)
    overstock = overstock or false
    if not logistic_point then
        logistic_point = return_logistic_point(player)
        if not logistic_point then
            return 0        -- How did we get here? Who knows, but bail.
        end
    end
    -- Standardize the structure of the requested filter
    if requested_item.value then
        requested_item.name = requested_item.value.name
        requested_item.quality = requested_item.value.quality
    end
    local stock_section = get_request_logistic_section(logistic_point, true)                    -- Find or create the request section
    if stock_section then
        local request_amount = calc_request_ceiling(player, requested_item, logistic_point)    -- Determine how much of the item we might want
        if not request_amount then
            return nil                     -- Return nil only if no filter exists for the item at all 
        end
        local overstock_amount = 0
        if request_amount <= 0 then        -- There's no room to request more stock, unless we want to overstock.
            if overstock then
                request_amount = 0
                overstock_amount = prototypes.item[requested_item.name].stack_size
            else
                return 0
            end
        end
        local target_slot = find_filter_in_section(requested_item, stock_section)
        if not target_slot then                                 -- If no filter for the item exists in the request section, then
            target_slot = find_empty_slot(stock_section)        -- Find the first empty slot
            local filter = {                                    -- Create a new empty filter
                value = {
                    name = requested_item.name,
                    quality = requested_item.quality
                },
                min = 0
            }
            stock_section.set_slot(target_slot, filter)
        end
        local filter = stock_section.get_slot(target_slot)              -- Get the filter from target_slot
        local old_minimum = filter.min
        filter.min = filter.min + request_amount + overstock_amount     -- Increase it
        if filter.min > request_amount and not overstock then           -- Don't go over the cap unless we are overstocking
            filter.min = request_amount
        end
        if overstock_amount > 0 then filter.max = filter.min end        -- Max is used to not automatically remove overstock requests
        stock_section.set_slot(target_slot, filter)                     -- Set it back to the slot
        return filter.min - old_minimum                                 -- Return the amount of stock added
    end
    return 0
end