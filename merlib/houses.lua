--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    Creates randomly generated houses that get turned into blueprints with merlib.blueprints.
]]

-- Start module environment ----------+
local mo = require "merlib.modules" --|
mo.startModule(_ENV)                --|
--------------------------------------+

local ac = require "merlib.actions"
local ba = require "merlib.basics"
local ve = require "merlib.vectors"
local st = require "merlib.state"
local algs = require "merlib.algs"
local Blueprint = (require "merlib.blueprints").Blueprint

local Vector3 = ve.Vector3

------------------------------------

-- Customizable properties
options = {
    MAX_SIZE = 11,
    MAX_COMPONENT_SIZE = 8,
    MIN_COMPONENT_SIZE = 3,
    MIN_BASE_SIZE = 5,
    MAX_COMPONENT_ADD_ATTEMPTS = 10,

    MIN_WALL_HEIGHT = 2,
    MAX_WALL_HEIGHT = 4,

    DOOR_HEIGHT = 1,
    WINDOW_HEIGHT = 2,

    WINDOW_CHANCE = 0.2,
    FLAT_TOP_CHANCE = 0.6
}

-- -- Variant properties (uncomment)
-- options = {
--     MAX_SIZE = 30,
--     MAX_COMPONENT_SIZE = 15,
--     MIN_COMPONENT_SIZE = 3,
--     MIN_BASE_SIZE = 5,
--     MAX_COMPONENT_ADD_ATTEMPTS = 50,
--     MIN_WALL_HEIGHT = 2,
--     MAX_WALL_HEIGHT = 4,
--     DOOR_HEIGHT = 1,
--     WINDOW_HEIGHT = 2,
--     WINDOW_CHANCE = 0.2,
--     FLAT_TOP_CHANCE = 0.1
-- }

------------------------------------

local TYPE_SLOTS = {
    "foundation",
    "floor",
    "roof_flat",
    "roof_slant",
    "wall",
    "glass",
    "corner",
    -- "scaffold",
}

local COMPONENT = 1
local OVERLAP = 2
local EDGE = 4
local DOOR = 8
local WINDOW = 16
local CORNER = 32

local UP = "north"
local RIGHT = "east"
local DOWN = "south"
local LEFT = "west"
local FLAT = "flat"

local OFFSETS = {
    [UP]    = { 0, -1},
    [RIGHT] = { 1,  0},
    [DOWN]  = { 0,  1},
    [LEFT]  = {-1,  0}
}

local ROTATIONS = {
    [UP]    = "north",
    [RIGHT] = "east",
    [DOWN]  = "south",
    [LEFT]  = "west"
}

local function find(table, x, y)
    return table[ve.pack2(x, y)] or 0
end


function houseToString(house)
    s = ''
    for y = house.min_y, house.max_y do

        -- Layout
        for x = house.min_x, house.max_x do
            if bit32.band(find(house.layout, x, y), COMPONENT) ~= 0 then
                if bit32.band(find(house.layout, x, y), EDGE) ~= 0 then
                    if bit32.band(find(house.layout, x, y), WINDOW) ~= 0 then
                        s = s .. 'W'
                    elseif bit32.band(find(house.layout, x, y), DOOR) ~= 0 then
                        s = s .. 'D'
                    elseif bit32.band(find(house.layout, x, y), CORNER) ~= 0 then
                        s = s .. '*'
                    else
                        s = s .. '+'
                    end
                else
                    if bit32.band(find(house.layout, x, y), OVERLAP) ~= 0 then
                        s = s .. '#'
                    else
                        s = s .. '#'
                    end
                end
            else
                s = s .. '.'
            end
        end
        s = s .. '   '

        -- Roof heights
        for x = house.min_x, house.max_x do
            local height = find(house.roof_heights, x, y)
            if height < 10 then
                s = s .. height
            else
                s = s .. "#"
            end
        end
        s = s .. '   '

        -- Roof elements
        for x = house.min_x, house.max_x do
            if find(house.roof_elements, x, y) == UP then
                s = s .. '^'
            elseif find(house.roof_elements, x, y) == RIGHT then
                s = s .. '>'
            elseif find(house.roof_elements, x, y) == DOWN then
                s = s .. 'v'
            elseif find(house.roof_elements, x, y) == LEFT then
                s = s .. '<'
            elseif find(house.roof_elements, x, y) == FLAT then
                s = s .. '='
            else
                s = s .. '.'
            end
        end
        if y ~= house.max_y then
            s = s .. '\n'
        end
    end
    return s
