local AE2Utils = require("Utils.AE2Utils")


---@class Recipe
---@field private _item_id string
---@field private _recipe_name string
---@field private _is_invalid boolean
---@field private _start_batch integer
---@field private _request_status AE2CraftingStatus | nil
---@field private _ae2_pattern AE2Pattern | nil
---@field private _min integer
---@field invalid_reason string
---@field user_data any
Recipe = {}
Recipe.__index = Recipe


---@param item_id string идентификатор предмета, по которому будет искаться зарегистрированный рецепт в ME сети
---@param min integer Минимальное кол-во предмета в сети, если <= 0 то ограничения нет
---@param start_batch integer сколько нужно заказывать у ME сети
---@param damage? number ХЗ что это
function Recipe.new(item_id, min, start_batch, damage)
    local obj = setmetatable({}, Recipe)

    obj._item_id = item_id
    obj._ae2_pattern = AE2Utils.findPattern(item_id)
    obj._ae2_item = nil
    obj.invalid_reason = ""
    obj._start_batch = start_batch
    obj._request_status = nil
    obj._is_invalid = false
    obj._min = min

    if obj._start_batch <= 0 then
        obj._is_invalid = true
        obj.invalid_reason = "batch <= 0"
    elseif obj._ae2_pattern == nil then
        obj._is_invalid = true
        obj.invalid_reason = "Не удалось найти рецепт"
    end

    return obj
end

---@return string
function Recipe:getItemId()
    return self._item_id
end

function Recipe:isLiquid()
    return self._ae2_pattern ~= nil and AE2Utils.isLiquidItem(self._ae2_pattern.getItemStack())
end

function Recipe:getName()
    return self._ae2_pattern ~= nil and AE2Utils.getItemName(self._ae2_pattern.getItemStack())
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
    return self._request_status ~= nil and self._request_status.isDone()
end

function Recipe:isCanceled()
    return self._request_status ~= nil and self._request_status.isCanceled()
end

function Recipe:isFinished()
    return self._request_status ~= nil and (self._request_status.isCanceled() or self._request_status.isDone())
end

function Recipe:isProcessing()
    return self._request_status ~= nil and self._request_status.isComputing()
end

function Recipe:isFailed()
    return self._request_status ~= nil and self._request_status.hasFailed()
end

function Recipe:canStart()
    if self._is_invalid or self._ae2_pattern == nil or self:isProcessing() then
        return false
    end

    if self._min <= 0 then
        return true
    end

    local item = AE2Utils.findStoredItem(self._item_id)

    if self._item_id == "gregtech:gt.metaitem.01" and item ~= nil then
        print(item.size, self._min)
    end

    return item == nil or item.size < self._min
end

function Recipe:start()
    if self:canStart() then
        self._request_status = self._ae2_pattern.request(self._start_batch)

        return not self._request_status.hasFailed()
    end

    return false
end

return Recipe
