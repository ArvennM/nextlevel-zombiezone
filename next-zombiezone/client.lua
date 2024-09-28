-- Next Level Developemnt
-- Discord : arvenm
local QBCore = exports['qb-core']:GetCoreObject()
Config = {}

Config.HashPed = "u_m_y_zombie_01"
Config.WaitForNewAttackFromPed = 0.1
Config.PedWeapon = true
Config.WeaponPed = "WEAPON_HATCHET"
Config.HelpNotify = "~r~Zombie bölgesine girdiniz!~s~"
Config.DeletePed = true
Config.WaitForDelete = 30*1000

Config.ZombieSpawn = {
    vector3(1519.193, 3564.295, 35.362),
    vector3(1532.127, 3555.318, 35.362),
    vector3(1539.287, 3531.986, 35.362),
    vector3(1551.550, 3532.700, 35.611),
    vector3(1552.608, 3549.358, 35.387),
    vector3(1534.643, 3548.164, 35.363),
}

Config.ZombieZone = {
    center = vector3(1532.379, 3540.450, 35.362),
    radius = 30.0
}

Config.Marker = {
    MarkerID = 28,
    MarkerRGB = {R = 255, G = 0, B = 0, A = 50},
    MarkerSize = {x = 30.0, y = 30.0, z = 30.0},
    MarkerDrawDist = 100.0
}

Config.Blip = {
    Blip = true,
    Position = vector3(1532.379, 3540.450, 26.422),
    Label = "Zombie Bölgesi",
    Sprite = 303,
    Display = 4,
    Scale = 0.8,
    Color = 1
}

Config.Rewards = {
    {item = "bandage", amount = 1, chance = 70},
}

local currentZombie = nil

function IsInZombieZone(entity)
    local coords = GetEntityCoords(entity)
    return #(coords - Config.ZombieZone.center) <= Config.ZombieZone.radius
end

function SpawnZombie()
    if currentZombie ~= nil and DoesEntityExist(currentZombie) then
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestSpawnPoint = Config.ZombieSpawn[1]
    local closestDistance = #(playerCoords - closestSpawnPoint)

    for _, spawnPoint in ipairs(Config.ZombieSpawn) do
        local distance = #(playerCoords - spawnPoint)
        if distance < closestDistance then
            closestSpawnPoint = spawnPoint
            closestDistance = distance
        end
    end

    local zombieHash = GetHashKey(Config.HashPed)
    
    RequestModel(zombieHash)
    while not HasModelLoaded(zombieHash) do
        Citizen.Wait(1)
    end

    currentZombie = CreatePed(4, zombieHash, closestSpawnPoint.x, closestSpawnPoint.y, closestSpawnPoint.z, 0.0, true, false)
    
    if DoesEntityExist(currentZombie) then
        SetPedRandomComponentVariation(currentZombie, true)
        SetPedAsEnemy(currentZombie, true)
        SetPedCombatAttributes(currentZombie, 46, true)
        SetPedFleeAttributes(currentZombie, 0, false)
        SetPedCombatRange(currentZombie, 1)
        SetPedCombatMovement(currentZombie, 3)
        TaskCombatPed(currentZombie, playerPed, 0, 16)
        
        RemoveAllPedWeapons(currentZombie, true)
        GiveWeaponToPed(currentZombie, GetHashKey(Config.WeaponPed), 999999, false, true)
        SetCurrentPedWeapon(currentZombie, GetHashKey(Config.WeaponPed), true)
        
        SetEntityMaxHealth(currentZombie, 200)
        SetEntityHealth(currentZombie, 200)
    end
    
    SetModelAsNoLongerNeeded(zombieHash)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3000)
        local playerPed = PlayerPedId()
        if IsInZombieZone(playerPed) then
            if not DoesEntityExist(currentZombie) or IsEntityDead(currentZombie) then
                if IsEntityDead(currentZombie) then
                    GiveRewardToPlayer()
                    Citizen.Wait(3000)
                    DeleteEntity(currentZombie)
                end
                SpawnZombie()
            end
        else
            if currentZombie and DoesEntityExist(currentZombie) then
                DeleteEntity(currentZombie)
                currentZombie = nil
            end
        end
    end
