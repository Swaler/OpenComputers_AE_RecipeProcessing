local component = require("component")
local Recipe = require("Recipe")
local AE2Utils = require("Utils.AE2Utils")
local ColouredText = require("Utils.ColouredText")

local TIME_UPDATE_FINISHED_CPUS = 1
local TIME_START_RECIPE = 1


---@class RecipeProcessing
---@field private _recipes Recipe[]
---@field private _await_recipes int[]
---@field private _processing_recipes int[]
---@field private _await_finished_recipes boolean
---@field private _time number
RecipeProcessing = {}
RecipeProcessing.__index = RecipeProcessing

function RecipeProcessing.new()
    local obj = setmetatable({}, RecipeProcessing)

    obj._recipes = {}
    obj._await_recipes = {}
    obj._processing_recipes = {}
    obj._await_finished_recipes = true
    obj._time = 0

    return obj
end

function RecipeProcessing:init(config)
    self:loadRecipe(config)

    if #self._recipes == 0 then
        print(ColouredText.red("Нет ни одного рецепта для обработки"))
        return
    end

    print(ColouredText.cyan("Доступных процессоров: ") .. #component.me_controller.getCpus())

    local busy_count = AE2Utils.BusyCpuCount()

    if busy_count > 0 then
        print(ColouredText.orange("Для начала обработки рецептов требуется что бы все процессоры завершили рецепты!"))
        print(ColouredText.cyan("Кол-во занятых процессоров: ") .. busy_count)
    end
end

function RecipeProcessing:loadRecipe(config)
    for _, recipe_data in pairs(config) do
        local recipe = Recipe.new(
            recipe_data.item_id,
            recipe_data.min,
            recipe_data.batch)

        if recipe:isInvalid() then
            print(ColouredText.red("Не удалось загрузить рецепт <" ..
                recipe_data.item_id .. "> по причине: " .. recipe.invalid_reason))
        else
            recipe.user_data = recipe_data
            table.insert(self._recipes, recipe)
            table.insert(self._await_recipes, #self._recipes)

            print(ColouredText.cyan("Загружен рецепт: ") .. recipe_data.name .. " " .. recipe:getLabel())
        end
    end
end

function RecipeProcessing:update(delta_time)
    if self:canRecipeProcessing(delta_time) then
        self:updateProcessingRecipe()
        self:updateAwaitingRecipe(delta_time)
    end
end

function RecipeProcessing:canRecipeProcessing(delta_time)
    if #self._recipes == 0 then
        return false
    end

    if self._await_finished_recipes then
        self._time = self._time + delta_time

        if self._time >= TIME_UPDATE_FINISHED_CPUS then
            local busy_count = AE2Utils.BusyCpuCount()

            if busy_count == 0 then
                self._await_finished_recipes = false
            end

            if self._await_finished_recipes then
                print(ColouredText.cyan("Кол-во занятых процессоров: ") .. busy_count)
            end

            self._time = 0
        end
    end

    return not self._await_finished_recipes
end

function RecipeProcessing:updateProcessingRecipe()
    if #self._processing_recipes == 0 then return end

    for i = #self._processing_recipes, 1, -1 do
        local recipe_index = self._processing_recipes[i]
        local recipe = self._recipes[recipe_index]
        local remove_from_processing = not recipe or recipe:isFailed()

        if recipe == nil then
            print(ColouredText.red("Recipe is nill ..."))
            table.remove(self._processing_recipes, i)
            return
        end

        if recipe:isFinished() and recipe:start() then
            remove_from_processing = false
            print(ColouredText.cyan("Перезапускаем рецепт: ") .. recipe:getLabel())
        end

        if remove_from_processing then
            table.remove(self._processing_recipes, i)
            table.insert(self._await_recipes, recipe_index)
        end
    end
end

function RecipeProcessing:updateAwaitingRecipe(delta_time)
    local cpus = component.me_controller.getCpus()

    if #self._processing_recipes >= #cpus then
        return
    end

    self._time = self._time + delta_time

    if self._time < TIME_START_RECIPE then return end

    for i = #self._await_recipes, 1, -1 do
        local recipe_index = self._await_recipes[i]
        local recipe = self._recipes[recipe_index]

        if recipe == nil then
            print(ColouredText.red("Recipe is nill ..."))
            table.remove(self._await_recipes, i)
            return
        end

        local remove_from_await = recipe:start()

        if remove_from_await then
            print(ColouredText.cyan("Рецепт запущен: ") .. recipe:getLabel())
            table.remove(self._await_recipes, i)
            table.insert(self._processing_recipes, recipe_index)
        else
            print(ColouredText.yellow("Не удалось запустить рецепт: ") .. recipe:getLabel())
        end
    end

    self._time = 0
end

return RecipeProcessing
