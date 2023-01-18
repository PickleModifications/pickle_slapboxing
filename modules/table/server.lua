SlapTables = {}
GlobalState.SlapTables = SlapTables

function GenerateIndex() 
    local index = os.time()
    repeat 
        index = os.time() .. "_" .. math.random(1, 1000)
    until not SlapTables[index]
    return index
end

function GenerateTableData(source, name, coords, heading, item)
    return {
        name = name,
        coords = coords, 
        heading = heading,
        source = source,
        item = item,
        activeMatch = false,
        bets = {
            home = {},
            away = {}
        },
        turn = "home",
        sides = {
            home = nil,
            away = nil
        }
    }
end

function CreateTable(source, name, coords, heading, item)
    local index = GenerateIndex()
    SlapTables[index] = GenerateTableData(source, name, coords, heading, item)
    GlobalState.SlapTables = SlapTables
    return index
end

function DestroyTable(index)
    SlapTables[index] = nil
    GlobalState.SlapTables = SlapTables
    TriggerClientEvent("pickle_slapboxing:destroyTable", -1, index)
end

RegisterNetEvent("pickle_slapboxing:removeTable", function(index) 
    local source = source
    local data = SlapTables[index]
    if data.sides.home or data.sides.away then 
        return
    end
    if Config.CanRemoveTable(source, SlapTables[index]) then 
        ShowNotification(source, _L("table_removed"))
        if SlapTables[index].item then 
            AddItem(source, SlapTables[index].item, 1)
        end
        DestroyTable(index)
    else
        ShowNotification(source, _L("table_fail_removed"))
    end
end)

for k,v in pairs(Config.Items) do 
    RegisterUsableItem(k, function(source)
        local ped = GetPlayerPed(source)
        local data = lib.callback.await('pickle_slapboxing:requestPlayerData', source, vector3(0.0, 1.0, -1.0))
        ShowNotification(source, _L("table_spawned"))
        CreateTable(source, v.table, data.offset, data.heading, k)
        RemoveItem(source, k, 1)
    end)
end