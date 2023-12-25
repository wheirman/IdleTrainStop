if mods["nullius"] then
    data:extend({
        {
          type = "recipe",
          name = "nullius-idle-train-stop",
          enabled = true,
          always_show_made_in = true,
          no_productivity = true,
          category = "medium-crafting",
          energy_required = 2,
          ingredients = {
            {"train-stop", 1},
            {"rail-signal", 1}
          },
          result = "idle-train-stop"
        }
    })

    table.insert(data.raw.technology["nullius-traffic-control"].effects,
                 {type = "unlock-recipe", recipe = "nullius-idle-train-stop"})

    data.raw["item"]["idle-train-stop"].order = "nullius-ebc"
    data.raw["item"]["idle-train-stop"].subgroup = "railway"
    data.raw["train-stop"]["idle-train-stop"].minable.mining_time = 1.2
end
