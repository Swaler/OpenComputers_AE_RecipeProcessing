local AE2Utils = require("Utils.AE2Utils")

---@class Recipe
---@field private _recipe_name string
---@field private _is_invalid boolean
---@field private _start_batch integer
---@field private _request_status AE2CraftingStatus | nil
---@field private _ae2_pattern AE2Pattern | nil
---@field invalid_reason string
---@field user_data table | nil
Recipe = {}
Recipe.__index = Recipe


---@param recipe_name string идентификатор рецепта, по которому будет искаться зарегистрированный рецепт в ME сети
---@param start_batch integer сколько нужно заказывать у ME сети
function Recipe.new(recipe_name, start_batch)
    local obj = setmetatable({}, Recipe)

    obj._ae2_pattern = AE2Utils.findPattern(recipe_name)
    obj.invalid_reason = ""
    obj._start_batch = start_batch
    obj._request_status = nil
    obj._is_invalid = false

    if obj._start_batch <= 0 then
        obj._is_invalid = true
        obj.invalid_reason = "batch <= 0"
    elseif obj._ae2_pattern == nil then
        obj._is_invalid = true
        obj.invalid_reason = "Не удалось найти рецепт"
    end

    return obj
end

function Recipe:isLiquid()
    return self._ae2_pattern and AE2Utils.isLiquidItem(self._ae2_pattern.getItemStack())
end

function Recipe:getName()
    return self._ae2_pattern and AE2Utils.getItemName(self._ae2_pattern.getItemStack())
end

function Recipe:getLabel()
    if self._ae2_pattern == nil then
        return ""
    end

    local item = self._ae2_pattern.getItemStack()
    return (self:isLiquid() and item.fluidDrop) and item.fluidDrop.label or item.label
end

function Recipe:isInvalid()
    return self._is_invalid
end

function Recipe:isAwait()
    return self._request_status ~= nil
end

function Recipe:isDone()
    return self._request_status and self._request_status.isDone()
end

function Recipe:isCanceled()
    return self._request_status and self._request_status.isCanceled()
end

function Recipe:isFinished()
    return self._request_status and (self._request_status.isCanceled() or self._request_status.isDone())
end

function Recipe:isProcessing()
    return self._request_status ~= nil and self._request_status.isComputing()
end

function Recipe:isFailed()
    return self._request_status ~= nil and self._request_status.hasFailed()
end

function Recipe:canStart()
    if self._is_invalid or not self._ae2_pattern then
        return false
    end

    return self._start_batch > 0 and not Recipe:isProcessing()
end

function Recipe:start()
    if Recipe:canStart() then
        ---@diagnostic disable-next-line: need-check-nil
        self._request_status = self._ae2_pattern.request(self._start_batch)

        return not self._request_status.hasFailed()
    end

    return false
end

return Recipe
