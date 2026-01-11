local script_dir = "/WIDGETS/HeliDash/"
local heliDashFunctions = loadScript(script_dir .. "helidashFunctions.lua")()
local showDebugBorder = 0
-- Header font - will be set dynamically in build_ui based on available space
local headerFont = SMLSIZE
local header_h = 0
local headerFontColour = COLOR_THEME_SECONDARY1

-- Map font names (strings) to EdgeTx constants for use in labels
local FontConstants = {
    TINSIZE = TINSIZE,
    SMLSIZE = SMLSIZE,
    STDSIZE = STDSIZE,
    MIDSIZE = MIDSIZE,
    DBLSIZE = DBLSIZE,
    XXLSIZE = XXLSIZE
}


local wgt = {is_connected = false, rssi_state = false, rssi_state_change_time = 0, rssi_debounce_threshold = 5}

wgt.values = {
    -- ========== LABELS (for future / possible translation support ) ==========
    label_current = "Current",
    label_fuel = "Fuel",
    label_capacity = "Energy Used (mAh)",
    label_esc_temp = "ESC Temperature",
    label_battery_voltage = "Battery Voltage",
    label_headspeed = "Headspeed",
    label_bec_voltage = "BEC Voltage",
    label_profile = "Profile",
    label_rate = "Rate",
    label_arm_state = "Arm State",
    label_governor = "Governor State",
    label_timer = "Timer",
    label_tpwr = "TPWR+",
    label_rqly = "RQly-",
    label_mcu_temp_max = "Tmcu+",
    label_armed = "Armed",
    label_disarmed = "Disarmed",
    label_flight_stats = "Flight Statistics",
    label_tx_batt = "TX Battery",
    label_min = "Min:",
    label_max = "Max:",
    label_esc_t = "ESC T",
    label_cell_v = "CELL V",
    label_bec_v = "BEC V",
    label_curr = "CURR",
    label_model = "Model: ",

    -- ========== HEADSPEED ==========
    headspeed = 0,
    headspeed_formatted = function() return string.format("%.0f", (wgt.values.headspeed or 0)) end,

    -- ========== BATTERY VOLTAGE ==========
    vbat = 0,
    vbat_formatted = function() return string.format("%.02f", wgt.values.vbat) end,

    -- ========== CELL VOLTAGE ==========
    vcel = 0,
    vcel_min = 0,
    vcel_max = 0,
    cel_count = 0,
    vcel_formatted = function() return string.format("%.02f", wgt.values.vcel) end,
    vcel_min_formatted = function() return string.format("%.02f", wgt.values.vcel_min) end,
    vcel_max_formatted = function() return string.format("%.02f", wgt.values.vcel_max) end,
    cel_count_formatted = function() return string.format("(%dS)", wgt.values.cel_count) end,

    -- ========== CURRENT / BATTERY USED ==========
    curr = 0,
    curr_min = 0,
    curr_max = 0,
    curr_min_formatted = function() return string.format("%.01f", wgt.values.curr_min) end,
    curr_formatted = function() return string.format("%.01f", wgt.values.curr) end,
    curr_max_formatted = function() return string.format("%.01f", wgt.values.curr_max) end,

    -- ========== CAPACITY ==========
    capa = 0,
    capa_percent = 100,
    capa_cell_color = COLOR_THEME_PRIMARY1,
    capa_mid_text_color = COLOR_THEME_PRIMARY1,
    capa_formatted = function() return string.format("%.0f", wgt.values.capa) end,
    capa_percent_formatted = function() return string.format("%.0f%%", wgt.values.capa_percent) end,

    -- ========== ESC TEMPERATURE ==========
    esc_temp = 0,
    esc_temp_min = 0,
    esc_temp_max = 0,
    esc_temp_formatted = function() return string.format("%.01f", wgt.values.esc_temp) end,
    esc_temp_min_formatted = function() return string.format("%.01f", wgt.values.esc_temp_min) end,
    esc_temp_max_formatted = function() return string.format("%.01f", wgt.values.esc_temp_max) end,

    -- ========== CRAFT NAME ==========
    craft_name = "NotDefined",
    craft_name_formatted = function() return wgt.values.craft_name end,

    -- ========== PROFILE & RATE ==========
    profile_id = 0,
    rate_id = 0,
    profile_id_formatted = function() return tostring(wgt.values.profile_id) end,
    rate_id_formatted = function() return tostring(wgt.values.rate_id) end,

    -- ========== ARM STATE ==========
    arm_state = false,
    arm_disable_flags_list = nil,
    arm_state_text = function() return wgt.values.arm_state and wgt.values.label_armed or wgt.values.label_disarmed end,
    arm_state_color = function() return wgt.values.arm_state and DARKGREEN or COLOR_THEME_WARNING end,

    -- ========== GOVERNOR ==========
    gov_state = 0,
    gov_state_formatted = function() return tostring(wgt.values.gov_state) end,

    -- ========== BEC VOLTAGE ==========
    vbec = 0,
    vbec_min = 0,
    vbec_max = 0,
    vbec_formatted = function() return string.format("%.02f", wgt.values.vbec) end,
    vbec_min_formatted = function() return string.format("%.02f", wgt.values.vbec_min) end,
    vbec_max_formatted = function() return string.format("%.02f", wgt.values.vbec_max) end,

    -- ========== TX VOLTS ==========
    vtx_volts = 0,
    vtx_volts_max = -1,
    vtx_volts_min = -1,
    vtx_volts_warn = -1,
    vtx_volts_percent = 0,
    vtx_volts_color = COLOR_THEME_PRIMARY1,
    vtx_volts_formatted = function() return string.format("%s%%", wgt.values.vtx_volts_percent or 0) end,

    -- ========== TIMER ==========
    timer_str = "--:--",
    timer_is_negative = false,
    timer_color = function() return wgt.values.timer_is_negative and COLOR_THEME_WARNING or COLOR_THEME_PRIMARY1 end,
    timer_str_formatted = function() return wgt.values.timer_str end,

    -- ========== RF QUALITY ==========
    rqly_min = 0,
    rqly_formatted = function() return string.format("%s%%", wgt.values.rqly_min or 0) end,

    -- ========== TX POWER ==========
    tpwr_max = 0,
    tpwr_formatted = function() return string.format("%smW", wgt.values.tpwr_max or 0) end,

    -- ========== MCU TEMPERATURE MAX ==========
    mcu_temp_max = 0,
    mcu_temp_max_formatted = function() return string.format("%.0f°C", wgt.values.mcu_temp_max) end
}

