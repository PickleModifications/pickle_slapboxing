local CurrentDisplay = nil

function GetMatchStats(index)
    local data = GlobalState.SlapTables[index]
    if not data then return end
    if not data.activeMatch then return end
    return data.sides
end

function UpdateUI(stats) 
    SendNUIMessage({
        updateStats = true,
        value = stats
    })
end

function ToggleUI(index)
    if index then 
        local stats = GetMatchStats(index)
        if not stats then return end
        CurrentDisplay = index
        SendNUIMessage({
            toggleUI = true,
            value = {
                value = true,
                stats = stats,
                maxHealth = Config.Slapping.DefaultHealth
            }
        })
    else
        CurrentDisplay = index
        SendNUIMessage({
            toggleUI = true,
            value = {
                value = false
            }
        })
    end
end

function DisplayHandler(index)
    if index == CurrentDisplay then 
        return 
    end
    ToggleUI(index)
end

RegisterNetEvent("pickle_slapboxing:updateStats", function(index, stats)
    if index == CurrentDisplay then 
        UpdateUI(stats)
    end
end)