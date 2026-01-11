local M = {

    options = {
        {"Timer"                , TIMER, 0 },
        {"BGFilled"             , BOOL  , 0 },
        {"FuelMin"              , VALUE , 30, 0, 100 },
		{"CalloutInt"           , VALUE , 6, 0, 60},
        {"Haptic"               , BOOL  , 1 },
    },

    translate = function(name)
        local translations = {
			Timer = "Which timer to display",
            BGFilled = "Fill background color",
			FuelMin = "Fuel min %",
			CalloutInt = "Callout interval (sec)",
            Haptic = "Vibrate on callout",
        }
        return translations[name]
    end
}

return M