end


local function attemptAddComponent(layout, roof_heights, roof_elements, first, min_size)
    local width = math.random(min_size, options.MAX_COMPONENT_SIZE)
    local length = math.random(min_size, options.MAX_COMPONENT_SIZE)
    local min_x = math.random(options.MAX_SIZE - width + 1)
    local min_y = math.random(options.MAX_SIZE - length + 1)
    if first then min_y = options.MAX_SIZE - length + 1 end
    local max_x = min_x + width - 1
    local max_y = min_y + length - 1

    -- Check to see if component can be added
    local connects = false
    local full_overlap = true
    for x = min_x, max_x do
        for y = min_y, max_y do
            local is_edge = x == min_x or x == max_x or y == min_y or y == max_y
            if bit32.band(find(layout, x, y), COMPONENT) ~= 0 then
                -- Already a component here
                if bit32.band(find(layout, x, y), OVERLAP) ~= 0 then
                    -- Already an overlap here
                    return
                end
                if not (is_edge or bit32.band(find(layout, x, y), EDGE) ~= 0) then
                    -- Neither current nor past is edge
                    connects = true
                end
            else
                -- Not a component here
                full_overlap = false
            end
        end
    end
    if full_overlap or not (connects or first) then
        return
    end

    -- Add component
    for x = min_x, max_x do
        for y = min_y, max_y do
            local is_edge = x == min_x or x == max_x or y == min_y or y == max_y
            if bit32.band(find(layout, x, y), COMPONENT) ~= 0 then
                -- Already a component here
                layout[ve.pack2(x, y)] = bit32.bor(find(layout, x, y), OVERLAP)
                if bit32.band(find(layout, x, y), EDGE) ~= 0 and not is_edge then
                    layout[ve.pack2(x, y)] = find(layout, x, y) - EDGE
                    if bit32.band(find(layout, x, y), WINDOW) ~= 0 then
                        layout[ve.pack2(x, y)] = find(layout, x, y) - WINDOW
                    end
                end
            else
                -- Not a component here
                layout[ve.pack2(x, y)] = bit32.bor(find(layout, x, y), COMPONENT)
                if is_edge then
                    layout[ve.pack2(x, y)] = bit32.bor(find(layout, x, y), EDGE)
                    if math.random() < options.WINDOW_CHANCE then
                        -- Add window
                        layout[ve.pack2(x, y)] = bit32.bor(find(layout, x, y), WINDOW)
                    end
                end
            end
        end
    end

    -- Add door
    local door_x
    if first then
        door_x = math.random(min_x + 1, max_x - 1)
        layout[ve.pack2(door_x, max_y)] = bit32.bor(find(layout, door_x, max_y), DOOR)
        for offset = -1, 1 do
            if bit32.band(find(layout, door_x + offset, max_y), WINDOW) ~= 0 then
                layout[ve.pack2(door_x + offset, max_y)] = find(layout, door_x + offset, max_y) - WINDOW
            end
        end
    end

    local height = math.random(options.MIN_WALL_HEIGHT, options.MAX_WALL_HEIGHT)

    -- Add roof
    local flat_portion = 0
    if math.random() < options.FLAT_TOP_CHANCE then
        flat_portion = math.random(0, math.min(width, length) / 2 - 1)
    end
    local mid, element
    if width > length then
        mid = (min_y + max_y) / 2
        for y = min_y, max_y do
            if y < mid - flat_portion then
                element = DOWN
                height = height + 1
            elseif y > mid + flat_portion then
                element = UP
            else
                element = FLAT
            end
            for x = min_x, max_x do
                if find(roof_heights, x, y) < height then
                    roof_heights[ve.pack2(x, y)] = height
                    roof_elements[ve.pack2(x, y)] = element
                end
            end
            if y > mid + flat_portion then
                height = height - 1
            end
        end
    else
        mid = (min_x + max_x) / 2
        for x = min_x, max_x do
            if x < mid - flat_portion then
                element = RIGHT
                height = height + 1
            elseif x > mid + flat_portion then
                element = LEFT
            else
                element = FLAT
            end
            for y = min_y, max_y do
                if find(roof_heights, x, y) < height then
                    roof_heights[ve.pack2(x, y)] = height
                    roof_elements[ve.pack2(x, y)] = element
                end
            end
            if x > mid + flat_portion then
                height = height - 1
            end
        end
    end
    return door_x, max_y
