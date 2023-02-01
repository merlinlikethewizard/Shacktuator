--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    Takes every file (recursively) from the <input_dirpath> and packs them into a single
    deployable file, <output_filepath>, by using the packer module. Will only pack files
    from a single directory (will ignore disks / rom).

    Usage:
    > pack.lua <input_dirpath> <output_filepath>

    To unpack:
    > package.lua [output_dirpath]

    Example:
    > merlib/programs/pack.lua . disk/package.lua
        ...
        Complete.
    > disk/package.lua
    > 
]]

package.path = "/?;/?.lua;" .. package.path
packer = require "merlib.packer"
packer.pack(...)