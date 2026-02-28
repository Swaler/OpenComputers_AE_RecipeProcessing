package.path = package.path .. ";/home/AE_RecipeProcessing/?.lua"


local event = require("event")
local config = require("config")
local RecipeProcessing = require("RecipeProcessing")

---@class Application
---@field recipe_processing RecipeProcessing
Application = {}
Application.__index = Application

function Application.new()
    local app = setmetatable({}, Application)
    app.recipe_processing = RecipeProcessing.new()
    return app
end

function Application:init()
    self.recipe_processing:loadRecipes(config)
end

function Application:run()
    while true do
        self.recipe_processing:update()
    end
end

function Application:pause()
    print("Press any key to continue...\n")
    event.pull("key_down")
end

local function main()
    local app = Application.new()

    app:init()
    app:pause()
end

main()
