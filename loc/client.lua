local ESX = nil

if Config and Config.ESXMode == 'old' then
    ESX = ESX or nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
else
    ESX = exports["es_extended"]:getSharedObject()
end

local rentedVehicle = nil
local rentedPlate = nil
local rentedModel = nil
local rentedModelHash = nil

-- Table pour stocker les IDs des interactions lfInteract
local interactionIds = {}

-- Fonction pour supprimer un véhicule loué
local function deleteRentedVehicle(price)
    if rentedVehicle and DoesEntityExist(rentedVehicle) then
        if Config.lfPersistence then
            TriggerEvent('Persistance:removeVehicles', rentedVehicle)
        end
        NetworkFadeOutEntity(rentedVehicle, true, false)
        Citizen.Wait(500)
        DeleteVehicle(rentedVehicle)
        SetEntityAsNoLongerNeeded(rentedVehicle)
        if IsPedInVehicle(PlayerPedId(), rentedVehicle, false) then
            TaskLeaveVehicle(PlayerPedId(), rentedVehicle, 0)
        end
    end
    ESX.ShowNotification(string.format("~g~%s", string.format(Config.Notifications.vehicleDeleted, price)))
    rentedVehicle = nil
    rentedPlate = nil
    rentedModel = nil
    rentedModelHash = nil
    TriggerServerEvent('vehicleRental:deleteVehicle', price)
end

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    ESX.TriggerServerCallback('vehicleRental:getRentedVehicle', function(rentedVehicleData)
        if rentedVehicleData then
            rentedPlate = rentedVehicleData.plate
            rentedModel = rentedVehicleData.model
            rentedModelHash = GetHashKey(rentedModel)
        end
    end)
end)

