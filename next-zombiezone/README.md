discord :  arvenm

This sharing is free


item verme kısmı server.lua içerisinde vardır oradan ayarlayabilirsiniz.
eğer zombilerin ölünce hemen gelmesini istiyorsanız bu aşağıdaki kodu değiştirinn 


-- zombilerin öldürüldüğünde 1 Saniye içerisinde tekrar gelmesini istiyorsanız bu kodu kullanın
Citizen.CreateThread(function()  
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        if IsInZombieZone(playerPed) then
            if not DoesEntityExist(currentZombie) or IsEntityDead(currentZombie) then
                if IsEntityDead(currentZombie) then
                    GiveRewardToPlayer()
                    Citizen.Wait(1000)
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

--  bu kod ile değişitirin client de aratırsanız bulursunuz      <3
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

