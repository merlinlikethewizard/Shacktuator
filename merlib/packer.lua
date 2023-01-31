-- This code © 2023 by Merlin is licensed under CC BY-SA 4.0.

--[[
    Takes every file (recursively) from the <input_dirpath> and packs them into a single
    deployable file, <output_filepath>. This is the most meta program I have ever written.
]]

-- Start module environment ----------+
local mo = require "merlib.modules" --|
mo.startModule(_ENV)                --|
--------------------------------------+

function pack(input_dirpath, output_filepath)
    -- GET PATHS
    if not input_dirpath then
        input_dirpath = ''
    end
    local path = shell.resolve(input_dirpath)
    if not fs.isDir(path) then
        error('"' .. path .. '" is not a directory')
    end
    if not output_filepath then
        error('must specify output filepath')
    end
    local drive = fs.getDrive(input_dirpath)

    -- WRITE [GET PATHS] TO OUTPUT FILE
    s = [[
    output_dir = ...
    if not output_dir then
        output_dir = ''
    end
    path = shell.resolve(output_dir)
    if not fs.isDir(path) then
        error(path .. ' is not a directory')
    end

    files = {
    ]]

    -- WRITE [ALL FILES] TO TABLE IN OUTPUT FILE
    queue = {''}
    while #queue > 0 do
        dir_name = table.remove(queue)
        path_name = fs.combine(path, dir_name)
        print(path_name)
        if fs.getDrive(path_name) == drive then
            for _, object_name in pairs(fs.list(path_name)) do
                if not string.match(object_name, '^[.]') then
                    sub_dir_name = fs.combine(dir_name, object_name)
                    sub_path_name = fs.combine(path, sub_dir_name)
                    if fs.isDir(sub_path_name) then
                        table.insert(queue, sub_dir_name)
                    elseif object_name ~= 'conglomerate.lua' then
                        print("Packing " .. sub_path_name)
                        local file_contents = fs.open(sub_path_name, 'r').readAll()
                        if string.find(file_contents, ']=' .. '==]') then
                            error('file ' .. sub_path_name .. ' contains occurance of the string "]=' .. '==]"')
                        end
                        s = s .. ('    ["' .. sub_dir_name .. '"] = [=' .. '==[' .. file_contents .. ']=' .. '==],\n')
                    end
                end
            end
        end
    end

    -- WRITE [WRITE OUTPUT FILES] TO OUTPUT FILE
    --     Are you confused enough yet? I am.
    s = s .. [[
    }

    for k, v in pairs(files) do
        local file = fs.open(fs.combine(path, k), 'w')
        file.write(v)
        file.close()
    end
    ]]

    -- OPEN OUTPUT FILE
    print("Writing to file...")
    file = fs.open(output_filepath, 'w')
    file.write(s)
    file.close()
    print("Complete.")
end

-- End module environment -------+
return mo.endModule(getfenv()) --|
---------------------------------+