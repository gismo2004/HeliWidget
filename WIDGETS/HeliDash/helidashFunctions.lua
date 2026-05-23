-- currently used RotorFlight telemetry values for this widget:

-- 3 = Vbat (Main battery voltage)
-- 4 = Curr (Main battery current + min/max)
-- 5 = Capa (Capacity used)
-- 6 = Bat% (Battery percentage/fuel)
-- 7 = Cel# (Cell count)
-- 8 = Vcel (Cell voltage + min/max)
-- 43 = Vbec (BEC voltage + min/max)
-- 50 = Tesc (ESC temperature + min/max)
-- 52 = Tmcu (MCU temperature, max used)
-- 60 = Hspd (Headspeed)
-- 90 = ARM (Arming flags)
-- 91 = ARMD (Arming disable flags)
-- 93 = Gov (Governor state)
-- 95 = PID# (Profile ID)
-- 96 = RTE# (Rate ID)

-- set telemetry_sensors = 3,4,5,6,7,8,43,50,52,60,90,91,93,95,96,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


local helidash_functions = {}

-- ============================================================================
-- LOCAL HELPER FUNCTIONS
-- ============================================================================

-- Logging helper with ms prefix and configurable tag
function helidash_functions.log(text, ...)
    if not text then return end
    local t = getTime() or 0 -- EdgeTX ticks are centiseconds
    local ms = t * 10        -- convert cs to ms
    local tag = "HeliDash"
    local formatted_text = text
    if select('#', ...) > 0 then formatted_text = string.format(tostring(text), ...) end
    print(string.format("[%dms][%s] %s", ms, tag, formatted_text))
end

-- Detect simulator mode for testing
helidash_functions.simu_mode = string.sub(select(2, getVersion()), -4) == "simu"
helidash_functions.log("simu_mode=%s", tostring(helidash_functions.simu_mode))

local function format_time(t1)
    if not t1 or t1.value == nil then return "00:00", false end

    local seconds = math.abs(t1.value)
    local is_negative = t1.value < 0

    local mm = math.floor(seconds / 60) % 60
    local ss = math.floor(seconds % 60)

    local time_str = string.format("%02d:%02d", mm, ss)

    if is_negative then time_str = '-' .. time_str end
    return time_str, is_negative
end

local function format_elapsed_time(elapsed_centiseconds)
    local seconds = math.floor(math.max(0, elapsed_centiseconds or 0) / 100)
    return format_time({ value = seconds })
end

local function is_rf_connected(wgt)
    return wgt.values.rf_connection_state ~= "disconnected"
end

local function is_craft_armed(wgt)
    return wgt.values.rf_connection_state == "armed"
end

local function should_track_governor_run_extrema(wgt)
    return wgt.values.gov_state ~= nil and wgt.values.gov_state > 2 and wgt.values.gov_state ~= 5
end

local function should_track_flight_time(wgt)
    return is_rf_connected(wgt) and should_track_governor_run_extrema(wgt)
end

local function reset_flight_time(wgt)
    wgt.flight_time_elapsed = 0
    wgt.flight_time_last_tick = nil
    wgt.last_model_timer_value = nil
    wgt.values.flight_time_str = "00:00"
end

local function update_tracked_extrema(wgt, value_key, min_key, max_key)
    local current_value = wgt.values[value_key]
    if current_value == nil then return end

    if wgt.values[min_key] == nil or current_value < wgt.values[min_key] then
        wgt.values[min_key] = current_value
    end
    if wgt.values[max_key] == nil or current_value > wgt.values[max_key] then
        wgt.values[max_key] = current_value
    end
end

local function get_battery_percent_text_color(percent, warning_percent)
    if percent == nil then return COLOR_THEME_PRIMARY1 end

    if not lcd or not lcd.RGB then
        return percent <= warning_percent and COLOR_THEME_WARNING or DARKGREEN
    end

    local clamped_percent = math.max(0, math.min(100, percent or 0))
    local clamped_warning = math.max(0, math.min(99, warning_percent or 30))
    if clamped_percent <= clamped_warning then
        return lcd.RGB(0xff, 0, 0)
    end

    local normalized = (clamped_percent - clamped_warning) / math.max(1, 100 - clamped_warning)
    if normalized < 0.5 then
        local green = math.floor(0xff * (normalized / 0.5))
        return lcd.RGB(0xff, green, 0)
    end

    local red = math.floor(0xff * (1 - ((normalized - 0.5) / 0.5)))
    return lcd.RGB(red, 0xff, 0)
end

