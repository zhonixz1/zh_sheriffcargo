local activeCargo = nil
local Core = exports.vorp_core:GetCore()

local function notifyPlayer(source, message)
    if Config.Notifications.enabled and source and tonumber(source) then
        Core.NotifyRightTip(tonumber(source), message, Config.Notifications.duration)
    end
end

local function notifyAll(message)
    if not Config.Notifications.enabled then
        return
    end

    for _, playerId in ipairs(GetPlayers()) do
        notifyPlayer(playerId, message)
    end
end

local function getCharacter(source)
    local user = Core.getUser(source)
    if not user then
        return nil
    end

    return user.getUsedCharacter
end

local function isAllowedToStart(source)
    if not Config.Permissions.enabled then
        return true
    end

    local character = getCharacter(source)
    if not character then
        return false
    end

    local job = string.lower(tostring(character.job or ""))
    local grade = tonumber(character.jobGrade or 0) or 0

    return Config.Permissions.jobs[job] == true and grade >= Config.Permissions.minimumJobGrade
end

local function getMarketItemMap()
    local market = {}

    for _, entry in ipairs(Config.MarketItems or {}) do
        if entry.item then
            market[entry.item] = {
                item = entry.item,
                label = entry.label or entry.item,
                maxAmount = tonumber(entry.maxAmount or Config.UI.maxPerItem or 1) or 1
            }
        end
    end

    return market
end

