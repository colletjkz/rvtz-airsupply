local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface("airsupply", src)
vCLIENT = Tunnel.getInterface("airsupply")


local coletado = false

function src.setcoletado()
    coletado = false
end

function SendWebhookMessage(webhook,message)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
end


local coordsChoosen = nil

local webhookSupply = ''

AddEventHandler("vRP:playerSpawn",function(user_id,source,first_spawn)
    vCLIENT.syncConfig(source, config)
end)


local function startEvent()
    local Entregas = {
        [1] = {['x'] = 1456.88, ['y'] = 1124.34, ['z'] = 114.34 },
        [2] = {['x'] = 1192.53, ['y'] = -3008.65, ['z'] = 5.9 },
        [3] = {['x'] = 133.54, ['y'] = -3332.03, ['z'] = 6.02 },
        [4] = {['x'] = -1257.73, ['y'] = -3344.34, ['z'] = 13.94 },
        [5] = {['x'] = -2242.27, ['y'] = 266.21, ['z'] = 174.62 },
        [6] = {['x'] = -450.51, ['y'] = 1104.31, ['z'] = 332.54 },
        [7] = {['x'] = 1053.14, ['y'] = 2356.23, ['z'] = 45.02 },
        [8] = {['x'] = -2170.64, ['y'] = 3206.85, ['z'] = 32.57 },
        [9] = {['x'] = -130.65, ['y'] = 6442.56, ['z'] = 31.24 },

    }
    local sorteado = math.random(1, #Entregas)
    local coordsx,coordsy,coordsz = Entregas[sorteado].x, Entregas[sorteado].y, Entregas[sorteado].z
    coordsChoosen1,coordsChoosen2,coordsChoosen3 = coordsx,coordsy,coordsz
    vCLIENT.startEvent(-1, coordsChoosen1,coordsChoosen2,coordsChoosen3)
end

function src.getSupply()
    local source = source
    local user_id = vRP.getUserId(source)
    local reward = math.random(4,4)
    local identity = vRP.getUserIdentity(user_id)
    
    if user_id then
        if not coletado then
            coletado = true
            if reward == 4 then
                vRP.giveInventoryItem(user_id,'wbody|WEAPON_ASSAULTRIFLE_MK2',math.random(1,4))
                vRP.giveInventoryItem(user_id,'wammo|WEAPON_ASSAULTRIFLE_MK2',math.random(1,250))
                vRP.giveInventoryItem(user_id,'bandagem',math.random(3,6))
                vRP.giveInventoryItem(user_id,'energetico',math.random(2,4))
                TriggerClientEvent('chatMessage',-1,"[AIR  SUPPLY] "..identity.name.." "..identity.firstname.." Coletou todos os Suprimentos do Air Supply")
                SendWebhookMessage(webhookSupply,"```prolog\n[ID]: "..user_id.." "..identity.name.." "..identity.firstname.." \n[===========REVINDICOU O AIR SUPPLY==========] "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
            elseif reward == 3 then
                vRP.giveInventoryItem(user_id,'wbody|WEAPON_SMG_MK2',math.random(1,4))
                vRP.giveInventoryItem(user_id,'bandagem',math.random(3,6))
                vRP.giveInventoryItem(user_id,'energetico',math.random(2,4))
                TriggerClientEvent('chatMessage',-1,"[AIR  SUPPLY] "..identity.name.." "..identity.firstname.." Coletou todos os Suprimentos do Air Supply")
                SendWebhookMessage(webhookSupply,"```prolog\n[ID]: "..user_id.." "..identity.name.." "..identity.firstname.." \n[===========REVINDICOU O AIR SUPPLY==========] "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
            else 
                if reward == 2 then
                    vRP.giveInventoryItem(user_id,'wbody|WEAPON_PISTOL_MK2',math.random(1,4))
                    vRP.giveInventoryItem(user_id,'wammo|WEAPON_PISTOL_MK2',math.random(1,4))
                    vRP.giveInventoryItem(user_id,'bandagem',math.random(3,6))
                    vRP.giveInventoryItem(user_id,'energetico',math.random(2,4))
                    -TriggerClientEvent('chatMessage',-1,"[AIR  SUPPLY] "..identity.name.." "..identity.firstname.." Coletou todos os Suprimentos do Air Supply")
                    SendWebhookMessage(webhookSupply,"```prolog\n[ID]: "..user_id.." "..identity.name.." "..identity.firstname.." \n[===========REVINDICOU O AIR SUPPLY==========] "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
                end
            end
        else
            TriggerClientEvent('Notify',source,'negado','Negado','Este Airdrop já foi coletado!')
        end
    end
end


RegisterCommand('lastairdrop', function(source, args, rawCmd)
    local source = source
    local user_id = vRP.getUserId(source)
    if vRP.hasPermission(user_id, 'admin.permissao') then
        coletado = false
        startEvent()
        TriggerClientEvent('Notify',source,'sucesso','Sucesso','Posicionado o airdrop no mapa!')
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKINTPERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function src.checkIntPermissions()
    local source = source
    local user_id = vRP.getUserId(source)
    local nplayer = vRPclient.getNearestPlayer(source,2)
    local nuser_id = vRP.getUserId(nplayer)

    if nuser_id then
        TriggerClientEvent("Notify",source,"negado","Negado","Você não consegue resgatar o airdrop com pessoas ao seu lado.")
        return false
    else
        return true
    end
end