local function clear_live_telemetry_values(wgt)
    wgt.values.vbat = nil
    wgt.values.vbat_min = nil
    wgt.values.vbat_max = nil
    wgt.values.vcel = nil
    wgt.values.vcel_min = nil
    wgt.values.vcel_max = nil
    wgt.values.cel_count = nil
    wgt.values.curr = nil
    wgt.values.curr_min = nil
    wgt.values.curr_max = nil
    wgt.values.capa = nil
    wgt.values.capa_percent = nil
    wgt.values.headspeed = nil
    wgt.values.headspeed_min = nil
    wgt.values.headspeed_max = nil
    wgt.values.vbec = nil
    wgt.values.vbec_min = nil
    wgt.values.vbec_max = nil
    wgt.values.esc_temp = nil
    wgt.values.esc_temp_min = nil
    wgt.values.esc_temp_max = nil
    wgt.values.gov_state = nil
    wgt.values.arm_disable_flags = nil
    wgt.values.profile_id = nil
    wgt.values.rate_id = nil
    wgt.values.rf_battery_profile = nil
    wgt.values.rf_battery_capacity_mah = nil
    wgt.values.rf_battery_cell_count = nil
    wgt.values.rqly_min = nil
    wgt.values.tpwr_max = nil
    wgt.values.mcu_temp_max = nil
    wgt.values.vtx_volts = nil
    wgt.values.vtx_volts_percent = nil
end

-- ============================================================================
-- GENERAL INFO UPDATES
-- ============================================================================
function helidash_functions.update_craft_name(wgt)
    local model_name = rf2 and rf2.modelName
    if not model_name then
        local model_info = model.getInfo()
        model_name = model_info and model_info.name
    end
    wgt.values.craft_name = string.gsub(model_name or "Unknown", "^>", "")
end

function helidash_functions.update_timer_count(wgt)
    local t1 = model.getTimer(wgt.options.Timer or 0)
    local timer_value = t1 and t1.value
    local timer_start = t1 and t1.start
    local timer_text, is_negative = format_time(t1)

    wgt.values.timer_str = timer_text
    wgt.values.timer_is_negative = is_negative

    if timer_value ~= nil and timer_start ~= nil and wgt.last_model_timer_value ~= nil and timer_value == timer_start and wgt.last_model_timer_value ~= timer_start then
        reset_flight_time(wgt)
    end
    wgt.last_model_timer_value = timer_value

    local now = getTime() or 0
    if should_track_flight_time(wgt) then
        if wgt.flight_time_last_tick ~= nil and now > wgt.flight_time_last_tick then
            wgt.flight_time_elapsed = (wgt.flight_time_elapsed or 0) + (now - wgt.flight_time_last_tick)
        end
        wgt.flight_time_last_tick = now
    else
        wgt.flight_time_last_tick = nil
    end

    wgt.values.flight_time_str = format_elapsed_time(wgt.flight_time_elapsed or 0)
end

function helidash_functions.update_profiles(wgt)
    wgt.values.profile_id = getSourceValue("PID#")
    wgt.values.rate_id = getSourceValue("RTE#")
    wgt.values.rf_battery_profile = getSourceValue("BAT#")
    if wgt.sync_active_battery_capacity then
        wgt.sync_active_battery_capacity(wgt)
    end
end

-- ============================================================================
-- TRANSMITTER/RADIO UPDATES
-- ============================================================================

function helidash_functions.update_tx_bat_voltage(wgt)
    wgt.values.vtx_volts = getSourceValue("tx-voltage")
    wgt.values.vtx_volts_max = getGeneralSettings().battMax
    wgt.values.vtx_volts_min = getGeneralSettings().battMin
    wgt.values.vtx_volts_warn = getGeneralSettings().battWarn

    if wgt.values.vtx_volts == nil then
        wgt.values.vtx_volts_percent = nil
        wgt.values.vtx_volts_color = COLOR_THEME_PRIMARY1
        return
    end

    wgt.values.vtx_volts_percent = math.floor(100 -
        (100 * (wgt.values.vtx_volts_max - wgt.values.vtx_volts) //
            (wgt.values.vtx_volts_max - wgt.values.vtx_volts_min)))

    if wgt.values.vtx_volts_percent > 100 then wgt.values.vtx_volts_percent = 100 end

    local warn_percent = math.ceil(100 -
        (100 * (wgt.values.vtx_volts_max - wgt.values.vtx_volts_warn) //
            (wgt.values.vtx_volts_max - wgt.values.vtx_volts_min)))

    if (wgt.values.vtx_volts_percent < warn_percent) then
        wgt.values.vtx_volts_color = COLOR_THEME_WARNING
    else
        wgt.values.vtx_volts_color = COLOR_THEME_PRIMARY1
    end
end

function helidash_functions.update_link_quality(wgt)
    -- Only track minimum link quality; current value not needed
    wgt.values.rqly_min = getSourceValue("RQly-")
end