end


local function fixCorners(layout)
    for coords, type in pairs(layout) do
        -- Find all adjacend edge types
        x, y = ve.unpack2(coords)
        adjacend_edges = {}
        for dir, offset in pairs(OFFSETS) do
            if bit32.band(find(layout, x + offset[1], y + offset[2]), EDGE) ~= 0 then
                adjacend_edges[dir] = true
            end
        end
        -- Mark as corner, remove windows
        if (adjacend_edges[UP] or adjacend_edges[DOWN]) and (adjacend_edges[LEFT] or adjacend_edges[RIGHT]) then
            layout[coords] = bit32.bor(layout[coords], CORNER)
            if bit32.band(layout[coords], WINDOW) ~= 0 then
                layout[coords] = layout[coords] - WINDOW
            end
        end
    end
end


local function fixRoof(layout, roof_heights, roof_elements)
    for coords, element in pairs(roof_elements) do
        height = roof_heights[coords]
        for cardinal, offset in pairs(OFFSETS) do
            local start_x, start_y = ve.unpack2(coords)
            local x = start_x
            local y = start_y
            local reverse = ve.cardinal_reverse[cardinal]
            if element == reverse then
                x = x + offset[1]
                y = y + offset[2]
                local new_coords = ve.pack2(x, y)
                if roof_heights[new_coords] == height and (roof_elements[new_coords] == element or roof_elements[new_coords] == FLAT) then
                    roof_elements[coords] = FLAT
                end
            elseif element ~= cardinal then
                while true do
                    x = x + offset[1]
                    y = y + offset[2]
                    local new_coords = ve.pack2(x, y)
                    if not roof_elements[new_coords] then
                        break
                    elseif roof_heights[new_coords] > height then
                        break
                    elseif roof_heights[new_coords] == height then
                        if roof_elements[new_coords] == reverse then
                            break
                        elseif roof_elements[new_coords] == cardinal then
                            while not (x == start_x and y == start_y) do
                                new_coords = ve.pack2(x, y)
                                roof_elements[new_coords] = element
                                roof_heights[new_coords] = height
                                x = x - offset[1]
                                y = y - offset[2]
                            end
                        else
                            break
                        end
                    end
                end
            end
        end
    end
end


function randomHouse(seed)
    if seed then
        math.randomseed(seed)
    end

    local temp_layout = {}
    local temp_roof_heights = {}
    local temp_roof_elements = {}

    -- Add components
    local door_x, door_y = attemptAddComponent(temp_layout, temp_roof_heights, temp_roof_elements, true, options.MIN_BASE_SIZE)
    for _ = 1, math.random(options.MAX_COMPONENT_ADD_ATTEMPTS - 1) do
        attemptAddComponent(temp_layout, temp_roof_heights, temp_roof_elements, false, options.MIN_COMPONENT_SIZE)
    end

    -- Reposition
    local house = {}
    house.seed = seed
    house.layout = {}
    house.roof_heights = {}
    house.roof_elements = {}
    house.min_x = ba.inf
    house.max_x = -ba.inf
    house.min_y = ba.inf
    house.max_y = -ba.inf
    for coords in pairs(temp_layout) do
        x, y = ve.unpack2(coords)
        x = x - door_x
        y = y - door_y
        house.layout[ve.pack2(x, y)] = temp_layout[coords]
        house.roof_heights[ve.pack2(x, y)] = temp_roof_heights[coords]
        house.roof_elements[ve.pack2(x, y)] = temp_roof_elements[coords]
        house.min_x = math.min(house.min_x, x)
        house.max_x = math.max(house.max_x, x)
        house.min_y = math.min(house.min_y, y)
        house.max_y = math.max(house.max_y, y)
    end

    -- Final touches
    fixCorners(house.layout)
    fixRoof(house.layout, house.roof_heights, house.roof_elements)

    return house
