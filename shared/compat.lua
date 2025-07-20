Compat = {}

local hasQBX = GetResourceState('qbx-core') == 'started'
local useOxLib = GetResourceState('ox_lib') == 'started'
local useOxInv = GetResourceState('ox_inventory') == 'started'
local useQbTarget = GetResourceState('qb-target') == 'started'
local useQTarget = GetResourceState('qtarget') == 'started'
local useOxTarget = GetResourceState('ox_target') == 'started'

Compat.core = (hasQBX and exports['qbx-core']:GetCoreObject())
    or exports['qb-core']:GetCoreObject()

function Compat.GetCore()
    return Compat.core
end

function Compat.Notify(text, ntype)
    local core = Compat.GetCore()
    if useOxLib then
        lib.notify({ description = text, type = ntype or 'inform' })
    else
        core.Functions.Notify(text, ntype)
    end
end

function Compat.ShowInput(data)
    if useOxLib then
        local dialog = {}
        for _, input in ipairs(data.inputs or {}) do
            dialog[#dialog+1] = {
                type = input.type or 'input',
                label = input.text or input.label,
                required = input.isRequired,
                name = input.name
            }
        end
        local result = lib.inputDialog(data.header or '', dialog)
        if not result then return nil end
        local output = {}
        for i, input in ipairs(data.inputs or {}) do
            output[input.name] = result[i]
        end
        return output
    else
        return exports['qb-input']:ShowInput(data)
    end
end

function Compat.OpenMenu(menu)
    if useOxLib then
        local id = ('keep_oilwell_%s'):format(math.random(1, 100000))
        local options = {}
        for _, item in ipairs(menu) do
            if not item.isMenuHeader then
                local onSelect
                if item.params and item.params.event then
                    local event = item.params.event
                    local args = item.params.args
                    onSelect = function()
                        TriggerEvent(event, args)
                    end
                elseif item.event then
                    local ev = item.event
                    local args = item.args
                    onSelect = function()
                        TriggerEvent(ev, args)
                    end
                end
                options[#options+1] = {
                    title = item.header,
                    description = item.txt,
                    icon = item.icon,
                    disabled = item.disabled,
                    onSelect = onSelect
                }
            end
        end
        lib.registerContext({ id = id, title = menu[1] and menu[1].header or 'Menu', options = options })
        lib.showContext(id)
    else
        exports['qb-menu']:openMenu(menu)
    end
end

function Compat.CloseMenu()
    if useOxLib then
        lib.hideContext()
    else
        TriggerEvent('qb-menu:closeMenu')
    end
end

function Compat.GetTarget()
    if useQbTarget then
        return exports['qb-target']
    elseif useQTarget then
        return exports['qtarget']
    elseif useOxTarget then
        return exports['ox_target']
    end
end

function Compat.AddTrunkItems(plate, items, src)
    if useOxInv then
        for _, item in ipairs(items) do
            exports.ox_inventory:AddItem(src, item.name, item.amount or 1, item.info or {})
        end
    else
        exports['qb-inventory']:addTrunkItems(plate, items)
    end
end

function Compat.ItemBox(src, item, typ)
    if not useOxInv then
        TriggerClientEvent('qb-inventory:client:ItemBox', src, item, typ)
    end
end

function Compat.ServerNotify(src, text, ntype)
    if useOxLib then
        TriggerClientEvent('ox_lib:notify', src, { description = text, type = ntype or 'inform' })
    else
        TriggerClientEvent('QBCore:Notify', src, text, ntype)
    end
end

return Compat