function helidash_functions.update_transmitter_power(wgt)
    -- Only track maximum transmitter power; current value not needed
    wgt.values.tpwr_max = getValue("TPWR+")
end

-- ============================================================================
-- AIRCRAFT TELEMETRY: VOLTAGE & TEMPERATURE
-- ============================================================================
function helidash_functions.update_cell(wgt)
    wgt.values.vbat = getSourceValue("Vbat")
    wgt.values.vbat_min = getSourceValue("Vbat-")
    wgt.values.vbat_max = getSourceValue("Vbat+")

    if helidash_functions.simu_mode then
        wgt.values.vbat = math.random(1101, 1201) / 100
        wgt.values.vbat_min = 10.80
        wgt.values.vbat_max = 12.30
    end
end

function helidash_functions.update_vcel(wgt)
    wgt.values.vcel = getSourceValue("Vcel")
    wgt.values.vcel_min = getSourceValue("Vcel-")
    wgt.values.vcel_max = getSourceValue("Vcel+")
    wgt.values.cel_count = getSourceValue("Cel#")

    if helidash_functions.simu_mode then
        wgt.values.vcel = 3.2
        wgt.values.vcel_max = 4.2
        wgt.values.vcel_min = 3.1
        wgt.values.cel_count = 2
    end
end

function helidash_functions.update_vbec(wgt)
    wgt.values.vbec = getSourceValue("Vbec")
    wgt.values.vbec_max = getSourceValue("Vbec+")
    wgt.values.vbec_min = getSourceValue("Vbec-")

    if helidash_functions.simu_mode then
        wgt.values.vbec = math.random(72, 78) / 10
        wgt.values.vbec_max = 8.4
        wgt.values.vbec_min = 7.2
    end
end

function helidash_functions.update_esc_temperature(wgt)
    wgt.values.esc_temp = getSourceValue("Tesc")
    wgt.values.esc_temp_min = getSourceValue("Tesc-")
    wgt.values.esc_temp_max = getSourceValue("Tesc+")

    if helidash_functions.simu_mode then
        wgt.values.esc_temp = 60
        wgt.values.esc_temp_max = 75
        wgt.values.esc_temp_min = 45
    end
end

function helidash_functions.update_mcu_temperature(wgt) wgt.values.mcu_temp_max = getSourceValue("Tmcu+") end

-- ============================================================================
-- AIRCRAFT TELEMETRY: CURRENT & CAPACITY
-- ============================================================================
function helidash_functions.update_curr(wgt)
    wgt.values.curr = getSourceValue("Curr")

    if helidash_functions.simu_mode then
        wgt.values.curr = math.random(0, 200)
    end

    if should_track_governor_run_extrema(wgt) then
        update_tracked_extrema(wgt, "curr", "curr_min", "curr_max")
    end
end

function helidash_functions.update_ma_used(wgt)
    wgt.values.capa = getSourceValue("Capa")
    wgt.values.capa_percent = getSourceValue("Bat%")

    if helidash_functions.simu_mode then
        wgt.values.capa = math.random(0, 2000)
        wgt.values.capa_percent = math.random(0, 100)
    end

    local batt_cap_min = wgt.options.FuelMin or 30
    wgt.values.capa_mid_text_color = get_battery_percent_text_color(wgt.values.capa_percent, batt_cap_min)
    if wgt.values.capa_percent == nil then
        wgt.values.capa_cell_color = COLOR_THEME_PRIMARY1
    elseif wgt.values.capa_percent > batt_cap_min then
        wgt.values.capa_cell_color = COLOR_THEME_SECONDARY2
    else
        wgt.values.capa_cell_color = COLOR_THEME_WARNING
    end
end

-- ============================================================================
-- AIRCRAFT TELEMETRY: HELI-SPECIFIC
-- ============================================================================
function helidash_functions.update_headspeed(wgt)
    wgt.values.headspeed = getSourceValue("Hspd")

    if helidash_functions.simu_mode then
        wgt.values.headspeed = math.random(2000, 3000)
    end

    if should_track_governor_run_extrema(wgt) then
        update_tracked_extrema(wgt, "headspeed", "headspeed_min", "headspeed_max")
    end
end

function helidash_functions.update_gov_state(wgt)
    wgt.values.gov_state = getSourceValue("Gov")
    if helidash_functions.simu_mode then wgt.values.gov_state = math.random(0, 9) end
end

-- ============================================================================
-- ARM STATE UPDATES
-- ============================================================================

function helidash_functions.update_arm(wgt)
    wgt.values.arm_disable_flags = getSourceValue("ARMD")
end

function helidash_functions.on_telemetry_state_changed(wgt, previous_state, new_state)
    if previous_state == "disconnected" and new_state ~= "disconnected" then
        clear_live_telemetry_values(wgt)
        helidash_functions.reset_telemetry_stats(wgt)
        return
    end

    if previous_state ~= "disconnected" and new_state == "disconnected" then
        helidash_functions.log("Connection lost")
    end
