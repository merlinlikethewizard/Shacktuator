-- This code © 2023 by Merlin is licensed under CC BY-SA 4.0.

local ba = require "merlib.basics"
local houses = require "merlib.houses"

local MAP_VIEW_MARGIN = 2
local RANDOMIZE_X = 3
local SELECT_X = 17
local SEED_X = 28

function stringTo2DTable(map_string)
    local x = 1
    local y = 1
    local width = 0
    local map = {}
    for char in map_string:gmatch'.' do
        if char == "\n" then
            y = y + 1
            width = math.max(width, x - 1)
            x = 1
        else
            map[ba.flat(x, y)] = char
            x = x + 1
        end
    end
    return map, width, y
end

function userApprove(house)
    local map, map_width, map_height = stringTo2DTable(houses.houseToString(house))
    local x_offset = 0
    local y_offset = 0
    local screen_width, screen_height = term.getSize()
    local x_max = map_width - screen_width + MAP_VIEW_MARGIN
    local y_max = map_height - screen_height + MAP_VIEW_MARGIN + 1
    
    while true do
        x_offset = math.max(-MAP_VIEW_MARGIN, math.min(x_offset, x_max))
        y_offset = math.max(-MAP_VIEW_MARGIN, math.min(y_offset, y_max))
        term.clear()
        term.setCursorPos(1, 1)
        for y = 1, screen_height - 1 do
            -- if y ~= 1 then s = s .. "\n" end
            for x = 1, screen_width do
                -- s = s .. (map[ba.flat(x + x_offset, y + y_offset)] or ' ')
                term.setCursorPos(x, y)
                term.write(map[ba.flat(x + x_offset, y + y_offset)] or ' ')
            end
        end
        term.setCursorPos(1, screen_height)
        term.setBackgroundColor(colors.white)
        term.write("                                                              ")
        term.setCursorPos(RANDOMIZE_X, screen_height)
        term.setBackgroundColor(colors.red)
        term.write(" RANDOMIZE ")
        term.setCursorPos(SELECT_X, screen_height)
        term.setBackgroundColor(colors.green)
        term.write(" SELECT ")
        term.setCursorPos(SEED_X, screen_height)
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
        term.write("SEED: " .. house.seed)
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.black)

        local event, arg1, arg2, arg3 = os.pullEvent()
        if event == "key" then
            if arg1 == keys.up then
                y_offset = y_offset - 1
            elseif arg1 == keys.down then
                y_offset = y_offset + 1
            elseif arg1 == keys.right then
                x_offset = x_offset + 1
            elseif arg1 == keys.left then
                x_offset = x_offset - 1
            end
        elseif event == "mouse_click" then
            if arg2 >= RANDOMIZE_X and arg2 < RANDOMIZE_X + 11 and arg3 == screen_height then
                return false
            elseif arg2 >= SELECT_X and arg2 < SELECT_X + 8 and arg3 == screen_height then
                return true
            end
        end
    end
end

function main()
    local house
    while true do
        seed = math.random(100000)
        house = houses.randomHouse(seed)
        if userApprove(house) then break end
    end
    local block_types = houses.getBlockTypes()
    local blueprint = houses.makeBlueprint(house, block_types, 0)
    houses.buildHouse(blueprint)
    print("Completed house with seed: " .. house.seed)
end

main()