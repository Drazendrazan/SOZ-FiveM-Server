local itemToRefill = 11 -- give 11 item for 24 second

--- Events
RegisterNetEvent("jobs:server:fueler:refillTanker", function(tankerId)
    local Player = QBCore.Functions.GetPlayer(source)
    local tanker = NetworkGetEntityFromNetworkId(tankerId)
    local tankerPlate = GetVehicleNumberPlateText(tanker)

    exports["soz-inventory"]:AddItem("trunk_" .. tankerPlate, "petroleum", itemToRefill, nil, nil, function(success, _)
        if success then
            TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, ("Vous avez ~g~remplis~s~ %dL de pétrole"):format(itemToRefill))

            TriggerEvent("monitor:server:event", "job_mtp_fill_oil_tanker", {player_source = Player.PlayerData.source},
                         {
                quantity = tonumber(itemToRefill),
                position = GetEntityCoords(GetPlayerPed(Player.PlayerData.source)),
            })
        else
            TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Votre remorque ~r~ne peut plus~s~ recevoir de pétrole.", "error")
        end
    end)
end)

RegisterNetEvent("jobs:server:fueler:refiningTanker", function(tankerId)
    local Player = QBCore.Functions.GetPlayer(source)
    local tanker = NetworkGetEntityFromNetworkId(tankerId)
    local tankerPlate = GetVehicleNumberPlateText(tanker)
    local tankerInv = "trunk_" .. tankerPlate

    if exports["soz-inventory"]:RemoveItem(tankerInv, "petroleum", itemToRefill) then
        local refinedSuccess = false

        exports["soz-inventory"]:AddItem(tankerInv, "petroleum_refined", 3 * itemToRefill, nil, nil, function(success, _)
            refinedSuccess = refinedSuccess or success
        end)
        exports["soz-inventory"]:AddItem(tankerInv, "petroleum_residue", itemToRefill, nil, nil, function(success, _)
            refinedSuccess = refinedSuccess or success
        end)

        if refinedSuccess then
            TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, ("Vous avez ~g~raffiné~s~ %dL de pétrole"):format(itemToRefill))

            TriggerEvent("monitor:server:event", "job_mtp_refining_oil", {player_source = Player.PlayerData.source},
                         {
                quantity = tonumber(itemToRefill),
                position = GetEntityCoords(GetPlayerPed(Player.PlayerData.source)),
            })
        else
            TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Votre remorque ~r~ne peut plus~s~ recevoir de pétrole raffiné.",
                               "error")
        end
    end
end)

RegisterNetEvent("jobs:server:fueler:craftEssence", function()
    local Player = QBCore.Functions.GetPlayer(source)
    local essenceItemAmount = exports["soz-inventory"]:GetItem(Player.PlayerData.source, "petroleum_refined", nil, true)

    if exports["soz-inventory"]:CanSwapItem(Player.PlayerData.source, "petroleum_refined", essenceItemAmount, "essence", essenceItemAmount) then
        if exports["soz-inventory"]:RemoveItem(Player.PlayerData.source, "petroleum_refined", essenceItemAmount) then
            exports["soz-inventory"]:AddItem(Player.PlayerData.source, "essence", essenceItemAmount, nil, nil, function(success, _)
                if success then
                    TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source,
                                       ("Vous avez ~g~transformé~s~ %dL en carburant"):format(essenceItemAmount))

                    TriggerEvent("monitor:server:event", "job_mtp_create_gasoline", {
                        player_source = Player.PlayerData.source,
                    }, {quantity = 1, position = GetEntityCoords(GetPlayerPed(Player.PlayerData.source))})
                else
                    TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Votre ne pouvez pas ~r~récupérer~s~ le carburant.", "error")
                end
            end)
        end
    else
        TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Votre ne pouvez pas ~r~transformer~s~ autant d'essence.", "error")
    end
end)

RegisterNetEvent("jobs:server:fueler:craftEssenceJerryCan", function()
    local Player = QBCore.Functions.GetPlayer(source)
    local essenceItemAmount = math.floor(exports["soz-inventory"]:GetItem(Player.PlayerData.source, "essence", nil, true) / 3)

    if exports["soz-inventory"]:CanSwapItem(Player.PlayerData.source, "essence", essenceItemAmount * 3, "essence_jerrycan", essenceItemAmount) then
        if exports["soz-inventory"]:RemoveItem(Player.PlayerData.source, "essence", essenceItemAmount * 3) then
            exports["soz-inventory"]:AddItem(Player.PlayerData.source, "essence_jerrycan", essenceItemAmount, nil, nil, function(success, _)
                if success then
                    TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source,
                                       ("Vous avez ~g~transformé~s~ %dL en JerryCan"):format(essenceItemAmount))
                    TriggerEvent("monitor:server:event", "job_mtp_create_jerrycan", {
                        player_source = Player.PlayerData.source,
                    }, {
                        quantity = essenceItemAmount,
                        position = GetEntityCoords(GetPlayerPed(Player.PlayerData.source)),
                    })
                else
                    TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Votre ne pouvez pas ~r~récupérer~s~ le JerryCan.", "error")
                end
            end)
        end
    else
        TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Votre ne pouvez pas ~r~transformer~s~ autant d'essence.", "error")
    end
