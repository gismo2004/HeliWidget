local M = {}

local DEFAULT_CELL_WARNING_VOLTAGE = 3.3
local DEFAULT_CELL_ALARM_VOLTAGE = 3.2
local GOV_STATE_LABELS = {
    [0] = "Throttle off",
    [1] = "Throttle Idle",
    [2] = "Spooling up",
    [3] = "Recovery",
    [4] = "Gov. Active",
    [5] = "Throttle Hold",
    [6] = "Gov. Fallback",
    [7] = "Autorotation",
    [8] = "Bailing Out"
}

local function normalize_cell_voltage(raw_value, fallback)
    if raw_value == nil or raw_value <= 0 then return fallback end
    if raw_value > 20 then return raw_value / 100 end
    return raw_value
end

local function get_cell_voltage_color_for_value(wgt, voltage)
    if voltage == nil or voltage <= 0 then return COLOR_THEME_PRIMARY1 end

    local alarm_voltage = wgt.values.vcel_alarm_threshold()
    local warning_voltage = math.max(alarm_voltage, wgt.values.vcel_warning_threshold())

    if voltage <= alarm_voltage then return COLOR_THEME_WARNING end
    if voltage <= warning_voltage then return YELLOW end
    return COLOR_THEME_PRIMARY1
end

local function get_arming_disable_flag_names()
    local flag_names = {
        [0] = "No Gyro",
        [1] = "Fail Safe",
        [2] = "RX Fail Safe",
        [3] = "Bad RX Recovery",
        [4] = "Box Fail Safe",
        [5] = "Governor",
        [6] = "RPM Signal",
        [7] = "Throttle",
        [8] = "Angle",
        [9] = "Boot Grace Time",
        [10] = "No Pre Arm",
        [11] = "Load",
        [12] = "Calibrating",
        [13] = "CLI",
        [14] = "CMS Menu",
        [15] = "BST",
        [16] = "MSP",
        [17] = "Paralyze",
        [18] = "GPS",
        [19] = "Resc",
        [20] = "RPM Filter",
        [21] = "Reboot Required",
        [22] = "DSHOT Bitbang",
        [23] = "Acc Calibration",
        [24] = "Motor Protocol"
    }

    if rf2 and rf2.apiVersion and rf2.apiVersion >= 12.09 then
        flag_names[25] = "Override"
        flag_names[26] = "Arm Switch"
    else
        flag_names[25] = "Arm Switch"
    end

    return flag_names
end

