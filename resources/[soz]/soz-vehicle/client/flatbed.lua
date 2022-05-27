local LastVehicle = nil

local function GetVehicleInfo(VehicleHash)
    for Index, CurrentFlatbed in pairs(Config.Flatbeds) do
        if VehicleHash == GetHashKey(CurrentFlatbed.Hash) then
            return CurrentFlatbed
        end
    end
end
local function GetOwnership(vehicle)
    while not NetworkHasControlOfEntity(vehicle) do
        NetworkRequestControlOfEntity(vehicle)
        Citizen.Wait(0)
    end
end

local function GetVehicles()
    local AllVehicles = {}
    local CurrentHandle, CurrentVehicle = FindFirstVehicle()
    local IsNext = true

    repeat
        table.insert(AllVehicles, CurrentVehicle)
        IsNext, CurrentVehicle = FindNextVehicle()
    until not IsNext

    EndFindVehicle(CurrentHandle)

    return AllVehicles
end

local function IsAllowed(Vehicle)
    local VehicleClass = GetVehicleClass(Vehicle)

    for Index, CurrentClass in pairs(Config.Blacklist) do
        if VehicleClass == CurrentClass then
            return false
        end
    end

    return true
end

local function GetNearestVehicle(CheckCoords, CheckRadius)
    local ClosestVehicle = nil
    local ClosestDistance = math.huge

    for Index, CurrentVehicle in pairs(GetVehicles()) do
        if DoesEntityExist(CurrentVehicle) and IsAllowed(CurrentVehicle) then
            local CurrentCoords = GetEntityCoords(CurrentVehicle)
            local CurrentDistance = Vdist2(CheckCoords, CurrentCoords, false)

            if CurrentDistance < CheckRadius and CurrentDistance < ClosestDistance then
                ClosestVehicle = CurrentVehicle
                ClosestDistance = CurrentDistance
            end
        end
    end

    return ClosestVehicle
end

RegisterNetEvent("soz-flatbed:client:getProp")
AddEventHandler("soz-flatbed:client:getProp", function(lastveh)
    if not DoesEntityExist(Entity(lastveh).state.prop) then
        if IsVehicleExtraTurnedOn(lastveh, 1) then
            SetVehicleExtra(lastveh, 1, false)
        end
        local VehicleInfo = GetVehicleInfo(GetEntityModel(lastveh))
        local NewBed = CreateObjectNoOffset(GetHashKey(Config.BedProp), GetEntityCoords(lastveh), true, false, false)

        if Entity(lastveh).state.prop == nil then
            Entity(lastveh).state.prop = NewBed
        end

        GetOwnership(lastveh)
        AttachEntityToEntity(NewBed, lastveh, nil, VehicleInfo.Default.Pos, VehicleInfo.Default.Rot, true, false, true, false, nil, true)
        Entity(lastveh).state.busy = false
        Entity(lastveh).state.status = false
        Entity(lastveh).state.towedVehicle = nil
    end
end)

