function GetPlayerMatch(source)
    local index, team
    for k,v in pairs(SlapTables) do 
        local sides = SlapTables[k].sides
        if sides["home"] and sides["home"].source == source then 
            team = "home"
            index = k
            break
        elseif sides["away"] and sides["away"].source == source then 
            team = "away"
            index = k
        end
    end
    return index, team
end

function RefundMatch(bets)
    local teams = {"home", "away"}
    for i=1, #teams do 
        for source, bet in pairs(bets[teams[i]]) do 
            AddItem(source, "money", bet)
            ShowNotification(source, _L("match_refund", bet))
        end
    end
end

function PayoutMatch(team, bets)
    local totals = {win = 0, lose = 0}
    local teams = {"home", "away"}
    for i=1, #teams do 
        for source, bet in pairs(bets[teams[i]]) do 
            if team == teams[i] then 
                totals.win = totals.win + bet
            else
                totals.lose = totals.lose + bet
                ShowNotification(source, _L("match_lose", bet))
            end
        end
    end
    for source, bet in pairs(bets[team]) do 
        local share = bet / totals.win
        local profit = totals.lose * share
        local reward = bet + profit
        ShowNotification(source, _L("match_win", reward))
        AddItem(source, "money", reward)
    end
end

function JoinMatch(source, index, pointID)
    for k,v in pairs(SlapTables[index].sides) do 
        if v == source then 
            return false
        end
    end
    SlapTables[index].sides[pointID] = {
        source = source,
        health = Config.Slapping.DefaultHealth
    } 
    GlobalState.SlapTables = SlapTables
    ShowNotification(source, _L("table_match_joined", pointID))
    TriggerClientEvent("pickle_slapboxing:joinMatch", source, index, pointID)
    return true
end

function LeaveMatch(source)
    local index, team = GetPlayerMatch(source)
    if index then 
        SlapTables[index].sides[team] = nil
        if SlapTables[index].activeMatch then 
            EndMatch(index)
        end
        GlobalState.SlapTables = SlapTables
    end
    ShowNotification(source, _L("table_match_left"))
    TriggerClientEvent("pickle_slapboxing:leaveMatch", source, index, team)
end

function StartMatch(source)
    local index, team = GetPlayerMatch(source)
    if not index then 
        return
    end
    local data = SlapTables[index]
    if data.activeMatch then 
        return
    end
    SlapTables[index].activeMatch = true
    GlobalState.SlapTables = SlapTables
end

function EndMatch(index)
    local data = SlapTables[index]
    if not data then return end
    local home, away = data.sides["home"], data.sides["away"]
    if home and home.health < 0 then -- Away Win.
        PayoutMatch("away", data.bets)
        local chance = math.random(1, 100)
        if chance < Config.Slapping.DeathChance then 
            TriggerClientEvent("pickle_slapboxing:death", home.source)
        end
    elseif away and away.health < 0 then -- Home Win.
        PayoutMatch("home", data.bets)
        local chance = math.random(1, 100)
        if chance < Config.Slapping.DeathChance then 
            TriggerClientEvent("pickle_slapboxing:death", away.source)
        end
    else -- Match Cancelled.
        RefundMatch(data.bets)
    end
    SlapTables[index] = GenerateTableData(data.source, data.name, data.coords, data.heading, data.item)
    GlobalState.SlapTables = SlapTables
    TriggerClientEvent("pickle_slapboxing:leaveMatch", home.source, index, "home")
    TriggerClientEvent("pickle_slapboxing:leaveMatch", away.source, index, "away")
end

function BetMatch(source, index, team, bet)
    local data = SlapTables[index]
    if not data then return end
    if data.activeMatch then 
        ShowNotification(source, _L("bet_active"))
        return 
    end    
    if data.bets[team][source] then 
        ShowNotification(source, _L("bet_already"))
        return 
    end
    local cash = Search(source, "money")
    if bet > cash then 
        ShowNotification(source, _L("bet_not_afford"))
        return 
    end
    RemoveItem(source, "money", bet)
    ShowNotification(source, _L("bet_placed", bet, _L(team)))
    SlapTables[index].bets[team][source] = bet
end

function SlapPlayer(source, power)
    local index, team = GetPlayerMatch(source)
    if not index then 
        return
    end
    local data = SlapTables[index]
    local otherTeam = (team == "home" and "away" or "home")
    if not data.activeMatch then 
        return
    end
    SlapTables[index].sides[otherTeam].health = SlapTables[index].sides[otherTeam].health - (power * Config.Slapping.MaxDamage)
    SlapTables[index].turn = otherTeam
    GlobalState.SlapTables = SlapTables
    TriggerClientEvent("pickle_slapboxing:animationEvent", SlapTables[index].sides[team].source, "slap")
    if power > 0.0 then 
        if SlapTables[index].sides[otherTeam].health <= 0 then 
            TriggerClientEvent("pickle_slapboxing:animationEvent", SlapTables[index].sides[otherTeam].source, "knockout")
            EndMatch(index)
        else
            TriggerClientEvent("pickle_slapboxing:animationEvent", SlapTables[index].sides[otherTeam].source, "slapped")
        end
    end
    TriggerClientEvent("pickle_slapboxing:updateStats", -1, index, SlapTables[index].sides)
end

RegisterNetEvent("pickle_slapboxing:attemptJoinMatch", function(index, pointID) 
    local source = source
    local data = SlapTables[index]
    if not data then 
        return
    end
    if data.sides[pointID] then 
        ShowNotification(source, _L("table_match_occupied", pointID))
        return
    end
    JoinMatch(source, index, pointID)
end)

RegisterNetEvent("pickle_slapboxing:attemptStartMatch", function() 
    local source = source
    StartMatch(source)
end)

RegisterNetEvent("pickle_slapboxing:attemptLeaveMatch", function() 
    local source = source
    LeaveMatch(source)
end)

RegisterNetEvent("pickle_slapboxing:attemptSlapPlayer", function(presses) 
    local source = source
    local power = (presses / Config.Slapping.MaxPresses)
    if power > 1.0 then 
        if power > 2.0 then 
            power = 0.01 -- Punish cheaters with the weakest slap of all time.
        else
            power = 1.0
        end
    end
    SlapPlayer(source, power)
end)

RegisterNetEvent("pickle_slapboxing:attemptBetMatch", function(index, team, amount)
    local source = source
    BetMatch(source, index, team, amount)
end)

AddEventHandler('playerDropped', function (reason)
    local source = source
    local index, team = GetPlayerMatch(source)
    if index then 
        EndMatch(index)
    end
end)