-- ============================================================================
-- UTILITY FUNCTIONS: Bar elements and font management
-- ============================================================================

function buildBarElement(parentBox, wgt, params, getPercent, getPercentColor)
    local box = parentBox:box({x = params.x, y = params.y})
    box:rectangle({w = params.w, h = params.h, color = params.bg_color or GREY, filled = true})
    box:rectangle({
        filled = true,
        size = function()
            local percent = math.max(0, math.min(100, getPercent()))
            return math.floor(percent / 100 * params.w), params.h
        end,
        color = function() return getPercentColor() or GREY end
    })
    return box
end

-- Helper function to measure actual text height for a given font
local function measureFontHeight(fontConst)
    local w, h = lcd.sizeText("X", fontConst)
    return h
end

-- Dynamic font selector: Choose appropriate font based on available height
-- Returns the actual font constant (SMLSIZE, DBLSIZE, etc.), not a string
-- Allow reasonable tolerance for font height measurement variance
local function selectFontByHeight(availableHeight, preferredOrder)
    local defaultOrder = {"XXLSIZE", "DBLSIZE", "MIDSIZE", "STDSIZE", "SMLSIZE", "TINSIZE"}
    preferredOrder = preferredOrder or defaultOrder
    local FONT_TOLERANCE = 2 -- Allow up to 2 pixels of overshoot

    for i = 1, #preferredOrder do
        local fontName = preferredOrder[i]
        local fontConst = FontConstants[fontName]
        if fontConst then
            local fontHeight = measureFontHeight(fontConst)
            if fontHeight <= availableHeight + FONT_TOLERANCE then
                return fontConst
            end
        end
    end

    local fallback = preferredOrder[#preferredOrder]
    return FontConstants[fallback] or FontConstants.STDSIZE
end



-- ============================================================================
-- UI ELEMENT BUILDERS: Individual panel builders for each data display
-- ============================================================================

-- Element builder: Battery used
local function buildBatteryUsedElement(container, wgt, x, y, c_w, c_h)
    local padding = 2
    local bar_bottom_padding = 2

    -- Layout: Fuel label (header_h), then 0%/mid%/100% row (header_h), then bar with bottom padding
    local bar_y = 2 * header_h
    local bar_h = c_h - bar_y - bar_bottom_padding
    local bar_w = c_w - 2 * padding

    -- Pick mid label font based on space available minus padding to bar
    local available_for_mid = c_h - bar_h
    local mid_label_font = selectFontByHeight(available_for_mid, {"DBLSIZE", "MIDSIZE", "SMLSIZE"})
    local mid_label_h = measureFontHeight(mid_label_font)

    local label_y = header_h
    local label_mid_y = bar_y - mid_label_h

    container:build({
        {
            type = "rectangle",
            x = x,
            y = y,
            w = c_w,
            h = c_h,
            thickness = showDebugBorder,

            children = {
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = c_w - 2 * padding,
                    h = header_h,
                    text = wgt.values.label_fuel,
                    font = headerFont,
                    color = headerFontColour
                }, {
                    type = "label",
                    x = padding,
                    y = label_y,
                    w = bar_w / 3,
                    h = header_h,
                    text = "0%",
                    font = headerFont,
                    color = headerFontColour,
                    align = LEFT
                }, {
                    type = "label",
                    x = padding + bar_w / 3,
                    y = label_mid_y,
                    w = bar_w / 3,
                    h = mid_label_h,
                    text = wgt.values.capa_percent_formatted,
                    font = mid_label_font,
                    color = function() return wgt.values.capa_mid_text_color end,
                    align = CENTER
                }, {
                    type = "label",
                    x = padding + 2 * bar_w / 3,
                    y = label_y,
                    w = bar_w / 3,
                    h = header_h,
                    text = "100%",
                    font = headerFont,
                    color = headerFontColour,
                    align = RIGHT
                }
            }
        }
    })
    buildBarElement(container, wgt, {x = x + padding, y = y + bar_y, w = bar_w - 1, h = bar_h, bg_color = COLOR_THEME_PRIMARY1},
                    function() return wgt.values.capa_percent end, function() return wgt.values.capa_cell_color end)
