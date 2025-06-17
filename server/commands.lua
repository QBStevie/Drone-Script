local ESX, QBCore

if GetResourceState and GetResourceState('es_extended') == 'started' then
  ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState and GetResourceState('qb-core') == 'started' then
  QBCore = exports['qb-core']:GetCoreObject()
end

local function Notify(src, msg)
  if ESX then
    TriggerClientEvent('esx:showNotification', src, msg)
  elseif QBCore then
    TriggerClientEvent('QBCore:Notify', src, msg)
  end
end

RegisterNetEvent('m1_drn:serverGiveDrone')
AddEventHandler('m1_drn:serverGiveDrone', function()
  local src = source
  local success = exports.ox_inventory:AddItem(src, 'drone', 1)
  if success then
    Notify(src, 'You received a drone')
  else
    Notify(src, 'Could not give you a drone.')
  end
end)

RegisterNetEvent('m1_drn:serverRemoveDrone')
AddEventHandler('m1_drn:serverRemoveDrone', function()
  local src = source
  local success = exports.ox_inventory:RemoveItem(src, 'drone', 1)
  if not success then
    Notify(src, 'Could not remove your drone.')
  end
end)
