ESX = exports['es_extended']:getSharedObject()

local isDroneActive   = false
local cam             = nil
local droneVehicle    = nil
local trackedVehicle  = nil
local trackBlip       = nil
local droppedVehicle  = nil

local modes       = { "normal", "suspect", "taser", "boost", "track" }
local modeIndex   = 1
local visionModes = { "normal", "night", "thermal" }
local visionIndex = 1

local lastTaseTime   = 0
local TASE_COOLDOWN  = 10 * 60 * 1000  
local firstNames     = { "Alex","Blake","Casey","Drew","Evan","Frankie","Grey","Harley","Jesse","Kai","Logan" }
local lastNames      = { "Anderson","Brown","Chen","Davies","Evans","Garcia","Hernandez","Ivanov","Johnson","Khan" }
local npcOwners      = {}

local DRONE_FORWARD    = 2.0
local DRONE_HEIGHT     = 10.0
local CAMERA_Z_OFFSET  = 1.0
local TRACK_DISTANCE   = 5.0
local SPEED_NORMAL     = 0.2
local SPEED_BOOST      = 0.6
local YAW_SPEED        = 3.0
local PITCH_SPEED      = 3.0
local MAX_SIGNAL_DIST  = 200.0

local function fullCleanup()
  SendNUIMessage({ action = 'hideHUD' })
  RenderScriptCams(false, false, 0, true, true)
  if cam and DoesCamExist(cam) then DestroyCam(cam, false); cam = nil end
  SetNightvision(false); SetSeethrough(false)
  if droneVehicle    and DoesEntityExist(droneVehicle)    then DeleteEntity(droneVehicle);    droneVehicle    = nil end
  if droppedVehicle  and DoesEntityExist(droppedVehicle)  then DeleteEntity(droppedVehicle);  droppedVehicle  = nil end
  if trackBlip       then RemoveBlip(trackBlip); trackBlip = nil end
  isDroneActive   = false
  trackedVehicle  = nil
  ClearPedTasksImmediately(PlayerPedId())
  FreezeEntityPosition(PlayerPedId(), false)
end

AddEventHandler('onClientResourceStart', function(res)
  if res == GetCurrentResourceName() then fullCleanup() end
end)
AddEventHandler('onClientResourceStop', function(res)
  if res == GetCurrentResourceName() then fullCleanup() end
end)
AddEventHandler('onResourceStop', function(res)
  if res == GetCurrentResourceName() then fullCleanup() end
end)

local function cycleMode()
  modeIndex = modeIndex % #modes + 1
  SendNUIMessage({ action = 'setMode', mode = modes[modeIndex] })
  ESX.ShowNotification("Mode: " .. modes[modeIndex]:upper())
  return modes[modeIndex]
end

local function cycleVision()
  visionIndex = visionIndex % #visionModes + 1
  local v = visionModes[visionIndex]
  if v == "normal" then
    SetNightvision(false); SetSeethrough(false)
  elseif v == "night" then
    SetNightvision(true); SetSeethrough(false)
  else
    SetNightvision(false); SetSeethrough(true)
  end
  SendNUIMessage({ action = 'setVision', vision = v })
  ESX.ShowNotification("Vision: " .. v:upper())
  return v
end

local function GetCamForwardVector(c)
  local r = GetCamRot(c, 2)
  local p, y = math.rad(r.x), math.rad(r.z)
  return vector3(-math.sin(y) * math.cos(p), math.cos(y) * math.cos(p), math.sin(p))
end
local function GetCamRightVector(c)
  local f = GetCamForwardVector(c)
  return vector3(f.y, -f.x, 0.0)
end

local function RaycastFromCam(dist)
  local cpos = GetCamCoord(cam)
  local fwd = GetCamForwardVector(cam)
  local endp = cpos + fwd * dist
  local ray = StartShapeTestRay(cpos.x, cpos.y, cpos.z, endp.x, endp.y, endp.z, 10, PlayerPedId(), 0)
  local _, hit, _, _, ent = GetShapeTestResult(ray)
  return hit, ent
end

local function DropDrone()
  isDroneActive = false
  SendNUIMessage({ action = 'hideHUD' })
  RenderScriptCams(false, false, 0, true, true)
  if cam and DoesCamExist(cam) then DestroyCam(cam, false); cam = nil end
  if trackBlip then RemoveBlip(trackBlip); trackBlip = nil end
  SetNightvision(false); SetSeethrough(false)
  ClearPedTasksImmediately(PlayerPedId()); FreezeEntityPosition(PlayerPedId(), false)

  if droneVehicle and DoesEntityExist(droneVehicle) then
    SetEntityInvincible(droneVehicle, false)
    FreezeEntityPosition(droneVehicle, false)
    SetVehicleOnGroundProperly(droneVehicle)
    droppedVehicle = droneVehicle
    droneVehicle = nil
    ESX.ShowNotification("Signal lost! Drone dropped. Press F10 to pick up drone")
  end
