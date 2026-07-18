local currentVehicle = nil
local currentDriver = nil
local currentCrate = nil
local currentVehicleNetId = nil
local currentDriverNetId = nil
local currentCrateNetId = nil
local currentBlip = nil
local activeRouteToken = 0
local activeServerToken = nil
local crateState = "none"
local crateCarrier = nil
local isInteractionThreadRunning = false
local isCarryControlThreadRunning = false
local isCargoUiOpen = false
local routeRecorder = {
    active = false,
    key = nil,
    label = nil,
    points = {}
}
local cleanupCargo
local startRouteDriving

local function loadModel(model, timeout)
    RequestModel(model)
    local deadline = GetGameTimer() + (timeout or Config.Timing.modelLoadTimeout)

    while not HasModelLoaded(model) and GetGameTimer() < deadline do
        Wait(10)
    end

    return HasModelLoaded(model)
end

local function requestControl(entity, timeout)
    if not entity or not DoesEntityExist(entity) then
        return false
    end

    local deadline = GetGameTimer() + (timeout or Config.Timing.requestControlTimeout)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < deadline do
        NetworkRequestControlOfEntity(entity)
        Wait(50)
    end

    return NetworkHasControlOfEntity(entity)
end

local function notifyRouteRecorder(message)
    print(("[Cargo Route Recorder] %s"):format(message))
    TriggerEvent("chat:addMessage", {
        args = {"Cargo Route", message}
    })
end

