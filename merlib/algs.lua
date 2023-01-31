--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    A collection of slightly different pathfinding algorithms.
]]

-- Start module environment ----------+
local mo = require "merlib.modules" --|
mo.startModule(_ENV)                --|
--------------------------------------+

local ve = require "merlib.vectors"

--- Simple algorithm for finding the fastest route to any of a given
--  table of end positions (including rotations), given a validation
--  function for obstacles
function fastestRouteMultiDestUseRot(start_pos, start_rot, endFunction, validFunction)
    local queue = {}
    table.insert(queue,
        {
            pos = start_pos:clone(),
            rot = start_rot,
            path = '',
        }
    )
    local explored = {}
    explored[start_pos:strXYZ(start_rot)] = true

    while #queue > 0 do
        local node = table.remove(queue, 1)
        if endFunction(node.pos, node.rot) then
            return node.path
        end
        for _, step in pairs({
                {pos = node.pos,                                     rot = ve.cardinal_left[node.rot],  path = node.path .. 'l'},
                {pos = node.pos,                                     rot = ve.cardinal_right[node.rot], path = node.path .. 'r'},
                {pos = node.pos:getAdjacentPos("forward", node.rot), rot = node.rot,                    path = node.path .. 'f'},
                {pos = node.pos:getAdjacentPos("up", node.rot),      rot = node.rot,                    path = node.path .. 'u'},
                {pos = node.pos:getAdjacentPos("down", node.rot),    rot = node.rot,                    path = node.path .. 'd'},
                }) do
            local explore_string = step.pos:strXYZ(step.rot)
            if not explored[explore_string] and
                (not validFunction or validFunction(step.pos:clone(), step.rot)) then
                explored[explore_string] = true
                table.insert(queue, step)
            end
        end
    end
end

--- Simple algorithm for finding the fastest route to any of a given
--  table of end positions, given a validation function for obstacles
function fastestRouteMultiDest(start_pos, endFunction, validFunction)
    local queue = {}
    table.insert(queue,
        {
            pos = start_pos:clone(),
            path = '',
        }
    )
    local explored = {}
    explored[start_pos:strXYZ()] = true

    while #queue > 0 do
        local node = table.remove(queue, 1)
        if endFunction(node.pos) then
            return node.path
        end
        for _, step in pairs({
                {pos = node.pos.getAdjacentPos("north"), path = node.path .. 'n'},
                {pos = node.pos.getAdjacentPos("south"), path = node.path .. 's'},
                {pos = node.pos.getAdjacentPos("east" ), path = node.path .. 'e'},
                {pos = node.pos.getAdjacentPos("west" ), path = node.path .. 'w'},
                {pos = node.pos.getAdjacentPos("up"   ), path = node.path .. 'u'},
                {pos = node.pos.getAdjacentPos("down" ), path = node.path .. 'd'},
                }) do
            local explore_string = step.pos:strXYZ()
            if not explored[explore_string] and
                (not validFunction or validFunction(step.pos)) then
                explored[explore_string] = true
                table.insert(queue, step)
            end
        end
    end
end

-- --- A* algorithm for finding the fastest route from a start position
-- --  to an end position, given a validation function for obstacles.
-- --  This version uses a priority queue to try to speed up the process
-- --  but in my tests wasn't actually much faster. Further research required.
-- --  Uses this: https://gist.github.com/LukeMS/89dc587abd786f92d60886f4977b1953
-- local PriorityQueue = require "lukems.priority_queue"
-- function fastestRoute(start_pos, end_pos, validFunction)

--     -- Create queue and starting node
--     local queue = PriorityQueue()
--     local start_distance = start_pos:distanceTo(end_pos)

--     local start_node = {
--         pos = start_pos:clone(),

--         -- g_score: path length from start
--         g_score = 0,

--         -- h_score: heuristic distance from end       
--         h_score = start_distance,

--         -- f_score: g_score + h_score
--         f_score = start_distance,
--     }

--     queue:put(start_node, start_node.f_score)

--     local visited = {[start_pos:strXYZ()] = true}

--     -- While nodes remain to be searched...
--     while true do

--         -- Remove best node (lowest f score)
--         local best_node = queue:pop()

--         -- If out of nodes, exit
--         if not best_node then
--             return
--         end

--         -- Check if end is reached
--         if best_node.pos == end_pos then

--             -- Build path back to start
--             local s = ""
--             local current_node = best_node
--             while current_node.from_node do
--                 s = current_node.from_dir .. s
--                 current_node = current_node.from_node
--             end
--             return s
--         end

--         -- For each neighbor...
--         for _, vector in pairs(ve.cardinal_vectors) do
--             local neighbor_pos = best_node.pos + vector
--             local neighbor_str_pos = neighbor_pos:strXYZ()

--             -- Check neighbor hasn't been visited & isn't an obstacle
--             if not visited[neighbor_str_pos] and
--                 (not validFunction or validFunction(neighbor_pos)) then

--                 -- Create neighbor node
--                 local neighbor_node = {
--                     pos = neighbor_pos,
--                     g_score = best_node.g_score + 1,
--                     h_score = neighbor_pos:distanceTo(end_pos)
--                 }
--                 neighbor_node.f_score = neighbor_node.g_score + neighbor_node.h_score

--                 -- Create bread crumbs
--                 neighbor_node.from_node = best_node
--                 neighbor_node.from_dir = best_node.pos:cardinalTo(neighbor_pos):sub(1, 1)

