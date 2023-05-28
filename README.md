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
  --data 'name=konnect-plugin-schema-validation' \
  --data 'paths[]=/konnect/plugin/schema/validation'

curl -X POST http://kong:8001/routes/konnect-plugin-schema-validation/plugins \
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

## Example

Validate a configuration for the third party
[Moesif custom plugin](https://docs.konghq.com/hub/moesif/kong-plugin-moesif/)
which captures and logs Kong Gateway traffic for
[Moesif API Analytics](https://www.moesif.com).

- `schema`: [schema.lua](https://github.com/Moesif/kong-plugin-moesif/blob/master/kong/plugins/moesif/schema.lua)

### Request

```
curl -X POST http://kong:8000/konnect/plugin/schema/validation \
  --header "content-type:application/json" \
  --data '{"schema": "local typedefs = require \"kong.db.schema.typedefs\"\n\nreturn {\n  name = \"moesif\",\n  fields = {\n    {\n      consumer = typedefs.no_consumer\n    },\n    {\n      protocols = typedefs.protocols_http\n    },\n    {\n      config = {\n        type = \"record\",\n        fields = {\n          {\n            api_endpoint = {required = true, type = \"string\", default = \"https://api.moesif.net\"}\n          },\n          {\n            timeout = {default = 1000, type = \"number\"}\n          },\n          {\n            connect_timeout = {default = 1000, type = \"number\"}\n          },\n          {\n            send_timeout = {default = 2000, type = \"number\"}\n          },\n          {\n            keepalive = {default = 5000, type = \"number\"}\n          },\n          {\n            event_queue_size = {default = 1000, type = \"number\"}\n          },\n          {\n            api_version = {default = \"1.0\", type = \"string\"}\n          },\n          {\n            application_id = {required = true, default = nil, type=\"string\"}\n          },\n          {\n            disable_capture_request_body = {default = false, type = \"boolean\"}\n          },\n          {\n            disable_capture_response_body = {default = false, type = \"boolean\"}\n          },\n          {\n            request_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            request_body_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            request_header_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            response_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            response_body_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            response_header_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            batch_size = {default = 200, type = \"number\", elements = typedefs.header_name}\n          },\n          {\n            disable_transaction_id = {default = false, type = \"boolean\"}\n          },\n          {\n            debug = {default = false, type = \"boolean\"}\n          },\n          {\n            disable_gzip_payload_decompression = {default = false, type = \"boolean\"}\n          },\n          {\n            user_id_header = {default = nil, type = \"string\"}\n          },\n          {\n            authorization_header_name = {default = \"authorization\", type = \"string\"}\n          },\n          {\n            authorization_user_id_field = {default = \"sub\", type = \"string\"}\n          },\n          {\n            authorization_company_id_field = {default = nil, type = \"string\"}\n          },\n          {\n            company_id_header = {default = nil, type = \"string\"}\n          },\n          {\n            max_callback_time_spent = {default = 750, type = \"number\"}\n          },\n          {\n            request_max_body_size_limit = {default = 100000, type = \"number\"}\n          },\n          {\n            response_max_body_size_limit = {default = 100000, type = \"number\"}\n          },\n          {\n            request_query_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            enable_reading_send_event_response = {default = false, type = \"boolean\"}\n          },\n          {\n            disable_moesif_payload_compression = {default = false, type = \"boolean\"}\n          },\n        },\n      },\n    },\n  },\n  entity_checks = {}\n}"}'
```

### Response

```
{
  "schema": "local typedefs = require \"kong.db.schema.typedefs\"\n\nreturn {\n  name = \"moesif\",\n  fields = {\n    {\n      consumer = typedefs.no_consumer\n    },\n    {\n      protocols = typedefs.protocols_http\n    },\n    {\n      config = {\n        type = \"record\",\n        fields = {\n          {\n            api_endpoint = {required = true, type = \"string\", default = \"https://api.moesif.net\"}\n          },\n          {\n            timeout = {default = 1000, type = \"number\"}\n          },\n          {\n            connect_timeout = {default = 1000, type = \"number\"}\n          },\n          {\n            send_timeout = {default = 2000, type = \"number\"}\n          },\n          {\n            keepalive = {default = 5000, type = \"number\"}\n          },\n          {\n            event_queue_size = {default = 1000, type = \"number\"}\n          },\n          {\n            api_version = {default = \"1.0\", type = \"string\"}\n          },\n          {\n            application_id = {required = true, default = nil, type=\"string\"}\n          },\n          {\n            disable_capture_request_body = {default = false, type = \"boolean\"}\n          },\n          {\n            disable_capture_response_body = {default = false, type = \"boolean\"}\n          },\n          {\n            request_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            request_body_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            request_header_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            response_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            response_body_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            response_header_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            batch_size = {default = 200, type = \"number\", elements = typedefs.header_name}\n          },\n          {\n            disable_transaction_id = {default = false, type = \"boolean\"}\n          },\n          {\n            debug = {default = false, type = \"boolean\"}\n          },\n          {\n            disable_gzip_payload_decompression = {default = false, type = \"boolean\"}\n          },\n          {\n            user_id_header = {default = nil, type = \"string\"}\n          },\n          {\n            authorization_header_name = {default = \"authorization\", type = \"string\"}\n          },\n          {\n            authorization_user_id_field = {default = \"sub\", type = \"string\"}\n          },\n          {\n            authorization_company_id_field = {default = nil, type = \"string\"}\n          },\n          {\n            company_id_header = {default = nil, type = \"string\"}\n          },\n          {\n            max_callback_time_spent = {default = 750, type = \"number\"}\n          },\n          {\n            request_max_body_size_limit = {default = 100000, type = \"number\"}\n          },\n          {\n            response_max_body_size_limit = {default = 100000, type = \"number\"}\n          },\n          {\n            request_query_masks = {default = {}, type = \"array\", elements = typedefs.header_name}\n          },\n          {\n            enable_reading_send_event_response = {default = false, type = \"boolean\"}\n          },\n          {\n            disable_moesif_payload_compression = {default = false, type = \"boolean\"}\n          },\n        },\n      },\n    },\n  },\n  entity_checks = {}\n}"
}
```
