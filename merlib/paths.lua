--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

	The Path class is used to make a permanent easily followable path for turtles.
	It can be cusomized to be a closed loop or open, and is used by followPath in merlib.actions
]]

-- Start module environment ----------+
local mo = require "merlib.modules" --|
mo.startModule(_ENV)                --|
--------------------------------------+

local ve = require "merlib.vectors"

Path = {}
Path.__index = Path

function Path.fromRoute(route, origin)
	local o = {}
	setmetatable(o, Path)
	
	o.route = route
	o.steps = {}
	local pos = origin or ve.Vector3.new()

	for char in route:gmatch'.' do
		o.steps[pos:strXYZ()] = char
		pos:increment(ve.cardinal_vectors[char])
    end

	return o
end

function Path:__len()
	return #self.route
end

-- function Path.fromNodes(nodes)
-- 	local o = {}
-- 	setmetatable(o, Path)

-- 	o.steps = {}
-- 	local pos = nodes[1]
-- 	for i = 2, #nodes do
-- 		local node = nodes[i]
-- 		local diff = node - pos
-- 	end
-- end


function Path:next(pos)
	return self.steps[pos:strXYZ()]
end


-- End module environment -------+
return mo.endModule(getfenv()) --|
---------------------------------+