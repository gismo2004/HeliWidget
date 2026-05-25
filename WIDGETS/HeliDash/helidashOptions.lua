local M = {

    options = {
        { "Timer",          TIMER,  0 },
        { "BGFilled",       BOOL,   0 },
        { "FuelMin",        VALUE,  30, 0, 100 },
        { "CalloutInt",     VALUE,  6,  1, 60 },
        { "Haptic",         BOOL,   1 },
        { "StatsViewMode",  CHOICE, 2,  { "Never", "On disarmed", "On disconnected" } },
        { "VoltageDisplay", CHOICE, 1,  { "Cell voltage", "Battery voltage" } },
    },

    translate = function(name)
        local translations = {
            Timer = "Which timer to display",
            BGFilled = "Fill background color",
            FuelMin = "Fuel min %",
            CalloutInt = "Callout interval (sec)",
            Haptic = "Vibrate on callout",
            StatsViewMode = "When to show statistics page",
            VoltageDisplay = "Voltage shown as",
        }
        return translations[name]
    end
}

return M
