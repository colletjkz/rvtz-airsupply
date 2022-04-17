local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
--------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
--------------------------------------------------------------------------------------------------------------------------------
src = {}
Tunnel.bindInterface("airsupply", src)
vSERVER = Tunnel.getInterface("airsupply")
--------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
--------------------------------------------------------------------------------------------------------------------------------
local config = {}
local blips = {}
local coords = nil
local crate = nil
local parachute = nil
local pickingAirDrop = false
local particleId = 0
local x,y,z = nil
local evento = nil
local dropNoChao = false
--------------------------------------------------------------------------------------------------------------------------------
-- REQUESTPARTICLE
--------------------------------------------------------------------------------------------------------------------------------
local function requestParticle(dict)
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        RequestNamedPtfxAsset(dict)
        Citizen.Wait(50)
    end
    UseParticleFxAssetNextCall(dict);
end
--------------------------------------------------------------------------------------------------------------------------------
-- DRAWPARTICLE
--------------------------------------------------------------------------------------------------------------------------------
local function drawParticle(x, y, z, particleDict, particleName)
    requestParticle(particleDict)
    particleId = StartParticleFxLoopedAtCoord(particleName, x, y, z, 0.0, 0.0, 0.0, 2.0, false, false, false, false);
end
--------------------------------------------------------------------------------------------------------------------------------
-- DRAWTEXT
--------------------------------------------------------------------------------------------------------------------------------
local function drawText(x,y,z,text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
	SetTextFont(6)
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,150)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text))/550
	DrawRect(_x,_y+0.0125,0.01+factor,0.03,0,0,0,80)
end
--------------------------------------------------------------------------------------------------------------------------------
-- DRAWSCREEN
--------------------------------------------------------------------------------------------------------------------------------
local function drawScreen(text,font,x,y,scale)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(255,255,255,150)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end
--------------------------------------------------------------------------------------------------------------------------------
-- CREATEAIRSUPPLYBLIP
--------------------------------------------------------------------------------------------------------------------------------
local function createAirSupplyBlip(index, delete, x, y, z, sprite, colour, scale, text)
    if not delete then
        blips[index] = AddBlipForCoord(x, y, z)
        SetBlipSprite(blips[index],sprite)
        SetBlipColour(blips[index],colour)
        SetBlipScale(blips[index],scale)
        SetBlipAsShortRange(blips[index],true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(text)
        EndTextCommandSetBlipName(blips[index])
    else
        if DoesBlipExist(blips[index]) then
            RemoveBlip(blips[index])
        end
        blips[index] = nil
    end
end
--------------------------------------------------------------------------------------------------------------------------------
-- PICKUPAIRDROP
--------------------------------------------------------------------------------------------------------------------------------
local function pickupAirDrop()
    local ped = PlayerPedId()
    local count = 0

    pickingAirDrop = true

    FreezeEntityPosition(ped, true)

    local function cancel()
        pickingAirDrop = false
        FreezeEntityPosition(ped, false)
        ClearPedTasks(ped)
    end

    while count <= 1250 do

        count = count + 1
        if not IsEntityPlayingAnim(ped, "amb@medic@standing@tendtodead@idle_a", "idle_a", 3) then
            ClearPedTasksImmediately(ped)
            vRP.playAnim(false, {{"amb@medic@standing@tendtodead@idle_a", "idle_a"}}, true)
            Citizen.Wait(500)
        end
        if GetEntityHealth(ped) <= 101 or IsControlJustPressed(0, 168) then
            cancel()
            return false
        end
        drawScreen('PRESSIONE ~b~F7 ~w~PARA CANCELAR A ~b~COLETA~w~', 4,0.5,0.93,0.50,255,255,255,180)
        drawScreen('AGUARDE ~b~'..math.ceil((1250-count)/100) .. ' ~w~SEGUNDOS', 4,0.5,0.96,0.50,255,255,255,180)
        Citizen.Wait(4)
    end

    cancel()
    return true
end
--------------------------------------------------------------------------------------------------------------------------------
-- CHECKAREACLEAROFPLAYER
--------------------------------------------------------------------------------------------------------------------------------
local function checkAreaClearOfPlayer(radius)

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)

    for k, v in pairs(GetActivePlayers()) do
        local nped = GetPlayerPed(v)
        local npedCoords = GetEntityCoords(nped)
        if ped ~= nped then
            if Vdist2(pedCoords,npedCoords) <= radius then
                if GetEntityHealth(nped) > 101 then
                    return false
                end
            end
        end
    end

    return true
