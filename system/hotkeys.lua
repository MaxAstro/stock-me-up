-- Hotkey that does nearly all the things
local stock_me_up_main_hotkey = {
    type = "custom-input",
    name = "stock-me-up-main-hotkey",
    localised_name = {"Stock-Me-Up-Hotkeys.stock-me-up-main-hotkey"},
    localised_description = {"Stock-Me-Up-Hotkeys.stock-me-up-main-hotkey-description"},
    order = "StockMeUp01",
    key_sequence = "ALT + S",
    action = "lua"
}
---@cast stock_me_up_main_hotkey data.CustomInputPrototype

-- Hotkey for fully stocking up; deprecated until selected_prototype is quality aware
local stock_me_up_full_hotkey = {
    type = "custom-input",
    name = "stock-me-up-full-hotkey",
    order = "StockMeUp02",
    key_sequence = "ALT + SHIFT + S",
    action = "lua"
}
---@cast stock_me_up_full_hotkey data.CustomInputPrototype

data:extend {stock_me_up_main_hotkey}