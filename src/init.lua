package.path = package.path .. ";/home/AE_RecipeProcessing/?.lua"


local event = require("event")
local computer = require("computer")
local config = require("config")
local RecipeProcessing = require("RecipeProcessing")
local ColouredText = require("Utils.ColouredText")

---@class Application
---@field private _recipe_processing RecipeProcessing
---@field private _last_time number
Application = {}
Application.__index = Application

function Application.new()
    local app = setmetatable({}, Application)
    app._recipe_processing = RecipeProcessing.new()
    app._last_time = computer.uptime()
    return app
end

function Application:init()
    self._recipe_processing:init(config)
end

function Application:run()
    local is_running = true

    event.listen("interrupted", function()
        is_running = false
    end)

    while is_running do
        local currentTime = computer.uptime()
        local dt = currentTime - self._last_time
        self._last_time = currentTime

        local success, err = pcall(function()
            self._recipe_processing:update(dt)
        end)

        if not success then
            print(ColouredText.red(err))
            break
        end

        os.sleep(0.1)
    end
end

local function main()
    local app = Application.new()

    app:init()

    print(ColouredText.yellow("Нажмите любую клавишу что бы продолжить..."))
    event.pull("key_down")

    app:run()
end

main()
