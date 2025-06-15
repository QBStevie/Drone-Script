ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('m1_drn:serverGiveDrone')
AddEventHandler('m1_drn:serverGiveDrone', function()
  local src = source
  local success = exports.ox_inventory:AddItem(src, 'drone', 1)
  if success then
    TriggerClientEvent('esx:showNotification', src, 'You received a drone')
  else
    TriggerClientEvent('esx:showNotification', src, 'Could not give you a drone.')
  end
end)

RegisterNetEvent('m1_drn:serverRemoveDrone')
AddEventHandler('m1_drn:serverRemoveDrone', function()
  local src = source
  local success = exports.ox_inventory:RemoveItem(src, 'drone', 1)
  if not success then
    TriggerClientEvent('esx:showNotification', src, 'Could not remove your drone.')
  end
end)
