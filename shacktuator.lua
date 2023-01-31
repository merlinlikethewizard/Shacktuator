--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    Have turtles build their own cute unique little and big houses with Shacktuator!!!
]]

local ba = require "merlib.basics"
local houses = require "merlib.houses"

local MAP_VIEW_MARGIN = 2
local OPTIONS_X = 2
local RANDOMIZE_X = 5
local SELECT_X = 18
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

function optionsWindow(win, seed)
    _, win_height = win.getSize()
    local options_enum = {}
    options_enum[1] = "SEED"
    local i = 2
    for option, value in pairs(houses.options) do
        options_enum[i] = option
        i = i + 1
    end

    while true do
        win.setBackgroundColor(colors.black)
        win.setTextColor(colors.white)
        win.clear()
        for y, option in pairs(options_enum) do
            win.setCursorPos(1, y)
            if option == "SEED" then
                win.write("SEED: " .. seed)
            else
                win.write(option .. ": " .. houses.options[option])
            end
        end
        win.setCursorPos(1, win_height)
        win.setBackgroundColor(colors.white)
        win.write("                                                              ")
        win.setCursorPos(OPTIONS_X, win_height)
        win.setBackgroundColor(colors.cyan)
        win.setTextColor(colors.white)
        win.write("*")
        win.setVisible(true)
        win.setVisible(false)

        local _, _, x, y = os.pullEvent("mouse_click")
        if x == OPTIONS_X and y == win_height then
            return seed
        elseif y == 1 or options_enum[y] then
            local option
            if y == 1 then
                option = "SEED"
            else
                option = options_enum[y]
            end
            win.setBackgroundColor(colors.white)
            win.setTextColor(colors.black)
            win.setCursorPos(1, y)
            win.write(option .. ":                               ")
            win.setVisible(true)
            win.setVisible(false)
            term.setBackgroundColor(colors.white)
            term.setTextColor(colors.black)
            term.setCursorPos(#option + 3, y)
            local number = tonumber(read())
            if number then 
                if y == 1 then
                    seed = number
                else
                    houses.options[option] = number
                end
            end
        end
    end
end

function userGenerate()
    local house = houses.randomHouse(math.random(100000))
    while true do
        local map, map_width, map_height = stringTo2DTable(houses.houseToString(house))
        local x_offset = 0
        local y_offset = 0
        local screen_width, screen_height = term.getSize()
        local x_max = map_width - screen_width + MAP_VIEW_MARGIN
        local y_max = map_height - screen_height + MAP_VIEW_MARGIN + 1
        win = window.create(term.current(), 1, 1, screen_width, screen_height)
        
        while true do
            x_offset = math.max(-MAP_VIEW_MARGIN, math.min(x_offset, x_max))
            y_offset = math.max(-MAP_VIEW_MARGIN, math.min(y_offset, y_max))
            win.setBackgroundColor(colors.black)
            win.clear()
            win.setCursorPos(1, 1)
            for y = 1, screen_height - 1 do
                -- if y ~= 1 then s = s .. "\n" end
                for x = 1, screen_width do
                    -- s = s .. (map[ba.flat(x + x_offset, y + y_offset)] or ' ')
                    win.setCursorPos(x, y)
                    win.write(map[ba.flat(x + x_offset, y + y_offset)] or ' ')
                end
            end
            win.setCursorPos(1, screen_height)
            win.setBackgroundColor(colors.white)
            win.write("                                                              ")
            win.setCursorPos(OPTIONS_X, screen_height)
            win.setBackgroundColor(colors.cyan)
            win.write("*")
            win.setCursorPos(RANDOMIZE_X, screen_height)
            win.setBackgroundColor(colors.red)
            win.write(" RANDOMIZE ")
            win.setCursorPos(SELECT_X, screen_height)
            win.setBackgroundColor(colors.green)
            win.write(" SELECT ")
            win.setCursorPos(SEED_X, screen_height)
            win.setBackgroundColor(colors.white)
            win.setTextColor(colors.black)
            win.write("SEED: " .. house.seed)
            win.setTextColor(colors.white)
            win.setBackgroundColor(colors.black)
            win.setVisible(true)
            win.setVisible(false)

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
                    house = houses.randomHouse(math.random(100000))
                    break
                elseif arg2 >= SELECT_X and arg2 < SELECT_X + 8 and arg3 == screen_height then
                    term.setBackgroundColor(colors.black)
                    term.setTextColor(colors.white)
                    return house
                elseif arg2 == OPTIONS_X and arg3 == screen_height then
                    house = houses.randomHouse(optionsWindow(win, house.seed))
                    break
                end
            end
        end
    end
end

function main()
    local house = userGenerate()
    local block_types = houses.manualBlockTypes()
    local blueprint = houses.makeBlueprint(house, block_types, 0)
    houses.buildHouse(blueprint)
    print("Completed house with seed: " .. house.seed)
end

main()