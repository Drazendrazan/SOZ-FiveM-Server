local auctions = {}

CreateThread(function()
    local result = MySQL.Sync.fetchAll("SELECT * FROM vehicles WHERE category IN (?) AND price > 0 ORDER BY RAND () LIMIT ?",
                                       {LuxuryDealershipConfig.AllowedCategories, #LuxuryDealershipConfig.Spawns})
    for i, vehicle in ipairs(result) do
        local spawn = LuxuryDealershipConfig.Spawns[i]
        auctions[vehicle.model] = {
            model = vehicle.model,
            hash = vehicle.hash,
            name = vehicle.name,
            pos = spawn.vehicle,
            window = spawn.window,
            minimumBidPrice = vehicle.price,
            bestBidCitizenId = nil,
            bestBidAccount = nil,
            bestBidName = nil,
            bestBidPrice = nil,
            required_licence = vehicle.required_licence,
        }
        auctions[vehicle.model].window.options.name = "luxury_" .. vehicle.model
    end
end)

QBCore.Functions.CreateCallback("soz-dealership:server:GetAuctions", function(source, cb)
    cb(auctions)
end)

QBCore.Functions.CreateCallback("soz-dealership:server:GetAuction", function(source, cb, model)
    cb(auctions[model])
end)

QBCore.Functions.CreateCallback("soz-dealership:server:BidAuction", function(source, cb, vehicleModel, price)
    price = math.floor(price)
    local auction = auctions[vehicleModel]
    if auction == nil then
        cb(false, "Ce véhicule n'est pas proposé à la mise aux enchères.")
        return
    end
    if price <= (auction.bestBidPrice or (auction.minimumBidPrice - 1)) then
        cb(false, "Le montant doit être supérieur à " .. (auction.bestBidPrice or auction.minimumBidPrice))
        return
    end

    local player = QBCore.Functions.GetPlayer(source)
    TriggerEvent("banking:server:TransferMoney", player.PlayerData.charinfo.account, LuxuryDealershipConfig.BankAccount, price, function(success, reason)
        if success then
            if auction.bestBidCitizenId ~= nil then
                TriggerEvent("banking:server:TransferMoney", LuxuryDealershipConfig.BankAccount, auction.bestBidBankAccount, auction.bestBidPrice,
                             function(successRefund, reasonRefund)
                    if not successRefund then
                        exports["soz-monitor"]:Log("WARN", "Could not transfer from the bank to the player " .. auction.bestBidCitizenId ": " .. reasonRefund)
                        cb(false, "Erreur avec la banque. Merci de contacter un responsable.")
                    end
                end)
            end
            auction.bestBidCitizenId = player.PlayerData.citizenid
            auction.bestBidBankAccount = player.PlayerData.charinfo.account
            auction.bestBidName = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
            auction.bestBidPrice = price
            cb(true, nil)
        else
            cb(false, "Vous n'avez pas assez d'argent sur votre compte.")
        end
    end)
end)

exports("finishAuctions", function()
    for _, auction in pairs(auctions) do
        if auction.bestBidCitizenId ~= nil then
            local PlayerData = exports.oxmysql:singleSync("SELECT * FROM player where citizenid = ?", {
                auction.bestBidCitizenId,
            })
            exports.oxmysql:insertSync(
                "INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, `condition`, plate, garage, category, state, life_counter, boughttime, parkingtime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {
                    PlayerData.license,
                    auction.bestBidCitizenId,
                    auction.model,
                    auction.hash,
                    "{}",
                    "{}",
                    GeneratePlate(),
                    "airportpublic",
                    "car",
                    1,
                    3,
                    os.time(),
                    os.time(),
                })
            exports["soz-monitor"]:Log("INFO", "[soz-vehicle] Le joueur " .. auction.bestBidName .. " a remporté une " .. auction.model .. " pour $" ..
                                           QBCore.Shared.GroupDigits(auction.bestBidPrice))
        end
    end
end)