--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    A few functions specifically for mining ore.
]]

-- Start module environment ----------+
local mo = require "merlib.modules" --|
mo.startModule(_ENV)                --|
--------------------------------------+

local ba = require "merlib.basics"
local ac = require "merlib.actions"
local st = require "merlib.state"
local algs = require "merlib.algs"

local ore_names = {}
local ore_tags = {}


local function scan(valid, ores)
    local checked_left  = false
    local checked_right = false

    local f = ac.getAdjacentPos('forward'):strXYZ()
    local u = ac.getAdjacentPos('up'):strXYZ()
    local d = ac.getAdjacentPos('down'):strXYZ()
    local l = ac.getAdjacentPos('left'):strXYZ()
    local r = ac.getAdjacentPos('right'):strXYZ()
    local b = ac.getAdjacentPos('back'):strXYZ()

    if not valid[f] and valid[f] ~= false then
        valid[f] = detectOre('forward')
        ores[f] = valid[f]
    end
    if not valid[u] and valid[u] ~= false then
        valid[u] = detectOre('up')
        ores[u] = valid[u]
    end
    if not valid[d] and valid[d] ~= false then
        valid[d] = detectOre('down')
        ores[d] = valid[d]
    end
    if not valid[l] and valid[l] ~= false then
        ac.left()
        checked_left = true
        valid[l] = detectOre('forward')
        ores[l] = valid[l]
    end
    if not valid[r] and valid[r] ~= false then
        ac.right()
        if checked_left then
            ac.right()
        end
        checked_right = true
        valid[r] = detectOre('forward')
        ores[r] = valid[r]
    end
    if not valid[b] and valid[b] ~= false then
        if checked_right then
            ac.right()
        elseif checked_left then
            ac.left()
        else
            ac.right()
            ac.right()
        end
        valid[b] = detectOre('forward')
        ores[b] = valid[b]
    end
end


function mineVein(direction, vein_max)
    if direction and not ac.face(direction) then return false end

    -- Log starting position
    local start = st.pos:strXYZ(st.rot)
    -- Begin block map
    local valid = {}
    local ores = {}
    valid[st.pos:strXYZ()] = true
    valid[ac.getAdjacentPos('back'):strXYZ()] = false
    vein_max = vein_max or ba.inf
    for i = 1, vein_max do
        -- Scan adjacent
        scan(valid, ores)

        -- Search for nearest ore
        local route = fastestMiningRoute(ores, valid)

        -- Check if there is one
        if not route then break end
        -- Retrieve ore
        turtle.select(5)
        if not ac.followRoute(route, true) then return false end
        ores[st.pos:strXYZ()] = nil

    end
    if not ac.followRoute(fastestMiningRoute({[start] = true}, valid), true) then return false end

    return true
end


function fastestMiningRoute(ores, valid)
	return algs.fastestRouteMultiDestUseRot(st.pos, st.rot, ores,
    		function(pos) return valid[pos:strXYZ()] end)
end


function checkTags(data)
    if type(data.tags) ~= 'table' then return false end

    for tag in pairs(data.tags) do
        if ore_tags[tag] then return true end
    end

    return false
end


function detectOre(direction)
    local block = ({ac.inspect_raw[direction]()})[2]

    if block == nil or block.name == nil then
        return false
    elseif ore_names[block.name] then
        return true
    elseif checkTags(block) then
        return true
    end

    return false
end


function setOreNames(new_table)
    for k in pairs(ore_names) do ore_names[k] = nil end
    for _, value in pairs(new_table) do ore_names[value] = true end
end


function setOreTags(new_table)
    for k in pairs(ore_tags) do ore_tags[k] = nil end
    for _, value in pairs(new_table) do ore_tags[value] = true end
end


function getOreNames()
	return ore_names
end


-- End module environment -------+
return mo.endModule(getfenv()) --|
---------------------------------+