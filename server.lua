ESX = nil

local bluePlayer = nil
local redPlayer = nil
local queuePlayer = nil
local bluePlayerReady = false
local redPlayerReady = false
local bluePlayerWin = 1
local redPlayerWin = 1
local waitPlayerReady = false
local waitNextRound = false
local fightStarted = false
local canBet = false
local totalBetOnBlue = 0
local totalBetOnRed = 0
local rewardBlue = 0
local rewardRed = 0
local Bets = {}

TriggerEvent('esx:getSharedObject',
    function(obj)
        ESX = obj
    end
)

RegisterServerEvent('esx_streetfight:register')
RegisterServerEvent('esx_streetfight:blueReady')
RegisterServerEvent('esx_streetfight:redReady')
RegisterServerEvent('esx_streetfight:nextFighter')
RegisterServerEvent('esx_streetfight:canBet')
RegisterServerEvent('esx_streetfight:bet')

RegisterServerEvent('esx_streetfight:givePayement')

AddEventHandler('esx_streetfight:register',
    function()
        local _source = source
        waitPlayerReady = true
        while waitPlayerReady do
            Wait(0)
            if bluePlayer == nil then
                bluePlayer = _source
                TriggerClientEvent('esx_streetfight:gotoBlueCorner', bluePlayer)
            elseif (bluePlayer ~= nil) and (redPlayer == nil) then
                if (_source ~= bluePlayer) then
                    redPlayer = _source
                    TriggerClientEvent('esx_streetfight:gotoRedCorner', redPlayer)
                end
            elseif (bluePlayer ~= nil) and (redPlayer ~= nil) and (queuePlayer == nil) then
                if (_source ~= bluePlayer) and (_source ~= redPlayer) then
                    queuePlayer = _source
                    TriggerClientEvent('esx:showNotification', queuePlayer, 'Attendez la fin du ~y~combat~w~, vous êtes le ~g~prochain~w~!')
                end
            elseif (bluePlayer ~= nil) and (redPlayer ~= nil) and (queuePlayer ~= nil) then
                if (_source ~= bluePlayer) and (_source ~= redPlayer) and (_source ~= queuePlayer) then
                    TriggerClientEvent('esx:showNotification', _source, "~r~J'ai déjà assez de combattant~w~, revenez au prochain ~y~combat~w~!")
                end
            elseif fightStarted then
                waitPlayerReady = false
            end
            if bluePlayerReady and redPlayerReady then
                TriggerClientEvent('esx_streetfight:fightTimer', bluePlayer)
                TriggerClientEvent('esx_streetfight:fightTimer', redPlayer)
                fightStarted = true
                bluePlayerReady = false
                redPlayerReady = false
                waitPlayerReady = false
            end
        end
    end
)

AddEventHandler('esx_streetfight:blueReady',
    function()
        bluePlayerReady = true
    end
)

AddEventHandler('esx_streetfight:redReady',
    function()
        redPlayerReady = true
    end
)

AddEventHandler('esx_streetfight:nextFighter',
    function()
        local _source = source
        fightStarted = false
        if _source == bluePlayer then
            payement('red')
            redReward()
            nextBlue()
        elseif _source == redPlayer then
            payement('blue')
            blueReward()
            nextRed()
        end
        if (redPlayer ~= nil) and (bluePlayer ~= nil) then
            nextRound()
        end
        totalBetOnBlue = 0
        totalBetOnRed = 0
    end
)

AddEventHandler('esx_streetfight:canBet',
    function(closestPlayer)
        local bettors = closestPlayer
        if bettors ~= bluePlayer and bettors ~= redPlayer then
            TriggerClientEvent('esx_streetfight:canBet', bettors)
        end
        canBet = true
    end
)

