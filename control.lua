function Init()
    global.TrainStop = {}
    global.TrainStopName = "Idle Stop"
    global.TrainList = {}
end

function EnableIdleTrainStop()
    for _,force in pairs(game.forces) do
        local tech = force.technologies['automated-rail-transportation']
        if tech and tech.researched then 
            force.recipes['idle-train-stop'].enabled = true
        end
    end
end

function CreateTrainList()
    for _,surface in pairs(game.surfaces) do
        local trains = surface.get_trains()
        for _,train in pairs(trains) do
            global.TrainList[train.id] = train
        end
    end
end

function ON_INIT()
    Init()
    EnableIdleTrainStop()
    CreateTrainList()
end
script.on_init(ON_INIT)

function CheckTrainList()
    if global.TrainList then
        for i,train in pairs(global.TrainList) do
            if train and train.valid then
                ::pass::
            else
                global.TrainList[i] = nil
            end
        end
    end
end

function ON_BUILT_ENTITY(event)
    local entity = event.created_entity or event.entity
    if entity and entity.valid then
        if entity.name == "idle-train-stop" then
            table.insert(global.TrainStop,entity)
            entity.backer_name = global.TrainStopName
        end
    end
end
script.on_event({defines.events.on_built_entity,defines.events.on_robot_built_entity,defines.events.script_raised_built},ON_BUILT_ENTITY)
    
function ON_REMOVE_ENTITY(event)
    local entity = event.entity
    if entity and entity.valid then
        if entity.name == "idle-train-stop" then
            for i,stop in pairs(global.TrainStop) do
                if stop == entity then
                    table.remove(global.TrainStop,i)
                    break
                end
            end
        end
    end
end
script.on_event({defines.events.on_pre_player_mined_item,defines.events.on_robot_pre_mined,defines.events.on_entity_died,defines.events.script_raised_destroy},ON_REMOVE_ENTITY)

function ON_ENTITY_RENAMED(event)
    if not event.by_script and event.entity.name == "idle-train-stop" then
        global.TrainStopName = event.entity.backer_name
        for i,stop in pairs(global.TrainStop) do
            if stop and stop.valid then
                stop.backer_name = global.TrainStopName
            else
                table.remove(global.TrainStop,i)
            end
        end
    end
end
script.on_event(defines.events.on_entity_renamed,ON_ENTITY_RENAMED)

function ON_TRAIN_CREATED(event)
    local train = event.train
    local old_train_id_1 = event.old_train_id_1
    local old_train_id_2 = event.old_train_id_2

    global.TrainList[train.id] = train

    if old_train_id_1 then
        global.TrainList[old_train_id_1] = nil
    end
    if old_train_id_2 then
        global.TrainList[old_train_id_2] = nil
    end
end
script.on_event(defines.events.on_train_created,ON_TRAIN_CREATED)

function AddSchedule(train)
    local schedule = train.schedule or {records = {}, current = 1}

    local record = {station = global.TrainStopName, temporary = true}
    table.insert(schedule.records,schedule.current,record)
    train.schedule = schedule
end

function GetTrainNumber(train)
    if train.locomotives["front_movers"] then
        return train.locomotives["front_movers"][1].unit_number
    elseif train.locomotives["back_movers"] then
        return train.locomotives["back_movers"][1].unit_number
    end
    return train.id
end

function PERIODIC()
    if global.TrainStop then
        for i,train in pairs(global.TrainList) do
            if not train.valid then
                global.TrainList[i] = nil
                goto continue
            end
            
            if train.manual_mode then goto continue end

            if train.schedule == nil then goto continue end

            for _,record in pairs(train.schedule.records) do
                if record.station == global.TrainStopName then goto continue end
            end

            if train.station and train.station.backer_name == global.TrainStopName then goto continue end

            if train.state == defines.train_state.no_schedule
                or train.state == defines.train_state.no_path
                or train.state == defines.train_state.destination_full
            then
                --game.print(string.format('Sending idle [train=%d] to depot', GetTrainNumber(train)))
                AddSchedule(train)
            end
    
            ::continue::
        end    
    end
end
script.on_nth_tick(600,PERIODIC)