local function sanitizeCrateItems(selectedItems)
    local market = getMarketItemMap()
    local sanitized = {}
    local byItem = {}
    local totalAmount = 0
    local maxTotal = tonumber(Config.UI.maxTotalItems or 0) or 0

    if type(selectedItems) ~= "table" then
        return sanitized
    end

    for _, selected in ipairs(selectedItems) do
        local itemName = tostring(selected.item or "")
        local marketItem = market[itemName]

        if marketItem then
            local alreadySelected = byItem[itemName] and byItem[itemName].amount or 0
            local amount = math.floor(tonumber(selected.amount or 0) or 0)
            amount = math.min(amount, marketItem.maxAmount - alreadySelected)

            if maxTotal > 0 and totalAmount + amount > maxTotal then
                amount = maxTotal - totalAmount
            end

            if amount > 0 then
                if byItem[itemName] then
                    byItem[itemName].amount = byItem[itemName].amount + amount
                else
                    local reward = {
                        item = itemName,
                        label = marketItem.label,
                        amount = amount
                    }

                    sanitized[#sanitized + 1] = reward
                    byItem[itemName] = reward
                end

                totalAmount = totalAmount + amount
            end

            if maxTotal > 0 and totalAmount >= maxTotal then
                break
            end
        end
    end

    return sanitized
end

local function giveCrateItems(source, crateItems)
    if type(crateItems) ~= "table" or #crateItems == 0 then
        return true
    end

    for _, reward in ipairs(crateItems) do
        if not exports.vorp_inventory:canCarryItem(source, reward.item, reward.amount) then
            local message = Config.Notifications.noInventorySpace

            if reward.label then
                message = ("%s (%s x%s)"):format(message, reward.label, reward.amount)
            end

            notifyPlayer(source, message)
            return false
        end
    end

    for _, reward in ipairs(crateItems) do
        exports.vorp_inventory:addItem(source, reward.item, reward.amount)
    end

    return true
end

local function getCargoNetIds()
    if not activeCargo then
        return nil
    end

    return {
        vehicleNetId = activeCargo.vehicleNetId,
        driverNetId = activeCargo.driverNetId,
        crateNetId = activeCargo.crateNetId
    }
end

local function deleteServerNetEntity(netId)
    if not NetworkDoesNetworkIdExist or not NetworkGetEntityFromNetworkId or not DoesEntityExist then
        return
    end

    if not netId or not NetworkDoesNetworkIdExist(netId) then
        return
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if DeleteEntity and entity and entity ~= 0 and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

local function clearCargo()
    if activeCargo then
        local netIds = getCargoNetIds()
        TriggerClientEvent("cargo:client:cleanupCargo", -1, activeCargo.token, netIds)
        deleteServerNetEntity(activeCargo.crateNetId)
        deleteServerNetEntity(activeCargo.driverNetId)
        deleteServerNetEntity(activeCargo.vehicleNetId)
    end

    activeCargo = nil
end

RegisterServerEvent("cargo:server:spawnFailed")
AddEventHandler("cargo:server:spawnFailed", function(token)
    if activeCargo and activeCargo.token == token and activeCargo.owner == source then
        clearCargo()
    end
end)

local function netEntityExists(netId)
    if not NetworkDoesNetworkIdExist or not NetworkGetEntityFromNetworkId or not DoesEntityExist then
        return true
    end

    if not netId or not NetworkDoesNetworkIdExist(netId) then
        return false
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    return entity and entity ~= 0 and DoesEntityExist(entity)
end

local function clearStaleCargo()
    if not activeCargo then
        return false
    end

    local now = GetGameTimer and GetGameTimer() or 0
    local spawnTimeout = Config.Timing.spawnRegisterTimeout or 15000

    if not activeCargo.vehicleNetId or not activeCargo.driverNetId or not activeCargo.crateNetId then
        if now == 0 or now - (activeCargo.createdAt or now) >= spawnTimeout then
            clearCargo()
            return true
        end

        return false
    end

    if not netEntityExists(activeCargo.vehicleNetId) and not netEntityExists(activeCargo.driverNetId) and not netEntityExists(activeCargo.crateNetId) then
        clearCargo()
        return true
    end

    return false
end

local function requestCargoSpawn(source, routeName, crateItems, startMessage)
    if source == 0 then
        return
    end

    routeName = routeName or Config.DefaultRoute

    if not Config.routePoints[routeName] then
        routeName = Config.DefaultRoute
    end

    clearStaleCargo()

    if activeCargo then
        notifyPlayer(source, Config.Notifications.alreadyActive)
        return
    end

    local token = os.time() .. ":" .. source
    activeCargo = {
        owner = source,
        routeName = routeName,
        token = token,
        createdAt = GetGameTimer and GetGameTimer() or 0,
        vehicleNetId = nil,
        driverNetId = nil,
        crateNetId = nil,
        crateState = "wagon",
        crateCarrier = nil,
        crateOpened = false,
        crateItems = sanitizeCrateItems(crateItems)
    }

    TriggerClientEvent("cargo:client:startCargo", source, activeCargo.routeName, token)
    notifyAll(startMessage or Config.Notifications.manualStarted)
    return true
end

RegisterServerEvent("cargo:server:startCargo")
AddEventHandler("cargo:server:startCargo", function(routeName, crateItems)
    if string.lower(Config.SpawnMode or "manual") ~= "manual" then
        return
    end

    if not isAllowedToStart(source) then
        notifyPlayer(source, Config.Permissions.denyMessage)
        return
    end

    requestCargoSpawn(source, routeName or Config.DefaultRoute, crateItems)
end)

RegisterCommand(Config.OpenCommand or "cargo", function(source, args)
    if source == 0 then
        return
    end

    if string.lower(Config.SpawnMode or "manual") ~= "manual" then
        notifyPlayer(source, "Cargo is currently running in automatic mode.")
        return
    end

    if not isAllowedToStart(source) then
        notifyPlayer(source, Config.Permissions.denyMessage)
        return
    end

    clearStaleCargo()
    if activeCargo then
        notifyPlayer(source, Config.Notifications.alreadyActive)
        return
    end

    TriggerClientEvent("cargo:client:openSetupUi", source)
end, false)

CreateThread(function()
    local lastTriggeredMinute = nil

    while true do
        local interval = math.max(1000, tonumber(Config.Automatic and Config.Automatic.checkInterval) or 15000)

        if string.lower(Config.SpawnMode or "manual") == "automatic" then
            local now = os.date("*t")
            local minuteKey = ("%04d-%03d-%02d:%02d"):format(now.year, now.yday, now.hour, now.min)

            if minuteKey ~= lastTriggeredMinute then
                for _, schedule in ipairs((Config.Automatic and Config.Automatic.times) or {}) do
                    if now.hour == tonumber(schedule.hour) and now.min == tonumber(schedule.minute) then
                        clearStaleCargo()

                        if not activeCargo then
                            local players = GetPlayers()
                            local owner = players[1] and tonumber(players[1])

                            if owner then
                                lastTriggeredMinute = minuteKey
                                local route = Config.Automatic.route or Config.DefaultRoute
                                local items = Config.Automatic.items or {}
                                requestCargoSpawn(owner, route, items, Config.Notifications.automaticStarted or Config.Notifications.manualStarted)
                            end
                        end
                        break
                    end
                end
            end
        end

        Wait(interval)
    end
end)

RegisterServerEvent("cargo:server:registerCargo")
AddEventHandler("cargo:server:registerCargo", function(token, vehicleNetId, driverNetId, crateNetId, routeName)
    local _source = source

    if not activeCargo or activeCargo.token ~= token or activeCargo.owner ~= _source then
        return
    end

    activeCargo.vehicleNetId = vehicleNetId
    activeCargo.driverNetId = driverNetId
    activeCargo.crateNetId = crateNetId
    activeCargo.registeredAt = GetGameTimer and GetGameTimer() or 0
    activeCargo.routeName = routeName or activeCargo.routeName

    TriggerClientEvent("cargo:client:syncCargo", -1, vehicleNetId, driverNetId, crateNetId, activeCargo.routeName)
end)

RegisterServerEvent("cargo:server:crateAction")
AddEventHandler("cargo:server:crateAction", function(action)
    local _source = source

    if not activeCargo or not activeCargo.crateNetId then
        return
    end

    if action == "carry" and (activeCargo.crateState == "wagon" or activeCargo.crateState == "dropped") then
        activeCargo.crateState = "carried"
        activeCargo.crateCarrier = _source
        TriggerClientEvent("cargo:client:setCrateState", -1, activeCargo.crateNetId, "carried", _source)
    elseif action == "drop" and activeCargo.crateState == "carried" and activeCargo.crateCarrier == _source then
        activeCargo.crateState = "dropped"
        activeCargo.crateCarrier = nil
        TriggerClientEvent("cargo:client:setCrateState", -1, activeCargo.crateNetId, "dropped", _source)
    elseif action == "open" and activeCargo.crateState ~= "opened" and not activeCargo.crateOpened then
        if not giveCrateItems(_source, activeCargo.crateItems) then
            return
        end

        activeCargo.crateOpened = true
        activeCargo.crateState = "opened"
        TriggerClientEvent("cargo:client:setCrateState", -1, activeCargo.crateNetId, "opened", _source)
        notifyAll(Config.Notifications.opened)
    end
end)

RegisterServerEvent("cargo:server:cargoFinished")
AddEventHandler("cargo:server:cargoFinished", function(token)
    if activeCargo and activeCargo.token == token and activeCargo.owner == source then
        clearCargo()
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    clearCargo()
end)
