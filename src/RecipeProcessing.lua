local component = require("component")
local Recipe = require("Recipe")

---@class RecipeProcessing
---@field recipes Recipe[]
---@field cpus any
RecipeProcessing = {}
RecipeProcessing.__index = RecipeProcessing

function RecipeProcessing.new()
    local obj = setmetatable({}, RecipeProcessing)

    obj.recipes = {}
    obj.cpus = component.me_controller.getCpus()

    print("Available number of cpu: " .. #obj.cpus .. "\n")

    return obj
end

function RecipeProcessing:loadRecipes(config)
    for _, recipe_data in pairs(config) do
        local recipe = Recipe.new(recipe_data.name, recipe_data.batch)
        recipe.user_data = recipe_data

        table.insert(self.recipes, recipe)
    end
end

function RecipeProcessing:update()

end

return RecipeProcessing