end

-- ============================================================================
-- ALERTS & CALLOUTS
-- ============================================================================

function helidash_functions.update_battery_callout(wgt)
    if not is_rf_connected(wgt) then return end
    if not is_craft_armed(wgt) then
        wgt.battery_low_start_time = nil
        return
    end

    -- Update capacity data first (needed for callout logic)
    helidash_functions.update_ma_used(wgt)

    local batt_cap_min = wgt.options.FuelMin or 30
    local callout_interval = math.max(1, wgt.options.CalloutInt or 10)
    local now = getTime() / 100
    wgt.last_battery_callout_time = wgt.last_battery_callout_time or 0

    local should_announce = false
    local announce_value, announce_unit, announce_precision, log_msg

    -- Mode 1: Current sensor detected (% < 100) - announce percentage when low (with 2+ sec debounce)
    if wgt.values.capa_percent ~= nil and wgt.values.capa_percent < 100 then
        if wgt.values.capa_percent <= batt_cap_min then
            wgt.battery_low_start_time = wgt.battery_low_start_time or now
            local low_duration = now - wgt.battery_low_start_time

            if low_duration >= 2 then
                should_announce = true
                announce_value, announce_unit, announce_precision = wgt.values.capa_percent, 13, 0
                log_msg = string.format("FUEL CALLOUT: %d%%", wgt.values.capa_percent)
            end
        else
            wgt.battery_low_start_time = nil
        end

        -- Mode 2: No current sensor (% = 100) - announce voltage when critically low for 2+ seconds
    else
        local vcel = wgt.values.vcel
        local voltage_threshold = wgt.values.vcel_alarm_threshold()

        if vcel ~= nil and vcel > 0 and vcel < voltage_threshold then
            wgt.battery_low_start_time = wgt.battery_low_start_time or now
            local low_duration = now - wgt.battery_low_start_time

            if low_duration >= 2 then
                should_announce = true
                announce_value, announce_unit, announce_precision = vcel, 1, 2
                log_msg = string.format("VOLTAGE CALLOUT: %.2fV", vcel)
            end
        else
            wgt.battery_low_start_time = nil
        end
    end

    -- Trigger callout if conditions met and enough time elapsed
    if should_announce and (now - wgt.last_battery_callout_time) >= callout_interval then
        playNumber(announce_value, announce_unit, announce_precision)
        helidash_functions.log(log_msg)
        if wgt.options.Haptic == 1 then playHaptic(20, 0, 0) end
        wgt.last_battery_callout_time = now
    end
end

function helidash_functions.reset_telemetry_stats(wgt)
    for i = 0, 99 do model.resetSensor(i) end

    model.resetTimer(wgt.options.Timer or 0)
    reset_flight_time(wgt)

    -- Reset battery callout timer on disconnect
    wgt.last_battery_callout_time = nil
    wgt.battery_low_start_time = nil
end

-- ============================================================================
-- REFRESH ORCHESTRATION
-- ============================================================================

function helidash_functions.refresh_ui_no_conn(wgt)
    helidash_functions.update_tx_bat_voltage(wgt)
    helidash_functions.update_craft_name(wgt)
    helidash_functions.update_timer_count(wgt)
end

function helidash_functions.refresh_ui(wgt)
    helidash_functions.update_gov_state(wgt)
    helidash_functions.update_headspeed(wgt)
    helidash_functions.update_cell(wgt)
    helidash_functions.update_vcel(wgt)
    helidash_functions.update_curr(wgt)
    helidash_functions.update_ma_used(wgt)
    helidash_functions.update_profiles(wgt)
    helidash_functions.update_link_quality(wgt)
    helidash_functions.update_transmitter_power(wgt)
    helidash_functions.update_arm(wgt)
    helidash_functions.update_vbec(wgt)
    helidash_functions.update_esc_temperature(wgt)
    helidash_functions.update_mcu_temperature(wgt)

    helidash_functions.refresh_ui_no_conn(wgt)
end

-- Background refresh: lightweight updates (connection state + battery callouts)
function helidash_functions.background_refresh(wgt)
    helidash_functions.update_battery_callout(wgt)
end

-- Main refresh: full telemetry updates (handles both connected and disconnected states)
function helidash_functions.refresh(wgt)
    if helidash_functions.simu_mode then
        helidash_functions.refresh_ui(wgt)
        return
    end

    if not is_rf_connected(wgt) then
        helidash_functions.refresh_ui_no_conn(wgt)
        return
    end
    helidash_functions.refresh_ui(wgt)
    helidash_functions.update_battery_callout(wgt)
end

return helidash_functions