RegisterNetEvent("soz-flatbed:client:action")
AddEventHandler("soz-flatbed:client:action", function(entity, Action)
    if DoesEntityExist(Entity(entity).state.prop) then
        local VehicleInfo = GetVehicleInfo(GetEntityModel(entity))
        local PropID = Entity(entity).state.prop
        if Action == "lower" then
            exports["soz-hud"]:DrawNotification("Le plateau descend !")
            local BedPos = VehicleInfo.Default.Pos
            local BedRot = VehicleInfo.Default.Rot

            repeat
                Citizen.Wait(10)
                BedPos = math.floor((BedPos - vector3(0.0, 0.02, 0.0)) * 1000) / 1000

                if BedPos.y < VehicleInfo.Active.Pos.y then
                    BedPos = vector3(BedPos.x, VehicleInfo.Active.Pos.y, BedPos.z)
                end
                GetOwnership(entity)
                DetachEntity(PropID, false, false)
                AttachEntityToEntity(PropID, entity, nil, BedPos, BedRot, true, false, true, false, nil, true)
            until BedPos.y == VehicleInfo.Active.Pos.y

            repeat
                Citizen.Wait(10)
                if BedPos.z ~= VehicleInfo.Active.Pos.z then
                    BedPos = math.floor((BedPos - vector3(0.0, 0.0, 0.0105)) * 1000) / 1000

                    if BedPos.z < VehicleInfo.Active.Pos.z then
                        BedPos = vector3(BedPos.x, BedPos.y, VehicleInfo.Active.Pos.z)
                    end
                end
                if BedRot.x ~= VehicleInfo.Active.Rot.x then
                    BedRot = math.floor((BedRot + vector3(0.15, 0, 0.0)) * 1000) / 1000

                    if BedRot.x > VehicleInfo.Active.Rot.x then
                        BedRot = vector3(VehicleInfo.Active.Rot.x, 0.0, 0.0)
                    end
                end
                GetOwnership(entity)
                DetachEntity(PropID, false, false)
                AttachEntityToEntity(PropID, entity, nil, BedPos, BedRot, true, false, true, false, nil, true)
            until BedRot.x == VehicleInfo.Active.Rot.x and BedPos.z == VehicleInfo.Active.Pos.z

            Entity(entity).state.status = true
        elseif Action == "raise" then
            exports["soz-hud"]:DrawNotification("Le plateau remonte !")
            local BedPos = VehicleInfo.Active.Pos
            local BedRot = VehicleInfo.Active.Rot

            repeat
                Citizen.Wait(10)
                if BedPos.z ~= VehicleInfo.Default.Pos.z then
                    BedPos = math.floor((BedPos + vector3(0.0, 0.0, 0.0105)) * 1000) / 1000

                    if BedPos.z > VehicleInfo.Default.Pos.z then
                        BedPos = vector3(BedPos.x, BedPos.y, VehicleInfo.Default.Pos.z)
                    end
                end
                if BedRot.x ~= VehicleInfo.Default.Rot.x then
                    BedRot = math.floor((BedRot - vector3(0.15, 0, 0.0)) * 1000) / 1000

                    if BedRot.x < VehicleInfo.Default.Rot.x then
                        BedRot = vector3(VehicleInfo.Default.Rot.x, 0.0, 0.0)
                    end
                end
                GetOwnership(entity)
                DetachEntity(PropID, false, false)
                AttachEntityToEntity(PropID, entity, nil, BedPos, BedRot, true, false, true, false, nil, true)
            until BedRot.x == VehicleInfo.Default.Rot.x and BedPos.z == VehicleInfo.Default.Pos.z

            repeat
                Citizen.Wait(10)
                BedPos = math.floor((BedPos + vector3(0.0, 0.02, 0.0)) * 1000) / 1000

                if BedPos.y > VehicleInfo.Default.Pos.y then
                    BedPos = vector3(BedPos.x, VehicleInfo.Default.Pos.y, BedPos.z)
                end
                GetOwnership(entity)
                DetachEntity(PropID, false, false)
                AttachEntityToEntity(PropID, entity, nil, BedPos, BedRot, true, false, true, false, nil, true)
            until BedPos.y == VehicleInfo.Default.Pos.y

            Entity(entity).state.status = false
        elseif Action == "attach" then
            if not Entity(entity).state.towedVehicle then
                local AttachCoords = GetOffsetFromEntityInWorldCoords(PropID, vector3(VehicleInfo.Attach.x, VehicleInfo.Attach.y, 0.0))
                local ClosestVehicle = GetNearestVehicle(AttachCoords, VehicleInfo.Radius)
                if DoesEntityExist(ClosestVehicle) and ClosestVehicle ~= entity then
                    local VehicleCoords = GetEntityCoords(ClosestVehicle)
                    GetOwnership(ClosestVehicle)
                    AttachEntityToEntity(ClosestVehicle, PropID, nil, GetOffsetFromEntityGivenWorldCoords(PropID, VehicleCoords), vector3(0.0, 0.0, 0.0), true,
                                         false, false, false, nil, true)
                    Entity(entity).state.towedVehicle = ClosestVehicle
                    TriggerEvent("InteractSound_CL:PlayOnOne", "seatbelt/buckle", 0.2)
                    exports["soz-hud"]:DrawNotification("Vous avez attaché le véhicule !")
                end
            end
        elseif Action == "detach" then
            if Entity(entity).state.towedVehicle then
                local AttachedVehicle = Entity(entity).state.towedVehicle
                GetOwnership(AttachedVehicle)
                DetachEntity(AttachedVehicle, true, true)
                Entity(entity).state.towedVehicle = nil
                TriggerEvent("InteractSound_CL:PlayOnOne", "seatbelt/unbuckle", 0.2)
                exports["soz-hud"]:DrawNotification("Vous avez détaché le véhicule !")
            end
        end
    else
        TriggerEvent("soz-flatbed:client:getProp", entity)
    end

    Entity(entity).state.busy = false
end)

