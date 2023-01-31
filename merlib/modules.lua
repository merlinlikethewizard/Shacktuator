--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    This module is meant to make the writing and importing of modules much easier
    by removing the need to return a table of functions at the end of each module.
    Instead, a table is automatically returned with all of the global functions.

    Instructions, paste this at the top of your module:

-- Start module environment ----------+
local mo = require "merlib.modules" --|
mo.startModule(_ENV)                --|
--------------------------------------+

    And this at the bottom:

-- End module environment -------+
return mo.endModule(getfenv()) --|
---------------------------------+

    And now you're ready for an easy import!

]]

-- Start module environment --------------+
local the_env = {}                      --|
setmetatable(the_env, {__index = _ENV}) --|
setfenv(1, the_env)                     --|
------------------------------------------+

function startModule(env)
    local new_env = {} -- Create a new environment for the module
    setmetatable(new_env, {__index = env}) -- Make the new enviroment inherit from the current one
    setfenv(2, new_env) -- Start up the new environment, in the encompassing context (the module)
end

function endModule(env)
    local meta_table = {} -- Make meta table for the proxy
    function meta_table.__index(in_table, in_key)
        return rawget(env, in_key) -- If proxy is indexed, return the value from the env (excluding inherited fields)
    end
    function meta_table.__pairs(in_table)
        return next, env -- Allow for the proxy to be iterated over (tab completion)
    end
    function meta_table.__ipairs(in_table)
        function inext(tbl, i)
            i = i + 1
            local v = tbl[i]
            if v ~= nil then return i, v end
        end
        return inext, env, 0 -- Allow for the proxy to be iterated over (pretty printing)
    end
    local proxy = {} -- Create proxy table
    setmetatable(proxy, meta_table)
    return proxy -- Send back to be returned at end of module
end

-- End module environment ----+
return endModule(getfenv()) --|
------------------------------+