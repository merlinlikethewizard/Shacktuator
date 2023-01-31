-- This code © 2023 by Merlin is licensed under CC BY-SA 4.0.

-- Make merlib library globally available (not necessary but useful)
_G.merlib = {}
_G.merlib.actions = require "merlib.actions"
_G.merlib.algs = require "merlib.algs"
_G.merlib.basics = require "merlib.basics"
_G.merlib.blueprints = require "merlib.blueprints"
_G.merlib.houses = require "merlib.houses"
_G.merlib.mining = require "merlib.mining"
_G.merlib.namer = require "merlib.namer"
_G.merlib.packer = require "merlib.packer"
_G.merlib.paths = require "merlib.paths"
_G.merlib.state = require "merlib.state"
_G.merlib.vectors = require "merlib.vectors"

-- Calibrate turtle if GPS is available
merlib.actions.calibrate()