package.path = package.path .. ";/home/AE_RecipeProcessing/?.lua"


local event = require("event")
local computer = require("computer")
local config = require("config")
local RecipeProcessing = require("RecipeProcessing")

---@class Application
---@field private _recipe_processing RecipeProcessing
---@field private _last_time number
---@field private _update_timer number | nil
Application = {}
Application.__index = Application

function Application.new()
    local app = setmetatable({}, Application)
    app._recipe_processing = RecipeProcessing.new()
    app._last_time = computer.uptime()
    app._update_timer = nil
    return app
end

function Application:init()
    self._recipe_processing:init(config)
end

function Application:isRunning()
    return self._update_timer ~= nil
end

function Application:run()
    if self:isRunning() then
        return
    end

    self._update_timer = event.timer(0.1, function()
        local currentTime = computer.uptime()
        local dt = currentTime - self._last_time
        self._last_time = currentTime

        self._recipe_processing:update(dt)
    end)
end

function Application:stop()
    if self:isRunning() then
        event.cancel(self._update_timer)
        self._update_timer = nil
    end
end

function Application:pause()
    print("Press any key to continue...\n")
    event.pull("key_down")
end

local function main()
    local app = Application.new()

    event.listen("interrupted", app:stop())

    local success, err = pcall(function()
        app:init()
        app:run()
    end)

    if not success then
        print(err)
    end

    app:stop()
    event.ignore("interrupted", app:stop())
end

main()
