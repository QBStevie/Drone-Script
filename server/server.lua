local ESX, QBCore

if GetResourceState and GetResourceState('es_extended') == 'started' then
  ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState and GetResourceState('qb-core') == 'started' then
  QBCore = exports['qb-core']:GetCoreObject()
end


if ESX then
  ESX.RegisterServerCallback('drone:getPlayerInfo', function(source, cb, targetId)
    local xPlayer = ESX.GetPlayerFromId(targetId)
    if xPlayer then
      cb({
        name = xPlayer.getName(),
        dob  = xPlayer.get('dob'),
        job  = xPlayer.job.label
      })
    else
      cb(nil)
    end
  end)
elseif QBCore then
  QBCore.Functions.CreateCallback('drone:getPlayerInfo', function(source, cb, targetId)
    local Player = QBCore.Functions.GetPlayer(targetId)
    if Player then
      cb({
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        dob  = Player.PlayerData.charinfo.birthdate,
        job  = Player.PlayerData.job.label
      })
    else
      cb(nil)
    end
  end)
end

local lastTase = {}

RegisterNetEvent('m1_drn:serverRequestTase', function(targetNetId)
  local src = source
  local now = os.time()
  local xSource = ESX and ESX.GetPlayerFromId(src) or QBCore.Functions.GetPlayer(src)

  local jobName = xSource and (ESX and xSource.job.name or xSource.PlayerData.job.name)

  if not xSource or jobName ~= 'police' then
    TriggerClientEvent('m1_drn:clientNotify', src, 'You do not have permission to use the taser.')
    return
  end

  if lastTase[src] and now - lastTase[src] < Config.TaserCooldown then
    TriggerClientEvent('m1_drn:clientNotify', src, 'Taser recharging, please wait.')
    return
  end

  lastTase[src] = now

  TriggerClientEvent('m1_drn:clientApplyTase', -1, targetNetId)
end)


RegisterNetEvent('m1_drn:serverDroneDropped', function(netId)
  TriggerClientEvent('m1_drn:clientDroneDropped', -1, netId)
end)

RegisterNetEvent('m1_drn:serverDronePickedUp', function(netId)
  TriggerClientEvent('m1_drn:clientDroneRemoved', -1, netId)
end)
