local ESX = nil

if Config and Config.ESXMode == 'old' then
    ESX = ESX or nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
else
    ESX = exports["es_extended"]:getSharedObject()
end

local playerRentalData = {}

local function GetVehiclePrice(model)
    for _, vehicle in ipairs(Config.Vehicles) do
        if vehicle.model == model then
            return vehicle.price
        end
    end
    return 0
end

local function IsAllowedModel(model)
    for _, vehicle in ipairs(Config.Vehicles) do
        if vehicle.model == model then
            return true
        end
    end
    return false
end

-- Fonction pour envoyer les webhooks Discord
function SendDiscordWebhook(title, description, color)
    if not Config.DiscordWebhook.enabled then
        return
    end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["footer"] = {
                ["text"] = Config.DiscordWebhook.footer .. " - " .. os.date("%d/%m/%Y %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(Config.DiscordWebhook.url, function(err, text, headers) end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
end

-- Vérifier si le joueur a assez d'argent
ESX.RegisterServerCallback('vehicleRental:checkMoney', function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getMoney() >= amount then
        cb(true)
    else
        cb(false)
    end
end)

-- Retirer l'argent du joueur et stocker le montant payé
RegisterNetEvent('vehicleRental:removeMoney')
AddEventHandler('vehicleRental:removeMoney', function(amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeMoney(amount)
    -- Stocker le montant payé
    playerRentalData[source] = (playerRentalData[source] or 0) + amount
end)

-- Rembourser le joueur
RegisterNetEvent('vehicleRental:refundMoney')
AddEventHandler('vehicleRental:refundMoney', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()
    
    MySQL.Async.fetchAll('SELECT model FROM rented_vehicles WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            local refundAmount = GetVehiclePrice(result[1].model)
            if refundAmount and refundAmount > 0 then
                xPlayer.addMoney(refundAmount)
                xPlayer.showNotification(string.format(Config.Notifications.refundReceived, refundAmount))
            end
        end
    end)

    local playerName = xPlayer.getName()
    local steamName = GetPlayerName(source)
    local coords = GetEntityCoords(GetPlayerPed(source))
    
    local steamHex
    for k,v in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, 5) == "steam" then
            steamHex = v
            break
        end
    end

    MySQL.Async.fetchAll('SELECT model, plate FROM rented_vehicles WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            local refundAmount = GetVehiclePrice(result[1].model)
            local description = string.format([[
**Joueur:** %s
**Steam:** %s
**Steam Hex:** %s
**Position:** %s, %s, %s
**Véhicule:** %s
**Plaque:** %s
**Remboursement:** $%s
            ]], playerName, steamName, steamHex,
            math.floor(coords.x), math.floor(coords.y), math.floor(coords.z),
            result[1].model, result[1].plate, refundAmount)

            SendDiscordWebhook("🔄 Véhicule rendu", description, Config.DiscordWebhook.colors.returned)
        end
    end)
end)

-- Modifier la fonction de sauvegarde pour ajouter l'historique
RegisterNetEvent('vehicleRental:saveRentedVehicle')
AddEventHandler('vehicleRental:saveRentedVehicle', function(vehicleData)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()
    local playerName = xPlayer.getName()
    local steamName = GetPlayerName(source)
    local coords = GetEntityCoords(GetPlayerPed(source))
    
    -- Récupérer le Steam Hex
    local steamHex
    for k,v in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, 5) == "steam" then
            steamHex = v
            break
        end
    end

    -- Webhook pour la location
    local price = GetVehiclePrice(vehicleData.model)
    local description = string.format([[
**Joueur:** %s
**Steam:** %s
**Steam Hex:** %s
**Position:** %s, %s, %s
**Véhicule:** %s
**Plaque:** %s
**Prix:** $%s
    ]], playerName, steamName, steamHex, 
    math.floor(coords.x), math.floor(coords.y), math.floor(coords.z),
    vehicleData.model, vehicleData.plate, price)

    SendDiscordWebhook("🚗 Nouveau véhicule loué", description, Config.DiscordWebhook.colors.rented)
    
    MySQL.Async.execute('INSERT INTO rented_vehicles (identifier, model, plate) VALUES (@identifier, @model, @plate)', {
        ['@identifier'] = identifier,
        ['@model'] = vehicleData.model,
        ['@plate'] = vehicleData.plate
    })
    
    MySQL.Async.execute('INSERT INTO rental_history (identifier) VALUES (@identifier)', {
        ['@identifier'] = identifier
    })
end)

ESX.RegisterServerCallback('vehicleRental:getRentedVehicle', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(nil)
        return
    end
    
    local identifier = xPlayer.getIdentifier()
    MySQL.Async.fetchAll('SELECT * FROM rented_vehicles WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end)

-- Fonction pour supprimer l'entrée du véhicule loué
RegisterNetEvent('vehicleRental:deleteRentedVehicle')
AddEventHandler('vehicleRental:deleteRentedVehicle', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()
    MySQL.Async.execute('DELETE FROM rented_vehicles WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })
    -- Supprimer le montant stocké
    playerRentalData[source] = nil
end)

-- Gérer la déconnexion du joueur pour nettoyer les données
AddEventHandler('playerDropped', function()
    local playerId = source
    if playerRentalData[playerId] then
        playerRentalData[playerId] = nil
    end
end)

-- Callback pour vérifier si le joueur peut louer
ESX.RegisterServerCallback('vehicleRental:canRentVehicle', function(source, cb)
    -- Nous retournons toujours true car la seule condition est de ne pas avoir de véhicule en location
    cb(true)
end)

-- Ajouter un nouvel événement pour la suppression
RegisterNetEvent('vehicleRental:deleteVehicle')
AddEventHandler('vehicleRental:deleteVehicle', function(price)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()
    local playerName = xPlayer.getName()
    local steamName = GetPlayerName(source)
    local coords = GetEntityCoords(GetPlayerPed(source))
    
    local steamHex
    for k,v in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, 5) == "steam" then
            steamHex = v
            break
        end
    end

    MySQL.Async.fetchAll('SELECT model, plate FROM rented_vehicles WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            local description = string.format([[
**Joueur:** %s
**Steam:** %s
**Steam Hex:** %s
**Position:** %s, %s, %s
**Véhicule:** %s
**Plaque:** %s
**Coût de suppression:** $%s
            ]], playerName, steamName, steamHex,
            math.floor(coords.x), math.floor(coords.y), math.floor(coords.z),
            result[1].model, result[1].plate, price)

            SendDiscordWebhook("❌ Véhicule supprimé", description, Config.DiscordWebhook.colors.deleted)
            
            -- Transférer l'argent au compte du gouvernement
            TriggerEvent('esx_addonaccount:getSharedAccount', Config.GovernmentAccount, function(account)
                if account then
                    account.addMoney(price)
                end
            end)
            
            MySQL.Async.execute('DELETE FROM rented_vehicles WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            })
        end
    end)
end)

RegisterNetEvent('vehicleRental:someEvent')
AddEventHandler('vehicleRental:someEvent', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return
    end
end)