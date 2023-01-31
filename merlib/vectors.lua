--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    A custom Vector3 class with a few useful mathy methods and operator overloads.
]]

-- Start module environment ----------+
local mo = require "merlib.modules" --|
mo.startModule(_ENV)                --|
--------------------------------------+

local ba = require "merlib.basics"

Vector3 = {x = 0, y = 0, z = 0}
Vector3.__index = Vector3

function Vector3.new(x, y, z)
    if type(x) == 'table' then return end

	local o = {x = x or 0, y = y or 0, z = z or 0}
	setmetatable(o, Vector3)
	return o
end

function Vector3.fromString(s)
    ---@diagnostic disable-next-line: deprecated
    return Vector3.new(table.unpack(ba.splitString(s, ',')))
end

function Vector3:__tostring(in_table)
	return string.format("{x=%d, y=%d, z=%d}", self.x, self.y, self.z)
end

function Vector3:strXYZ(r)
    local xyz = pack3(self.x, self.y, self.z)
	if r then return xyz .. ':' .. r end
	return xyz
end

function Vector3:__eq(v)
	return self.x == v.x and self.y == v.y and self.z == v.z
end

function Vector3:__add(v)
	return Vector3.new(self.x + v.x, self.y + v.y, self.z + v.z)
end

function Vector3:__sub(v)
	return Vector3.new(self.x - v.x, self.y - v.y, self.z - v.z)
end

function Vector3:__mul(n)
	return Vector3.new(self.x * n, self.y * n, self.z * n)
end

function Vector3:__div(n)
	return Vector3.new(self.x / n, self.y / n, self.z / n)
end

function Vector3:__unm()
	return Vector3.new(-self.x, -self.y, -self.z)
end

function Vector3:increment(v)
	self.x = self.x + v.x
	self.y = self.y + v.y
	self.z = self.z + v.z
end

function Vector3:decrement(v)
	self.x = self.x - v.x
	self.y = self.y - v.y
	self.z = self.z - v.z
end

function Vector3:scale(n)
	self.x = self.x * n
	self.y = self.y * n
	self.z = self.z * n
end

function Vector3:inverseScale(n)
	self.x = self.x / n
	self.y = self.y / n
	self.z = self.z / n
end

function Vector3:distanceTo(v)
    return math.abs(self.x - v.x) +
           math.abs(self.y - v.y) +
           math.abs(self.z - v.z)
end

function Vector3:rot90()
	return Vector3.new(
        -self.z,
        self.y,
        self.x
    )
end

function Vector3:rot180()
	return Vector3.new(
        -self.x,
        self.y,
        -self.z
    )
end

function Vector3:rot270()
	return Vector3.new(
        self.z,
        self.y,
        -self.x
    )
end

local vec_to_cardinal = {
    ["0,1,0" ] = "up",
    ["0,-1,0"] = "down",
    ["0,0,-1"] = "north",
    ["0,0,1" ] = "south",
    ["1,0,0" ] = "east",
    ["-1,0,0"] = "west",
}
function Vector3:cardinalTo(v)
	return vec_to_cardinal[(v - self):strXYZ()]
end

function Vector3:inArea(area)
    return self.x <= area.max_x and self.x >= area.min_x and
		   self.y <= area.max_y and self.y >= area.min_y and
		   self.z <= area.max_z and self.z >= area.min_z
end

function Vector3:clone(o)
	if o then
		o.x = self.x
		o.y = self.y
		o.z = self.z
		return o
	else
		return Vector3.new(self.x, self.y, self.z)
	end
end

local adjacent_pos_getters = {
    up = function(pos) return pos + cardinal_vectors.up end,
    down = function(pos) return pos + cardinal_vectors.down end,
    forward = function(pos, rot) return pos + cardinal_vectors[rot] end,
    back = function(pos, rot) return pos + cardinal_vectors[cardinal_reverse[rot]] end,
    left = function(pos, rot) return pos + cardinal_vectors[cardinal_left[rot]] end,
    right = function(pos, rot) return pos + cardinal_vectors[cardinal_right[rot]] end,
    north = function(pos) return pos + cardinal_vectors.north end,
    south = function(pos) return pos + cardinal_vectors.south end,
    east  = function(pos) return pos + cardinal_vectors.east  end,
    west  = function(pos) return pos + cardinal_vectors.west  end
}

function Vector3:getAdjacentPos(dir, rot)
	return adjacent_pos_getters[dir](self, rot)
end

function pack3(x, y, z)
    return string.format('%d,%d,%d', (x or 1), (y or 1), (z or 1))
end

function unpack3(s)
    ---@diagnostic disable-next-line: deprecated
    local x, y, z = table.unpack(ba.splitString(s, ','))
    return tonumber(x), tonumber(y), tonumber(z)
end

function pack2(x, y)
    return string.format('%d,%d', (x or 1), (y or 1))
end

function unpack2(s)
    ---@diagnostic disable-next-line: deprecated
    local x, y = table.unpack(ba.splitString(s, ','))
    return tonumber(x), tonumber(y)
end

cardinal_vectors = {
    up    = Vector3.new( 0,  1,  0),
    down  = Vector3.new( 0, -1,  0),
    north = Vector3.new( 0,  0, -1),
    south = Vector3.new( 0,  0,  1),
    east  = Vector3.new( 1,  0,  0),
    west  = Vector3.new(-1,  0,  0),
    u = Vector3.new( 0,  1,  0),
    d = Vector3.new( 0, -1,  0),
    n = Vector3.new( 0,  0, -1),
    s = Vector3.new( 0,  0,  1),
    e = Vector3.new( 1,  0,  0),
    w = Vector3.new(-1,  0,  0),
}

cardinal_identity = {
    north = 'north',
    south = 'south',
    east  = 'east',
    west  = 'west',
    n = 'n',
    s = 's',
    e = 'e',
    w = 'w',
}

cardinal_left = {
    north = 'west',
    south = 'east',
    east  = 'north',
    west  = 'south',
    n = 'w',
    s = 'e',
    e = 'n',
    w = 's',
}

cardinal_right = {
    north = 'east',
    south = 'west',
    east  = 'south',
    west  = 'north',
    n = 'e',
    s = 'w',
    e = 's',
    w = 'n',
}

cardinal_reverse = {
    north = 'south',
    south = 'north',
    east  = 'west',
    west  = 'east',
    n = 's',
    s = 'n',
    e = 'w',
    w = 'e',
}

-- End module environment -------+
return mo.endModule(getfenv()) --|
---------------------------------+