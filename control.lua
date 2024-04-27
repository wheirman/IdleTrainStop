function Init()
    global.TrainStop = {}
    global.TrainStopName = "Idle Stop"
    global.TrainList = {}
    global.StationList = nil
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

function CreateStationList()
    global.StationList = {}
    for _,surface in pairs(game.surfaces) do
        local stations = surface.find_entities_filtered{type='train-stop'}
        for _, entity in pairs(stations) do
            global.StationList[entity.unit_number] = entity
        end
    end
end

function ON_INIT()
    Init()
    EnableIdleTrainStop()
    CreateTrainList()
    CreateStationList()
end
script.on_init(ON_INIT)

function ON_BUILT_ENTITY(event)
    local entity = event.created_entity or event.entity
    if entity and entity.valid then
        if entity.name == "idle-train-stop" then
            table.insert(global.TrainStop,entity)
            entity.backer_name = global.TrainStopName
        elseif entity.name == "train-stop" then
            global.StationList[entity.unit_number] = entity
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
        elseif entity.name == "train-stop" then
            global.StationList[entity.unit_number] = nil
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

function GetTrainNextStation(train)
    if train.schedule == nil then return nil end
    if train.schedule.current == #train.schedule.records then
        return train.schedule.records[1].station
    else
        return train.schedule.records[train.schedule.current + 1].station
    end
end

function IsTrainStationDisabled(station)
    local found = false
    for _, entity in pairs(global.StationList) do
        if entity ~= nil and entity.backer_name == station then
            if entity.get_control_behavior() == nil or not entity.get_control_behavior().disabled then
                return false
            end
            found = true
        end
    end
    if found then
        -- Station with this name found but none were enabled
        return true
    else
        -- Station with this name not found, might mean global.StationList is not up-to-date?
        return false
    end
end

function PERIODIC()
    if global.TrainStop then
        if global.StationList == nil then
            -- Migration to v0.4.0+: create global.StationList if it does not yet exist
            CreateStationList()
        end
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
                --or (train.state == defines.train_state.wait_station and IsTrainStationDisabled(GetTrainNextStation(train)))
            then
                --game.print(string.format('Sending idle [train=%d] to depot', GetTrainNumber(train)))
                AddSchedule(train)
            end

            ::continue::
        end
    end
end
script.on_nth_tick(600,PERIODIC)
