--[[
    Copyright (c) 2023 MerlinLikeTheWizard. All rights reserved.

    This work is licensed under the terms of the MIT license.  
    For a copy, see <https://opensource.org/licenses/MIT>.

    ----------

    Takes every file (recursively) from the <input_dirpath> and packs them into a single
    deployable file, <output_filepath>, by using the houses module.
]]

package.path = "/?;/?.lua;" .. package.path
packer = require "merlib.packer"
packer.pack(...)