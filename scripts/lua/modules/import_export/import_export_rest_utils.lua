--
-- (C) 2020 - ntop.org
--
local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/pools/?.lua;" .. package.path

require "lua_utils"
local json = require "dkjson"
local rest_utils = require "rest_utils"
local pools = require "pools"
local pools_lua_utils = require "pools_lua_utils"
local tracker = require("tracker")

-- ##############################################

local import_export_rest_utils = {}

import_export_rest_utils.IMPORT_EXPORT_JSON_VERSION = "1.0"

-- ##############################################

-- @brief Add an envelope to the module configurations
function import_export_rest_utils.pack(modules)
   local rc = rest_utils.consts.success.ok
   local envelope = {}

   -- Add a version to the envelope to track the dump version
   envelope.version = import_export_rest_utils.IMPORT_EXPORT_JSON_VERSION

   -- Add the configuration of all provided module
   envelope.modules = modules

   return envelope
end

-- ##############################################

-- @brief Decode the configuration in json format
-- and handle the envelope. Return the list of
-- configurations for all the modules to be imported. 
function import_export_rest_utils.unpack(json)  

   -- Decode the json
   if json == nil then
      return nil
   end

   local envelope = json.decode(json)

   -- Check the envelope format and version
   if not envelope or
      not envelope.version == nil or
      envelope.version ~= import_export_rest_utils.IMPORT_EXPORT_JSON_VERSION then
      return nil
   end

   return envelope.modules
end


-- ##############################################

-- @brief Import the configuration for a list of (provided)
-- module instances
function import_export_rest_utils.import(items) 
   local rc = rest_utils.consts.success.ok

   for name, module in pairs(items) do
      local res = module.instance:import(module.conf)
      if res.err then 
         rc = res.err     
      end
   end

   rest_utils.answer(rc)

   -- TRACKER HOOK
   tracker.log('import', { })
end

-- ##############################################

-- @brief Export the configuration for a list of (provided) module instances
function import_export_rest_utils.export(instances, is_download)
   local rc = rest_utils.consts.success.ok
   local modules = {}

   -- Build the list of configurations for each module
   for name, instance in pairs(instances) do
      local conf = instance:export()
      if not conf then
         rc = rest_utils.consts.err.internal_error 
      else
         modules[name] = conf
      end
   end

   local envelope = import_export_rest_utils.pack(modules)

   if is_download then
      -- Download as file
      sendHTTPContentTypeHeader('application/json', 'attachment; filename="configuration.json"')
      print(json.encode(envelope, nil))
   else
      -- Send as REST answer
      rest_utils.answer(rc, envelope)
   end

   -- TRACKER HOOK
   tracker.log('export', { })
end

-- ##############################################

return import_export_rest_utils
