ESX = exports['es_extended']:getSharedObject()

ESX.RegisterServerCallback('drone:getPlateInfo', function(source, cb, plate)
  MySQL.Async.fetchAll('SELECT owner_name FROM owned_vehicles WHERE plate = @plate', {
    ['@plate'] = plate
  }, function(results)
    local owner = (results[1] and results[1].owner_name) or 'Unknown'
    cb({ owner = owner })
  end)
end)

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

RegisterNetEvent('m1_drn:serverDroneDropped', function(netId)
  TriggerClientEvent('m1_drn:clientDroneDropped', -1, netId)
end)

RegisterNetEvent('m1_drn:serverDronePickedUp', function(netId)
  TriggerClientEvent('m1_drn:clientDroneRemoved', -1, netId)
end)
