QBCore.Functions.CreateCallback("soz-character:server:GetUserAccount", function(source, cb)
    local discord = QBCore.Functions.GetDiscordIdentifier(source)
    local status, result = pcall(function()
        return MySQL.single.await("SELECT a.* FROM soz_api.accounts a LEFT JOIN soz_api.account_identities ai ON a.id = ai.accountId WHERE ai.identityType = 'DISCORD' AND ai.identityId = ? LIMIT 1", {discord})
    end)

    if not status or not result then
        exports["soz-monitor"]:Log("ERROR", GetPlayerName(source) .. " error finding account for this user: " .. json.encode(result), {
            discord = discord,
            callback = "soz-character:server:GetUserAccount"
        })

        if not GetConvar("soz_allow_anonymous_login", "false") == "true" then
            DropPlayer(source, "no account found with this discord id")
        else
            cb(nil)
        end
    else
        cb(result)
    end
end)

QBCore.Functions.CreateCallback("soz-character:server:CreatePlayer", function(source, cb, charinfo, skin, clothConfig)
    local player = {charinfo = charinfo, skin = skin, cloth_config = clothConfig}

    if QBCore.Player.Login(source, false, player) then
        exports["soz-monitor"]:Log("INFO", GetPlayerName(source) .. " has succesfully loaded!")
        QBCore.Commands.Refresh(source)

        cb(true)
    else
        cb(false)
    end
end)

RegisterServerEvent("soz-character:server:SetGodmode")
AddEventHandler("soz-character:server:SetGodmode", function(source, val)
    local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.SetMetaData("godmode", val)
end)