end

-- Element builder: ESC Temperature
local function buildESCTempElement(container, wgt, x, y, c_w, c_h)
    local padding = 2
    local availableHeight = c_h - header_h
    local valueFont = selectFontByHeight(availableHeight)
    local valueFontHeight = measureFontHeight(valueFont)
    container:build({
        {
            type = "rectangle",
            x = x,
            y = y,
            w = c_w,
            h = c_h,
            thickness = showDebugBorder,

            children = {
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = c_w - padding,
                    h = header_h,
                    text = wgt.values.label_esc_temp,
                    font = headerFont,
                    color = headerFontColour
                }, {
                    type = "label",
                    x = padding,
                    y = c_h - valueFontHeight,
                    w = c_w - padding,
                    h = valueFontHeight,
                    text = wgt.values.esc_temp_formatted,
                    font = valueFont,
                    color = COLOR_THEME_PRIMARY1
                }
            }
        }
    })
end

-- Element builder: Battery Voltage
local function buildBatteryVoltageElement(container, wgt, x, y, c_w, c_h)
    local padding = 2
    local availableHeight = c_h - header_h
    local valueFont = selectFontByHeight(availableHeight)
    local valueFontHeight = measureFontHeight(valueFont)
    container:build({
        {
            type = "rectangle",
            x = x,
            y = y,
            w = c_w,
            h = c_h,
            thickness = showDebugBorder,

            children = {
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = c_w - padding,
                    h = header_h,
                    thickness = 1,
                    text = wgt.values.label_battery_voltage,
                    font = headerFont,
                    color = headerFontColour
                }, {
                    type = "label",
                    x = padding,
                    y = c_h - valueFontHeight,
                    w = c_w - padding,
                    h = valueFontHeight,
                    text = wgt.values.vbat_formatted,
                    font = valueFont,
                    color = COLOR_THEME_PRIMARY1
                }
            }
        }
    })
end

-- Element builder: Timer
local function buildTimerElement(container, wgt, x, y, c_w, c_h)
    local padding = 2
    local availableHeight = c_h - header_h
    local valueFont = selectFontByHeight(availableHeight)
    local valueFontHeight = measureFontHeight(valueFont)
    container:build({
        {
            type = "rectangle",
            x = x,
            y = y,
            w = c_w,
            h = c_h,
            thickness = showDebugBorder,

            children = {
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = c_w - padding,
                    h = header_h,
                    text = wgt.values.label_timer,
                    font = headerFont,
                    color = headerFontColour
                }, {
                    type = "label",
                    x = padding,
                    y = c_h - valueFontHeight,
                    w = c_w - padding,
                    h = valueFontHeight,
                    text = wgt.values.timer_str_formatted,
                    font = valueFont,
                    color = wgt.values.timer_color
                }
            }
        }
    })
end