end

function ActivateDrone()
  isDroneActive = true
  modeIndex, visionIndex = 1, 1
  trackedVehicle = nil
  if trackBlip then RemoveBlip(trackBlip); trackBlip = nil end
  SetNightvision(false); SetSeethrough(false)

  local ped = PlayerPedId()
  local pC = GetEntityCoords(ped)
  local fwd = GetEntityForwardVector(ped)
  local spawnPos

  if droneVehicle and DoesEntityExist(droneVehicle) then
    spawnPos = GetEntityCoords(droneVehicle)
  else
    local mdl = GetHashKey("rcmavic")
    RequestModel(mdl)
    while not HasModelLoaded(mdl) do Citizen.Wait(0) end
    spawnPos = pC + fwd * DRONE_FORWARD + vector3(0, 0, DRONE_HEIGHT)
    droneVehicle = CreateVehicle(mdl, spawnPos.x, spawnPos.y, spawnPos.z, GetEntityHeading(ped), true, false)
    SetEntityInvincible(droneVehicle, true)
    FreezeEntityPosition(droneVehicle, true)
    SetVehicleEngineOn(droneVehicle, false, true, true)
  end

  TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_MOBILE", 0, true)
  FreezeEntityPosition(ped, true)

  cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  SetCamCoord(cam, spawnPos.x, spawnPos.y, spawnPos.z - CAMERA_Z_OFFSET)
  SetCamRot(cam, -30.0, 0.0, GetEntityHeading(ped), 2)
  SetCamActive(cam, true)
  RenderScriptCams(true, false, 0, true, true)

  SendNUIMessage({
    action   = 'showHUD',
    setMode  = true, mode  = modes[modeIndex],
    setVision= true, vision= visionModes[visionIndex]
  })

  local startCamPos  = GetCamCoord(cam)
  local lastCamPos   = startCamPos
  local recStartTime = GetGameTimer()

  Citizen.CreateThread(function()
    while isDroneActive do
      local pos
      if modes[modeIndex] == "track" and trackedVehicle and DoesEntityExist(trackedVehicle) then
        local vc, hd = GetEntityCoords(trackedVehicle), GetEntityHeading(trackedVehicle)
        local r    = math.rad(hd)
        pos = vc + vector3(math.sin(r) * TRACK_DISTANCE, -math.cos(r) * TRACK_DISTANCE, DRONE_HEIGHT - CAMERA_Z_OFFSET)
      else
        pos = GetCamCoord(cam)
        local fw, rt = GetCamForwardVector(cam), GetCamRightVector(cam)
        local spd    = (modes[modeIndex] == "boost") and SPEED_BOOST or SPEED_NORMAL
        if IsControlPressed(0, 32) then pos = pos + fw * spd end
        if IsControlPressed(0, 33) then pos = pos - fw * spd end
        if IsControlPressed(0, 34) then pos = pos - rt * spd end
        if IsControlPressed(0, 35) then pos = pos + rt * spd end
        if IsControlPressed(0, 44) then pos = pos + vector3(0, 0, spd) end
        if IsControlPressed(0, 45) then pos = pos - vector3(0, 0, spd) end
      end

      SetCamCoord(cam, pos.x, pos.y, pos.z)
      if DoesEntityExist(droneVehicle) then
        SetEntityCoordsNoOffset(droneVehicle, pos.x, pos.y, pos.z + CAMERA_Z_OFFSET, false, false, false)
      end

      local dx = GetDisabledControlNormal(0, 1) * -YAW_SPEED
      local dy = GetDisabledControlNormal(0, 2) * -PITCH_SPEED
      local cr = GetCamRot(cam, 2)
      local pitch = math.max(-89, math.min(89, cr.x + dy))
      local yaw   = (cr.z + dx) % 360
      SetCamRot(cam, pitch, 0.0, yaw, 2)

      local dt   = GetFrameTime()
      local hDist= Vdist(pos.x, pos.y, lastCamPos.x, lastCamPos.y) / dt
      local vDist= math.abs(pos.z - lastCamPos.z) / dt
      lastCamPos = pos
      local fz, gz = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 100, false)
      local alt    = pos.z - (fz and gz or pos.z)
      local dist   = math.floor(Vdist(pos.x, pos.y, startCamPos.x, startCamPos.y))
      local coords = string.format("%.2f, %.2f", pos.x, pos.y)
      local elapsed= GetGameTimer() - recStartTime
      local h     = math.floor(elapsed / 3600000)
      local m     = math.floor((elapsed % 3600000) / 60000)
      local s     = math.floor((elapsed % 60000) / 1000)
      local recStr= string.format("%02d:%02d:%02d", h, m, s)
      local ppos  = GetEntityCoords(PlayerPedId())
      local sig   = math.floor(math.max(0, math.min(1, 1 - Vdist(ppos, pos) / MAX_SIGNAL_DIST)) * 100)

      SendNUIMessage({ action='updateTelemetry', speedH=math.floor(hDist), speedV=math.floor(vDist), alt=math.floor(alt), dist=dist, coords=coords })
      SendNUIMessage({ action='updateRecording', time=recStr })
      SendNUIMessage({ action='updateSignal', signal=sig })

      if sig <= 0 then DropDrone(); break end

      if IsDisabledControlJustReleased(0, 47) then cycleMode()    end
      if IsDisabledControlJustReleased(0, 74) then cycleVision() end

      if IsDisabledControlJustReleased(0, 51) then
        local hit, ent = RaycastFromCam(50.0)
        local md = modes[modeIndex]

        if md == "suspect" and hit then
          if IsEntityAVehicle(ent) then
            local plate = GetVehicleNumberPlateText(ent)
            if not npcOwners[plate] then
              npcOwners[plate] = firstNames[math.random(#firstNames)] .. " " .. lastNames[math.random(#lastNames)]
            end
            SendNUIMessage({ action='showPlateInfo', plate=plate, owner=npcOwners[plate] })
          elseif IsEntityAPed(ent) and IsPedAPlayer(ent) then
            local sid = GetPlayerServerId(NetworkGetEntityOwner(ent))
            ESX.TriggerServerCallback('drone:getPlayerInfo', function(data)
              SendNUIMessage({ action='showPlayerInfo', data=data })
            end, sid)
          end

        elseif md == "taser" and hit then
          local now = GetGameTimer()
          if IsEntityAVehicle(ent) then
            if now - lastTaseTime >= TASE_COOLDOWN then
              FreezeEntityPosition(ent, true)
              SetVehicleEngineOn(ent, false, true, true)
              ESX.ShowNotification("Vehicle EMP! Disabled for 8s")
              lastTaseTime = now
              Citizen.SetTimeout(8000, function()
                if DoesEntityExist(ent) then
                  FreezeEntityPosition(ent, false)
                  SetVehicleEngineOn(ent, true, true, true)
                end
              end)
            else
              ESX.ShowNotification("Vehicle EMP recharging")
            end

          elseif IsEntityAPed(ent) and IsPedAPlayer(ent) then
            SetPedToRagdoll(ent, 5000, 5000, 0, false, false, false)
            ESX.ShowNotification("Player tased!")
          end
        end
      end

      Citizen.Wait(0)
    end
  end)
end

RegisterCommand('toggledrone', function()
  local ped, ppos = PlayerPedId(), GetEntityCoords(PlayerPedId())
  local picked = false

  for _, veh in ipairs({ droppedVehicle, (not isDroneActive and droneVehicle) or nil }) do
    if veh and DoesEntityExist(veh) and #(ppos - GetEntityCoords(veh)) < 2.0 then
      TriggerServerEvent('m1_drn:serverGiveDrone')
      DeleteEntity(veh)
      if veh == droppedVehicle then droppedVehicle = nil else droneVehicle = nil end
      ESX.ShowNotification("Drone returned to your inventory.")
      picked = true
      break
    end
  end

  if not picked then
    if not isDroneActive then
      if droneVehicle and DoesEntityExist(droneVehicle) then
        ActivateDrone()
      elseif exports.ox_inventory:Search('count','drone') > 0 then
        ActivateDrone()
        TriggerServerEvent('m1_drn:serverRemoveDrone')
      else
        ESX.ShowNotification("You need a drone in your inventory.")
      end
    else
      DropDrone()
    end
  end
end, false)
RegisterKeyMapping('toggledrone', 'Toggle/Pickup Drone', 'keyboard', 'F10')

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    local ped, ppos = PlayerPedId(), GetEntityCoords(PlayerPedId())
    local veh, pos
    if droppedVehicle and DoesEntityExist(droppedVehicle) then
      veh, pos = droppedVehicle, GetEntityCoords(droppedVehicle)
    elseif droneVehicle and not isDroneActive and DoesEntityExist(droneVehicle) then
      veh, pos = droneVehicle, GetEntityCoords(droneVehicle)
    end
    if veh and pos then
      DrawMarker(20, pos.x, pos.y, pos.z + 1.5, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 255, 255, 0, 180, false, true, 2)
      if #(ppos - pos) < 2.0 then
        ESX.ShowHelpNotification("Press F10 to pick up drone")
      end
    end
  end
end)
