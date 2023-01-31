-- This code © 2023 by Merlin is licensed under CC BY-SA 4.0.

-- Start module environment ----------+
local mo = require "merlib.modules" --|
mo.startModule(_ENV)                --|
--------------------------------------+

local st = require "merlib.state"
local ve = require "merlib.vectors"
local ba = require "merlib.basics"

local dig_disallow = {}

-- Quick functions
move_raw = {up = turtle.up, down = turtle.down, forward = turtle.forward, back = turtle.back, left = turtle.turnLeft, right = turtle.turnRight}
detect_raw = {forward = turtle.detect, up = turtle.detectUp, down = turtle.detectDown}
inspect_raw = {forward = turtle.inspect, up = turtle.inspectUp, down = turtle.inspectDown}
dig_raw = {forward = turtle.dig, up = turtle.digUp, down = turtle.digDown}
attack_raw = {forward = turtle.attack, up = turtle.attackUp, down = turtle.attackDown}

local function logMovement(direction)
    if not st.calibrated then
        print("WARNING, turtle movement while uncalibrated!")
    end
    if direction == 'up' then
        st.pos.y = st.pos.y + 1
    elseif direction == 'down' then
        st.pos.y = st.pos.y - 1
    elseif direction == 'forward' then
        st.pos:increment(ve.cardinal_vectors[st.rot])
    elseif direction == 'back' then
        st.pos:decrement(ve.cardinal_vectors[st.rot])
    elseif direction == 'left' then
        st.rot = ve.cardinal_left[st.rot]
    elseif direction == 'right' then
        st.rot = ve.cardinal_right[st.rot]
    end
    return true
end

function backDig()
    move_raw['right']()
    move_raw['right']()
    safeDig('forward')
    result = move_raw['forward']()
    move_raw['right']()
    move_raw['right']()
    if result then
        logMovement('back')
        return true
    end
    return false
end

function go(direction, dig_allowed)
    if dig_allowed and dig_raw[direction] then safeDig(direction) end
    if move_raw[direction]() then
        logMovement(direction)
        return true
    end
    if direction == 'back' and dig_allowed then return backDig() end
    if attack_raw[direction] then attack_raw[direction]() end
    return false
end
function up(dig_allowed) return go('up', dig_allowed) end
function down(dig_allowed) return go('down', dig_allowed) end
function forward(dig_allowed) return go('forward', dig_allowed) end
function back(dig_allowed) return go('back', dig_allowed) end
function left() return go('left') end
function right() return go('right') end
function north(dig_allowed) return goCardinal('north', dig_allowed) end
function south(dig_allowed) return goCardinal('south', dig_allowed) end
function east(dig_allowed) return goCardinal('east', dig_allowed) end
function west(dig_allowed) return goCardinal('west', dig_allowed) end
function goCardinal(cardinal, dig_allowed)
    if not face(cardinal) then return false end
    return forward(dig_allowed)
end
function goAbsolute(direction, dig_allowed)
    while not go(direction, dig_allowed) do sleep(0) end
end

function face(rot)
    if not st.calibrated then
        print("WARNING: Attempt to call face() when uncalibrated!")
    end
    if st.rot == rot then
        return true
    elseif ve.cardinal_right[st.rot] == rot then
        if not go('right') then return false end
    elseif ve.cardinal_left[st.rot] == rot then
        if not go('left') then return false end
    elseif ve.cardinal_reverse[st.rot] == rot then
        if not go('right') then return false end
        if not go('right') then return false end
    else
        return false
    end
    return true
end

function open_rednet()
    peripheral.find('modem').open(1)
end

--- Geoposition by moving to adjacent block and back
if st.calibrated == nil then
    st.calibrated = false
end
function calibrate()
    -- Get starting position
    local sx, sy, sz = gps.locate()
    if not sx or not sy or not sz then return false end
    sv = ve.Vector3.new(sx, sy, sz)

    -- Try to find empty adjacent block
    for i = 1, 4 do
        if not turtle.detect() then break end
        if not turtle.turnRight() then return false end
    end

    -- Try to dig adjacent block
    if turtle.detect() then
        for i = 1, 4 do
            safeDig('forward')
            if not turtle.detect() then break end
            if not turtle.turnRight() then return false end
        end
        if turtle.detect() then return false end
    end

    -- Go forward
    if not turtle.forward() then return false end

    -- Get ending position
    local nx, ny, nz = gps.locate()
    if not nx or not ny or not nz then return false end
    nv = ve.Vector3.new(nx, ny, nz)
    st.rot = sv:cardinalTo(nv)
    if not st.rot then return false end

    -- Set position
    st.pos.x = nx
    st.pos.y = ny
    st.pos.z = nz
    st.calibrated = true

    -- Go back if possible
    back()

    -- Wrap up
    print('Calibrated to ' .. st.pos:strXYZ(st.rot))

    return true
end

shortMoves = {u = up, d = down, f = forward, b = back, l = left, r = right, n = north, s = south, e = east, w = west}
function followRoute(route, dig_allowed)
    if route == nil then
        error('Route provided was nil')
    end
    for char in route:gmatch'.' do
        if not shortMoves[char](dig_allowed) then return false end
    end
    return true
end

function followPath(path, offset, dig_allowed)
    for _ = 1, #path do
        local move_str = path:next(st.pos - offset)
        if not move_str then break end
        if not ac.shortMoves[move_str](dig_allowed) then return false end
    end
end


--- Dig if block not on disallow list
function safeDig(direction)
    direction = direction or 'forward'

    local block_name = ({inspect_raw[direction]()})[2].name
    if block_name then
        for _, word in pairs(dig_disallow) do
            if string.find(string.lower(block_name), word) then return false end
        end
        return dig_raw[direction]()
    end
    return true
end


function setDigDisallow(new_table)
    for k in pairs(dig_disallow) do dig_disallow[k] = nil end
    for _, value in pairs(new_table) do table.insert(dig_disallow, value) end
    return true
end


function goDownToGround()
    while not inspect_raw.down() do
        if not down() then return false end
    end
    return true
end


function getAdjacentPos(direction)
    return st.pos:getAdjacentPos(direction, st.rot)
end


function selectItem(item_name)
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == item_name then
            turtle.select(slot)
            return true
        end
    end
    return false
end

function manualRefuel()
    turtle.select(1)
    print("Please refuel turtle by placing fuel in slot 1.")
    print("Press F to consume. Press C when complete.")
    while true do
        term.setCursorPos(1, ({term.getCursorPos()})[2])
        term.write("Current fuel level: " .. turtle.getFuelLevel() .. "                   ")
        local event, arg1, arg2, arg3 = os.pullEvent()
        if event == "key" then
            if arg1 == keys.f then
                turtle.refuel()
            elseif arg1 == keys.c then
                sleep(0)
                return
            end
        end
    end
end


-- End module environment -------+
return mo.endModule(getfenv()) --|
---------------------------------+