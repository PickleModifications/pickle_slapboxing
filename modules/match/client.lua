local MATCH_STATUS = {}
function StartMatch()
    TriggerServerEvent("pickle_slapboxing:attemptStartMatch")
end

function LeaveMatch()
    TriggerServerEvent("pickle_slapboxing:attemptLeaveMatch")
end

function SlapPlayer()
    if MATCH_STATUS.activeProcess then return end
    MATCH_STATUS.activeProcess = true
    local slapping = true
    local presses = 1
    local lastPress = GetGameTimer()
    CreateThread(function()
        lib.progressCircle({duration = Config.Slapping.SlappingLength, position = 'middle'})
        slapping = false
    end)
    while slapping do 
        ShowHelpNotification(_L("table_match_spam"))
        if IsControlJustPressed(1, 51) then 
            local time = GetGameTimer()
            local timeDist = (lastPress - time) * -1.0
            if timeDist >= Config.Slapping.MinPressDist then 
                presses = presses + 1
            end
            lastPress = GetGameTimer()
        end
        Wait(0)
    end
    Wait(1000)
    if not (lib.skillCheck({areaSize = Config.Slapping.SkillSize, speedMultiplier = (presses/Config.Slapping.MaxPresses) * Config.Slapping.SkillSpeed})) then 
        presses = 0
    end
    TriggerServerEvent("pickle_slapboxing:attemptSlapPlayer", presses)
    SetTimeout(1000, function() 
        MATCH_STATUS.activeProcess = false
    end)
end

function CreateMatchCam(entity, offset, heading)
    local pos, heading = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z), GetEntityHeading(entity) - heading
    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, 0.0, 0.00, heading, 45.00, false, 0)
	SetCamActive(cam, true)
	RenderScriptCams(true, true, 1, true, true)
    return cam
end

function DeleteMatchCam(cam)
	SetCamActive(cam, false)
	RenderScriptCams(false, true, 1, true, true)
    DestroyCam(cam) 
end

function DisableControls()
    for i=1, 298 do 
        if i ~= 51 and i~= 177 then
           DisableControlAction(0, i, true)
        end
    end
end

function MatchThread(index, team)
    local otherTeam = (team == "home" and "away" or "home")
    CreateThread(function() 
        local data = GlobalState.SlapTables[index]
        if not data then return end
        local cfg = Config.SlapTables[data.name]
        local cam = CreateMatchCam(GetTableEntity(index), cfg.camera.offset, cfg.camera.heading)
        while MATCH_STATUS.index == index and MATCH_STATUS.team == team do 
            if not MATCH_STATUS.performingTask then
                local data = GlobalState.SlapTables[index]
                if not data then
                    print("Table deleted, stopping match thread.")
                    break 
                end
                local ped = PlayerPedId()
                local pcoords = GetEntityCoords(ped)
                local dist = #(data.coords - pcoords)
                if (dist > 10.0 or IsEntityDead(ped)) then 
                    LeaveMatch()
                    break
                elseif data.activeMatch then 
                    if data.turn == otherTeam then 
                        ShowHelpNotification(_L("table_match_waitslap"))
                    elseif not ShowHelpNotification(_L("table_match_slap")) and IsControlJustPressed(1, 51) then
                        SlapPlayer() 
                    end 
                elseif data.sides[otherTeam] then
                    ShowHelpNotification(_L("table_interact_start"))
                    if IsControlJustPressed(1, 51) then
                        StartMatch()
                    elseif IsControlJustPressed(1, 177) then 
                        LeaveMatch()
                        break
                    end
                elseif not ShowHelpNotification(_L("table_match_wait")) and IsControlJustPressed(1, 177) then
                    LeaveMatch()
                    break
                end
            end
            DisableControls()
            Wait(0)
        end
        DeleteMatchCam(cam)
    end)    
end

RegisterNetEvent("pickle_slapboxing:joinMatch", function(index, team) 
    local data = GlobalState.SlapTables[index]
    local cfg = Config.SlapTables[data.name]
    local point = cfg.points[team]
    local ped = PlayerPedId()
    local entity = GetTableEntity(index)
    local coords = GetOffsetFromEntityInWorldCoords(entity, point.x, point.y, point.z)
    ClearPedTasksImmediately(ped)
    SetEntityCoords(ped, coords.x, coords.y, coords.z - 0.75)
    SetEntityHeading(ped, data.heading - (team == "home" and 0.0 or 180.0 ))
    FreezeEntityPosition(ped, true)    
    MATCH_STATUS.index = index
    MATCH_STATUS.team = team
    MatchThread(index, team)
end)

RegisterNetEvent("pickle_slapboxing:leaveMatch", function(index, team) 
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    MATCH_STATUS = {}
end)

RegisterNetEvent("pickle_slapboxing:animationEvent", function(name)
    local ped = PlayerPedId()
    local reset = true
    ClearPedTasksImmediately(ped)
    if not MATCH_STATUS.performingTask then 
        MATCH_STATUS.performingTask = true
    else
        reset = false
    end
    if name == "slap" then 
        Wait(200)
        PlayAnim(ped, "melee@unarmed@streamed_core_fps", "plyr_takedown_front_slap", -8.0, 8.0, -1, 1, 1.0)
        Wait(2000)
        ClearPedTasks(ped)
    elseif name == "slapped" then 
        Wait(400)
        PlayAnim(ped, "melee@unarmed@streamed_core", "melee_damage_left", -8.0, 8.0, -1, 1, 1.0)
        Wait(1500)
        ClearPedTasks(ped)
    elseif name == "knockout" then 
        PlayAnim(ped, "melee@unarmed@streamed_core", "victim_takedown_front_uppercut", -8.0, 8.0, -1, 1, 1.0)
        Wait(2000)
        SetPedToRagdoll(GetPlayerPed(-1), 1000, 1000)
    end
    if reset then 
        MATCH_STATUS.performingTask = false
    end
end)

RegisterNetEvent("pickle_slapboxing:death", function()
    SetEntityHealth(PlayerPedId(), 0)
end)