end


function makeBlueprint(house, block_types, foundation_height)
    local blueprint = Blueprint.new()

    -- Foundation
    for y = -foundation_height, -1 do
        for coords, _ in pairs(house.layout) do
            local x, z = ve.unpack2(coords)
            blueprint:addBlock(block_types.foundation, Vector3.new(x, y, z))
        end
    end

    -- Floor
    for coords, type in pairs(house.layout) do
        local x, z = ve.unpack2(coords)
        if bit32.band(type, EDGE) ~= 0 then
            blueprint:addBlock(block_types.foundation, Vector3.new(x, 0, z))
        else
            blueprint:addBlock(block_types.floor, Vector3.new(x, 0, z))
        end
    end

    -- Roof
    for coords, type in pairs(house.roof_elements) do
        local x, z = ve.unpack2(coords)
        local y = house.roof_heights[coords]
        local vector = Vector3.new(x, y, z)
        if type == FLAT then
            blueprint:addBlock(block_types.roof_flat, vector)
        else
            blueprint:addBlock(block_types.roof_slant, vector, ROTATIONS[type])
        end

        -- Calc wall bottom
        local wall_bottom = y
        if bit32.band(house.layout[coords], EDGE) ~= 0 then
            wall_bottom = 1
        end
        for _, offset in pairs(OFFSETS) do
            local adj_x = x + offset[1]
            local adj_z = z + offset[2]
            local adj_height = house.roof_heights[ve.pack2(adj_x, adj_z)]
            if adj_height then
                wall_bottom = math.min(wall_bottom, adj_height)
            end
        end

        -- Scaffold
        if wall_bottom == y and type ~= FLAT then
            blueprint:addBlock(block_types.wall, Vector3.new(x, y-1, z)) -- used to be scaffold
        end

        vector.y = vector.y - 1
        while vector.y > 0 do
            if vector.y >= wall_bottom then
                -- Windows
                if vector.y == options.WINDOW_HEIGHT and bit32.band(house.layout[coords], WINDOW) ~= 0 then
                    blueprint:addBlock(block_types.glass, vector)

                -- Doors
                elseif (vector.y == options.DOOR_HEIGHT or vector.y == options.DOOR_HEIGHT + 1) and bit32.band(house.layout[coords], DOOR) ~= 0 then
                    if vector.y == options.DOOR_HEIGHT + 1 then
                        blueprint:addBlock(block_types.wall, vector) -- used to be scaffold
                    end

                -- Corners
                elseif vector.y == options.DOOR_HEIGHT + 1 and bit32.band(house.layout[coords], CORNER) ~= 0 then
                    blueprint:addBlock(block_types.corner, vector)

                -- Walls
                else
                    blueprint:addBlock(block_types.wall, vector)
                end
            else
                -- Mark interior
                blueprint:addEmpty(vector) -- removed -1
            end

            vector.y = vector.y - 1
        end
    end

    return blueprint
end


function buildHouse(blueprint)
    blueprint = blueprint:transformed(st.pos, st.rot)
    blueprint:build('up')
end


function manualBlockTypes()
    term.clear()
    term.setCursorPos(1, 1)
    print()
    while true do
        print("Please enter items:")
        for slot, type in pairs(TYPE_SLOTS) do
            print(string.format("  SLOT %d: %s", slot, type))
        end
        print("<ENTER to continue>")
        read()

        local all_set = true
        local block_types = {}
        for slot, type in pairs(TYPE_SLOTS) do
            local item = turtle.getItemDetail(slot)
            if item == nil then
                all_set = false
                term.clear()
                term.setCursorPos(1, 1)
                print(string.format("Please place %s item in slot %d", type, slot))
                break
                -- error(string.format("Please place %s item in slot %d", type, slot))
            end
            block_types[type] = item.name
        end
        if all_set then return block_types end
    end
end

-- End module environment -------+
return mo.endModule(getfenv()) --|
---------------------------------+