local kong = kong
local ngx = ngx

local cjson = require "cjson.safe"
local entity = require "kong.db.schema.entity"
local errors = require "kong.db.errors"
local metaschema = require "kong.db.schema.metaschema"
local plugins_definition = require "kong.db.schema.entities.plugins"

local content_type_json = "application/json"

local konnect_plugin_schema_validation = {
  PRIORITY = 1000,
  VERSION = "0.1"
}

--- Checking the content type of the request to ensure it is valid for the
-- schema validation.
-- @param content_type Content type of the request.
-- @return True if content type is valid; false otherwise.
local function is_valid_content_type(content_type)
  if type(content_type) ~= "string" then
    return false
  end

  if string.find(content_type, content_type_json, 1, true) ~= nil then
    return true
  end
  return false
end

--- Determine if "a thing" is empty or not.
-- @param value Any value; e.g. "a thing".
-- @return True if value is empty; false otherwise.
local function is_empty(value)
  if value == nil
     or value == ngx.null
     or (type(value) == "table" and not next(value))
     or (type(value) == "string" and value == "") then
    return true
  end

  return false
end

--- Check the contents of a plugin schema string representation and ensure that
-- it is valid metaschema. All fields and attributes are validated
-- while executing checks against the entire plugin schema.
-- @param input The string representation of the plugin schema.
-- @return Instantiated plugins subschema entity and loaded plugin schema;
--         otherwise nil with error if validation fails.
local function validate_plugin_schema(input)
  -- Load the input into a compiled Lua function which will represent the
  -- plugin schema for further validations.
  --
  -- Note: "pcall" is used for this operation to ensure proper error handling
  -- for "assert" calls performed in the "load" function.
  local plugin_schema
  local pok, perr = pcall(function()
    local err
    plugin_schema, err = load(input)()
    if err then
      return error("error processing load for plugin schema: " .. err)
    end
  end)
  if not pok then
    return nil, nil, perr
  end
  if is_empty(plugin_schema) then
    return nil, nil, "invalid schema for plugin: cannot be empty"
  end

  -- Complete the validation of the plugin schema.
  --
  -- Note: "pcall" is used for this operation to ensure proper error handling
  -- for "assert" calls performed in the "MetaSubSchema:validate" function.
  -- When validating the fields of the plugin schema an "assert" is possible.
  local pok, perr = pcall(function()
    local ok, err = metaschema.MetaSubSchema:validate(plugin_schema)
    if not ok then
      return error(errors:schema_violation(err))
    end
  end)
  if not pok then
    return nil, nil, perr
  end

  -- Load the plugin schema for use in configuration validation when
  -- associated with a plugins subschema entity
  local plugins_subschema_entity, err = entity.new(plugins_definition)
  if err then
    return nil, nil, "unable to create plugin entity: " .. err
  end
  local plugin_name = plugin_schema.name
  -- Note: "pcall" is used for this operation to ensure proper error handling
  -- for "assert" calls performed in the "entity:new_subschema" function. When
  -- iterating the arrays/fields of the plugin schema an "assert" is possible.
  pok, perr = pcall(function()
    local ok, err = plugins_subschema_entity:new_subschema(plugin_name, plugin_schema)
    if not ok then
      return error("error loading schema for plugin " .. plugin_name .. ": " .. err)
    end
  end)
  if not pok then
    return nil, nil, perr
  end

  return plugins_subschema_entity, plugin_schema, nil
end

--- Access handler for the Konnect Plugin Schema Validation plugin. This
-- handler will validate plugin schemas via a POST method and process the JSON
-- body utilizing the "schema" field. On sucessful plugin schema validation the
-- JSON body will be returned; otherwise the JSON body will contain an error
-- message along with an appropriate status code.
function konnect_plugin_schema_validation:access(conf)
  if kong.request.get_method() ~= "POST" then
    return kong.response.error(405) -- Method not allowed
  end
  if not is_valid_content_type(kong.request.get_header("Content-Type")) then
    return kong.response.error(415) -- Unsupported media type
  end

  local body, err = kong.request.get_body()
  if err then
    return kong.response.error(400, "unable to get request body: " .. err) -- Bad request
  end
  if is_empty(body.schema) then
    return kong.response.error(400, "missing schema field") -- Bad request
  end
  local _, plugin_schema, err = validate_plugin_schema(body.schema)
  if err then
    -- Handle error messages that already that are already formatted
    if type(err) == "string" then
      return kong.response.error(400, err) -- Bad request
    end

    -- Remove extra fields if message is present
    local rmessage = err
    if err.message then
      rmessage = {
        message = err.message
      }
    end
    return kong.response.exit(400, rmessage, { ["Content-Type"] = "application/json" }) -- Bad request
  end
  if plugin_schema == nil then
    return kong.response.error(500, "validated plugin_schema is empty")
  end

  -- Add the plugin name to the response along with the original schema
  local resp = {
    name = plugin_schema.name,
    schema = body.schema
  }
  return kong.response.exit(200, cjson.encode(resp)) -- OK
end

return konnect_plugin_schema_validation
