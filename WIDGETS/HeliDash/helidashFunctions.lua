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


local heliDashFunctions = {}

-- ============================================================================
-- LOCAL HELPER FUNCTIONS
-- ============================================================================

-- Logging helper with ms prefix and configurable tag
function heliDashFunctions.log(text, ...)
    if not text then return end
    local t = getTime() or 0 -- EdgeTX ticks are centiseconds
    local ms = t * 10        -- convert cs to ms
    local tag = "HeliDash"
    local formatted_text = text
    if select('#', ...) > 0 then formatted_text = string.format(tostring(text), ...) end
    print(string.format("[%dms][%s] %s", ms, tag, formatted_text))
end

-- Detect simulator mode for testing
heliDashFunctions.simuMode = string.sub(select(2, getVersion()), -4) == "simu"
heliDashFunctions.log("simuMode=%s", tostring(heliDashFunctions.simuMode))

local function formatTime(t1)
    if not t1 or t1.value == nil then return "00:00", false end

    local seconds = math.abs(t1.value)
    local isNegative = t1.value < 0

    local mm = math.floor(seconds / 60) % 60
    local ss = math.floor(seconds % 60)

    local time_str = string.format("%02d:%02d", mm, ss)

    if isNegative then time_str = '-' .. time_str end
    return time_str, isNegative
end

local function isArmed()
    local flags = getSourceValue("ARM")
    if flags == nil then return false end
    return bit32.band(flags, 0x01) == 1
end

local function armingDisableFlagsList(flags)
    if flags == nil then return nil end

    local flagNames = {
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
        [24] = "Motor Protocol",
        [25] = "Arm Switch"
    }

    local result = {}
    for i = 0, 25 do if bit32.band(flags, bit32.lshift(1, i)) ~= 0 then table.insert(result, flagNames[i]) end end
    return result
end

-- ============================================================================
-- GENERAL INFO UPDATES
-- ============================================================================
function heliDashFunctions.updateCraftName(wgt) wgt.values.craft_name = string.gsub(model.getInfo().name, "^>", "") end

function heliDashFunctions.updateTimerCount(wgt)
    local t1 = model.getTimer(wgt.options.Timer or 0)
    local time_str, isNegative = formatTime(t1)
    wgt.values.timer_str = time_str
    wgt.values.timer_is_negative = isNegative
end

function heliDashFunctions.updateProfiles(wgt)
    wgt.values.profile_id = getSourceValue("PID#") or -1
    wgt.values.rate_id = getSourceValue("RTE#") or -1
end

-- ============================================================================
-- TRANSMITTER/RADIO UPDATES
-- ============================================================================

function heliDashFunctions.updateTXBatVoltage(wgt)
    wgt.values.vtx_volts = getSourceValue("tx-voltage") or 0
    wgt.values.vtx_volts_max = getGeneralSettings().battMax
    wgt.values.vtx_volts_min = getGeneralSettings().battMin
    wgt.values.vtx_volts_warn = getGeneralSettings().battWarn

    wgt.values.vtx_volts_percent = math.floor(100 -
        (100 * (wgt.values.vtx_volts_max - wgt.values.vtx_volts) //
            (wgt.values.vtx_volts_max - wgt.values.vtx_volts_min)))

    if wgt.values.vtx_volts_percent > 100 then wgt.values.vtx_volts_percent = 100 end

    local warnPercent = math.ceil(100 -
        (100 * (wgt.values.vtx_volts_max - wgt.values.vtx_volts_warn) //
            (wgt.values.vtx_volts_max - wgt.values.vtx_volts_min)))

    if (wgt.values.vtx_volts_percent < warnPercent) then
        wgt.values.vtx_volts_color = COLOR_THEME_WARNING
    else
        wgt.values.vtx_volts_color = COLOR_THEME_PRIMARY1
    end
end

function heliDashFunctions.updateLinkQuality(wgt)
    -- Only track minimum link quality; current value not needed
    wgt.values.rqly_min = getSourceValue("RQly-") or 0
end

function heliDashFunctions.updateTransmitterPower(wgt)
    -- Only track maximum transmitter power; current value not needed
    wgt.values.tpwr_max = getValue("TPWR+") or 0
end

-- ============================================================================
-- AIRCRAFT TELEMETRY: VOLTAGE & TEMPERATURE
-- ============================================================================
function heliDashFunctions.updateCell(wgt)
    wgt.values.vbat = getSourceValue("Vbat") or 0

    if heliDashFunctions.simuMode then wgt.values.vbat = math.random(11.01, 12.01) end
end

function heliDashFunctions.updateVcel(wgt)
    wgt.values.vcel = getSourceValue("Vcel") or 0
    wgt.values.vcel_min = getSourceValue("Vcel-") or 0
    wgt.values.vcel_max = getSourceValue("Vcel+") or 0
    wgt.values.cel_count = getSourceValue("Cel#") or 0

    if heliDashFunctions.simuMode then
        wgt.values.vcel = 3.2
        wgt.values.vcel_max = 4.2
        wgt.values.vcel_min = 3.5
        wgt.values.cel_count = 2
    end