-- Element builder: Capacity Used (mAh) value
local function buildCapacityUsedValueElement(container, wgt, x, y, c_w, c_h)
    local padding = 2
    local availableHeight = c_h - header_h
    local valueFont = selectFontByHeight(availableHeight)
    local valueFontHeight = measureFontHeight(valueFont)
    container:build({
        {
            type = "rectangle",
            x = x,
            y = y,
            w = c_w,
            h = c_h,
            thickness = showDebugBorder,

            children = {
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = c_w - padding,
                    h = header_h,
                    text = wgt.values.label_capacity,
                    font = headerFont,
                    color = headerFontColour
                }, {
                    type = "label",
                    x = padding,
                    y = c_h - valueFontHeight,
                    w = c_w - padding,
                    h = valueFontHeight,
                    text = wgt.values.capa_formatted,
                    font = valueFont,
                    color = COLOR_THEME_PRIMARY1
                }
            }
        }
    })
end

-- Element builder: Flight Statistics
local function buildFlightStatisticsElement(container, wgt, x, y, c_w, c_h)
    local padding = 2
    local header_spacing = 2 -- Gap between header and column headers
    local available_h = c_h - header_h - header_spacing
    local row_h = math.floor(available_h / 3) -- 3 rows: column headers, Min, Max
    local row_h_last = available_h - row_h * 2 -- Last row gets remaining pixels
    local col_w = (c_w - 2 * padding) / 5 -- 5 columns: label + 4 values
    local col_start_y = header_h + header_spacing

    container:build({
        {
            type = "rectangle",
            x = x,
            y = y,
            w = c_w,
            h = c_h,
            thickness = showDebugBorder,

            children = {
                -- Header: left side
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = c_w / 2 - padding,
                    h = header_h,
                    text = wgt.values.label_flight_stats,
                    font = headerFont,
                    color = headerFontColour,
                    align = LEFT
                }, -- Header: right side - Model text (right-aligned) and craft name (left-aligned) using col_w spacing
                {
                    type = "label",
                    x = padding + col_w * 2,
                    y = 0,
                    w = col_w,
                    h = header_h,
                    text = wgt.values.label_model,
                    font = headerFont,
                    color = headerFontColour,
                    align = RIGHT
                }, {
                    type = "label",
                    x = padding + col_w * 3,
                    y = 0,
                    w = col_w * 2,
                    h = header_h,
                    text = wgt.values.craft_name_formatted,
                    font = headerFont,
                    color = COLOR_THEME_PRIMARY1,
                    align = LEFT
                }, -- Column headers (ESC T, Vcell-2S, BEC V, Curr)
                {
                    type = "label",
                    x = padding + col_w * 1,
                    y = col_start_y,
                    w = col_w,
                    h = row_h,
                    text = wgt.values.label_esc_t,
                    font = headerFont,
                    color = headerFontColour,
                    align = CENTER
                }, {
                    type = "label",
                    x = padding + col_w * 2,
                    y = col_start_y,
                    w = col_w,
                    h = row_h,
                    text = function() return wgt.values.label_cell_v .. " " .. wgt.values.cel_count_formatted() end,
                    font = headerFont,
                    color = headerFontColour,
                    align = CENTER
                }, {
                    type = "label",
                    x = padding + col_w * 3,
                    y = col_start_y,
                    w = col_w,
                    h = row_h,
                    text = wgt.values.label_bec_v,
                    font = headerFont,
                    color = headerFontColour,
                    align = CENTER
                }, {
                    type = "label",
                    x = padding + col_w * 4,
                    y = col_start_y,
                    w = col_w - padding,
                    h = row_h,
                    text = wgt.values.label_curr,
                    font = headerFont,
                    color = headerFontColour,
                    align = CENTER
                }, -- Min row
                {
                    type = "label",
                    x = padding,
                    y = col_start_y + row_h,
                    w = col_w,
                    h = row_h,
                    text = wgt.values.label_min,
                    font = headerFont,
                    color = headerFontColour,
                    align = LEFT
                }, {
                    type = "label",
                    x = padding + col_w * 1,
                    y = col_start_y + row_h,
                    w = col_w,
                    h = row_h,
                    text = wgt.values.esc_temp_min_formatted,
                    font = headerFont,
                    color = COLOR_THEME_PRIMARY1,
                    align = CENTER
                }, {
                    type = "label",
                    x = padding + col_w * 2,
                    y = col_start_y + row_h,
                    w = col_w,
                    h = row_h,
                    text = wgt.values.vcel_min_formatted,
                    font = headerFont,
                    color = COLOR_THEME_PRIMARY1,
                    align = CENTER
                }, {
                    type = "label",
                    x = padding + col_w * 3,
                    y = col_start_y + row_h,
                    w = col_w,
                    h = row_h,
                    text = wgt.values.vbec_min_formatted,
                    font = headerFont,
                    color = COLOR_THEME_PRIMARY1,
                    align = CENTER
                }, {
                    type = "label",
                    x = padding + col_w * 4,
                    y = col_start_y + row_h,
                    w = col_w - padding,
                    h = row_h,
                    text = wgt.values.curr_min_formatted,
                    font = headerFont,
                    color = COLOR_THEME_PRIMARY1,
                    align = CENTER
                }, -- Max row (uses row_h_last to consume remaining pixels)
                {
                    type = "label",
                    x = padding,
                    y = col_start_y + row_h * 2,
                    w = col_w,
                    h = row_h_last,
                    text = wgt.values.label_max,
                    font = headerFont,
                    color = headerFontColour,
                    align = LEFT
                }, {
                    type = "label",
                    x = padding + col_w * 1,
                    y = col_start_y + row_h * 2,
                    w = col_w,
                    h = row_h_last,
                    text = wgt.values.esc_temp_max_formatted,
                    font = headerFont,
                    color = COLOR_THEME_PRIMARY1,
                    align = CENTER
                }, {
                    type = "label",
                    x = padding + col_w * 2,
                    y = col_start_y + row_h * 2,
                    w = col_w,
                    h = row_h_last,
                    text = wgt.values.vcel_max_formatted,
                    font = headerFont,
                    color = COLOR_THEME_PRIMARY1,
                    align = CENTER
                }, {
                    type = "label",
                    x = padding + col_w * 3,
                    y = col_start_y + row_h * 2,
                    w = col_w,
                    h = row_h_last,
                    text = wgt.values.vbec_max_formatted,
                    font = headerFont,
                    color = COLOR_THEME_PRIMARY1,
                    align = CENTER
                }, {
                    type = "label",
                    x = padding + col_w * 4,
                    y = col_start_y + row_h * 2,
                    w = col_w - padding,
                    h = row_h_last,
                    text = wgt.values.curr_max_formatted,
                    font = headerFont,
                    color = COLOR_THEME_PRIMARY1,
                    align = CENTER
                }
            }
        }
    })
