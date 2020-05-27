ESX = nil

local Gang = {
    models = {
        -39239064,
        -984709238,
        -984709238,
        -236444766
    },
    pos = vector3(138.22, -1343.25, 29.2),
    h = 237.17
}
local waitBluePlayer = false
local waitRedPlayer = false
local fightStarted = false
local timer = 30000
local BLUECORNER = {x = 134.7, y = -1325.08, z = 29.2}
local REDCORNER = {x = 141.32, y = -1325.63, z = 29.2}
local RING = {x = 137.81, y = -1325.28, z = 29.2}
local RINGRANGE = 4.5
local MAXDISTANCE = 20.0
local canBet = false

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent(
            'esx:getSharedObject',
            function(obj)
                ESX = obj
            end
        )
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    PlayerData = ESX.GetPlayerData()
    RunThread()
end)

RegisterNetEvent('esx_streetfight:openMenu')
RegisterNetEvent('esx_streetfight:closeMenu')
RegisterNetEvent('esx_streetfight:gotoBlueCorner')
RegisterNetEvent('esx_streetfight:gotoRedCorner')
RegisterNetEvent('esx_streetfight:fightTimer')
RegisterNetEvent('esx_streetfight:noMoreFighter')
RegisterNetEvent('esx_streetfight:looser')
RegisterNetEvent('esx_streetfight:winner')
RegisterNetEvent('esx_streetfight:canBet')
RegisterNetEvent('esx_streetfight:cantBet')
RegisterNetEvent('esx_streetfight:callGang')

AddEventHandler('esx_streetfight:openMenu',
    function()
        ESX.TriggerServerCallback(
            'esx_streetfight:wanted',
            function(wanted)
                if not wanted then
                    OpenBookmakerMenu()
                end
            end
        )
    end
)

AddEventHandler('esx_streetfight:closeMenu',
    function()
        ESX.UI.Menu.CloseAll()
    end
)

AddEventHandler('esx_streetfight:gotoBlueCorner',
    function()
        waitBluePlayer = true
        while waitBluePlayer do
            Citizen.Wait(0)
            local player = PlayerPedId()
            local playerPos = GetEntityCoords(player)
            local distance = GetDistanceBetweenCoords(playerPos, BLUECORNER.x, BLUECORNER.y, BLUECORNER.z, true)
            DrawMarker(21, BLUECORNER.x, BLUECORNER.y, BLUECORNER.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.5, 0.5, 0.5, 0, 0, 255, 150, false, true, 2, true, false, false, false)
            ESX.ShowHelpNotification('Allez dans le coin ~b~bleu~w~. Attendez votre ~r~adversaire~w~.')
            if distance < 0.5 then
                TriggerServerEvent('esx_streetfight:blueReady')
                waitBluePlayer = false
            elseif distance > MAXDISTANCE then
                NextFighter()
                waitBluePlayer = false
            end
            if IsPedDeadOrDying(player) ~= false then
                CallCops(player)
                NextFighter()
                waitBluePlayer = false
            end
        end
    end
)

AddEventHandler('esx_streetfight:gotoRedCorner',
    function()
        waitRedPlayer = true
        while waitRedPlayer do
            Citizen.Wait(0)
            local player = PlayerPedId()
            local playerPos = GetEntityCoords(player)
            local distance = GetDistanceBetweenCoords(playerPos, REDCORNER.x, REDCORNER.y, REDCORNER.z, true)
            DrawMarker(21, REDCORNER.x, REDCORNER.y, REDCORNER.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 0, 0, 150, false, true, 2, true, false, false, false)
            ESX.ShowHelpNotification('Allez dans le coin ~r~rouge~w~. Attendez votre ~r~adversaire~w~.')
            if distance < 0.5 then
                TriggerServerEvent('esx_streetfight:redReady')
                waitRedPlayer = false
            elseif distance > MAXDISTANCE then
                NextFighter()
                waitRedPlayer = false
            end
            if IsPedDeadOrDying(player) ~= false then
                CallCops(player)
                NextFighter()
                waitRedPlayer = false
            end
        end
    end
)

