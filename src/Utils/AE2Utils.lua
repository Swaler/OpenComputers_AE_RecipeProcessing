local component = require("component")

AE2Utils = {}

---
---Возвращает паттерн, который зарегистрирован в ME сети
---
---@param name string идентификатор рецепта
---@return AE2Pattern | nil
function AE2Utils.findPattern(name)
    for _, v in pairs(component.me_controller.getCraftables()) do
        local item = v.getItemStack()
        local recipe_name = AE2Utils.getItemName(item)

        if recipe_name == name then
            return v
        end
    end

    return nil
end

---@param item AE2Item | nil
function AE2Utils.isLiquidItem(item)
    return item and item.name == "ae2fc:fluid_drop" and item.fluidDrop or false
end

-- В зависимости от того какой тип рецепта добавляется таблица fluidDrop,
-- где находится действительная информация о рецепте,
---@param item AE2Item | nil
function AE2Utils.getItemName(item)
    if item then
        return (AE2Utils.isLiquidItem(item) and item.fluidDrop) and item.fluidDrop.name or item.name
    end

    return ""
end

---@return integer
function AE2Utils.BusyCpuCount()
    local cpus = component.me_controller.getCpus()
    local count = 0

    for i = 1, #cpus do
        if cpus[i].busy then
            count = count + 1
        end
    end

    return count
end

return AE2Utils