end

-- Element builder: Headspeed
local function buildHeadspeedElement(container, wgt, x, y, c_w, c_h)
    local padding = 2
    local availableHeight = c_h - header_h
    local valueFont = selectFontByHeight(availableHeight)
    local valueFontHeight = measureFontHeight(valueFont)
    container:build({
        {
            type = "rectangle",
            x = x,
            y = y,
            w = c_w,
            h = c_h,
            thickness = showDebugBorder,

            children = {
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = c_w - padding,
                    h = header_h,
                    text = wgt.values.label_headspeed,
                    font = headerFont,
                    color = headerFontColour
                }, {
                    type = "label",
                    x = padding,
                    y = c_h - valueFontHeight,
                    w = c_w - padding,
                    h = valueFontHeight,
                    text = wgt.values.headspeed_formatted,
                    font = valueFont,
                    color = COLOR_THEME_PRIMARY1
                }
            }
        }
    })
end

-- Element builder: BEC Voltage
local function buildBECVoltageElement(container, wgt, x, y, c_w, c_h)
    local padding = 2
    local availableHeight = c_h - header_h
    local valueFont = selectFontByHeight(availableHeight)
    local valueFontHeight = measureFontHeight(valueFont)
    container:build({
        {
            type = "rectangle",
            x = x,
            y = y,
            w = c_w,
            h = c_h,
            thickness = showDebugBorder,

            children = {
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = c_w - padding,
                    h = header_h,
                    text = wgt.values.label_bec_voltage,
                    font = headerFont,
                    color = headerFontColour
                }, {
                    type = "label",
                    x = padding,
                    y = c_h - valueFontHeight,
                    w = c_w - padding,
                    h = valueFontHeight,
                    text = wgt.values.vbec_formatted,
                    font = valueFont,
                    color = COLOR_THEME_PRIMARY1
                }
            }
        }
    })
end

