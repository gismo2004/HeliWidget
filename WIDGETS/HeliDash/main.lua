local app_name = "HeliDash"
local widg_dir = "/WIDGETS/HeliDash/"

local helidash = nil
local helidash_options = loadScript(widg_dir .. "helidashOptions.lua", "btd")()
---@type WidgetOptions
local widget_options = helidash_options.options

local function get_heli_dash()
    helidash = helidash or assert(loadScript(widg_dir .. "helidash.lua", "btd"))()
    return helidash
end

local function create(zone, options)
    return get_heli_dash().create(zone, options)
end
local function update(wgt, options) return get_heli_dash().update(wgt, options) end
local function refresh(wgt, event, touch_state) return get_heli_dash().refresh(wgt, event, touch_state) end
local function background(wgt) return get_heli_dash().background(wgt) end

---@type WidgetScript
local script = {
    name = app_name,
    options = widget_options,
    translate = helidash_options.translate,
    create = create,
    update = update,
    refresh = refresh,
    background = background,
    useLvgl = true,
}

return script