end

function heliDashFunctions.updateVbec(wgt)
    wgt.values.vbec = getSourceValue("Vbec") or 0
    wgt.values.vbec_max = getSourceValue("Vbec+") or 0
    wgt.values.vbec_min = getSourceValue("Vbec-") or 0

    if heliDashFunctions.simuMode then
        wgt.values.vbec = math.random(72, 78) / 10
        wgt.values.vbec_max = 8.4
        wgt.values.vbec_min = 7.2
    end
end

function heliDashFunctions.updateESCTemperature(wgt)
    wgt.values.esc_temp = getSourceValue("Tesc") or 0
    wgt.values.esc_temp_min = getSourceValue("Tesc-") or 0
    wgt.values.esc_temp_max = getSourceValue("Tesc+") or 0

    if heliDashFunctions.simuMode then
        wgt.values.esc_temp = 60
        wgt.values.esc_temp_max = 75
        wgt.values.esc_temp_min = 45
    end
end

function heliDashFunctions.updateMCUTemperature(wgt) wgt.values.mcu_temp_max = getSourceValue("Tmcu+") or 0 end

-- ============================================================================
-- AIRCRAFT TELEMETRY: CURRENT & CAPACITY
-- ============================================================================
function heliDashFunctions.updateCurr(wgt)
    wgt.values.curr = getSourceValue("Curr") or 0
    wgt.values.curr_min = getSourceValue("Curr-") or 0
    wgt.values.curr_max = getSourceValue("Curr+") or 0

    if heliDashFunctions.simuMode then
        wgt.values.curr = math.random(0, 200)
        wgt.values.curr_max = 255
        wgt.values.curr_min = 0.2
    end
end

function heliDashFunctions.updateMAUsed(wgt)
    wgt.values.capa = getSourceValue("Capa") or 0
    wgt.values.capa_percent = getSourceValue("Bat%") or 100

    if heliDashFunctions.simuMode then
        wgt.values.capa = math.random(0, 2000)
        wgt.values.capa_percent = math.random(0, 100)
    end

    local batt_cap_min = (wgt.options and wgt.options.FuelMin) or 30
    if wgt.values.capa_percent > batt_cap_min then
        wgt.values.capa_mid_text_color = COLOR_THEME_PRIMARY1
        wgt.values.capa_cell_color = COLOR_THEME_SECONDARY2
    else
        wgt.values.capa_mid_text_color = COLOR_THEME_WARNING
        wgt.values.capa_cell_color = COLOR_THEME_WARNING
    end
end

-- ============================================================================
-- AIRCRAFT TELEMETRY: HELI-SPECIFIC
-- ============================================================================
function heliDashFunctions.updateHeadspeed(wgt)
    wgt.values.headspeed = getSourceValue("Hspd") or 0
    if heliDashFunctions.simuMode then wgt.values.headspeed = math.random(2000, 3000) end
end

function heliDashFunctions.updateGovState(wgt)
    local gov_state = getSourceValue("Gov") or 0

    if heliDashFunctions.simuMode then gov_state = math.random(0, 9) end

    local govStates = {
        [0] = "Throttle off",  -- GOV_STATE_THROTTLE_OFF
        [1] = "Throttle Idle", -- GOV_STATE_THROTTLE_IDLE
        [2] = "Spooling up",   -- GOV_STATE_SPOOLUP
        [3] = "Recovery",      -- GOV_STATE_RECOVERY
        [4] = "Gov. Active",   -- GOV_STATE_ACTIVE
        [5] = "Throttle Hold", -- GOV_STATE_THROTTLE_HOLD
        [6] = "Gov. Fallback", -- GOV_STATE_FALLBACK
        [7] = "Autorotation",  -- GOV_STATE_AUTOROTATION
        [8] = "Bailing Out"    -- GOV_STATE_BAILOUT
    }

    wgt.values.gov_state = govStates[gov_state] or "Gov. Disabled"
end

-- ============================================================================
-- ARM STATE UPDATES
-- ============================================================================

function heliDashFunctions.updateArm(wgt)
    wgt.values.arm_state = isArmed()
    local flags = getSourceValue("ARMD")
    if flags == nil then flags = 0 end
    local flagList = armingDisableFlagsList(flags)
    wgt.values.arm_disable_flags_list = flagList
end

-- Update arming flags display (cycles every 2 seconds if multiple flags)
function heliDashFunctions.updateArmingFlagsDisplay(wgt)
    if not wgt.values.arm_disable_flags_list or #wgt.values.arm_disable_flags_list == 0 then
        wgt.values.arm_flags_text_formatted = ""
        return
    end

    -- Initialize cycling state if needed
    if not wgt.flag_cycle_time then wgt.flag_cycle_time = getTime() end
    if not wgt.flag_cycle_index then wgt.flag_cycle_index = 0 end

    local flags = wgt.values.arm_disable_flags_list
    local cycle_interval = 200 -- 2 seconds in centiseconds
    local now = getTime()
    local elapsed = now - wgt.flag_cycle_time

    -- Cycle to next flag every 2 seconds
    if elapsed >= cycle_interval then
        wgt.flag_cycle_index = (wgt.flag_cycle_index + 1) % #flags
        wgt.flag_cycle_time = now
    end

    local current_flag = flags[wgt.flag_cycle_index + 1]
    wgt.values.arm_flags_text_formatted = "Arming Disabled: " .. (current_flag or "")
