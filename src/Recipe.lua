local AE2Utils = require("Utils.AE2Utils")

---@enum RecipeStatus
RecipeStatus = {
    AWAIT = 0,
    PROCESSING = 1,
    CANCELED = 2,
    DONE = 3,
    INVALID = 4,
}

---@class Recipe
---@field recipe_name string
---@field status RecipeStatus
---@field invalid_reason string
---@field start_batch integer
---@field request_status table | nil
---@field user_data table | nil
---@field ae2_pattern AE2Pattern | nil
Recipe = {}
Recipe.__index = Recipe


---@param recipe_name string идентификатор рецепта, по которому будет искаться зарегистрированный рецепт в ME сети
---@param start_batch integer сколько нужно заказывать у ME сети
function Recipe.new(recipe_name, start_batch)
    local obj = setmetatable({}, Recipe)

    obj.ae2_pattern = AE2Utils.findPattern(recipe_name)
    obj.recipe_name = recipe_name
    obj.status = RecipeStatus.AWAIT
    obj.invalid_reason = ""
    obj.start_batch = start_batch
    obj.request_status = nil

    if obj.start_batch <= 0 then
        obj.status = RecipeStatus.INVALID
        obj.invalid_reason = "batch <= 0"
    elseif obj.ae2_pattern == nil then
        obj.status = RecipeStatus.INVALID
        obj.invalid_reason = "Не удалось найти рецепт"
    end

    return obj
end

function Recipe:isLiquid()
    return self.ae2_pattern and AE2Utils.isLiquidItem(self.ae2_pattern.getItemStack())
end

function Recipe:getName()
    return self.ae2_pattern and AE2Utils.getItemName(self.ae2_pattern.getItemStack())
end

function Recipe:getLabel()
    if not self.ae2_pattern then
        return ""
    end

    local item = self.ae2_pattern.getItemStack()
    return (self:isLiquid() and item.fluidDrop) and item.fluidDrop.label or item.label
end

function Recipe:isInvalid()
    return self.status == RecipeStatus.INVALID
end

function Recipe:isAwait()
    return self.status == RecipeStatus.AWAIT
end

function Recipe:isDone()
    return self.status == RecipeStatus.DONE
end

function Recipe:isCanceled()
    return self.status == RecipeStatus.CANCELED
end

function Recipe:isFinished()
    return self.status == RecipeStatus.CANCELED or self.status == RecipeStatus.DONE
end

function Recipe:isProcessing()
    return self.request_status ~= nil
end

function Recipe:canStart()
    return self.start_batch > 0
end

function Recipe:process()
    if self.status == RecipeStatus.INVALID or self:isFinished() or not self.ae2_pattern then
        return false
    end

    if self.request_status == nil then
        if not self:canStart() then
            return false
        end

        self.request_status = self.ae2_pattern.request(self.start_batch)
    end

    if self.request_status.isCanceled() then
        self.status = RecipeStatus.CANCELED
        self.request_status = nil
    elseif self.request_status.isDone() then
        self.status = RecipeStatus.DONE
        self.request_status = nil
    end

    return true
end

return Recipe
