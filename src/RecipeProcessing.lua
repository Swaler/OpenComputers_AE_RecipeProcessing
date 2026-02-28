local folderOfThisFile = (...):match("(.-)[^%.]+$")

local component = require("component")
local Recipe = require(folderOfThisFile .. "Recipe")

---@class RecipeProcessing
---@field recipes Recipe[]
---@field cpus any
RecipeProcessing = {}
RecipeProcessing.__index = RecipeProcessing

function RecipeProcessing.new()
    local obj = setmetatable({}, RecipeProcessing)

    obj.recipes = {}
    obj.cpus = component.me_controller.getCpus()

    print("Кол-во доступных процессоров: " .. #obj.cpus .. "\n")

    return obj
end

function RecipeProcessing:loadRecipes(config)
    for _, recipe_data in pairs(config) do
        local recipe = Recipe.new(recipe_data.name, recipe_data.batch)

        if recipe.status == RecipeStatus.AWAIT then
            recipe.user_data = recipe_data
            table.insert(self.recipes, recipe)
            print("Загружен рецепт: " .. recipe_data.name)
        else
            print("Не удалось загрузить рецепт <" .. recipe_data.name .. "> по причине: " .. recipe.invalid_reason)
        end
        
    end
end

function RecipeProcessing:update()

end

return RecipeProcessing
