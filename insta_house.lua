local houses = require "merlib.houses"

function main()
    local house = houses.randomHouse(math.random(100000))
    local block_types = houses.manualBlockTypes(true)
    local blueprint = houses.makeBlueprint(house, block_types, 0) -- integer arg here determines depth of house foundation
    houses.buildHouse(blueprint)
    print("Completed house with seed: " .. house.seed)
end

main()