-- Stock section name               DONE
local stock_section_name = {
    type = "string-setting",
    name = "stock-me-up-section-name-setting",
    setting_type = "runtime-per-user",
    order = "a",
    default_value = "Stock Me Up",
    allow_blank = false,
    auto_trim = true
}

-- Ignore section filter            DONE
local ignore_section_filter = {
    type = "string-setting",
    name = "stock-me-up-section-ignore-setting",
    setting_type = "runtime-per-user",
    order = "b",
    default_value = "",
    allow_blank = true,
    auto_trim = true
}

-- Aggressive stock checking        DONE
local aggressive_stock_checking = {
    type = "bool-setting",
    name = "stock-me-up-aggressive-stock-checking-setting",
    setting_type = "runtime-per-user",
    order = "c",
    default_value = false
}

-- Disable automatic requests       DONE
local disable_automatic_requests = {
    type = "bool-setting",
    name = "stock-me-up-no-automatic-requests-setting",
    setting_type = "runtime-per-user",
    order = "d",
    default_value = false
}

-- Clearance check rate             DONE
local clearance_check_rate = {
    type = "int-setting",
    name = "stock-me-up-request-cleanup-check-rate-setting",
    setting_type = "runtime-global",
    order = "a",
    default_value = 60,
    minimum_value = 1,
}

data:extend({
    stock_section_name,
    ignore_section_filter,
    aggressive_stock_checking,
    disable_automatic_requests,
    clearance_check_rate,
})