AddEventHandler('esx_streetfight:fightTimer',
    function()
        local initTimer = GetNetworkTime() + 30000
        timer = 30000
        ESX.ShowNotification("~y~Attendez qu'on pari sur vous~w~, pour gagner de l'~g~argent.")
        while timer > 0 do
            local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
            local player = PlayerPedId()
            local playerPos = GetEntityCoords(player)
            local distance = GetDistanceBetweenCoords(playerPos, RING.x, RING.y, RING.z, true)
            Citizen.Wait(0)
            if distance > RINGRANGE then
                NextFighter()
            end
            if IsPedDeadOrDying(player) ~= false then
                CallCops(player)
                NextFighter()
            end
            if timer > 5000 then
                DrawHudText('Attendez les paris!', {255, 191, 0, 255}, 0.23, 0.05, 2.0, 2.0)
                if (closestPlayer ~= -1) and (closestDistance <= 20.0) then
                    TriggerServerEvent('esx_streetfight:canBet', GetPlayerServerId(closestPlayer))
                end
            end
            if timer < 4000 then
                DrawHudText(math.floor(timer / 1000), {255, 191, 0, 255}, 0.43, 0.05, 3.0, 3.0)
                if (closestPlayer ~= -1) and (closestDistance <= 20.0) then
                    TriggerServerEvent('esx_streetfight:cantBet', GetPlayerServerId(closestPlayer))
                end
            end
            if timer <= 1000 then
                DrawHudText('Fight !', {255, 191, 0, 255}, 0.33, 0.05, 3.0, 3.0)
            end
            timer = initTimer - GetNetworkTime()
        end
        StartFighting()
    end
)

AddEventHandler('esx_streetfight:noMoreFighter',
    function()
        waitBluePlayer = false
        waitRedPlayer = false
        fightStarted = false
        timer = 0
    end
)

AddEventHandler('esx_streetfight:looser',
    function()
        local hudTimer = 300
        while hudTimer > 0 do
            Citizen.Wait(0)
            hudTimer = hudTimer - 1
            DrawHudText('Perdu!', {255, 191, 0, 255}, 0.33, 0.05, 3.0, 3.0)
        end
    end
)

AddEventHandler('esx_streetfight:winner',
    function()
        local hudTimer = 300
        while hudTimer > 0 do
            Citizen.Wait(0)
            hudTimer = hudTimer - 1
            DrawHudText('Gagné!', {255, 191, 0, 255}, 0.33, 0.05, 3.0, 3.0)
        end
    end
)

AddEventHandler('esx_streetfight:canBet',
    function()
        ESX.ShowNotification('Prenez les ~g~paris~w~! Un ~y~combat~w~ va commencer!')
        canBet = true
    end
)

AddEventHandler('esx_streetfight:cantBet',
    function()
        local player = PlayerPedId()
        ESX.ShowNotification('Le ~y~combat~w~ commence, tout les ~g~paris~w~ sont ~r~fermés~w~!')
        canBet = false
    end
)

AddEventHandler('esx_streetfight:callGang',
    function()
        for _, model in pairs(Gang.models) do
            wantedPlayer = PlayerPedId()
            if model ~= nil then
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Citizen.Wait(1)
                end
                SpawnedGang = CreatePed(2, model, Gang.pos, Gang.h, true, true)
                TaskCombatPed(SpawnedGang, GetPlayerPed(-1), 0, 16)
                SetModelAsNoLongerNeeded(wantedPlayer)
            end
        end
    end
)

function RunThread()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if canBet then
                DrawText3D(BLUECORNER.x, BLUECORNER.y, BLUECORNER.z +1.5, '~b~Coin Bleu', 0.4)
                DrawText3D(REDCORNER.x, REDCORNER.y, REDCORNER.z +1.5, '~r~Coin Rouge', 0.4)
                DrawMarker(29, REDCORNER.x, REDCORNER.y, REDCORNER.z +2, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 1.5, 255, 0, 0, 120, false, true, 2, true, false, false, false)
                DrawMarker(29, BLUECORNER.x, BLUECORNER.y, BLUECORNER.z +2, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 1.5, 0, 0, 255, 120, false, true, 2, true, false, false, false)
                DrawHudText('Prenez les paris!', {255, 191, 0, 255}, 0.24, 0.05, 2.0, 2.0)
            end
        end
    end)
end