AddEventHandler('esx_streetfight:bet',
    function(betAmount, betOnFighter)
        local _source = source
        local xPlayer = ESX.GetPlayerFromId(_source)
        local bettorName = GetPlayerName(_source)
        local playerBlack = xPlayer.getAccount('black_money')
        local betWin = 0
        if playerBlack.money >= betAmount then
            if (Bets[bettorName] == nil) then
                local payement = 0
                local score = 0
                if betOnFighter == 'blue' then
                    totalBetOnBlue = totalBetOnBlue + betAmount
                    betWin = betAmount + (betAmount / bluePlayerWin)
                    registerBet(bettorName, _source, betWin, payement, score, betOnFighter)
                    TriggerClientEvent('esx:showNotification', _source, 'Votre ~g~pari~w~ a été enregistré!')
                    TriggerClientEvent('esx:showNotification', bluePlayer, 'Un ~g~pari~w~ a été enregistré sur vous!')
                elseif betOnFighter == 'red' then
                    totalBetOnRed = totalBetOnRed + betAmount
                    betWin = betAmount + (betAmount / redPlayerWin)
                    registerBet(bettorName, _source, betWin, payement, score, betOnFighter)
                    TriggerClientEvent('esx:showNotification', _source, 'Votre ~g~pari~w~ a été enregistré!')
                    TriggerClientEvent('esx:showNotification', redPlayer, 'Un ~g~pari~w~ a été enregistré sur vous!')
                end
                xPlayer.removeAccountMoney('black_money', betAmount)
            elseif (Bets[bettorName] ~= nil) and (Bets[bettorName].bet == 0) then
                local payement = Bets[bettorName].payement
                local score = Bets[bettorName].score
                if betOnFighter == 'blue' then
                    totalBetOnBlue = totalBetOnBlue + betAmount
                    betWin = betAmount + (betAmount / bluePlayerWin)
                    registerBet(bettorName, _source, betWin, payement, score, betOnFighter)
                    TriggerClientEvent('esx:showNotification', _source, 'Votre ~g~pari~w~ a été enregistré!')
                    TriggerClientEvent('esx:showNotification', bluePlayer, 'Un ~g~pari~w~ a été enregistré sur vous!')
                elseif betOnFighter == 'red' then
                    totalBetOnRed = totalBetOnRed + betAmount
                    betWin = betAmount + (betAmount / redPlayerWin)
                    registerBet(bettorName, _source, betWin, payement, score, betOnFighter)
                    TriggerClientEvent('esx:showNotification', _source, 'Votre ~g~pari~w~ a été enregistré!')
                    TriggerClientEvent('esx:showNotification', redPlayer, 'Un ~g~pari~w~ a été enregistré sur vous!')
                end
                xPlayer.removeAccountMoney('black_money', betAmount)
            else
                TriggerClientEvent('esx:showNotification', _source, '~r~Vous avez déjà parié!')
            end
        else
            TriggerClientEvent('esx:showNotification', _source, "~r~Vous n'avez pas assez d'argent sale")
        end
    end
)

AddEventHandler('esx_streetfight:givePayement',
    function()
        local _source = source
        local xPlayer = ESX.GetPlayerFromId(_source)
        local sourceName = GetPlayerName(_source)
        if Bets[sourceName] == nil then
            TriggerClientEvent('esx:showNotification', _source, '~r~Vous n\'avez aucun pari à récupérer')
        end
        for i, val in pairs(Bets) do
            if val.player == _source then
                if val.score <= 3 then
                    TriggerClientEvent('esx:showNotification', _source, 'Vous avez gagné' .. val.payement .. '$')
                    xPlayer.addAccountMoney('black_money', val.payement)
                else
                    TriggerClientEvent('esx:showNotification', _source, '~r~T\'essayes de m\'anarquer? T\'es mort!')
                    TriggerClientEvent('esx_streetfight:callGang')
                    val.wanted = true
                end
                val.payement = 0
            elseif val.payement == 0 then
                TriggerClientEvent('esx:showNotification', _source, '~r~Vous n\'avez aucun pari à récupérer')
            end
        end
    end
)

ESX.RegisterServerCallback('esx_streetfight:wanted',
    function(source, cb)
        local _source = source
        local bettorName = GetPlayerName(_source)
        if (Bets[bettorName] == nil) or (Bets[bettorName].wanted == false) then
            cb(false)
        else
            TriggerClientEvent('esx:showNotification', _source, '~r~Tu es fou de te ramener ici, on va te buter!')
            TriggerClientEvent('esx_streetfight:callGang')
            local xPlayers = ESX.GetPlayers()
            for i = 1, #xPlayers, 1 do
                local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
                if xPlayer.job.name == 'police' then
                    TriggerClientEvent('esx_streetfight:setcopblip', xPlayers[i], 137.81, -1325.28, 29.2)
                end
            end
            cb(true)
        end
    end
)

