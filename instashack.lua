--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    Have turtles build their own cute unique little and big houses with Shacktuator!!!
    Instantly builds a house without asking for user input
]]

local houses = require "merlib.houses"

function main()
    local house = houses.randomHouse(math.random(100000))
    local block_types = houses.manualBlockTypes(true)
    local blueprint = houses.makeBlueprint(house, block_types, 0) -- integer arg here determines depth of house foundation
    houses.buildHouse(blueprint)
    print("Completed house with seed: " .. house.seed)
end

main()