-- This code © 2023 by Merlin is licensed under CC BY-SA 4.0.

-- Start module environment ----------+
local mo = require "merlib.modules" --|
mo.startModule(_ENV)                --|
--------------------------------------+

local ba = require "merlib.basics"
local ve = require "merlib.vectors"
local ac = require "merlib.actions"
local st = require "merlib.state"
local algs = require "merlib.algs"

Vector3 = ve.Vector3

Blueprint = {}
Blueprint.__index = Blueprint

function Blueprint.new()
	local o = {
        blocks = {},
        rotations = {},
        layers = {},
        empty = {},
        data = {},
        min = Vector3.new(ba.inf, ba.inf, ba.inf),
        max = Vector3.new(-ba.inf, -ba.inf, -ba.inf)
    }
	setmetatable(o, Blueprint)
	return o
end

function Blueprint:addLayer(height)
    local layer = {blocks = {}, rotations = {}}
    self.layers[height] = layer
    return layer
end

function Blueprint:addBlock(block_name, pos, rot)
    local pos_str = pos:strXYZ()
    self.blocks[pos_str] = block_name
    self.rotations[pos_str] = rot

    local layer = self.layers[pos.y]
    if not layer then
        layer = self:addLayer(pos.y)
    end
    layer.blocks[ve.pack2(pos.x, pos.z)] = true

    self.min.x = math.min(self.min.x, pos.x)
    self.max.x = math.max(self.max.x, pos.x)
    self.min.y = math.min(self.min.y, pos.y)
    self.max.y = math.max(self.max.y, pos.y)
    self.min.z = math.min(self.min.z, pos.z)
    self.max.z = math.max(self.max.z, pos.z)
end

function Blueprint:addEmpty(pos)
    self.empty[pos:strXYZ()] = true
end

function Blueprint:transformed(new_origin, new_rotation)
    local translation_vector = new_origin:clone()
    translation_vector.y = translation_vector.y - 1
    local rotation_table, rotationFunction
    if new_rotation == 'north' then
        rotationFunction = Vector3.clone
        rotation_table = ve.cardinal_identity
    elseif new_rotation == 'west' then
        rotationFunction = Vector3.rot270
        rotation_table = ve.cardinal_left
    elseif new_rotation == 'south' then
        rotationFunction = Vector3.rot180
        rotation_table = ve.cardinal_reverse
    elseif new_rotation == 'east' then
        rotationFunction = Vector3.rot90
        rotation_table = ve.cardinal_right
    end

    local new_blueprint = Blueprint.new()
    local new_phase, old_vector, new_vector

    for old_pos_str, block_name in pairs(self.blocks) do
        old_vector = Vector3.fromString(old_pos_str)
        new_vector = rotationFunction(old_vector) + translation_vector
        new_rotation = rotation_table[self.rotations[old_pos_str]]
        new_blueprint:addBlock(block_name, new_vector, new_rotation)
    end
    for old_pos_str, _ in pairs(self.empty) do
        old_vector = Vector3.fromString(old_pos_str)
        new_vector = rotationFunction(old_vector) + translation_vector
        new_blueprint.empty[new_vector:strXYZ()] = true
    end
    new_blueprint.min = rotationFunction(self.min) + translation_vector
    new_blueprint.max = rotationFunction(self.max) + translation_vector
    new_blueprint.data = self.data

    return new_blueprint
end

function Blueprint:build(direction)
    local inTotalArea, isBlockPosition, remaining_blocks, layer, layer_y, block_y, turtle_y, turtle_offset, inLayerArea, validFunction

    if direction == 'up' then
        turtle_offset = ve.cardinal_vectors.up
        layer_y = self.min.y
    elseif direction == 'down' then
        turtle_offset = ve.cardinal_vectors.down
        layer_y = self.max.y
    end

    function inTotalArea(pos)
        return self.empty[pos:strXYZ()] or self.blocks[(pos - turtle_offset):strXYZ()]
    end

    function inLayerArea(pos)
        return pos.y == turtle_y and inTotalArea(pos)
    end

    function isBlockPosition(pos, rot)
        local rotation = self.rotations[(pos - turtle_offset):strXYZ()]
        if rotation and rotation ~= rot then return false end
        return remaining_blocks[ve.pack2(pos.x, pos.z)] and pos.y == turtle_y
    end

    while layer_y >= self.min.y and layer_y <= self.max.y do
        layer = self.layers[layer_y]
        block_y = layer_y
        turtle_y = layer_y + turtle_offset.y

        remaining_blocks = {}
        for xz_str, _ in pairs(layer.blocks) do
            remaining_blocks[xz_str] = true
        end

        validFunction = inTotalArea
        while next(remaining_blocks) do
            route = algs.fastestRouteMultiDestUseRot(st.pos, st.rot, isBlockPosition, validFunction)
            if not route then error('No valid route found to blueprint layer ' .. block_y) end
            while turtle.getFuelLevel() < #route do ac.manualRefuel() end
            if not ac.followRoute(route, true) then error('Could not follow route') end

            validFunction = inLayerArea
            assert(st.pos.y == turtle_y)

            local block_pos = st.pos - turtle_offset
            local block_name = self.blocks[block_pos:strXYZ()]

            if block_name == 'air' then
                if direction == 'up' then
                    ac.safeDig('down')
                elseif direction == 'down' then
                    ac.safeDig('up')
                end
            else
                while not ac.selectItem(block_name) do
                    print('Item ' .. block_name .. ' not found, please replenish')
                    print('<ENTER to continue>')
                    read()
                end
                if direction == 'up' then
                    ac.safeDig('down')
                    turtle.placeDown()
                elseif direction == 'down' then
                    ac.safeDig('up')
                    turtle.placeUp()
                end
            end

            remaining_blocks[ve.pack2(block_pos.x, block_pos.z)] = nil
        end

        layer_y = layer_y + turtle_offset.y
    end
end

-- End module environment -------+
return mo.endModule(getfenv()) --|
---------------------------------+