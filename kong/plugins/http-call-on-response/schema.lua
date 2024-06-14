
local typedefs = require "kong.db.schema.typedefs"


return {
  name = "rest-call-on-response",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { request_header = typedefs.header_name {required = true, default = "X-Lua-Plugin" } },
          { response_header = typedefs.header_name {required = true, default = "X-Lua-Version" } },
        },
    }, },
  },
}