RegisterNetEvent("soz-flatbed:client:tpaction")
AddEventHandler("soz-flatbed:client:tpaction", function(lastveh, entity)
    if DoesEntityExist(Entity(lastveh).state.prop) then
        local VehicleInfo = GetVehicleInfo(GetEntityModel(lastveh))
        local PropID = Entity(lastveh).state.prop
        if not Entity(lastveh).state.towedVehicle then
            local AttachCoords = GetOffsetFromEntityInWorldCoords(PropID, vector3(VehicleInfo.Attach.x, VehicleInfo.Attach.y, 0.6))
            if DoesEntityExist(entity) and entity ~= lastveh then
                GetOwnership(lastveh)
                GetOwnership(entity)
                AttachEntityToEntity(entity, PropID, nil, GetOffsetFromEntityGivenWorldCoords(PropID, AttachCoords), vector3(0.0, 0.0, 0.6), true, false, false,
                                     false, nil, true)
                Entity(lastveh).state.towedVehicle = entity
                TriggerEvent("InteractSound_CL:PlayOnOne", "seatbelt/buckle", 0.2)
                exports["soz-hud"]:DrawNotification("Vous avez mis le véhicule sur le plateau !")
            end
        else
            local AttachedVehicle = Entity(lastveh).state.towedVehicle
            local AttachedCoords = GetEntityCoords(AttachedVehicle)
            local FlatCoords = GetEntityCoords(lastveh)
            GetOwnership(lastveh)
            GetOwnership(AttachedVehicle)
            DetachEntity(AttachedVehicle, true, true)
            SetEntityCoords(AttachedVehicle, FlatCoords.x - ((FlatCoords.x - AttachedCoords.x) * 4), FlatCoords.y - ((FlatCoords.y - AttachedCoords.y) * 4),
                            FlatCoords.z, false, false, false, false)
            Entity(lastveh).state.towedVehicle = nil
            TriggerEvent("InteractSound_CL:PlayOnOne", "seatbelt/unbuckle", 0.2)
            exports["soz-hud"]:DrawNotification("Vous avez enlevé le véhicule du plateau !")
        end
    else
        TriggerEvent("soz-flatbed:client:getProp", lastveh)
    end
    Entity(lastveh).state.busy = false
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)

        if not DoesEntityExist(LastVehicle) or NetworkGetEntityOwner(LastVehicle) ~= PlayerId() then
            LastVehicle = nil
        end

        local PlayerVehicle = GetVehiclePedIsIn(PlayerPedId(), false)

        if PlayerVehicle ~= 0 then
            if PlayerVehicle ~= LastVehicle then
                local VehicleModel = GetEntityModel(PlayerVehicle)

                for Index, CurrentFlatbed in pairs(Config.Flatbeds) do
                    if VehicleModel == GetHashKey(CurrentFlatbed.Hash) then
                        LastVehicle = PlayerVehicle
                        TriggerEvent("soz-flatbed:client:getProp", PlayerVehicle)
                        break
                    end
                end
            else
                if Entity(LastVehicle).state.towedVehicle and DoesEntityExist(Entity(LastVehicle).state.towedVehicle) then
                    DisableCamCollisionForEntity(Entity(LastVehicle).state.towedVehicle)
                end
            end
        end
    end
end)

local function ActionFlatbed(entity)
    if not Entity(entity).state.busy then
        if not Entity(entity).state.status then
            Entity(entity).state.busy = true
            TriggerEvent("soz-flatbed:client:action", entity, "lower")
        else
            Entity(entity).state.busy = true
            TriggerEvent("soz-flatbed:client:action", entity, "raise")
        end
    end
end

local function ChainesFlatbed(entity)
    if not Entity(entity).state.busy then
        if Entity(entity).state.status then
            Entity(entity).state.busy = true
            if Entity(entity).state.towedVehicle then
                TriggerEvent("soz-flatbed:client:action", entity, "detach")
            else
                TriggerEvent("soz-flatbed:client:action", entity, "attach")
            end
        end
    end
end

local function TpFlatbed(entity, lastveh)
    if lastveh then
        if not Entity(lastveh).state.busy then
            Entity(lastveh).state.busy = true
            if not Entity(lastveh).state.towedVehicle then
                TriggerEvent("soz-flatbed:client:tpaction", lastveh, entity)
            end
        end
    else
        if not Entity(entity).state.busy then
            Entity(entity).state.busy = true
            if Entity(entity).state.towedVehicle then
                TriggerEvent("soz-flatbed:client:tpaction", entity, nil)
            end
        end
    end
end

RegisterNetEvent("soz-flatbed:client:calltp", function(entity, lastveh)
    TpFlatbed(entity, lastveh)
end)