end
--------------------------------------------------------------------------------------------------------------------------------
-- SYNCCONFIG
--------------------------------------------------------------------------------------------------------------------------------
function src.syncConfig(_config)
    config = _config
end
--------------------------------------------------------------------------------------------------------------------------------
-- FINISHEVENT
--------------------------------------------------------------------------------------------------------------------------------
function finishEvent()

    if DoesEntityExist(crate) then
        DeleteEntity(crate)
    end

    if DoesEntityExist(dropNoChao) then
        DeleteEntity(dropNoChao)
    end

    if DoesEntityExist(parachute) then
        DeleteEntity(parachute)
    end

    DeleteObject(parachuteObj)
    DeleteObject(crateObj)

    coords = nil
    crate = nil
    parachute = nil
    dropNoChao = false
    --vSERVER.setcoletado()

    createAirSupplyBlip('airSupplyArea', true)
    createAirSupplyBlip('airSupplyCenterFalling', true)
    createAirSupplyBlip('airSupplyCenterOnFloor', true)
end
--------------------------------------------------------------------------------------------------------------------------------
-- STARTEVENT
--------------------------------------------------------------------------------------------------------------------------------
function src.startEvent(c,v,r)
    evento = 1
    --TriggerEvent('Notify', 'aviso','Um suprimento está sendo encomendado, verifique seu GPS para mais informações.')
    -- TriggerEvent('vrp_sound:source', 'airsupply', 1.0)

    x, y, z = c,v,r
    local crateObj = GetHashKey('ex_prop_adv_case_sm_03')
    local parachuteObj = GetHashKey('p_parachute1_mp_dec')

    local sky = z + 550
    local floor = z - 1.0

    crate = CreateObject(crateObj, x, y, sky, false, true, false)
    SetEntityAsMissionEntity(crate,true,true)

    parachute = CreateObject(parachuteObj, x, y, sky, false, true, false)

    FreezeEntityPosition(crate, true)
    FreezeEntityPosition(parachute, true)

    AttachEntityToEntity(parachute, crate, 0, 0.0, 0.0, 3.4, 0.0, 0.0, 0.0, false, false, false, true, 2, true)

    blips['airSupplyArea'] = AddBlipForRadius(x, y, z, 200.0)
    SetBlipColour(blips['airSupplyArea'], 47)
    SetBlipAlpha(blips['airSupplyArea'], 70)

    createAirSupplyBlip('airSupplyCenterFalling', false, x, y, z, 94, 5, 1.0, '~b~ALERTA: ~w~ Air Supply')
    drawParticle(x, y, z-1.0, 'core', 'exp_grd_flare')

    while sky > floor do
        sky = sky - 0.1
        SetEntityCoords(crate, x, y, sky)

        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        local _, _, pedZ = table.unpack(pedCoords)

        if #(pedCoords - vector3( x, y, sky)) <= 1.7 then
            SetEntityHealth(ped, 101)
        end

        if sky - floor <= 1 then
            if parachute then
                DeleteEntity(parachute)
            end

            createAirSupplyBlip('airSupplyCenterFalling', true)
            createAirSupplyBlip('airSupplyCenterOnFloor', false, x, y, z, 478, 5, 1.0, '~b~ALERTA: ~w~ Air Supply')
            StopParticleFxLooped(particleId, false)
            SetEntityCoords(crate,x,y,floor)
            PlaceObjectOnGroundProperly(crate)

            coords = c,v,r
            dropNoChao = true
            break
        end
        Citizen.Wait(2) -- LOCAL AONDE VC ESCOLHE O TEMPO DE QUEDA DO AIR DROP,RECOMENDO O VALOR 15
    end
end
--------------------------------------------------------------------------------------------------------------------------------
-- MAINTHREAD
--------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function() 
    while true do
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        local timeDistance = 2000
        if evento ~= nil then
            timeDistance = 4
            local dist = #(pedCoords - vector3(x,y,z))
            local alive = GetEntityHealth(ped) > 101

            if not IsPedInAnyVehicle(ped) and alive and not pickingAirDrop and not create ~= nil and not dropNoChao == false then
                if dist <= 3.0 then
                        drawText(x,y,z,'~b~[E]   ~w~PEGAR ~b~AIRDROP~w~')
                        if dist <= 1.5 then
                            if IsControlJustPressed(0,38) then
                                if vSERVER.checkIntPermissions() then
                                    if pickupAirDrop() then
                                        if alive then
                                            finishEvent()
                                            vSERVER.getSupply()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        Citizen.Wait(timeDistance)
    end
end)