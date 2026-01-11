local app_name = "HeliDash"
local widg_dir = "/WIDGETS/HeliDash/"

local helidash = nil
local helidash_options = loadScript(widg_dir..app_name .. "Options.lua", "btd")()

local function create(zone, options)
    helidash = assert(loadScript(widg_dir..app_name .. ".lua", "btd"))()
    return helidash.create(zone, options)
end
local function update(wgt, options) return helidash.update(wgt, options) end
local function refresh(wgt)         return helidash.refresh(wgt)    end
local function background(wgt)      return helidash.background(wgt) end

return {name=app_name, options=helidash_options.options, translate=helidash_options.translate, create=create, update=update, refresh=refresh, background=background, useLvgl=true}