end)

function GiveRewardToPlayer()
    for _, reward in ipairs(Config.Rewards) do
        if math.random(100) <= reward.chance then
            if QBCore.Shared.Items[reward.item] then
                TriggerServerEvent('QBCore:Server:AddItem', reward.item, reward.amount)
                TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items[reward.item], "add")
            else
                print("Hata: " .. reward.item .. " item'ı QBCore.Shared.Items'da bulunamadı.")
            end
        end
    end
end

Citizen.CreateThread(function()
    local blip = AddBlipForCoord(Config.Blip.Position)
    SetBlipSprite(blip, Config.Blip.Sprite)
    SetBlipDisplay(blip, Config.Blip.Display)
    SetBlipScale(blip, Config.Blip.Scale)
    SetBlipColour(blip, Config.Blip.Color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.Label)
    EndTextCommandSetBlipName(blip)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - Config.Blip.Position)
        
        if distance < Config.Marker.MarkerDrawDist then
            DrawMarker(Config.Marker.MarkerID, Config.Blip.Position.x, Config.Blip.Position.y, Config.Blip.Position.z,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                Config.Marker.MarkerSize.x, Config.Marker.MarkerSize.y, Config.Marker.MarkerSize.z,
                Config.Marker.MarkerRGB.R, Config.Marker.MarkerRGB.G, Config.Marker.MarkerRGB.B, Config.Marker.MarkerRGB.A,
                false, true, 2, false, nil, nil, false)
            
            if distance < 5.0 then
                QBCore.Functions.DrawText3D(Config.Blip.Position.x, Config.Blip.Position.y, Config.Blip.Position.z + 1.0, Config.HelpNotify)
            end
        end
    end
end)

function OnZombieKilled()
    TriggerServerEvent('zombie:killed')
end

local lastZombieKillTime = 0
local zombieRespawnDelay = 3000

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        if IsInZombieZone(playerPed) then
            if currentZombie and IsEntityDead(currentZombie) then
                OnZombieKilled()
                DeleteEntity(currentZombie)
                currentZombie = nil
                lastZombieKillTime = GetGameTimer()
            elseif currentZombie == nil and GetGameTimer() - lastZombieKillTime > zombieRespawnDelay then
                SpawnZombie()
            end
        end
    end
end)

Config.ZoneEnterMessage = "Zombi bölgesine giris sagladın!"
Config.NotificationDuration = 5000

local isInZone = false
local showNotification = false
local notificationStart = 0

function DrawNotification(text)
    SetTextFont(4)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(false)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    
    DrawRect(0.068, 0.05, 0.265, 0.06, 40, 0, 0, 200)
    
    DrawRect(0.068, 0.079, 0.265, 0.003, 140, 0, 0, 255)
    DrawRect(0.068, 0.021, 0.265, 0.003, 140, 0, 0, 255)
    DrawRect(0.199, 0.05, 0.003, 0.06, 140, 0, 0, 255)
    DrawRect(-0.063, 0.05, 0.003, 0.06, 140, 0, 0, 255)
    
    DrawText(0.01, 0.02)
end

function CheckZoneEntry()
    local playerPed = PlayerPedId()
    local inZone = IsInZombieZone(playerPed)
    
    if inZone and not isInZone then
        isInZone = true
        showNotification = true
        notificationStart = GetGameTimer()
    elseif not inZone and isInZone then
        isInZone = false
        showNotification = false
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        CheckZoneEntry()
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if showNotification then
            DrawNotification(Config.ZoneEnterMessage)
            if GetGameTimer() - notificationStart > Config.NotificationDuration then
                showNotification = false
            end
        end
    end
end)