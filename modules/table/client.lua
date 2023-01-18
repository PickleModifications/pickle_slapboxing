local MenuOpen = false
TableEntities = {}

function GetTableEntity(index)
    return TableEntities[index]
end

function CreateTableEntity(index)
    local data = GlobalState.SlapTables[index]
    local cfg = Config.SlapTables[data.name]
    local prop = CreateProp(cfg.model, data.coords.x, data.coords.y, data.coords.z, false, true, true)
    FreezeEntityPosition(prop, false)
    SetEntityAsMissionEntity(prop, 1, 1)
    SetEntityHeading(prop, data.heading)
    FreezeEntityPosition(prop, true)
    TableEntities[index] = prop
    return prop
end

function RemoveTableEntity(index)
    DeleteEntity(TableEntities[index])
    TableEntities[index] = nil
end

function AttemptJoinMatch(index, team)    
    TriggerServerEvent("pickle_slapboxing:attemptJoinMatch", index, team)
end

function AttemptBetMatch(index, team)
    local input = lib.inputDialog(_L("bet_menu_title", _L(team)), {_L("bet_menu_one")})
    if not input or not tonumber(input[1]) then return end
    TriggerServerEvent("pickle_slapboxing:attemptBetMatch", index, team, tonumber(input[1]))
end

function AttemptRemoveTable(index)
    TriggerServerEvent("pickle_slapboxing:removeTable", index)
end

function TableMenu(index) 
    local data = GlobalState.SlapTables[index]
    if not data then return end
    MenuOpen = true
    lib.registerContext({
        id = 'pickle_slapboxing:tableMenu',
        title = _L("table_menu_title"),
        menu = 'example_menu',
        onExit = function() 
            MenuOpen = false
        end,
        options = {
            [_L("table_fighter_title", 1, _L("home"), (data.bets.home[serverID] or 0))] = {
                description = data.sides.home and _L("table_fighter", data.sides.home.source) or _L("table_fighter_none"),
                onSelect = function(args)
                    if data.bets.home[serverID] then 
                        ShowNotification(_L("bet_already"))
                        return 
                    end
                    lib.hideContext()
                    MenuOpen = false
                    AttemptBetMatch(index, "home")
                end,
            },
            [_L("table_fighter_title", 2, _L("away"), (data.bets.away[serverID] or 0))] = {
                description = data.sides.away and _L("table_fighter", data.sides.away.source) or _L("table_fighter_none"),
                onSelect = function(args)
                    if data.bets.home[serverID] then 
                        ShowNotification(_L("bet_already"))
                        return 
                    end
                    lib.hideContext()
                    MenuOpen = false
                    AttemptBetMatch(index, "away")
                end,
            },
            [_L("table_remove")] = {
                description =_L("table_remove_desc"),
                onSelect = function(args)
                    lib.hideContext()
                    MenuOpen = false
                    AttemptRemoveTable(index)
                end,
            },
        }
    })
    lib.showContext('pickle_slapboxing:tableMenu')
end

function InteractPoint(index, pointID)
    if pointID == "home" or pointID == "away" then 
        AttemptJoinMatch(index, pointID)
    elseif pointID == "menu" then
        TableMenu(index)
    end
end

CreateThread(function() 
    while true do 
        local wait = 1000
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        local displayedMatch = nil
        local garbage = GlobalState.SlapTables
        for k,v in pairs(GlobalState.SlapTables) do 
            local coords = v.coords
            local dist = #(pcoords - coords)
            if dist < 20.0 then
                wait = 0
                local entity = GetTableEntity(k)
                if not entity then 
                    entity = CreateTableEntity(k)
                end
                if dist < 10.0 and v.activeMatch then
                    displayedMatch = k
                end
                local cfg = Config.SlapTables[v.name]
                if not v.activeMatch and not MenuOpen then
                    for a,b in pairs(cfg.points) do
                        local _coords = GetOffsetFromEntityInWorldCoords(entity, b.x, b.y, b.z)
                        local _dist = #(pcoords - _coords)
                        if a == "menu" then 
                            DrawMarker(1, _coords.x, _coords.y, _coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, v.heading - 90.0, 0.15, 0.15, 0.15, 255, 255, 255, 127, false, false)
                            if _dist < 0.5 and not ShowHelpNotification(_L("table_interact_menu")) and IsControlJustPressed(1, 51) then
                                InteractPoint(k, a)
                            end
                        elseif (not v.sides or not v.sides[a]) then
                            DrawMarker(1, _coords.x, _coords.y, _coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, v.heading, 0.15, 0.15, 0.15, 255, 0, 0, 127, false, false)
                            if _dist < 0.5 and not ShowHelpNotification(_L("table_interact_".. a)) and IsControlJustPressed(1, 51) then
                                InteractPoint(k, a)
                            end
                        end
                    end
                end
            elseif GetTableEntity(k) then 
                RemoveTableEntity(k)
            end
        end
        DisplayHandler(displayedMatch)
        Wait(wait)
    end
end)

RegisterNetEvent("pickle_slapboxing:destroyTable", function(index)
    Wait(1000)
    RemoveTableEntity(index)
end)

lib.callback.register('pickle_slapboxing:requestPlayerData', function(offset)
    local ped = PlayerPedId()
    return {coords = GetEntityCoords(ped), heading = GetEntityHeading(ped), offset = GetOffsetFromEntityInWorldCoords(ped, offset.x, offset.y, offset.z)}
end)