end)

RegisterNetEvent("jobs:server:fueler:refillStation", function(tankerId, station, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    local tanker = NetworkGetEntityFromNetworkId(tankerId)
    local tankerPlate = GetVehicleNumberPlateText(tanker)
    local tankerInv = "trunk_" .. tankerPlate

    TriggerEvent("soz-fuel:server:getStationStock", function(stock)
        local itemToUse = math.ceil(amount / 10)

        if stock + amount <= 2000 then
            if exports["soz-inventory"]:RemoveItem(tankerInv, "essence", itemToUse) then
                TriggerEvent("banking:server:TransferMoney", "farm_mtp", "safe_oil", amount * FuelerConfig.SellPrice)
                TriggerEvent("soz-fuel:server:addStationStock", station, amount)
                TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source,
                                   ("Vous avez ~g~ajouté~s~ %dL d'essence dans la station"):format(itemToUse * 10))

                TriggerEvent("monitor:server:event", "job_mtp_refill_station", {
                    player_source = Player.PlayerData.source,
                    station = station,
                }, {quantity = amount, position = GetEntityCoords(etPlayerPed(Player.PlayerData.source))})
            else
                TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Le tanker n'a plus ~r~assez~s~ de stock.", "error")
            end
        else
            TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "La station n'a pas ~r~assez~s~ de stockage.", "error")
        end

    end, station)
end)

RegisterNetEvent("jobs:server:fueler:resellTanker", function(tankerId)
    local Player = QBCore.Functions.GetPlayer(source)
    local tanker = NetworkGetEntityFromNetworkId(tankerId)
    local tankerPlate = GetVehicleNumberPlateText(tanker)
    local tankerInv = "trunk_" .. tankerPlate

    if exports["soz-inventory"]:RemoveItem(tankerInv, "essence", 10) then
        TriggerEvent("banking:server:TransferMoney", "farm_mtp", "safe_oil", 10 * FuelerConfig.SellPrice)
        TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Vous avez ~g~revendu~s~ 10L d'essence")
        TriggerEvent("monitor:server:event", "job_mtp_sell_oil", {player_source = Player.PlayerData.source},
                     {quantity = 10, position = GetEntityCoords(etPlayerPed(Player.PlayerData.source))})
    else
        TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Le tanker n'a plus ~r~assez~s~ de stock.", "error")
    end
end)

QBCore.Functions.CreateCallback("jobs:server:fueler:ensureInventory", function(source, cb, tankerId, model, class)
    local tanker = NetworkGetEntityFromNetworkId(tankerId)
    local tankerPlate = GetVehicleNumberPlateText(tanker)
    local inventory = exports["soz-inventory"]:GetOrCreateInventory("tanker", tankerPlate, {
        model = model,
        class = class,
    })

    if inventory ~= nil then
        cb(true)
    else
        cb(false)
    end
end)

--- Callback
QBCore.Functions.CreateCallback("jobs:server:fueler:canRefill", function(source, cb, tankerId)
    local tanker = NetworkGetEntityFromNetworkId(tankerId)
    local tankerPlate = GetVehicleNumberPlateText(tanker)

    cb(exports["soz-inventory"]:CanCarryItem("trunk_" .. tankerPlate, "petroleum", itemToRefill))
end)

QBCore.Functions.CreateCallback("jobs:server:fueler:canRefining", function(source, cb, tankerId)
    local tanker = NetworkGetEntityFromNetworkId(tankerId)
    local tankerPlate = GetVehicleNumberPlateText(tanker)

    local srcItem, srcItemAmount = "petroleum", 1
    local dstItem, dstItemAmount = "petroleum_refined", 3

    cb(exports["soz-inventory"]:CanSwapItem("trunk_" .. tankerPlate, srcItem, srcItemAmount, dstItem, dstItemAmount))
end)

QBCore.Functions.CreateCallback("jobs:server:fueler:canStationRefill", function(source, cb, tankerId, amount)
    local tanker = NetworkGetEntityFromNetworkId(tankerId)
    local tankerPlate = GetVehicleNumberPlateText(tanker)
    local itemToUse = math.ceil(amount / 10)

    cb(exports["soz-inventory"]:GetItem("trunk_" .. tankerPlate, "essence", nil, true) >= itemToUse)
end)

QBCore.Functions.CreateCallback("jobs:server:fueler:canResell", function(source, cb, tankerId)
    local tanker = NetworkGetEntityFromNetworkId(tankerId)
    local tankerPlate = GetVehicleNumberPlateText(tanker)

    cb(exports["soz-inventory"]:GetItem("trunk_" .. tankerPlate, "essence", nil, true) >= 10)
end)