function OpenBookmakerMenu()
    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open(
        'default',
        GetCurrentResourceName(),
        'open_menu',
        {
            title = 'Bookmaker',
            elements = {
                {label = 'Combattre', value = 'fight'},
                {label = 'Parier', value = 'bet'},
                {label = 'Récupérer les gains', value = 'payement'}
            }
        },
        function(data, menu)
            local val = data.current.value
            if val == 'fight' then
                ESX.UI.Menu.Open(
                    'default',
                    GetCurrentResourceName(),
                    'validation',
                    {
                        title = 'Vous voulez combattre?',
                        align = 'top-left',
                        elements = {
                            {label = 'Non', value = 'no'},
                            {label = 'Oui', value = 'yes'}
                        }
                    },
                    function(data2, menu2)
                        if data2.current.value == 'yes' then
                            TriggerServerEvent('esx_streetfight:register')
                            ESX.UI.Menu.CloseAll()
                        elseif data2.current.value == 'no' then
                            ESX.UI.Menu.CloseAll()
                        end
                    end,
                    function(data2, menu2)
                        menu2.close()
                    end
                )
                menu.close()
            elseif val == 'bet' then
                OpenBetMenu()
                menu.close()
            elseif val == 'payement' then
                TriggerServerEvent('esx_streetfight:givePayement')
                menu.close()
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end

function OpenBetMenu()
    ESX.UI.Menu.CloseAll()
    ESX.TriggerServerCallback(
        'esx_streetfight:betOpen',
        function(betOpen)
            if betOpen then
                ESX.UI.Menu.Open(
                    'default',
                    GetCurrentResourceName(),
                    'open_menu',
                    {
                        title = 'Sur qui voulez-vous parier?',
                        elements = {
                            {label = 'Coin Bleu', value = 'blue'},
                            {label = 'Coin Rouge', value = 'red'}
                        }
                    },
                    function(data, menu)
                        local betOnFighter = data.current.value
                        ESX.UI.Menu.Open(
                            'default',
                            GetCurrentResourceName(),
                            'validation',
                            {
                                title = 'Combien?',
                                align = 'top-left',
                                elements = {
                                    {label = '100$', value = '100'},
                                    {label = '1000$', value = '1000'},
                                    {label = '10000$', value = '10000'}
                                }
                            },
                            function(data2, menu2)
                                if data2.current.value == '100' then
                                    if not fightStarted then
                                        TriggerServerEvent('esx_streetfight:bet', 100, betOnFighter)
                                    end
                                    ESX.UI.Menu.CloseAll()
                                elseif data2.current.value == '1000' then
                                    if not fightStarted then
                                        TriggerServerEvent('esx_streetfight:bet', 1000, betOnFighter)
                                    end
                                    ESX.UI.Menu.CloseAll()
                                elseif data2.current.value == '10000' then
                                    if not fightStarted then
                                        TriggerServerEvent('esx_streetfight:bet', 10000, betOnFighter)
                                    end
                                    ESX.UI.Menu.CloseAll()
                                end
                            end,
                            function(data2, menu2)
                                menu2.close()
                            end
                        )
                        menu.close()
                    end,
                    function(data, menu)
                        menu.close()
                    end
                )
            else
                ESX.ShowHelpNotification('~r~Les paris sont fermés!')
            end
        end
    )
end

function NextFighter()
    TriggerServerEvent('esx_streetfight:nextFighter')
    fightStarted = false
    timer = 0
end

function StartFighting()
    local player = PlayerPedId()
    SetEntityHealth(player, 200)
    ESX.ShowNotification('Ne tuez pas votre ~r~adversaire~w~ sinon ~r~vous ne gagnerez rien!')
    fightStarted = true
    while fightStarted == true do
        local playerHealth = GetEntityHealth(player)
        local playerPos = GetEntityCoords(player)
        local distance = GetDistanceBetweenCoords(playerPos, RING.x, RING.y, RING.z, true)
        if playerHealth < 130 then
            if IsPedDeadOrDying(player) == false then
                Knockout(player)
                NextFighter()
            else
                CallCops(player)
                NextFighter()
            end
        end
        if distance > RINGRANGE then
            NextFighter()
        end
        Citizen.Wait(0)
    end
end

function Knockout(looser)
    SetPedToRagdoll(looser, 1000, 1000, 0, 0, 0, 0)
end

function CallCops(deadPlayer)
    local coords = GetEntityCoords(deadPlayer)
    TriggerServerEvent('esx_alertpolice:callCops', coords, '~r~Signalement:~w~ Un combat de rue à mal tourner.')
end

function DrawHudText(text, colour, coordsx, coordsy, scalex, scaley)
    local colourr, colourg, colourb, coloura = table.unpack(colour)
    SetTextFont(7)
    SetTextProportional(7)
    SetTextScale(scalex, scaley)
    SetTextColour(colourr, colourg, colourb, coloura)
    SetTextDropshadow(0, 0, 0, 0, coloura)
    SetTextEdge(1, 0, 0, 0, coloura)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(coordsx, coordsy)
end

function DrawText3D(x, y, z, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())
    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(1)
    SetTextColour(255, 255, 255, 215)
    AddTextComponentString(text)
    DrawText(_x, _y)
end