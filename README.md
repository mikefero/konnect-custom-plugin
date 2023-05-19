[![Unix build](https://img.shields.io/github/actions/workflow/status/mikefero/konnect-plugin-schema-validation/test.yml?branch=main&label=Test&logo=lua)](https://github.com/mikefero/konnect-plugin-schema-validation/actions/workflows/test.yml)
[![Luacheck](https://github.com/mikefero/konnect-plugin-schema-validation/workflows/Lint/badge.svg)](https://github.com/mikefero/konnect-plugin-schema-validation/actions/workflows/lint.yml)

# Konnect Plugin Schema Validation

Validate Kong Gateway plugin schemas using the Konnect Plugin Schema Validation
plugin. This plugin, when attached to a route, will only accept a JSON payload
which must contain a field `schema` with a string representation of a Kong
Gateway plugin schema to validate.

```
{
  "schema": "<kong-gateway-plugin-schema>"
}
```

## Configuration

While this plugin can be configured globally, it will have no effect and will
not perform plugin schema validation; ensure this plugin is configured on a
route.

### Enabling the plugin on a Route

Configure this plugin on a
[Route](https://docs.konghq.com/latest/admin-api/#Route-object) by using the
Kong Gateway admin API:

```
curl -X POST http://kong:8001/routes \
  --data 'name=plugin-schema-validation' \
  --data 'paths[]=/konnect/plugin/schema/validation'

curl -X POST http://kong:8001/routes/plugin-schema-validation/plugins \
  --data 'name=konnect-plugin-schema-validation'
```

## Validation of a Kong Gateway Plugin Schema

In order to properly validate a Kong Gateway plugin schema the string
representation must be properly escaped before adding it to the `schema` field
in the JSON body of the request. To validate a Kong Gateway plugin schema use
the proxy/client API using a `POST` method:

```
curl -X POST http://kong:8000/konnect/plugin/schema/validation \
  --header "content-type:application/json" \
  --data '{"schema": "local typedefs = require \"kong.db.schema.typedefs\"\nlocal PLUGIN_NAME = \"konnect-plugin-schema-validation\"\nlocal schema = {\nname = PLUGIN_NAME,\nfields = {\n{ consumer = typedefs.no_consumer },\n{ service = typedefs.no_service },\n{ protocols = typedefs.protocols_http },\n{ config = { type = \"record\", fields = {} } }\n}\n}\nreturn schema\n"}'
```