--                 -- Add to visited
--                 visited[neighbor_pos:strXYZ()] = true

--                 -- Add to queue
--                 queue:put(neighbor_node, neighbor_node.f_score)
                
--             end
--         end

--     end
-- end

--- A* algorithm for finding the fastest route from a start position
--  to an end position, given a validation function for obstacles
function fastestRoute(start_pos, end_pos, validFunction)

    -- Create queue and starting node
    local queue = {
        [start_pos:strXYZ()] = {
            pos = start_pos:clone(),

            -- g_score: path length from start
            g_score = 0,

            -- h_score: heuristic distance from end       
            h_score = start_pos:distanceTo(end_pos),

            -- f_score: g_score + h_score
            f_score = start_pos:distanceTo(end_pos),
        }
    }
    local visited = {}

    -- While nodes remain to be searched...
    while true do

        -- Find best node (lowest f score)
        local best_str_pos, best_node = next(queue)
        for str_pos, node in pairs(queue) do
            if node.f_score < best_node.f_score or
                    (node.f_score == best_node.f_score and
                    node.h_score < best_node.h_score) then
                best_node = node
                best_str_pos = str_pos
            end
        end

        -- If out of nodes, exit
        if not best_node then
            return
        end

        -- Remove node from queue, add to visited
        queue[best_str_pos] = nil
        visited[best_str_pos] = true

        -- Check if end is reached
        if best_node.pos == end_pos then

            -- Build path back to start
            local s = ""
            local current_node = best_node
            while current_node.from_node do
                s = current_node.from_dir .. s
                current_node = current_node.from_node
            end
            return s
        end

        -- For each neighbor...
        for cardinal, vector in pairs(ve.cardinal_vectors) do
            local neighbor_pos = best_node.pos + vector
            local neighbor_str_pos = neighbor_pos:strXYZ()

            -- Check neighbor hasn't been visited & isn't an obstacle
            if not (queue[neighbor_str_pos] or visited[neighbor_str_pos]) and
                (not validFunction or validFunction(neighbor_pos)) then

                -- Create neighbor node
                local neighbor_node = {
                    pos = neighbor_pos,
                    g_score = best_node.g_score + 1,
                    h_score = neighbor_pos:distanceTo(end_pos)
                }
                neighbor_node.f_score = neighbor_node.g_score + neighbor_node.h_score

                -- Create bread crumbs
                neighbor_node.from_node = best_node
                neighbor_node.from_dir = best_node.pos:cardinalTo(neighbor_pos):sub(1, 1)

                -- Add to queue
                queue[neighbor_str_pos] = neighbor_node
            end
        end

    end
end



--- A* algorithm for finding the fastest route from a start position
--  to an end position, given a validation function for obstacles
function fastestRouteUseRot(start_pos, start_rot, end_pos, end_rot, validFunction)
    error('not yet implemeted')

    -- Create queue and starting node
    local queue = {
        [start_pos:strXYZ(start_rot)] = {
            pos = start_pos:clone(),
            rot = start_rot,

            -- g_score: path length from start
            g_score = 0,

            -- h_score: heuristic distance from end       
            h_score = start_pos:distance(end_pos),

            -- f_score: g_score + h_score
            f_score = start_pos:distance(end_pos),
        }
    }
    local visited = {}

    -- While nodes remain to be searched...
    while true do

        -- Find best node (lowest f score)
        local best_node, best_str_pos_rot
        for str_pos_rot, node in pairs(queue) do
            if not best_node or
                    node.f_score < best_node.f_score or
                    (node.f_score == best_node.f_score and node.h_score < best_node.h_score)
                    then
                best_node = node
                best_str_pos_rot = str_pos_rot
            end
        end

        -- If out of nodes, exit
        if not best_node then
            return
        end

        -- Remove node from queue, add to visited
        queue[best_str_pos_rot] = nil
        visited[best_str_pos_rot] = true

        -- Check if end is reached
        if best_node.pos == end_pos then

            -- Build path back to start
            local s = ""
            local current_node = best_node
            while current_node.from_node do
                s = current_node.from_dir .. s
                current_node = current_node.from_node
            end
            return s
        end

        -- For each neighbor...
        for cardinal, vector in pairs(ve.cardinal_vectors) do
            local neighbor_pos = best_node.pos + vector
            local neighbor_str_pos = neighbor_pos:strXYZ()

            -- Check neighbor hasn't been visited & isn't an obstacle
            if not (queue[neighbor_str_pos] or visited[neighbor_str_pos]) and
                (not validFunction or validFunction(neighbor_pos)) then

                -- Create neighbor node
                local neighbor_node = {
                    pos = neighbor_pos,
                    g_score = best_node.g_score + 1,
                    h_score = neighbor_pos:distance(end_pos)
                }
                neighbor_node.f_score = neighbor_node.g_score + neighbor_node.h_score

                -- Create bread crumbs
                neighbor_node.from_node = best_node
                neighbor_node.from_dir = best_node.pos:cardinalTo(neighbor_pos):sub(1, 1)

                -- Add to queue
                queue[neighbor_str_pos] = neighbor_node
            end
        end

    end
end

-- test_func = function (pos) return (pos.y ~= 1 or (pos.x == 23 and pos.z == 56)) end
-- r = fastest_route({x = 0, y = 0, z = 0}, {x = 55, y = 55, z = 55}, test_func)


-- End module environment -------+
return mo.endModule(getfenv()) --|
---------------------------------+