end

-- ============================================================================
-- ALERTS & CALLOUTS
-- ============================================================================

function heliDashFunctions.updateBatteryCallout(wgt)
    if not wgt.is_connected then return end

    -- Update capacity data first (needed for callout logic)
    heliDashFunctions.updateMAUsed(wgt)

    local batt_cap_min = wgt.options.FuelMin or 30
    local callout_interval = wgt.options.CalloutInt or 10
    local now = getTime() / 100
    wgt.last_battery_callout_time = wgt.last_battery_callout_time or 0

    local should_announce = false
    local announce_value, announce_unit, announce_precision, log_msg

    -- Mode 1: Current sensor detected (% < 100) - announce percentage when low (with 2+ sec debounce)
    if wgt.values.capa_percent < 100 then
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
    elseif wgt.values.capa_percent >= 100 then
        local vcel = wgt.values.vcel or 0
        local voltage_threshold = 3.3

        if vcel > 0 and vcel < voltage_threshold then
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
    else
        wgt.battery_low_start_time = nil
    end

    -- Trigger callout if conditions met and enough time elapsed
    if should_announce and (now - wgt.last_battery_callout_time) >= callout_interval then
        playNumber(announce_value, announce_unit, announce_precision)
        heliDashFunctions.log(log_msg)
        if wgt.options.Haptic == 1 then playHaptic(20, 0, 0) end
        wgt.last_battery_callout_time = now
    end
end

-- ============================================================================
-- CONNECTION & STATE MANAGEMENT
-- ============================================================================

-- Connection state tracking with debouncing
function heliDashFunctions.updateConnectionState(wgt)
    local current_rssi = getRSSI() > 0
    if heliDashFunctions.simuMode then current_rssi = true end

    local now = getTime() / 100

    if current_rssi ~= wgt.rssi_state then
        if current_rssi == true then
            local was_connected = wgt.is_connected
            wgt.rssi_state = true
            wgt.is_connected = true
            wgt.rssi_state_change_time = 0

            if not was_connected then heliDashFunctions.resetTelemetryStats(wgt) end
        else
            if wgt.rssi_state_change_time == 0 then
                wgt.rssi_state_change_time = now
            elseif (now - wgt.rssi_state_change_time) >= wgt.rssi_debounce_threshold then
                wgt.rssi_state = false
                wgt.is_connected = false
                wgt.rssi_state_change_time = 0
                heliDashFunctions.log("Connection lost")
            end
        end
    else
        wgt.rssi_state_change_time = 0
    end
end

function heliDashFunctions.resetTelemetryStats(wgt)
    for i = 0, 99 do model.resetSensor(i) end

    model.resetTimer(wgt.options.Timer or 0)

    -- Reset battery callout timer on disconnect
    wgt.last_battery_callout_time = nil
    wgt.battery_low_start_time = nil
end

-- ============================================================================
-- REFRESH ORCHESTRATION
-- ============================================================================

function heliDashFunctions.refreshUINoConn(wgt)
    heliDashFunctions.updateTXBatVoltage(wgt)
    heliDashFunctions.updateCraftName(wgt)
    heliDashFunctions.updateTimerCount(wgt)
end

function heliDashFunctions.refreshUI(wgt)
    heliDashFunctions.updateHeadspeed(wgt)
    heliDashFunctions.updateCell(wgt)
    heliDashFunctions.updateVcel(wgt)
    heliDashFunctions.updateCurr(wgt)
    heliDashFunctions.updateGovState(wgt)
    heliDashFunctions.updateProfiles(wgt)
    heliDashFunctions.updateLinkQuality(wgt)
    heliDashFunctions.updateTransmitterPower(wgt)
    heliDashFunctions.updateArm(wgt)
    heliDashFunctions.updateVbec(wgt)
    heliDashFunctions.updateESCTemperature(wgt)
    heliDashFunctions.updateArmingFlagsDisplay(wgt)
    heliDashFunctions.updateMCUTemperature(wgt)

    heliDashFunctions.refreshUINoConn(wgt)
end

-- Background refresh: lightweight updates (connection state + battery callouts)
function heliDashFunctions.backgroundRefresh(wgt)
    heliDashFunctions.updateConnectionState(wgt)
    heliDashFunctions.updateBatteryCallout(wgt)
end

-- Main refresh: full telemetry updates (handles both connected and disconnected states)
function heliDashFunctions.refresh(wgt)
    heliDashFunctions.updateConnectionState(wgt)
    if not wgt.is_connected then
        heliDashFunctions.refreshUINoConn(wgt)
        return
    end
    heliDashFunctions.refreshUI(wgt)
    heliDashFunctions.updateBatteryCallout(wgt)
end

return heliDashFunctions
