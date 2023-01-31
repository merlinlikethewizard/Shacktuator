--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    Works with merlib.actions to remember the state of the turtle's position
    (and possibly other things in the future).
]]

-- Start module environment --------------+
local the_env = {}                      --|
setmetatable(the_env, {__index = _ENV}) --|
setfenv(1, the_env)                     --|
------------------------------------------+

ve = require "merlib.vectors"

------------------------------------------+
local meta_table = {} -- Make meta table for the proxy
function meta_table.__index(in_table, in_key)
    return settings['merlib_' .. in_key]
end
function meta_table.__newindex(in_table, in_key, in_value)
    settings['merlib_' .. in_key] = in_value
end
local state = {} -- Create proxy table
setmetatable(state, meta_table)
------------------------------------------+

-- Defaults go here
if state.pos == nil then
    state.pos = ve.Vector3.new()
end
if state.rot == nil then
    state.rot = 'north'
end


------------------------------------------+
return state -- Send back to be returned at end of module