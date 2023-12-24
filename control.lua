require("lib")

local train_ignore_list = {}


function Init()
	global.TrainStop = {}
	global.TrainStopName = "Idle Stop"
	global.FinishTrain = {}
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
			for _,carriage in pairs(train.carriages) do
				if Contains(train_ignore_list,carriage.name) then goto continue end
			end
			
			global.TrainList[train.id] = train
			::continue::
		end
	end
end

function ON_INIT()
	Init()
	EnableIdleTrainStop()
	CreateTrainList()
end
script.on_init(ON_INIT)

function AddTrainIgnore(name)
	if not Contains(train_ignore_list,name) then 
		table.insert(train_ignore_list,name)
		CheckTrainList()
	end
end

function CheckTrainList()
	if global.TrainList then
		for i,train in pairs(global.TrainList) do
			if train and train.valid then
				for _,carriage in pairs(train.carriages) do
					if Contains(train_ignore_list,carriage.name) then 
						global.TrainList[i] = nil
						break;
					end
				end
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

	for _,carriage in pairs(train.carriages) do
		if Contains(train_ignore_list,carriage.name) then
			if old_train_id_1 then		
				global.TrainList[old_train_id_1] = nil
			end
			if old_train_id_2 then
				global.TrainList[old_train_id_2] = nil
			end
			goto continue 
		end
	end
	
	global.TrainList[train.id] = train
	
	if old_train_id_1 then
		global.TrainList[old_train_id_1] = nil
		
		if global.FinishTrain[old_train_id_1] then
			global.FinishTrain[old_train_id_1] = nil
			global.FinishTrain[train.id] = train
		end	
	end
	if old_train_id_2 then
		global.TrainList[old_train_id_2] = nil
		
		if global.FinishTrain[old_train_id_2] then
			global.FinishTrain[old_train_id_2] = nil
			global.FinishTrain[train.id] = train
		end	
	end
	::continue::
end
script.on_event(defines.events.on_train_created,ON_TRAIN_CREATED)

function ON_TRAIN_CHANGED_STATE(event)
	local train = event.train
	if train.state == defines.train_state.wait_station then
		if train.station and train.station.backer_name == global.TrainStopName then
			global.FinishTrain[train.id] = train
		end
	end
end
script.on_event(defines.events.on_train_changed_state,ON_TRAIN_CHANGED_STATE)

function AddSchedule(train)
	local schedule = train.schedule or {records = {}, current = 1}
	
	for _,record in pairs(schedule.records) do
		if record.station == global.TrainStopName then return end
	end
	
	local record = {station = global.TrainStopName, wait_conditions = {{type = "inactivity", compare_type = "and", ticks = 120 }}}

	table.insert(schedule.records,schedule.current,record)
	
	train.schedule = schedule
end

function ON_600TH_TICK()
	if Count(global.TrainStop) > 0 then 
		for i,train in pairs(global.TrainList) do
			if not train.valid then
				global.TrainList[i] = nil
				goto continue
			end
			
			if train.manual_mode then goto continue end

			print(train.state)
	
			::continue::
		end	
	end
end
script.on_nth_tick(600,ON_600TH_TICK)	

function ChangeSchedule(train,schedule)
	train.schedule = schedule
end

function ON_300TH_TICK()
	if Count(global.FinishTrain) > 0 then
		for i,train in pairs(global.FinishTrain) do
			if not train.valid then
				global.FinishTrain[i] = nil
			else
				if not (train.station and train.station.backer_name == global.TrainStopName) then 
					local changedSchedule = false
					local schedule = train.schedule
					if (schedule) then
						for j,record in pairs(schedule.records) do
							if record.station == global.TrainStopName then
								table.remove(schedule.records,j)
								if j > Count(schedule.records) then
									schedule.current = 1
								else
									schedule.current = j
								end					
								break
							end
						end
												
						changedSchedule = pcall(ChangeSchedule,train,schedule)												
					end
					
					if changedSchedule then
						global.FinishTrain[i] = nil
					end
				end
			end
		end
	end
end
script.on_nth_tick(300,ON_300TH_TICK)