local function addRecordedRoutePoint(coords)
    routeRecorder.points[#routeRecorder.points + 1] = vector3(coords.x, coords.y, coords.z)
end

local function printRecordedRoute()
    local settings = Config.RouteRecorder
    local lines = {
        ("[\"%s\"] = {"):format(routeRecorder.key),
        ("    label = \"%s\","):format(routeRecorder.label),
        "    driving = {",
        ("        speed = %.1f,"):format(settings.defaultSpeed),
        "        stoppingRange = 0.5,",
        "        straightLineDistance = -1.0,",
        ("        arrivalDistance = %.1f,"):format(settings.defaultArrivalDistance),
        "        routeCheckInterval = 150,",
        "        startPointIndex = 2",
        "    },",
        "    locations = {"
    }

    for index, coords in ipairs(routeRecorder.points) do
        local suffix = index < #routeRecorder.points and "," or ""
        lines[#lines + 1] = ("        {coords = vector3(%.4f, %.4f, %.4f)}%s"):format(coords.x, coords.y, coords.z, suffix)
    end

    lines[#lines + 1] = "    }"
    lines[#lines + 1] = "}"
    print("========== Cargo recorded route ==========")
    print(table.concat(lines, "\n"))
    print("==========================================")
end

local function startRouteRecorder(routeKey, label)
    if routeRecorder.active then
        notifyRouteRecorder("A route recording is already active. Use /record_route stop first.")
        return
    end

    routeRecorder.active = true
    routeRecorder.key = routeKey or "new_route"
    routeRecorder.label = label or routeRecorder.key
    routeRecorder.points = {}

    local lastCoords = GetEntityCoords(PlayerPedId())
    addRecordedRoutePoint(lastCoords)
    notifyRouteRecorder(("Started recording '%s'."):format(routeRecorder.key))

    Citizen.CreateThread(function()
        while routeRecorder.active do
            Wait(Config.RouteRecorder.interval)
            local coords = GetEntityCoords(PlayerPedId())

            if #(coords - lastCoords) >= Config.RouteRecorder.minDistance then
                addRecordedRoutePoint(coords)
                lastCoords = coords
            end
        end
    end)
end

local function allowNetworkMigration(netId)
    if Config.Network.canMigrate and SetNetworkIdCanMigrate then
        SetNetworkIdCanMigrate(netId, true)
    elseif SetNetworkIdCanMigrate then
        SetNetworkIdCanMigrate(netId, false)
    end

    if Config.Network.alwaysExistsForPlayers and SetNetworkIdExistsOnAllMachines then
        SetNetworkIdExistsOnAllMachines(netId, true)
    end
end

local function keepCargoEntityActive(entity)
    if not entity or not DoesEntityExist(entity) then
        return
    end

    SetEntityAsMissionEntity(entity, true, true)

    if SetEntityDynamic then
        SetEntityDynamic(entity, true)
    end

    if Config.Network.cullingRadius and SetEntityDistanceCullingRadius then
        SetEntityDistanceCullingRadius(entity, Config.Network.cullingRadius)
    end
end

local function applyPedOutfit(ped)
    if ped and DoesEntityExist(ped) then
        Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    end
end

local function deleteEntity(entity)
    if entity and DoesEntityExist(entity) then
        requestControl(entity, Config.Timing.deleteControlTimeout)
        DeleteEntity(entity)
    end
end

local function deleteNetEntity(netId)
    if not netId or not NetworkDoesNetworkIdExist(netId) then
        return
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    deleteEntity(entity)
end

local function removeCargoBlip()
    if currentBlip then
        RemoveBlip(currentBlip)
        currentBlip = nil
    end
end

local function getBlipSprite()
    if type(Config.Blip.sprite) == "string" then
        return GetHashKey(Config.Blip.sprite)
    end

    return Config.Blip.sprite
end

local function createCargoBlip()
    if not Config.Blip.enabled or currentBlip or not currentVehicle or not DoesEntityExist(currentVehicle) then
        return
    end

    currentBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, Config.Blip.style, currentVehicle)
    SetBlipSprite(currentBlip, getBlipSprite(), true)

    if SetBlipScale then
        SetBlipScale(currentBlip, Config.Blip.scale)
    end

    SetBlipName(currentBlip, Config.Blip.name)
end

local function failCargoSpawn(serverToken)
    activeRouteToken = activeRouteToken + 1
    TriggerServerEvent("cargo:server:spawnFailed", serverToken)
    cleanupCargo()
end

cleanupCargo = function(netIds)
    removeCargoBlip()
    if netIds then
        deleteNetEntity(netIds.crateNetId)
        deleteNetEntity(netIds.driverNetId)
        deleteNetEntity(netIds.vehicleNetId)
    end

    deleteNetEntity(currentCrateNetId)
    deleteNetEntity(currentDriverNetId)
    deleteNetEntity(currentVehicleNetId)
    deleteEntity(currentCrate)
    deleteEntity(currentDriver)
    deleteEntity(currentVehicle)
    currentCrate = nil
    currentDriver = nil
    currentVehicle = nil
    currentCrateNetId = nil
    currentDriverNetId = nil
    currentVehicleNetId = nil
    crateState = "none"
    crateCarrier = nil
end

local function attachCrateToWagon()
    if not currentCrate or not currentVehicle or not DoesEntityExist(currentCrate) or not DoesEntityExist(currentVehicle) then
        return
    end

    requestControl(currentCrate)
    local attach = Config.Crate.attachToWagon
    AttachEntityToEntity(currentCrate, currentVehicle, attach.bone, attach.offset.x, attach.offset.y, attach.offset.z, attach.rotation.x, attach.rotation.y, attach.rotation.z, false, false, true, false, 2, true)
end

local function attachCrateToPlayer(serverId)
    if not currentCrate or not DoesEntityExist(currentCrate) then
        return
    end

    local player = GetPlayerFromServerId(serverId)
    if player == -1 then
        return
    end

    local ped = GetPlayerPed(player)
    if not ped or not DoesEntityExist(ped) then
        return
    end

    requestControl(currentCrate)
    DetachEntity(currentCrate, true, true)

    local attach = Config.Crate.attachToPlayer
    local bone = GetEntityBoneIndexByName(ped, attach.boneName)
    if bone == -1 then
        bone = attach.fallbackBone
    end

    AttachEntityToEntity(currentCrate, ped, bone, attach.offset.x, attach.offset.y, attach.offset.z, attach.rotation.x, attach.rotation.y, attach.rotation.z, false, false, true, false, 2, true)
end

local function dropCrateFromPlayer()
    if not currentCrate or not DoesEntityExist(currentCrate) then
        return
    end

    requestControl(currentCrate)
    DetachEntity(currentCrate, true, true)
    PlaceObjectOnGroundProperly(currentCrate)
end

local function isLocalPlayerCarryingCrate()
    return crateState == "carried" and crateCarrier == GetPlayerServerId(PlayerId())
end

local function startCarryControlThread()
    if isCarryControlThreadRunning or not Config.Controls.disableWhileCarrying then
        return
    end

    isCarryControlThreadRunning = true

    Citizen.CreateThread(function()
        while isLocalPlayerCarryingCrate() do
            local ped = PlayerPedId()

            DisablePlayerFiring(PlayerId(), true)
            SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)

            for _, control in ipairs(Config.Controls.disabledWhileCarrying) do
                DisableControlAction(0, control, true)
            end

            Wait(0)
        end

        isCarryControlThreadRunning = false
    end)
end

local function applyCrateState(newState, carrier)
    crateState = newState
    crateCarrier = carrier

    if newState == "wagon" then
        attachCrateToWagon()
    elseif newState == "carried" then
        attachCrateToPlayer(carrier)
        startCarryControlThread()
    elseif newState == "dropped" then
        dropCrateFromPlayer()
    elseif newState == "opened" then
        dropCrateFromPlayer()
    end
end

local function startCrateInteractionThread()
    if isInteractionThreadRunning then
        return
    end

    isInteractionThreadRunning = true

    Citizen.CreateThread(function()
        while currentCrate and DoesEntityExist(currentCrate) do
            local waitTime = Config.Timing.idleInteractionInterval
            local ped = PlayerPedId()
            local crateCoords = GetEntityCoords(currentCrate)
            local pedCoords = GetEntityCoords(ped)
            local distance = #(pedCoords - crateCoords)

            if distance < Config.Crate.interactionDistance and crateState ~= "opened" then
                waitTime = 0

                if IsControlJustPressed(0, Config.Controls.interact) then
                    local startedAt = GetGameTimer()

                    while IsControlPressed(0, Config.Controls.interact) do
                        Wait(0)

                        if GetGameTimer() - startedAt >= Config.Timing.holdToOpen then
                            TriggerServerEvent("cargo:server:crateAction", "open")
                            break
                        end
                    end

                    if GetGameTimer() - startedAt < Config.Timing.holdToOpen then
                        if crateState == "wagon" or crateState == "dropped" then
                            TriggerServerEvent("cargo:server:crateAction", "carry")
                        elseif crateState == "carried" and crateCarrier == GetPlayerServerId(PlayerId()) then
                            TriggerServerEvent("cargo:server:crateAction", "drop")
                        end
                    end
                end
            end

            Wait(waitTime)
        end

        isInteractionThreadRunning = false
    end)
end

local function getNearestPointIndex(points)
    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        return 2
    end

    local currentCoords = GetEntityCoords(currentVehicle)
    local nearestIndex = 2
    local nearestDistance = nil

    for i = 2, #points do
        local distance = #(currentCoords - points[i].coords)
        if not nearestDistance or distance < nearestDistance then
            nearestDistance = distance
            nearestIndex = i
        end
    end

    return nearestIndex
end

local function getRouteDrivingConfig(routeData)
    local routeDriving = routeData and routeData.driving or {}

    return {
        speed = routeDriving.speed or Config.Driving.speed,
        drivingStyle = routeDriving.drivingStyle or Config.Driving.drivingStyle,
        stoppingRange = routeDriving.stoppingRange or Config.Driving.stoppingRange,
        straightLineDistance = routeDriving.straightLineDistance or Config.Driving.straightLineDistance,
        arrivalDistance = routeDriving.arrivalDistance or Config.Driving.arrivalDistance,
        routeCheckInterval = routeDriving.routeCheckInterval or Config.Timing.routeCheckInterval,
        startPointIndex = routeDriving.startPointIndex or Config.Driving.startPointIndex
    }
end

local function getHeadingToPoint(fromCoords, toCoords)
    if not fromCoords or not toCoords then
        return 0.0
    end

    return GetHeadingFromVector_2d(toCoords.x - fromCoords.x, toCoords.y - fromCoords.y)
end

local function setupCargoOwner()
    if not currentVehicle or not currentDriver or not DoesEntityExist(currentVehicle) or not DoesEntityExist(currentDriver) then
        return false
    end

    requestControl(currentVehicle)
    requestControl(currentDriver)

    Citizen.InvokeNative(0x77FF8D35EEC6BBC4, currentVehicle, 1, 0)
    applyPedOutfit(currentDriver)

    if not IsPedInVehicle(currentDriver, currentVehicle, false) then
        SetPedIntoVehicle(currentDriver, currentVehicle, -1)
        Wait(Config.Timing.driverSeatCheckDelay)
    end

    SetBlockingOfNonTemporaryEvents(currentDriver, true)
    SetPedConfigFlag(currentDriver, 296, true)

    return true
end

local function waitForEntity(entity, routeToken, timeout)
    local deadline = GetGameTimer() + (timeout or Config.Timing.modelLoadTimeout)

    while (not entity or entity == 0 or not DoesEntityExist(entity)) and GetGameTimer() < deadline do
        if routeToken ~= activeRouteToken then
            return false
        end

        Wait(10)
    end

    return entity and entity ~= 0 and DoesEntityExist(entity)
end

local function createCargoDriver(driverModel, spawnCoords, spawnHeading, routeToken)
    local driver = nil

    if CreatePedInsideVehicle then
        driver = CreatePedInsideVehicle(currentVehicle, driverModel, -1, true, true, false, false)

        if waitForEntity(driver, routeToken, 1000) then
            return driver
        end
    end

    driver = CreatePed(driverModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, true, false, false)

    if waitForEntity(driver, routeToken, Config.Timing.modelLoadTimeout) then
        return driver
    end

    return nil
end

RegisterNetEvent("cargo:client:startCargo")
AddEventHandler("cargo:client:startCargo", function(routeName, serverToken)
    local routeData = Config.routePoints[routeName]
    if not routeData then return end

    local points = routeData.locations
    if not points or #points < 2 then return end

    activeRouteToken = activeRouteToken + 1
    local routeToken = activeRouteToken
    activeServerToken = serverToken

    cleanupCargo()

    local spawnCoords = points[1].coords
    local spawnHeading = getHeadingToPoint(spawnCoords, points[2].coords)
    local vehicleModel = GetHashKey(Config.Models.vehicle)
    local driverModel = GetHashKey(Config.Models.driver)
    local crateModel = GetHashKey(Config.Models.crate)

    if not loadModel(vehicleModel) then
        failCargoSpawn(serverToken)
        return
    end

    if not loadModel(crateModel) then
        SetModelAsNoLongerNeeded(vehicleModel)
        failCargoSpawn(serverToken)
        return
    end

    currentVehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, true, false, false)
    while not DoesEntityExist(currentVehicle) do
        if routeToken ~= activeRouteToken then return end
        Wait(10)
    end

    Citizen.InvokeNative(0x77FF8D35EEC6BBC4, currentVehicle, 1, 0)
    SetEntityHeading(currentVehicle, spawnHeading)
    SetVehicleOnGroundProperly(currentVehicle)
    keepCargoEntityActive(currentVehicle)
    createCargoBlip()

    currentCrate = CreateObject(crateModel, spawnCoords.x, spawnCoords.y, spawnCoords.z + Config.Crate.spawnZOffset, true, true, false, false, false)
    while not DoesEntityExist(currentCrate) do
        if routeToken ~= activeRouteToken then return end
        Wait(10)
    end

    crateState = "wagon"
    keepCargoEntityActive(currentCrate)
    attachCrateToWagon()

    if not loadModel(driverModel) then
        SetModelAsNoLongerNeeded(vehicleModel)
        SetModelAsNoLongerNeeded(crateModel)
        failCargoSpawn(serverToken)
        return
    end

    currentDriver = createCargoDriver(driverModel, spawnCoords, spawnHeading, routeToken)

    if not currentDriver then
        SetModelAsNoLongerNeeded(vehicleModel)
        SetModelAsNoLongerNeeded(driverModel)
        SetModelAsNoLongerNeeded(crateModel)
        failCargoSpawn(serverToken)
        return
    end

    keepCargoEntityActive(currentDriver)

    local netIdVehicle = NetworkGetNetworkIdFromEntity(currentVehicle)
    local netIdDriver = NetworkGetNetworkIdFromEntity(currentDriver)
    local netIdCrate = NetworkGetNetworkIdFromEntity(currentCrate)
    currentVehicleNetId = netIdVehicle
    currentDriverNetId = netIdDriver
    currentCrateNetId = netIdCrate
    allowNetworkMigration(netIdVehicle)
    allowNetworkMigration(netIdDriver)
    allowNetworkMigration(netIdCrate)

    SetModelAsNoLongerNeeded(vehicleModel)
    SetModelAsNoLongerNeeded(driverModel)
    SetModelAsNoLongerNeeded(crateModel)

    setupCargoOwner()
    TriggerServerEvent("cargo:server:registerCargo", serverToken, netIdVehicle, netIdDriver, netIdCrate, routeName)
    startCrateInteractionThread()

    local drivingConfig = getRouteDrivingConfig(routeData)
    startRouteDriving(points, drivingConfig.startPointIndex, routeToken, drivingConfig)
end)

local function buildRouteOptions()
    local routes = {}

    for routeName, routeData in pairs(Config.routePoints or {}) do
        routes[#routes + 1] = {
            value = routeName,
            label = routeData.label or routeName
        }
    end

    table.sort(routes, function(a, b)
        return a.label < b.label
    end)

    return routes
end

local function buildMarketItems()
    local items = {}

    for _, item in ipairs(Config.MarketItems or {}) do
        if item.item then
            local image = item.image
            if image == nil then
                image = "item/" .. item.item .. ".png"
            elseif image == false then
                image = ""
            end

            items[#items + 1] = {
                item = item.item,
                label = item.label or item.item,
                image = image,
                defaultAmount = tonumber(item.defaultAmount or 1) or 1,
                maxAmount = tonumber(item.maxAmount or Config.UI.maxPerItem or 1) or 1
            }
        end
    end

    return items
end

local function closeCargoUi()
    if not isCargoUiOpen then
        return
    end

    isCargoUiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({type = "close"})
end

local function openCargoUi()
    if isCargoUiOpen then
        return
    end

    isCargoUiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "open",
        title = Config.UI.title,
        subtitle = Config.UI.subtitle,
        emptySelectionText = Config.UI.emptySelectionText,
        startButton = Config.UI.startButton,
        cancelButton = Config.UI.cancelButton,
        defaultRoute = Config.DefaultRoute,
        maxTotalItems = Config.UI.maxTotalItems,
        maxPerItem = Config.UI.maxPerItem,
        routes = buildRouteOptions(),
        items = buildMarketItems()
    })