local function get_arming_disable_flags_list(flags)
    if flags == nil or flags == 0 then return nil end

    local flag_names = get_arming_disable_flag_names()
    local result = {}

    for i = 0, 26 do
        if (flags & (1 << i)) ~= 0 and flag_names[i] then
            result[#result + 1] = flag_names[i]
        end
    end

    if #result == 0 then return nil end
    return result
end

local function get_current_arm_disable_flag(wgt)
    local flags = get_arming_disable_flags_list(wgt.values.arm_disable_flags)
    if not flags then
        wgt.flag_cycle_time = nil
        wgt.flag_cycle_index = 0
        return nil
    end

    if not wgt.flag_cycle_time then wgt.flag_cycle_time = getTime() end
    wgt.flag_cycle_index = (wgt.flag_cycle_index or 0) % #flags

    local now = getTime()
    if now - wgt.flag_cycle_time >= 200 then
        wgt.flag_cycle_index = (wgt.flag_cycle_index + 1) % #flags
        wgt.flag_cycle_time = now
    end

    return flags[wgt.flag_cycle_index + 1]
end

function M.createValues(wgt)
    return {
        label_current = "Current",
        label_fuel = "Fuel",
        label_capacity = "Energy Used (mAh)",
        label_esc_temp = "ESC Temperature",
        label_battery_voltage = "Battery Voltage",
        label_headspeed = "Headspeed",
        label_bec_voltage = "BEC Voltage",
        label_profile = "Profile",
        label_rate = "Rate",
        label_battery_profile = "Batt Profile",
        label_battery_profile_short = "B. Profile",
        label_battery_profile_tiny = "Batt",
        label_arm_state = "Arm State",
        label_governor = "Governor State",
        label_timer = "Timer",
        label_tpwr = "TPWR+",
        label_rqly = "RQly-",
        label_mcu_temp_max = "Tmcu+",
        label_armed = "Armed",
        label_disarmed = "Disarmed",
        label_connected = "Connected",
        label_disconnected = "Disconnected",
        label_flight_stats = "Flight Statistics",
        label_flight_time = "Flight Time",
        label_total_flight_time = "Total Flight Time",
        label_total_flights = "Flights",
        label_capacity_used_short = "mAh Used",
        label_tx_batt = "TX Battery",
        label_model_card = "Model",
        label_status = "Status",
        label_actual = "Actual",
        label_min = "Min",
        label_max = "Max",
        label_esc_t = "ESC T",
        label_cell_v = "Cell Voltage",
        label_bec_v = "BEC V",
        label_curr = "CURR",
        label_model = "Model: ",

        headspeed = nil,
        headspeed_min = nil,
        headspeed_max = nil,
        headspeed_formatted = function()
            if wgt.values.headspeed == nil then return "-" end
            return string.format("%.0f", wgt.values.headspeed)
        end,
        headspeed_min_formatted = function()
            if wgt.values.headspeed_min == nil then return "-" end
            return string.format("%.0f", wgt.values.headspeed_min)
        end,
        headspeed_max_formatted = function()
            if wgt.values.headspeed_max == nil then return "-" end
            return string.format("%.0f", wgt.values.headspeed_max)
        end,

        vbat = nil,
        vbat_min = nil,
        vbat_max = nil,
        vbat_formatted = function()
            if wgt.values.vbat == nil then return "-" end
            return string.format("%.02f", wgt.values.vbat)
        end,
        vbat_min_formatted = function()
            if wgt.values.vbat_min == nil then return "-" end
            return string.format("%.02f", wgt.values.vbat_min)
        end,
        vbat_max_formatted = function()
            if wgt.values.vbat_max == nil then return "-" end
            return string.format("%.02f", wgt.values.vbat_max)
        end,

        vcel = nil,
        vcel_min = nil,
        vcel_max = nil,
        cel_count = nil,
        vcel_formatted = function()
            if wgt.values.vcel == nil then return "-" end
            return string.format("%.02f", wgt.values.vcel)
        end,
        vcel_min_formatted = function()
            if wgt.values.vcel_min == nil then return "-" end
            return string.format("%.02f", wgt.values.vcel_min)
        end,
        vcel_max_formatted = function()
            if wgt.values.vcel_max == nil then return "-" end
            return string.format("%.02f", wgt.values.vcel_max)
        end,
        cel_count_formatted = function()
            if wgt.values.cel_count == nil then return "" end
            return string.format("(%dS)", wgt.values.cel_count)
        end,
        vcel_warning_threshold = function()
            return normalize_cell_voltage(wgt.values.rf_cell_warning_voltage, DEFAULT_CELL_WARNING_VOLTAGE)
        end,
        vcel_alarm_threshold = function()
            return normalize_cell_voltage(wgt.values.rf_cell_alarm_voltage, DEFAULT_CELL_ALARM_VOLTAGE)
        end,
        vcel_actual_color = function()
            return get_cell_voltage_color_for_value(wgt, wgt.values.vcel)
        end,
        vcel_min_color = function()
            return get_cell_voltage_color_for_value(wgt, wgt.values.vcel_min)
        end,
        vcel_max_color = function()
            return get_cell_voltage_color_for_value(wgt, wgt.values.vcel_max)
        end,
        vcel_color = function()
            return wgt.values.vcel_actual_color()
        end,

        curr = nil,
        curr_min = nil,
        curr_max = nil,
        curr_min_formatted = function()
            if wgt.values.curr_min == nil then return "-" end
            return string.format("%.01f", wgt.values.curr_min)
        end,
        curr_formatted = function()
            if wgt.values.curr == nil then return "-" end
            return string.format("%.01f", wgt.values.curr)
        end,
        curr_max_formatted = function()
            if wgt.values.curr_max == nil then return "-" end
            return string.format("%.01f", wgt.values.curr_max)
        end,

        capa = nil,
        capa_percent = nil,
        capa_cell_color = COLOR_THEME_PRIMARY1,
        capa_mid_text_color = COLOR_THEME_PRIMARY1,
        capa_formatted = function()
            if wgt.values.capa == nil then return "-" end
            return string.format("%.0f", wgt.values.capa)
        end,
        capa_percent_formatted = function()
            if wgt.values.capa_percent == nil then return "-" end
            return string.format("%.0f%%", wgt.values.capa_percent)
        end,

        esc_temp = nil,
        esc_temp_min = nil,
        esc_temp_max = nil,
        esc_temp_formatted = function()
            if wgt.values.esc_temp == nil then return "-" end
            return string.format("%.01f", wgt.values.esc_temp)
        end,
        esc_temp_min_formatted = function()
            if wgt.values.esc_temp_min == nil then return "-" end
            return string.format("%.01f", wgt.values.esc_temp_min)
        end,
        esc_temp_max_formatted = function()
            if wgt.values.esc_temp_max == nil then return "-" end
            return string.format("%.01f", wgt.values.esc_temp_max)
        end,

        craft_name = "-",
        craft_name_formatted = function()
            if not wgt.values.craft_name or wgt.values.craft_name == "" or wgt.values.craft_name == "NotDefined" or wgt.values.craft_name == "Unknown" then return
                "-" end
            return wgt.values.craft_name
        end,

        profile_id = nil,
        rate_id = nil,
        profile_id_formatted = function()
            if wgt.values.profile_id == nil then return "-" end
            return tostring(wgt.values.profile_id)
        end,
        rate_id_formatted = function()
            if wgt.values.rate_id == nil then return "-" end
            return tostring(wgt.values.rate_id)
        end,

        arm_disable_flags = nil,
        arm_disable_flags_list = function()
            return get_arming_disable_flags_list(wgt.values.arm_disable_flags)
        end,
        arm_flags_visible = function()
            if not (wgt.rf and wgt.rf.available) then return true end
            return wgt.values.arm_disable_flags_list() ~= nil
        end,
        arm_state_text = function()
            return wgt.values.rf_connection_state == "armed" and wgt.values.label_armed or wgt.values.label_disarmed
        end,
        arm_state_color = function()
            return wgt.values.rf_connection_state == "armed" and DARKGREEN or COLOR_THEME_WARNING
        end,
        arm_flags_text_formatted = function()
            if not (wgt.rf and wgt.rf.available) then return "RFTools widget missing" end
            local current_flag = get_current_arm_disable_flag(wgt)
            if current_flag == nil then return "" end
            return "Arming Disabled: " .. current_flag
        end,
        rf_connection_state = "disconnected",
        rf_connection_state_formatted = function()
            if wgt.values.rf_connection_state == "armed" then return wgt.values.label_armed end
            if wgt.values.rf_connection_state == "disarmed" then return wgt.values.label_disarmed end
            if wgt.values.rf_connection_state == "connected" then return wgt.values.label_connected end
            return wgt.values.label_disconnected
        end,
        rf_connection_state_color = function()
            if wgt.values.rf_connection_state == "armed" then return DARKGREEN end
            if wgt.values.rf_connection_state == "disconnected" then return COLOR_THEME_WARNING end
            return COLOR_THEME_PRIMARY1
        end,

        gov_state = nil,
        gov_state_formatted = function()
            if wgt.values.gov_state == nil then return "-" end
            return GOV_STATE_LABELS[wgt.values.gov_state] or "Gov. Disabled"
        end,

        vbec = nil,
        vbec_min = nil,
        vbec_max = nil,
        vbec_formatted = function()
            if wgt.values.vbec == nil then return "-" end
            return string.format("%.02f", wgt.values.vbec)
        end,
        vbec_min_formatted = function()
            if wgt.values.vbec_min == nil then return "-" end
            return string.format("%.02f", wgt.values.vbec_min)
        end,
        vbec_max_formatted = function()
            if wgt.values.vbec_max == nil then return "-" end
            return string.format("%.02f", wgt.values.vbec_max)
        end,

        vtx_volts = nil,
        vtx_volts_max = -1,
        vtx_volts_min = -1,
        vtx_volts_warn = -1,
        vtx_volts_percent = nil,
        vtx_volts_color = COLOR_THEME_PRIMARY1,
        vtx_volts_formatted = function()
            if wgt.values.vtx_volts_percent == nil then return "-" end
            return string.format("%s%%", wgt.values.vtx_volts_percent)
        end,

        timer_str = "00:00",
        timer_is_negative = false,
        timer_color = function() return wgt.values.timer_is_negative and COLOR_THEME_WARNING or COLOR_THEME_PRIMARY1 end,
        timer_str_formatted = function() return wgt.values.timer_str end,

        flight_time_str = "00:00",
        flight_time_color = COLOR_THEME_PRIMARY1,
        flight_time_str_formatted = function() return wgt.values.flight_time_str end,

        rqly_min = nil,
        rqly_formatted = function()
            if wgt.values.rqly_min == nil then return "-" end
            return string.format("%s%%", wgt.values.rqly_min)
        end,

        tpwr_max = nil,
        tpwr_formatted = function()
            if wgt.values.tpwr_max == nil then return "-" end
            return string.format("%smW", wgt.values.tpwr_max)
        end,

        mcu_temp_max = nil,
        mcu_temp_max_formatted = function()
            if wgt.values.mcu_temp_max == nil then return "-" end
            return string.format("%.0f°C", wgt.values.mcu_temp_max)
        end,

        rf_battery_profile = nil,
        rf_cell_warning_voltage = nil,
        rf_cell_alarm_voltage = nil,
        rf_battery_profile_display_formatted = function()
            local profile_value = wgt.values.rf_battery_profile
            if profile_value == nil or profile_value < 0 then return "-" end
            profile_value = tostring(profile_value)
            local capacity_value = wgt.values.rf_battery_capacity_display_formatted()
            if capacity_value == "-" then return profile_value end
            return string.format("%s (%s)", capacity_value, profile_value)
        end,
        rf_battery_capacity_mah = nil,
        rf_battery_capacity_display_formatted = function()
            if wgt.values.rf_battery_capacity_mah == nil then return "-" end
            return string.format("%.0f", wgt.values.rf_battery_capacity_mah)
        end,
        rf_battery_profile_compact_formatted = function()
            local capacity_value = wgt.values.rf_battery_capacity_display_formatted()
            if capacity_value ~= "-" then return capacity_value end
            if wgt.values.rf_battery_profile == nil or wgt.values.rf_battery_profile < 0 then return "-" end
            return tostring(wgt.values.rf_battery_profile)
        end,
        battery_usage_summary_formatted = function()
            local used_value = wgt.values.capa_formatted()
            local percent_value = wgt.values.capa_percent_formatted()
            if used_value == "-" and percent_value == "-" then return "-" end
            if used_value == "-" then return percent_value end
            if percent_value == "-" then return used_value end
            return string.format("%s (%s)", used_value, percent_value)
        end,
        rf_battery_cell_count = nil,
        rf_total_flights = nil,
        rf_total_flights_display_formatted = function()
            if wgt.values.rf_total_flights == nil then return "-" end
            return tostring(wgt.values.rf_total_flights)
        end,
        rf_total_flight_time = nil,
        rf_total_flight_time_formatted = "",
        rf_total_flight_time_display_formatted = function()
            if not wgt.values.rf_total_flight_time_formatted or wgt.values.rf_total_flight_time_formatted == "" then return
                "-" end
            return wgt.values.rf_total_flight_time_formatted
        end
    }
end

function M.createWidget()
    local wgt = {}
    wgt.values = M.createValues(wgt)
    return wgt
end

return M
