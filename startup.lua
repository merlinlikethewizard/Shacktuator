--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    A few things that run on startup to make the turtle happy.
    Not necessary to have things work, but can be useful.
]]

-- Make merlib library globally available as an API
_G.merlib = {}
merlib.actions = require "merlib.actions"
merlib.algs = require "merlib.algs"
merlib.basics = require "merlib.basics"
merlib.blueprints = require "merlib.blueprints"
merlib.houses = require "merlib.houses"
merlib.mining = require "merlib.mining"
merlib.namer = require "merlib.namer"
merlib.packer = require "merlib.packer"
merlib.paths = require "merlib.paths"
merlib.state = require "merlib.state"
merlib.vectors = require "merlib.vectors"

-- Name the turtle
merlib.namer.nameTurtle()

-- Calibrate turtle if GPS is available
merlib.actions.calibrate()

-- Make house instantly on startup (uncomment)
shell.run("instashack")