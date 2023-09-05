local helpers = require "spec.helpers"
local PLUGIN_NAME = "konnect-plugin-schema-validation"

for _, strategy in helpers.all_strategies() do if strategy ~= "cassandra" then
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()
      local bp = helpers.get_db_utils(strategy == "off" and "postgres" or strategy, nil, { PLUGIN_NAME })
      local route = bp.routes:insert({
        paths = { "/konnect/plugin/schema/validation" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route.id }
      }

      assert(helpers.start_kong({
        database   = strategy,
        nginx_conf = "spec/fixtures/custom_nginx.template",
        plugins = "bundled," .. PLUGIN_NAME,
        declarative_config = strategy == "off" and helpers.make_yaml_file() or nil
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)

    describe("request", function()
      describe("validation")
        it("accepts schema definition", function()
          local schema_name = "plugin-schema"
          local schema = string.format([[
            return {
              name = "%s",
              fields = {
                { config = { type = "record", fields = {} } }
              }
            }
          ]], schema_name)
          local r = client:post("/konnect/plugin/schema/validation", {
            headers = {
              ["Content-Type"] = "application/json"
            },
            body = {
              schema = schema
            }
          })
          assert.response(r).has.status(200)
          local json = assert.response(r).has.jsonbody()
          assert.same({
            name = schema_name,
            schema = schema
          }, json)
        end)

        it("fails when schema definition is invalid - missing fields", function()
          local r = client:post("/konnect/plugin/schema/validation", {
            headers = {
              ["Content-Type"] = "application/json"
            },
            body = {
              schema = [[
                return {
                  name = "invalid-schema-missing-fields",
                  missing_fields = {}
                }
              ]]
            }
          })
          assert.response(r).has.status(400)
        end)

        it("fails when schema definition is invalid - nil function", function()
          local r = client:post("/konnect/plugin/schema/validation", {
            headers = {
              ["Content-Type"] = "application/json"
            },
            body = {
              schema = "return schema"
            }
          })
          assert.response(r).has.status(400)
        end)

        it("fails when schema definition is invalid - missing plugin name", function()
          local r = client:post("/konnect/plugin/schema/validation", {
            headers = {
              ["Content-Type"] = "application/json"
            },
            body = {
              schema = [[
                return {
                  fields = {
                    { config = { type = "record", fields = {} } }
                  }
                }
              ]]
            }
          })
          assert.response(r).has.status(400)
          local json = assert.response(r).has.jsonbody()
          assert.same({
            message = "invalid schema for plugin: missing plugin name"
          }, json)
        end)

        it("fails when using invalid method", function()
          local r = client:get("/konnect/plugin/schema/validation", {})
          assert.response(r).has.status(405)
        end)

        it("fails when using invalid content-type", function()
          local r = client:post("/konnect/plugin/schema/validation", {
            headers = {
              ["Content-Type"] = "text/html; charset=utf-8"
            },
          })
          assert.response(r).has.status(415)
        end)

        it("fails when body is missing", function()
          local r = client:post("/konnect/plugin/schema/validation", {
            headers = {
              ["Content-Type"] = "application/json"
            },
          })
          assert.response(r).has.status(400)
        end)

        it("fails when schema definition is missing", function()
          local r = client:post("/konnect/plugin/schema/validation", {
            headers = {
              ["Content-Type"] = "application/json"
            },
            body = {}
          })
          assert.response(r).has.status(400)
          local json = assert.response(r).has.jsonbody()
          assert.same({
            message = "missing schema field"
          }, json)
        end)

        it("fails when schema definition is empty", function()
          local r = client:post("/konnect/plugin/schema/validation", {
            headers = {
              ["Content-Type"] = "application/json"
            },
            body = {
              schema = "return"
            }
          })
          assert.response(r).has.status(400)
          local json = assert.response(r).has.jsonbody()
          assert.same({
            message = "invalid schema for plugin: cannot be empty"
          }, json)
        end)
      end)
    end)
  end
end
