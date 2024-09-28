-- Next Level Developemnt

local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('zombie:killed')
AddEventHandler('zombie:killed', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        if Player.Functions.AddItem("bandage", 1) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["bandage"], "add", 1)
            TriggerClientEvent('QBCore:Notify', src, '1x Bandaj aldınız', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Envanterinizde yeterli alan yok', 'error')
        end
    end
end)