ESX.RegisterServerCallback('esx_streetfight:betOpen',
    function(source, cb)
        if canBet then
            cb(true)
        else
            cb(false)
        end
    end
)

function nextBlue()
    if redPlayer ~= nil then
        TriggerClientEvent('esx_streetfight:looser', bluePlayer)
        TriggerClientEvent('esx_streetfight:winner', redPlayer)
        bluePlayer = nil
        bluePlayerWin = 1
        redPlayerWin = redPlayerWin + 1
        if queuePlayer ~= nil then
            queuePlayer = bluePlayer
        else
            TriggerClientEvent('esx:showNotification', redPlayer, '~r~Plus personne ne veut se battre contre toi!')
            TriggerClientEvent('esx_streetfight:noMoreFighter', redPlayer)
            redPlayer = nil
        end
    end
end

function nextRed()
    if bluePlayer ~= nil then
        TriggerClientEvent('esx_streetfight:looser', redPlayer)
        TriggerClientEvent('esx_streetfight:winner', bluePlayer)
        redPlayer = nil
        redPlayerWin = 1
        bluePlayerWin = bluePlayerWin + 1
        if queuePlayer ~= nil then
            queuePlayer = redPlayer
        else
            TriggerClientEvent('esx:showNotification', bluePlayer, '~r~Plus personne ne veut se battre contre toi!')
            TriggerClientEvent('esx_streetfight:noMoreFighter', bluePlayer)
            bluePlayer = nil
        end
    end
end

function blueReward()
    local xPlayer = ESX.GetPlayerFromId(bluePlayer)
    if totalBetOnBlue > 0 then
        local betOnBlue = totalBetOnBlue / 10
        rewardBlue = betOnBlue * bluePlayerWin
        xPlayer.addAccountMoney('black_money', rewardBlue)
        TriggerClientEvent('esx:showNotification', bluePlayer, "Vous avez gagné ~g~"..rewardBlue.."~w~ $")
    else
        TriggerClientEvent('esx:showNotification', bluePlayer, "Il y n'avait aucun pari sur vous, ~r~vous n'avez rien gagné!")
    end
end

function redReward()
    local xPlayer = ESX.GetPlayerFromId(redPlayer)
    if totalBetOnRed > 0 then
        local betOnRed = totalBetOnRed / 10
        rewardRed = betOnRed * redPlayerWin
        xPlayer.addAccountMoney('black_money', rewardRed)
        TriggerClientEvent('esx:showNotification', redPlayer, "Vous avez gagné ~g~"..rewardRed.."~w~ $")
    else
        TriggerClientEvent('esx:showNotification', redPlayer, "Il y n'avait aucun pari sur vous, ~r~vous n'avez rien gagné!")
    end
end

function nextRound()
    waitNextRound = true
    while waitNextRound do
        Wait(0)
        TriggerClientEvent('esx_streetfight:gotoBlueCorner', bluePlayer)
        TriggerClientEvent('esx_streetfight:gotoRedCorner', redPlayer)
        if bluePlayerReady and redPlayerReady then
            TriggerClientEvent('esx_streetfight:fightTimer', bluePlayer)
            TriggerClientEvent('esx_streetfight:fightTimer', redPlayer)
            fightStarted = true
            bluePlayerReady = false
            redPlayerReady = false
            waitNextRound = false
        end
    end
end

function registerBet(bettorName, _source, betWin, payement, score, betOnFighter)
    Bets[bettorName] = {
        player = _source,
        bet = betWin,
        payement = payement,
        score = score,
        betOn = betOnFighter,
        wanted = false
    }
end

function payement(side)
    for i, val in pairs(Bets) do
        if val.betOn == side then
            val.payement = val.payement + val.bet
            if val.bet >= 5000 then
                val.score = val.score + 1
            end
            val.bet = 0
        end
        if val.betOn ~= side then
            val.score = 0
        end
    end
end