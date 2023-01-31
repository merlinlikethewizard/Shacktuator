--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    A few basic functions.
]]

-- Start module environment ----------+
local mo = require "merlib.modules" --|
mo.startModule(_ENV)                --|
--------------------------------------+

local pretty = require "cc.pretty"
pprint = pretty.pretty_print

inf = 1e309

function flat(x, y, z)
    return string.format('%d,%d,%d', (x or 1), (y or 1), (z or 1))
end

function unflat(s)
    ---@diagnostic disable-next-line: deprecated
    local x, y, z = table.unpack(splitString(s, ','))
    return tonumber(x), tonumber(y), tonumber(z)
end

function cloneTable(t)
    new_table = {}
    for key, val in pairs(t) do
        new_table[key] = val
    end
    return new_table
end

-- https://stackoverflow.com/a/7615129/7970048
function splitString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end


-- End module environment -------+
return mo.endModule(getfenv()) --|
---------------------------------+