-- Element builder: Current Value (simple display, no bar)
local function buildCurrentValueElement(container, wgt, x, y, c_w, c_h)
    local padding = 2
    local availableHeight = c_h - header_h
    local valueFont = selectFontByHeight(availableHeight)
    local valueFontHeight = measureFontHeight(valueFont)
    container:build({
        {
            type = "rectangle",
            x = x,
            y = y,
            w = c_w,
            h = c_h,
            thickness = showDebugBorder,
            children = {
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = c_w - padding,
                    h = header_h,
                    text = wgt.values.label_current,
                    font = headerFont,
                    color = headerFontColour
                }, {
                    type = "label",
                    x = padding,
                    y = c_h - valueFontHeight,
                    w = c_w - padding,
                    h = valueFontHeight,
                    text = wgt.values.curr_formatted,
                    font = valueFont,
                    color = COLOR_THEME_PRIMARY1
                }
            }
        }
    })
end

-- Element builder: Rate & Profile (side-by-side rectangles)
local function buildRateProfileElement(container, wgt, x, y, c_w, c_h)
    local rect_w = math.floor(c_w / 2)
    local rect_h = c_h
    local availableHeight = rect_h - header_h
    local valueFont = selectFontByHeight(availableHeight)
    local valueFontHeight = measureFontHeight(valueFont)

    -- Profile rectangle (left)
    local padding = 2
    container:build({
        {
            type = "rectangle",
            x = x,
            y = y,
            w = rect_w,
            h = rect_h,
            thickness = showDebugBorder,

            children = {
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = rect_w - padding,
                    h = header_h,
                    text = wgt.values.label_profile,
                    font = headerFont,
                    color = headerFontColour
                }, {
                    type = "label",
                    x = padding,
                    y = rect_h - valueFontHeight,
                    w = rect_w - padding,
                    h = valueFontHeight,
                    text = wgt.values.profile_id_formatted,
                    font = valueFont,
                    color = COLOR_THEME_PRIMARY1
                }
            }
        }
    })

    -- Rate rectangle (right)
    container:build({
        {
            type = "rectangle",
            x = x + rect_w,
            y = y,
            w = c_w - rect_w,
            h = rect_h,
            thickness = showDebugBorder,

            children = {
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = c_w - rect_w - padding,
                    h = header_h,
                    text = wgt.values.label_rate,
                    font = headerFont,
                    color = headerFontColour
                }, {
                    type = "label",
                    x = padding,
                    y = rect_h - valueFontHeight,
                    w = c_w - rect_w - padding,
                    h = valueFontHeight,
                    text = wgt.values.rate_id_formatted,
                    font = valueFont,
                    color = COLOR_THEME_PRIMARY1
                }
            }
        }
    })
end

-- Element builder: Arm State
local function buildArmStateElement(container, wgt, x, y, c_w, c_h)
    local padding = 2
    local availableHeight = c_h - header_h
    local valueFont = selectFontByHeight(availableHeight, {"MIDSIZE", "STDSIZE"})
    local valueFontHeight = measureFontHeight(valueFont)
    container:build({
        {
            type = "rectangle",
            x = x,
            y = y,
            w = c_w,
            h = c_h,
            thickness = showDebugBorder,

            children = {
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = c_w - padding,
                    h = header_h,
                    text = wgt.values.label_arm_state,
                    font = headerFont,
                    color = headerFontColour
                }, {
                    type = "label",
                    x = padding,
                    y = c_h - valueFontHeight,
                    w = c_w - padding,
                    h = valueFontHeight,
                    text = wgt.values.arm_state_text,
                    font = valueFont,
                    color = wgt.values.arm_state_color
                }
            }
        }
    })
end

-- Element builder: Governor State
local function buildGovernorElement(container, wgt, x, y, c_w, c_h)
    local padding = 2
    local availableHeight = c_h - header_h
    local valueFont = selectFontByHeight(availableHeight, {"STDSIZE", "SMLSIZE", "TINSIZE"})
    local valueFontHeight = measureFontHeight(valueFont)
    container:build({
        {
            type = "rectangle",
            x = x,
            y = y,
            w = c_w,
            h = c_h,
            thickness = showDebugBorder,

            children = {
                {
                    type = "label",
                    x = padding,
                    y = 0,
                    w = c_w - padding,
                    h = header_h,
                    text = wgt.values.label_governor,
                    font = headerFont,
                    color = headerFontColour
                }, {
                    type = "label",
                    x = padding,
                    y = c_h - valueFontHeight,
                    w = c_w - padding,
                    h = valueFontHeight,
                    text = wgt.values.gov_state_formatted,
                    font = valueFont,
                    color = COLOR_THEME_PRIMARY1
                }
            }
        }
    })
end


-- ============================================================================
-- STATUS BAR FUNCTIONS: Dual-mode status bar (normal telemetry vs arming flags)
-- ============================================================================

