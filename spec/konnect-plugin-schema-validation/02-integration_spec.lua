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
        route = { id = route.id },
        config = {

        },
      }

      assert(helpers.start_kong({
        database   = strategy,
        nginx_conf = "spec/fixtures/custom_nginx.template",
        plugins = "bundled," .. PLUGIN_NAME,
        declarative_config = strategy == "off" and helpers.make_yaml_file() or nil,
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
          local schema = [[
            local typedefs = require "kong.db.schema.typedefs"
            local PLUGIN_NAME = "konnect-plugin-schema-validation"
            local schema = {
              name = PLUGIN_NAME,
              fields = {
                { consumer = typedefs.no_consumer },
                { service = typedefs.no_service },
                { protocols = typedefs.protocols_http },
                { config = { type = "record", fields = {} } }
              }
            }
            return schema
          ]]
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
          assert.same({ schema = schema }, json)
        end)

        it("fails when schema definition is invalid", function()
          local r = client:post("/konnect/plugin/schema/validation", {
            headers = {
              ["Content-Type"] = "application/json"
            },
            body = {
              schema = "invalid schema"
            }
          })
          assert.response(r).has.status(400)
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
        end)
      end)
    end)
  end
end
