table.insert(data.raw.technology['automated-rail-transportation'].effects,{type = "unlock-recipe",recipe = "idle-train-stop"})

local train_stop_entity = table.deepcopy(data.raw['train-stop']['train-stop'])
train_stop_entity.name = "idle-train-stop"
train_stop_entity.minable.result = "idle-train-stop"

local train_stop_item = table.deepcopy(data.raw['item']['train-stop'])
train_stop_item.name = "idle-train-stop"
train_stop_item.icon = nil
train_stop_item.icons = { {icon = "__IdleTrainStop__/graphics/idle-train-stop.png"} }
train_stop_item.order = "a[train-system]-c[train-stop]-a[idle-train-stop]"
train_stop_item.place_result = "idle-train-stop"

local train_stop_recipe = table.deepcopy(data.raw['recipe']['train-stop'])
train_stop_recipe.name = "idle-train-stop"
train_stop_recipe.result = "idle-train-stop"
train_stop_recipe.enabled = true

data:extend({train_stop_entity,train_stop_item,train_stop_recipe})
