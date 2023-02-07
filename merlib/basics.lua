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

local last_seed = math.random(10000000000)
function random(...)
    -- For programs that have used math.randomseed() and need some "true" randomness again
    math.randomseed(last_seed)
    last_seed = math.random(10000000000)
    return math.random(...)
end


-- End module environment -------+
return mo.endModule(getfenv()) --|
---------------------------------+