RegisterNetEvent("soz-flatbed:client:callchaines", function(entity)
    ChainesFlatbed(entity)
end)

RegisterNetEvent("soz-flatbed:client:callaction", function(entity)
    ActionFlatbed(entity)
end)

CreateThread(function()
    exports["qb-target"]:AddGlobalVehicle({
        options = {
            {
                type = "client",
                icon = "c:mechanic/Activer.png",
                event = "soz-flatbed:client:callaction",
                feature = "flatbed-ramp",
                label = "TEST Descendre",
                action = function(entity)
                    TriggerEvent("soz-flatbed:client:callaction", entity)
                end,
                canInteract = function(entity, distance, data)
                    if GetEntityModel(entity) ~= GetHashKey("flatbed3") then
                        return false
                    end
                    if OnDuty == false then
                        return false
                    end
                    return not Entity(entity).state.status
                end,
                job = "bennys",
            },
            {
                type = "client",
                icon = "c:mechanic/Desactiver.png",
                event = "soz-flatbed:client:callaction",
                feature = "flatbed-ramp",
                label = "TEST Relever",
                action = function(entity)
                    TriggerEvent("soz-flatbed:client:callaction", entity)
                end,
                canInteract = function(entity, distance, data)
                    if GetEntityModel(entity) ~= GetHashKey("flatbed3") then
                        return false
                    end
                    if OnDuty == false then
                        return false
                    end
                    return Entity(entity).state.status
                end,
                job = "bennys",
            },
            {
                type = "client",
                icon = "c:mechanic/Attacher.png",
                event = "soz-flatbed:client:callchaines",
                feature = "flatbed-ramp",
                label = "TEST Attacher",
                action = function(entity)
                    TriggerEvent("soz-flatbed:client:callchaines", entity)
                end,
                canInteract = function(entity, distance, data)
                    if GetEntityModel(entity) ~= GetHashKey("flatbed3") then
                        return false
                    end
                    if OnDuty == false then
                        return false
                    end
                    return not Entity(entity).state.towedVehicle
                end,
                job = "bennys",
            },
            {
                type = "client",
                icon = "c:mechanic/Detacher.png",
                event = "soz-flatbed:client:callchaines",
                feature = "flatbed-ramp",
                label = "TEST Détacher",
                action = function(entity)
                    TriggerEvent("soz-flatbed:client:callchaines", entity)
                end,
                canInteract = function(entity, distance, data)
                    if GetEntityModel(entity) ~= GetHashKey("flatbed3") then
                        return false
                    end
                    if OnDuty == false then
                        return false
                    end
                    return Entity(entity).state.towedVehicle
                end,
                job = "bennys",
            },
            {
                type = "client",
                icon = "c:mechanic/Retirer.png",
                event = "soz-flatbed:client:calltp",
                feature = "flatbed-ramp",
                label = "TEST Démorquer",
                action = function(entity)
                    TriggerEvent("soz-flatbed:client:calltp", entity)
                end,
                canInteract = function(entity, distance, data)
                    if GetEntityModel(entity) ~= GetHashKey("flatbed3") then
                        return false
                    end
                    if OnDuty == false then
                        return false
                    end
                    return Entity(entity).state.towedVehicle
                end,
                job = "bennys",
            },
            {
                type = "client",
                icon = "c:mechanic/Mettre.png",
                event = "soz-flatbed:client:calltp",
                feature = "flatbed-ramp",
                label = "TEST Remorquer",
                action = function(entity)
                    local lastveh = GetVehiclePedIsIn(PlayerPedId(), true)
                    TriggerEvent("soz-flatbed:client:calltp", entity, lastveh)
                end,
                canInteract = function(entity, distance, data)
                    if GetEntityModel(entity) == GetHashKey("flatbed3") then
                        return false
                    end
                    if OnDuty == false then
                        return false
                    end
                    if (GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), true)) ~= GetHashKey("flatbed3")) or
                        (#(GetEntityCoords(GetVehiclePedIsIn(PlayerPedId(), true)) - GetEntityCoords(PlayerPedId())) >= 50) then
                        return false
                    end
                    return true
                end,
                job = "bennys",
            },
        },
        distance = 3,
    })
    exports["qb-target"]:AddTargetModel(-669511193, {
        options = {
            {
                type = "client",
                icon = "fa-solid fa-ban",
                label = "Supprimer",
                action = function(entity)
                    DeleteEntity(entity)
                end,
                job = "bennys",
            },
        },
        distance = 3,
    })
end)