end

RegisterNetEvent("cargo:client:openSetupUi")
AddEventHandler("cargo:client:openSetupUi", function()
    openCargoUi()
end)

RegisterCommand(Config.RouteRecordCommandName, function(_, args)
    local action = string.lower(args[1] or "")

    if action == "start" then
        local routeKey = args[2] or "new_route"
        local label = table.concat(args, " ", 3)
        startRouteRecorder(routeKey, label ~= "" and label or routeKey)
        return
    end

    if action == "stop" then
        if not routeRecorder.active then
            notifyRouteRecorder("No active route recording.")
            return
        end

        routeRecorder.active = false
        addRecordedRoutePoint(GetEntityCoords(PlayerPedId()))
        notifyRouteRecorder(("Stopped. Recorded %d points. Check the F8 console."):format(#routeRecorder.points))
        printRecordedRoute()
        return
    end

    if action == "clear" then
        routeRecorder.active = false
        routeRecorder.key = nil
        routeRecorder.label = nil
        routeRecorder.points = {}
        notifyRouteRecorder("Route recording cleared.")
        return
    end

    notifyRouteRecorder("Usage: /record_route start route_key Route Label | /record_route stop | /record_route clear")
end, false)

RegisterNUICallback("close", function(_, cb)
    closeCargoUi()
    cb({ok = true})
end)

RegisterNUICallback("startCargo", function(data, cb)
    local routeName = data and data.route or Config.DefaultRoute
    local selectedItems = data and data.items or {}

    closeCargoUi()
    TriggerServerEvent("cargo:server:startCargo", routeName, selectedItems)
    cb({ok = true})
end)

RegisterNetEvent("cargo:client:syncCargo")
AddEventHandler("cargo:client:syncCargo", function(netIdVehicle, netIdDriver, netIdCrate, routeName)
    if not NetworkDoesNetworkIdExist(netIdVehicle) or not NetworkDoesNetworkIdExist(netIdDriver) or not NetworkDoesNetworkIdExist(netIdCrate) then
        return
    end

    local vehicle = NetworkGetEntityFromNetworkId(netIdVehicle)
    local driver = NetworkGetEntityFromNetworkId(netIdDriver)
    local crate = NetworkGetEntityFromNetworkId(netIdCrate)

    if DoesEntityExist(vehicle) and DoesEntityExist(driver) and DoesEntityExist(crate) then
        currentVehicle = vehicle
        currentDriver = driver
        currentCrate = crate
        currentVehicleNetId = netIdVehicle
        currentDriverNetId = netIdDriver
        currentCrateNetId = netIdCrate
        crateState = "wagon"
        keepCargoEntityActive(currentVehicle)
        keepCargoEntityActive(currentDriver)
        keepCargoEntityActive(currentCrate)
        attachCrateToWagon()
        createCargoBlip()
        startCrateInteractionThread()
    end
end)

RegisterNetEvent("cargo:client:setCrateState")
AddEventHandler("cargo:client:setCrateState", function(netIdCrate, newState, carrier)
    if not NetworkDoesNetworkIdExist(netIdCrate) then
        return
    end

    currentCrate = NetworkGetEntityFromNetworkId(netIdCrate)
    if not currentCrate or not DoesEntityExist(currentCrate) then
        return
    end

    applyCrateState(newState, carrier)
    startCrateInteractionThread()
end)

RegisterNetEvent("cargo:client:cleanupCargo")
AddEventHandler("cargo:client:cleanupCargo", function(serverToken, netIds)
    if activeServerToken and serverToken and activeServerToken ~= serverToken then
        return
    end

    activeRouteToken = activeRouteToken + 1
    activeServerToken = nil
    cleanupCargo(netIds)
end)

AddEventHandler("onClientResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    activeRouteToken = activeRouteToken + 1
    cleanupCargo()
    closeCargoUi()
end)

startRouteDriving = function(points, startIndex, routeToken, drivingConfig)
    Citizen.CreateThread(function()
        local driving = drivingConfig or Config.Driving
        local taskRefreshInterval = driving.taskRefreshInterval or Config.Timing.routeTaskRefreshInterval or 5000

        for i = startIndex or 2, #points do
            if routeToken ~= activeRouteToken then
                return
            end

            local nextCoord = points[i].coords
            setupCargoOwner()

            TaskVehicleDriveToCoord(
                currentDriver,
                currentVehicle,
                nextCoord.x,
                nextCoord.y,
                nextCoord.z,
                driving.speed,
                1,
                GetHashKey(Config.Models.vehicle),
                driving.drivingStyle,
                driving.stoppingRange,
                driving.straightLineDistance
            )

            local arrivalCheck = false
            local lastTaskRefresh = GetGameTimer()
            while not arrivalCheck do
                Wait(driving.routeCheckInterval)

                if routeToken ~= activeRouteToken then
                    return
                end

                if currentVehicle and currentDriver and DoesEntityExist(currentVehicle) and DoesEntityExist(currentDriver) then
                    local currentCoords = GetEntityCoords(currentVehicle)
                    local distance = #(currentCoords - nextCoord)
                    local now = GetGameTimer()

                    if distance < driving.arrivalDistance then
                        arrivalCheck = true
                    end

                    if now - lastTaskRefresh >= taskRefreshInterval then
                        setupCargoOwner()
                        TaskVehicleDriveToCoord(
                            currentDriver,
                            currentVehicle,
                            nextCoord.x,
                            nextCoord.y,
                            nextCoord.z,
                            driving.speed,
                            1,
                            GetHashKey(Config.Models.vehicle),
                            driving.drivingStyle,
                            driving.stoppingRange,
                            driving.straightLineDistance
                        )
                        lastTaskRefresh = now
                    end
                else
                    return
                end
            end
        end

        Wait(Config.Timing.cleanupAfterRoute)

        cleanupCargo()
        TriggerServerEvent("cargo:server:cargoFinished", activeServerToken)
        activeServerToken = nil

    end)
end