Citizen.CreateThread(function()
    -- Charger les modèles de PNJ
    RequestModel(GetHashKey(Config.RentalPed.model))
    while not HasModelLoaded(GetHashKey(Config.RentalPed.model)) do
        Citizen.Wait(10)
    end

    RequestModel(GetHashKey(Config.DeletePed.model))
    while not HasModelLoaded(GetHashKey(Config.DeletePed.model)) do
        Citizen.Wait(10)
    end

    -- Créer le PNJ de location
    local ped = CreatePed(4, GetHashKey(Config.RentalPed.model), Config.RentalPed.coords.x, Config.RentalPed.coords.y, Config.RentalPed.coords.z - 1.0, Config.RentalPed.coords.w, false, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- Créer le PNJ de suppression
    local deletePed = CreatePed(4, GetHashKey(Config.DeletePed.model), Config.DeletePed.coords.x, Config.DeletePed.coords.y, Config.DeletePed.coords.z - 1.0, Config.DeletePed.coords.w, false, true)
    SetEntityInvincible(deletePed, true)
    FreezeEntityPosition(deletePed, true)
    SetBlockingOfNonTemporaryEvents(deletePed, true)

    -- Créer le PNJ de retour (point 2)
    local returnPed2 = CreatePed(4, GetHashKey(Config.ReturnPed2.model), Config.ReturnPed2.coords.x, Config.ReturnPed2.coords.y, Config.ReturnPed2.coords.z - 1.0, Config.ReturnPed2.coords.w, false, true)
    SetEntityInvincible(returnPed2, true)
    FreezeEntityPosition(returnPed2, true)
    SetBlockingOfNonTemporaryEvents(returnPed2, true)

    -- Créer le blip de location
    local blip = AddBlipForCoord(Config.RentalPed.coords.x, Config.RentalPed.coords.y, Config.RentalPed.coords.z)
    SetBlipSprite(blip, Config.RentalPed.blip.sprite)
    SetBlipDisplay(blip, Config.RentalPed.blip.display)
    SetBlipScale(blip, Config.RentalPed.blip.scale)
    SetBlipColour(blip, Config.RentalPed.blip.colour)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.RentalPed.blip.name)
    EndTextCommandSetBlipName(blip)

    -- Créer les blips de retour
    for i, returnPoint in ipairs(Config.ReturnPoints) do
        local returnBlip = AddBlipForCoord(returnPoint.coords.x, returnPoint.coords.y, returnPoint.coords.z)
        SetBlipSprite(returnBlip, returnPoint.blip.sprite)
        SetBlipDisplay(returnBlip, returnPoint.blip.display)
        SetBlipScale(returnBlip, returnPoint.blip.scale)
        SetBlipColour(returnBlip, returnPoint.blip.colour)
        SetBlipAsShortRange(returnBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(returnPoint.blip.name)
        EndTextCommandSetBlipName(returnBlip)
    end
end)

-- ============================================
-- INTÉGRATION lfInteract
-- ============================================
if Config.UseLfInteract then
    CreateThread(function()
        -- Attendre que lfInteract soit chargé (avec timeout de sécurité)
        local timeout = 0
        while not exports['lfInteract'] and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        
        -- Vérifier que lfInteract est bien disponible
        if not exports['lfInteract'] then
            print("^1[lfLocation] Erreur: lfInteract n'est pas disponible. Utilisation du système par défaut avec markers.^0")
            Config.UseLfInteract = false -- Désactiver pour utiliser le système par défaut
            return
        end
        
        -- Créer l'interaction pour le PNJ de location
        local rentalLabel = Config.HelpNotifications.openRental:gsub("~INPUT_CONTEXT~", ""):gsub("Appuyez sur", ""):gsub("pour voir les locations", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        if rentalLabel == "" then rentalLabel = "Ouvrir les locations" end
        local rentalId = exports['lfInteract']:AddInteraction({
            id = 'lflocation_rental',
            coords = vector3(Config.RentalPed.coords.x, Config.RentalPed.coords.y, Config.RentalPed.coords.z),
            distance = Config.InteractionDistance,
            interactDst = 2.0,
            options = {
                {
                    label = rentalLabel,
                    action = function()
                        ESX.TriggerServerCallback('vehicleRental:getRentedVehicle', function(rentedVehicleData)
                            if rentedVehicleData then
                                ESX.ShowNotification(Config.Notifications.alreadyRented)
                                SetNewWaypoint(Config.DeletePed.coords.x, Config.DeletePed.coords.y)
                            else
                                SetNuiFocus(true, true)
                                SendNUIMessage({ action = 'open' })
                            end
                        end)
                    end,
                }
            }
        })
        interactionIds['rental'] = rentalId
        
        -- Créer l'interaction pour le PNJ de suppression
        local deleteLabel = Config.HelpNotifications.deleteVehicle:gsub("~INPUT_CONTEXT~", ""):gsub("Appuyez sur", ""):gsub("pour supprimer le véhicule", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        if deleteLabel == "" then deleteLabel = "Supprimer le véhicule" end
        deleteLabel = string.format(deleteLabel, Config.DeletePrice)
        local deleteId = exports['lfInteract']:AddInteraction({
            id = 'lflocation_delete',
            coords = vector3(Config.DeletePed.coords.x, Config.DeletePed.coords.y, Config.DeletePed.coords.z),
            distance = Config.InteractionDistance,
            interactDst = 2.0,
            options = {
                {
                    label = deleteLabel,
                    action = function()
                        ESX.TriggerServerCallback('vehicleRental:getRentedVehicle', function(rentedVehicleData)
                            if rentedVehicleData then
                                ESX.TriggerServerCallback('vehicleRental:checkMoney', function(hasEnoughMoney)
                                    if hasEnoughMoney then
                                        TriggerServerEvent('vehicleRental:removeMoney', Config.DeletePrice)
                                        deleteRentedVehicle(Config.DeletePrice)
                                    else
                                        ESX.ShowNotification("~r~" .. Config.Notifications.notEnoughMoney)
                                    end
                                end, Config.DeletePrice)
                            else
                                ESX.ShowNotification("~o~" .. Config.Notifications.noVehicleToDelete)
                            end
                        end)
                    end,
                }
            }
        })
        interactionIds['delete'] = deleteId
        
        -- Créer l'interaction pour le PNJ de retour (point 2)
        local returnPed2Id = exports['lfInteract']:AddInteraction({
            id = 'lflocation_return_ped2',
            coords = vector3(Config.ReturnPed2.coords.x, Config.ReturnPed2.coords.y, Config.ReturnPed2.coords.z),
            distance = Config.InteractionDistance,
            interactDst = 2.0,
            options = {
                {
                    label = deleteLabel,
                    action = function()
                        ESX.TriggerServerCallback('vehicleRental:getRentedVehicle', function(rentedVehicleData)
                            if rentedVehicleData then
                                ESX.TriggerServerCallback('vehicleRental:checkMoney', function(hasEnoughMoney)
                                    if hasEnoughMoney then
                                        TriggerServerEvent('vehicleRental:removeMoney', Config.DeletePrice)
                                        deleteRentedVehicle(Config.DeletePrice)
                                    else
                                        ESX.ShowNotification("~r~" .. Config.Notifications.notEnoughMoney)
                                    end
                                end, Config.DeletePrice)
                            else
                                ESX.ShowNotification("~o~" .. Config.Notifications.noVehicleToDelete)
                            end
                        end)
                    end,
                }
            }
        })
        interactionIds['return_ped2'] = returnPed2Id
        
        -- Créer les interactions pour les points de retour
        -- Ces interactions vérifient dynamiquement si le joueur est dans un véhicule loué
        local returnLabel = Config.HelpNotifications.returnVehicle:gsub("~INPUT_CONTEXT~", ""):gsub("Appuyez sur", ""):gsub("pour rendre le véhicule", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        if returnLabel == "" then returnLabel = "Rendre le véhicule" end
        for i, returnPoint in ipairs(Config.ReturnPoints) do
            local returnId = exports['lfInteract']:AddInteraction({
                id = 'lflocation_return_' .. i,
                coords = returnPoint.coords,
                distance = Config.InteractionDistance,
                interactDst = 2.0,
                options = {
                    {
                        label = returnLabel,
                        action = function()
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if not vehicle or vehicle == 0 then
                                ESX.ShowNotification("~o~" .. Config.Notifications.noVehicleToReturn)
                                return
                            end
                            
                            -- Vérifier si c'est un modèle valide
                            local vehicleModel = GetEntityModel(vehicle)
                            local isValidModel = false
                            for _, vehicleConfig in ipairs(Config.Vehicles) do
                                if vehicleModel == GetHashKey(vehicleConfig.model) then
                                    isValidModel = true
                                    break
                                end
                            end
                            
                            if not isValidModel then
                                ESX.ShowNotification("~r~" .. Config.Notifications.notRentedVehicle)
                                return
                            end
                            
                            local vehiclePlateForCallback = GetVehicleNumberPlateText(vehicle)
                            local cleanVehiclePlateForCallback = string.gsub(vehiclePlateForCallback, "%s+", "")
                            
                            ESX.TriggerServerCallback('vehicleRental:getRentedVehicle', function(rentedVehicleData)
                                if rentedVehicleData then
                                    local cleanRentedPlate = string.gsub(rentedVehicleData.plate, "%s+", "")
                                    if cleanVehiclePlateForCallback == cleanRentedPlate then
                                        if Config.lfPersistence then
                                            TriggerEvent('Persistance:removeVehicles', vehicle)
                                        end
                                        NetworkFadeOutEntity(vehicle, true, false)
                                        Citizen.Wait(500)
                                        DeleteVehicle(vehicle)
                                        SetEntityAsNoLongerNeeded(vehicle)
                                        
                                        ESX.ShowNotification("~g~" .. Config.Notifications.vehicleReturned)
                                        rentedVehicle = nil
                                        rentedPlate = nil
                                        rentedModel = nil
                                        rentedModelHash = nil
                                        TriggerServerEvent('vehicleRental:deleteRentedVehicle')
                                        TriggerServerEvent('vehicleRental:refundMoney')
                                    else
                                        ESX.ShowNotification("~r~" .. Config.Notifications.notRentedVehicle)
                                    end
                                else
                                    ESX.ShowNotification("~o~" .. Config.Notifications.noVehicleToReturn)
                                end
                            end)
                        end,
                    }
                }
            })
            interactionIds['return_' .. i] = returnId
        end
    end)
    
    -- Nettoyage à l'arrêt de la ressource
    AddEventHandler('onResourceStop', function(resourceName)
        if GetCurrentResourceName() == resourceName then
            -- Supprimer toutes les interactions enregistrées
            if exports['lfInteract'] then
                for _, interactionId in pairs(interactionIds) do
                    if interactionId then
                        exports['lfInteract']:RemoveInteraction(interactionId)
                    end
                end
            end
        end
    end)
end

-- Boucle principale pour les interactions avec les PNJ (uniquement si lfInteract n'est pas utilisé)
if not Config.UseLfInteract then
    Citizen.CreateThread(function()
        while true do
            local sleep = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())

            local distanceToPed = #(playerCoords - vector3(Config.RentalPed.coords.x, Config.RentalPed.coords.y, Config.RentalPed.coords.z))
            local distanceToDeletePed = #(playerCoords - vector3(Config.DeletePed.coords.x, Config.DeletePed.coords.y, Config.DeletePed.coords.z))
            local distanceToReturnPed2 = #(playerCoords - vector3(Config.ReturnPed2.coords.x, Config.ReturnPed2.coords.y, Config.ReturnPed2.coords.z))
            
            if distanceToPed < Config.DrawDistance or distanceToDeletePed < Config.DrawDistance or distanceToReturnPed2 < Config.DrawDistance then
                sleep = 0
                if distanceToPed < Config.InteractionDistance then
                    ShowHelpNotification(Config.HelpNotifications.openRental)
                    if IsControlJustPressed(1, 51) then
                        ESX.TriggerServerCallback('vehicleRental:getRentedVehicle', function(rentedVehicleData)
                            if rentedVehicleData then
                                ESX.ShowNotification(Config.Notifications.alreadyRented)
                                SetNewWaypoint(Config.DeletePed.coords.x, Config.DeletePed.coords.y)
                            else
                                SetNuiFocus(true, true)
                                SendNUIMessage({ action = 'open' })
                            end
                        end)
                    end
                end
                if distanceToDeletePed < Config.InteractionDistance then
                    ShowHelpNotification(string.format(Config.HelpNotifications.deleteVehicle, Config.DeletePrice))
                    if IsControlJustPressed(1, 51) then
                        ESX.TriggerServerCallback('vehicleRental:getRentedVehicle', function(rentedVehicleData)
                            if rentedVehicleData then
                                ESX.TriggerServerCallback('vehicleRental:checkMoney', function(hasEnoughMoney)
                                    if hasEnoughMoney then
                                        TriggerServerEvent('vehicleRental:removeMoney', Config.DeletePrice)
                                        deleteRentedVehicle(Config.DeletePrice)
                                    else
                                        ESX.ShowNotification("~r~" .. Config.Notifications.notEnoughMoney)
                                    end
                                end, Config.DeletePrice)
                            else
                                ESX.ShowNotification("~o~" .. Config.Notifications.noVehicleToDelete)
                            end
                        end)
                    end
                end
                if distanceToReturnPed2 < Config.InteractionDistance then
                    ShowHelpNotification(string.format(Config.HelpNotifications.deleteVehicle, Config.DeletePrice))
                    if IsControlJustPressed(1, 51) then
                        ESX.TriggerServerCallback('vehicleRental:getRentedVehicle', function(rentedVehicleData)
                            if rentedVehicleData then
                                ESX.TriggerServerCallback('vehicleRental:checkMoney', function(hasEnoughMoney)
                                    if hasEnoughMoney then
                                        TriggerServerEvent('vehicleRental:removeMoney', Config.DeletePrice)
                                        deleteRentedVehicle(Config.DeletePrice)
                                    else
                                        ESX.ShowNotification("~r~" .. Config.Notifications.notEnoughMoney)
                                    end
                                end, Config.DeletePrice)
                            else
                                ESX.ShowNotification("~o~" .. Config.Notifications.noVehicleToDelete)
                            end
                        end)
                    end
                end
            end
            
            Citizen.Wait(sleep)
        end
    end)
end

function ShowHelpNotification(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

RegisterNUICallback('rentVehicle', function(data, cb)
    local model = data.model
    local price = tonumber(data.price)

    if not (model and price) then
        cb('ok')
        return
    end

    ESX.TriggerServerCallback('vehicleRental:getRentedVehicle', function(rentedVehicleData)
        if rentedVehicleData then
            ESX.ShowNotification(Config.Notifications.alreadyRented)
            SetNewWaypoint(Config.DeletePed.coords.x, Config.DeletePed.coords.y)
        else
            local spawnCoord = getAvailableSpawnLocation()
            if spawnCoord then
                ESX.TriggerServerCallback('vehicleRental:checkMoney', function(hasEnoughMoney)
                    if hasEnoughMoney then
                        TriggerServerEvent('vehicleRental:removeMoney', price)
                        local plate = Config.PlatePrefix .. tostring(math.random(Config.PlateMin, Config.PlateMax))
                        spawnRentedVehicle(model, plate, spawnCoord)
                        ESX.ShowNotification(string.format(Config.Notifications.vehicleRented, model, price))
                        TriggerServerEvent('vehicleRental:saveRentedVehicle', { model = model, plate = plate })
                        rentedModel = model
                        rentedPlate = plate
                        rentedModelHash = GetHashKey(model)
                    else
                        ESX.ShowNotification("~r~" .. Config.Notifications.notEnoughMoney)
                    end
                end, price)
            else
                ESX.ShowNotification("~r~" .. Config.Notifications.noSpawnAvailable)
            end
        end
    end)
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb('ok')
end)

function getAvailableSpawnLocation()
    for _, location in ipairs(Config.SpawnLocations) do
        if IsSpawnPointClear(vector3(location.x, location.y, location.z), Config.SpawnRadius) then
            return location
        end
    end
    return nil
end

function IsSpawnPointClear(coords, radius)
    local vehicles = ESX.Game.GetVehiclesInArea(coords, radius)
    return #vehicles == 0
end

function spawnRentedVehicle(model, plate, spawnCoord)
    local vehicleModel = GetHashKey(model)
    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Citizen.Wait(10)
    end

    local vehicle = CreateVehicle(vehicleModel, spawnCoord.x, spawnCoord.y, spawnCoord.z, spawnCoord.h, true, false)
    SetVehicleNumberPlateText(vehicle, plate)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetVehicleEngineOn(vehicle, true, true, false)
    rentedVehicle = vehicle
    rentedPlate = plate
    rentedModel = model
    rentedModelHash = vehicleModel -- Stockage du hash du modèle
    SetEntityAsMissionEntity(vehicle, true, true)
    if Config.lfPersistence then
        TriggerEvent('Persistance:addVehicles', vehicle)
    end
    ESX.ShowNotification(string.format("~g~%s", string.format(Config.Notifications.vehicleReady, model, plate)))
end

-- Boucle principale pour les points de retour (uniquement si lfInteract n'est pas utilisé)
if not Config.UseLfInteract then
    Citizen.CreateThread(function()
        while true do
            local sleep = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distanceToReturn = #(playerCoords - Config.ReturnPoints[1].coords)
            local distanceToReturn2 = #(playerCoords - Config.ReturnPoints[2].coords)
            local isInRentedVehicle = false
            local isValidModel = false
            
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle and vehicle ~= 0 then
                local vehicleModel = GetEntityModel(vehicle)
                for _, vehicleConfig in ipairs(Config.Vehicles) do
                    if vehicleModel == GetHashKey(vehicleConfig.model) then
                        isValidModel = true
                        break
                    end
                end
                
                -- Vérifier si c'est un véhicule loué en comparant la plaque
                local vehiclePlate = GetVehicleNumberPlateText(vehicle)
                local cleanVehiclePlate = string.gsub(vehiclePlate, "%s+", "")
                
                -- Si nous avons déjà les informations du véhicule loué en local
                if rentedPlate then
                    local cleanRentedPlate = string.gsub(rentedPlate, "%s+", "")
                    if cleanVehiclePlate == cleanRentedPlate then
                        isInRentedVehicle = true
                    end
                end
            end
            
            -- Si le joueur est proche du point de retour, dans le véhicule loué et que c'est un modèle valide
            if (distanceToReturn < Config.DrawDistance or distanceToReturn2 < Config.DrawDistance) and isInRentedVehicle and isValidModel then
                sleep = 0
                
                -- Dessiner les marqueurs pour les points de retour
                if Config.Markers.enabled then
                    if distanceToReturn < Config.DrawDistance then
                        DrawMarker(
                            Config.Markers.type,
                            Config.ReturnPoints[1].coords.x,
                            Config.ReturnPoints[1].coords.y,
                            Config.ReturnPoints[1].coords.z - 1.0,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            Config.Markers.size.x,
                            Config.Markers.size.y,
                            Config.Markers.size.z,
                            Config.Markers.color.r,
                            Config.Markers.color.g,
                            Config.Markers.color.b,
                            Config.Markers.color.a,
                            Config.Markers.bobUpAndDown,
                            Config.Markers.faceCamera,
                            2,
                            Config.Markers.rotate,
                            nil, nil, false
                        )
                    end
                    
                    if distanceToReturn2 < Config.DrawDistance then
                        DrawMarker(
                            Config.Markers.type,
                            Config.ReturnPoints[2].coords.x,
                            Config.ReturnPoints[2].coords.y,
                            Config.ReturnPoints[2].coords.z - 1.0,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            Config.Markers.size.x,
                            Config.Markers.size.y,
                            Config.Markers.size.z,
                            Config.Markers.color.r,
                            Config.Markers.color.g,
                            Config.Markers.color.b,
                            Config.Markers.color.a,
                            Config.Markers.bobUpAndDown,
                            Config.Markers.faceCamera,
                            2,
                            Config.Markers.rotate,
                            nil, nil, false
                        )
                    end
                end
                
                -- Fonction pour retourner un véhicule
                local function returnVehicle()
                    local vehiclePlateForCallback = GetVehicleNumberPlateText(vehicle)
                    local cleanVehiclePlateForCallback = string.gsub(vehiclePlateForCallback, "%s+", "")
                    
                    ESX.TriggerServerCallback('vehicleRental:getRentedVehicle', function(rentedVehicleData)
                        if rentedVehicleData then
                            local cleanRentedPlate = string.gsub(rentedVehicleData.plate, "%s+", "")
                            if cleanVehiclePlateForCallback == cleanRentedPlate then
                                if Config.lfPersistence then
                                    TriggerEvent('Persistance:removeVehicles', vehicle)
                                end
                                NetworkFadeOutEntity(vehicle, true, false)
                                Citizen.Wait(500)
                                DeleteVehicle(vehicle)
                                SetEntityAsNoLongerNeeded(vehicle)
                                
                                ESX.ShowNotification("~g~" .. Config.Notifications.vehicleReturned)
                                rentedVehicle = nil
                                rentedPlate = nil
                                rentedModel = nil
                                rentedModelHash = nil
                                TriggerServerEvent('vehicleRental:deleteRentedVehicle')
                                TriggerServerEvent('vehicleRental:refundMoney')
                            else
                                ESX.ShowNotification("~r~" .. Config.Notifications.notRentedVehicle)
                            end
                        else
                            ESX.ShowNotification("~o~" .. Config.Notifications.noVehicleToReturn)
                        end
                    end)
                end
                
                if distanceToReturn < Config.InteractionDistance then
                    ShowHelpNotification(Config.HelpNotifications.returnVehicle)
                    if IsControlJustPressed(1, 51) then
                        returnVehicle()
                    end
                end
                
                if distanceToReturn2 < Config.InteractionDistance then
                    ShowHelpNotification(Config.HelpNotifications.returnVehicle)
                    if IsControlJustPressed(1, 51) then
                        returnVehicle()
                    end
                end
            end

            Citizen.Wait(sleep)
        end
    end)
end

RegisterNetEvent('vehicleRental:forceReturnVehicle')
AddEventHandler('vehicleRental:forceReturnVehicle', function()
    if rentedPlate and rentedModelHash then
        if rentedVehicle and DoesEntityExist(rentedVehicle) then
            if Config.lfPersistence then
                TriggerEvent('Persistance:removeVehicles', rentedVehicle)
            end
            NetworkFadeOutEntity(rentedVehicle, true, false)
            Citizen.Wait(500)
            DeleteVehicle(rentedVehicle)
            SetEntityAsNoLongerNeeded(rentedVehicle)
            
            if IsPedInVehicle(PlayerPedId(), rentedVehicle, false) then
                TaskLeaveVehicle(PlayerPedId(), rentedVehicle, 0)
            end
        end
        rentedVehicle = nil
        rentedPlate = nil
        rentedModel = nil
        rentedModelHash = nil
        ESX.ShowNotification("~o~" .. Config.Notifications.vehicleRecovered)
        TriggerServerEvent('vehicleRental:deleteRentedVehicle')
    end
end)