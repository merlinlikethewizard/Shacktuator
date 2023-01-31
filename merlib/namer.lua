--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    Generates random names for turtles!
]]

-- Start module environment ----------+
local mo = require "merlib.modules" --|
mo.startModule(_ENV)                --|
--------------------------------------+

--[[
namer.lua
Used for making random names for turtles.
]]

local VOWELS = {
    'a', 'a', 'a', 'a', 'a',
    'e', 'e', 'e', 'e', 'e', 'e',
    'i', 'i', 'i',
    'o', 'o', 'o',
    'u', 'u',
    'y',
    }
local CONSONANTS = {
    'b', 'b', 'b', 'b', 'b', 'b', 'b',
    'c', 'c', 'c', 'c', 'c', 'c', 'c',
    'd', 'd', 'd', 'd', 'd',
    'f', 'f', 'f', 'f', 'f',
    'g', 'g', 'g', 'g',
    'h', 'h', 'h',
    'j',
    'k', 'k',
    'l', 'l', 'l', 'l', 'l',
    'm', 'm', 'm', 'm', 'm', 'm', 'm',
    'n', 'n', 'n', 'n', 'n', 'n', 'n',
    'p', 'p', 'p', 'p', 'p',
    'r', 'r', 'r', 'r', 'r', 'r', 'r',
    's', 's', 's', 's', 's', 's', 's', 's', 's',
    't', 't', 't', 't', 't', 't', 't',
    'v',
    'w',
    'x',
    'y',
    'z', 'z', 'z',
    }
local DOUBLES = {
    'bl', 'br', 'bw', 
    'cr', 'cl',
    'dr', 'dw',
    'fr', 'fl', 'fw',
    'gr', 'gl', 'gw', 'gh',
    'kr', 'kl', 'kw',
    'mw',
    'ng',
    'pr', 'pl',
    'qu',
    'sr', 'sl', 'sw', 'st', 'sh',
    'tr', 'tl', 'tw', 'th',
    'vr', 'vl',
    'wr',
    }
local CONS_DOUB = {}
for _, c in pairs(CONSONANTS) do
    table.insert(CONS_DOUB, c)
end
for _, c in pairs(DOUBLES) do
    table.insert(CONS_DOUB, c)
end


function genRandName()
    -- Returns a random name
    local name = ''
    local count = math.random(3, 6)

    for i = 0, count - 1 do
        if i % 2 == 1 then
            name = name .. VOWELS[math.random(#VOWELS)]
        else
            if (i == count-1) then
                name = name .. CONSONANTS[math.random(#CONSONANTS)]
            else
                name = name .. CONS_DOUB[math.random(#CONS_DOUB)]
            end
        end
    end

    return string.upper(name:sub(1, 1)) .. name:sub(2, -1)
end


function nameTurtle()
    -- Labels the turtle with a random name if not already named
    if not os.getComputerLabel() then
        os.setComputerLabel(genRandName())
    end
end

-- End module environment -------+
return mo.endModule(getfenv()) --|
---------------------------------+