-- Status bar builder: Normal telemetry display (TPWR, RQly, Tmcu, TX Battery)
local function buildStatusBarNormalElement(container, wgt, x, y, c_w, c_h)
    local item_w = math.floor(c_w / 4)
    local labels = {}

    labels[1] = container:label({
        x = x,
        y = y,
        w = item_w,
        h = c_h,
        text = function() return string.format("%s: %s", wgt.values.label_tpwr, wgt.values.tpwr_formatted()) end,
        font = headerFont,
        color = COLOR_THEME_PRIMARY1
    })
    labels[2] = container:label({
        x = x + item_w,
        y = y,
        w = item_w,
        h = c_h,
        text = function() return string.format("%s: %s", wgt.values.label_rqly, wgt.values.rqly_formatted()) end,
        font = headerFont,
        color = COLOR_THEME_PRIMARY1
    })
    labels[3] = container:label({
        x = x + 2 * item_w,
        y = y,
        w = item_w,
        h = c_h,
        text = function() return string.format("%s: %s", wgt.values.label_mcu_temp_max, wgt.values.mcu_temp_max_formatted()) end,
        font = headerFont,
        color = COLOR_THEME_PRIMARY1
    })
    labels[4] = container:label({
        x = x + 3 * item_w,
        y = y,
        w = item_w,
        h = c_h,
        text = function() return string.format("%s: %s", wgt.values.label_tx_batt, wgt.values.vtx_volts_formatted()) end,
        font = headerFont,
        color = function() return wgt.values.vtx_volts_color or COLOR_THEME_PRIMARY1 end
    })

    return labels
end

-- Element builder: Status bar - Arming flags display (full width)
local function buildStatusBarFlagsElement(container, wgt, x, y, c_w, c_h)
    return container:label({
        x = x,
        y = y,
        w = c_w,
        h = c_h,
        text = function() return wgt.values.arm_flags_text_formatted or "Arming Disabled" end,
        font = headerFont,
        color = COLOR_THEME_WARNING
    })
end

local function updateStatusBarVisibility(wgt, forceUpdate)
    if not wgt.statusBarElements then return end

    local hasFlags = wgt.values.arm_disable_flags_list and #wgt.values.arm_disable_flags_list > 0

    -- Only update if state changed (unless force update requested)
    if not forceUpdate and hasFlags == wgt.statusBarState then return end
    wgt.statusBarState = hasFlags

    if hasFlags then
        wgt.statusBarElements.flags:show()
        for i = 1, 4 do wgt.statusBarElements.normal[i]:hide() end
    else
        for i = 1, 4 do wgt.statusBarElements.normal[i]:show() end
        wgt.statusBarElements.flags:hide()
    end
end

-- Element builder: Status bar (main dispatcher - build both, swap visibility)
local function buildStatusBarElement(container, wgt, x, y, c_w, c_h)
    -- Build both status bar modes and store references
    if not wgt.statusBarElements then
        wgt.statusBarElements = {}
        wgt.statusBarElements.normal = buildStatusBarNormalElement(container, wgt, x, y, c_w, c_h)
        wgt.statusBarElements.flags = buildStatusBarFlagsElement(container, wgt, x, y, c_w, c_h)
    end
end

-- ========== UI Builder Function ==========
-- ============================================================================
-- MAIN FUNCTIONS: Widget lifecycle (create, update, background, refresh)
-- ============================================================================

-- Main UI builder: Creates the full widget layout with grid system
local function build_ui(wgt, zone)
    local w = zone.w
    local h = zone.h

    local line_h = 1 -- Separator line height
    local h_status = math.floor(h * 0.075) -- Status bar height (7%)

    -- Dynamic header font based on available space (status bar is smallest constraint)
    headerFont = selectFontByHeight(h_status, {"SMLSIZE", "TINSIZE"})
    header_h = measureFontHeight(headerFont)

    local h_top = math.floor((h - h_status - 2 * line_h) * 0.45) -- Top row height (~45%)
    local h_mid = h - h_top - h_status - 2 * line_h -- Middle row gets remaining space (guaranteed to sum correctly)

    -- Row y positions (accounting for separator lines)
    local y_top = 0
    local y_mid = y_top + h_top + line_h
    local y_status = y_mid + h_mid + line_h

    -- Top row cell heights (split exactly)
    local h_cell = math.floor(h_top / 2)
    local h_cell2 = h_top - h_cell

    -- Column x positions and widths (split exactly)
    local w_col = math.floor(w / 4) - 2 -- Reduce slightly to prevent horizontal scroll bar
    local x_col = {0, w_col, w_col * 2, w_col * 3}
    local w_col_last = w - x_col[4] - 2

    -- Clear status bar elements reference since they'll be rebuilt
    wgt.statusBarElements = nil
    wgt.statusBarState = nil

    -- Main container (holds all sections) and background if wanted
    local bg_filled = (wgt.options.BGFilled == 1)
    local pMain = lvgl.rectangle({x = 0, y = 0, w = w, h = h, color = COLOR_THEME_SECONDARY3, filled = bg_filled})

    -- ========== TOP ROW (50% height, 4 columns × 2 rows) ==========
    local gridElements = {
        {buildESCTempElement, buildBatteryVoltageElement}, {buildHeadspeedElement, buildBECVoltageElement},
        {buildRateProfileElement, buildCurrentValueElement}, {buildGovernorElement, buildArmStateElement}
    }

    for col = 1, 4 do
        local colX = x_col[col]
        local col_w = (col == 4) and w_col_last or w_col

        -- Top cell in column
        gridElements[col][1](pMain, wgt, colX, y_top, col_w, h_cell)
        -- Bottom cell in column
        gridElements[col][2](pMain, wgt, colX, y_top + h_cell, col_w, h_cell2)
    end

    -- Separator line between top and middle rows
    pMain:hline({y = y_mid - line_h, w = w - 3, h = line_h, color = COLOR_THEME_SECONDARY1})

    -- ========== MIDDLE ROW (remaining height) ==========
    -- Split middle row: top half = Flight Statistics, bottom half = Capacity, far right = Timer and energy used
    -- Must align with top row grid: left 3 columns end at x_col[4], right column starts there
    local h_top_half = math.floor(h_mid / 1.75)
    local h_top_half2 = h_mid - h_top_half
    local left_w = x_col[4] -- Left section width (aligns exactly with 3 top-row columns)
    local right_x = x_col[4] -- Right section starts after vertical line
    local right_w = w - right_x - 2 -- Remaining width for right section

    -- Flight Statistics: top row (use same width as 3 top-row columns)
    buildFlightStatisticsElement(pMain, wgt, 0, y_mid, left_w, h_top_half - 1)
    -- Separator line between Flight Statistics and Capacity
    pMain:hline({y = y_mid + h_top_half - 1, w = left_w, h = line_h, color = COLOR_THEME_SECONDARY1})
    -- Capacity: bottom row
    buildBatteryUsedElement(pMain, wgt, 0, y_mid + h_top_half, left_w, h_top_half2)
    -- Vertical line on right side of flight statistics/capacity section
    pMain:vline({x = left_w - 1, y = y_mid, h = h_top_half + line_h + h_top_half2, w = line_h, color = COLOR_THEME_SECONDARY1})
    -- Far right: split into Timer (top) and Capacity Used value (bottom)
    local right_h_top = math.floor(h_mid / 2)
    local right_h_bottom = h_mid - right_h_top
    -- Timer (top half) - use remaining width after left section
    buildTimerElement(pMain, wgt, right_x, y_mid, right_w, right_h_top)
    -- Energy Used (mAh) value (bottom half)
    buildCapacityUsedValueElement(pMain, wgt, right_x, y_mid + right_h_top, right_w, right_h_bottom)

    -- Separator line between middle and status bar rows
    pMain:hline({y = y_status - line_h, w = w - 3, h = line_h, color = COLOR_THEME_SECONDARY1})

    -- ========== STATUS BAR (7% height, full width) ==========
    -- Create a separate box for status bar that can be completely rebuilt
    local statusBarBox = pMain:box({x = 0, y = y_status, w = w - 4, h = h_status - 2})
    wgt.statusBarBox = statusBarBox
    wgt.statusBarDims = {x = 0, y = 0, w = w - 4, h = h_status - 2} -- Relative to the box

    buildStatusBarElement(statusBarBox, wgt, 0, 0, w - 4, h_status - 2)
end

local function update(wgt, options)
    if (wgt == nil) then return end
    wgt.options = options
    lvgl.clear()

    build_ui(wgt, wgt.zone)
    -- Force status bar visibility update after UI rebuild
    updateStatusBarVisibility(wgt, true)
    return wgt
end

local function create(zone, options)
    wgt.zone = zone
    wgt.options = options
    return update(wgt, options)
end

local function background(wgt)
    heliDashFunctions.backgroundRefresh(wgt)
end

local function refresh(wgt, event, touchState)
    heliDashFunctions.refresh(wgt)
    updateStatusBarVisibility(wgt)
end

return {create = create, update = update, background = background, refresh = refresh}
