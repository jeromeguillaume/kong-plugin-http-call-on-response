# kong plugin: call an Http Endpoint during the `header_filter` or `body_filter` phases

## Introduction
In the `header_filter` or `body_filter` phases  you are not allowed to call an Http Endpoint with `request_uri`:
```lua
local http  = require "resty.http"
local httpc = http.new()

local res, err = httpc:request_uri("https://httpbin.org/uuid", {
    method = "GET",
  })
```
 The following error will be raised:
```lua
failed to run header_filter_by_lua*: /usr/local/share/lua/5.1/kong/globalpatches.lua:581: API disabled in the context of header_filter_by_lua*
```

## Options
Two options are available in the `header_filter` or `body_filter` phases to workaround the limitation:
1) **Asynchronous** call of the Http Endpoint
- Use `ngx.timer.at` for invoking asynchronously a Lua function (called `asyncHttpCall`) in a background "light thread"
- The `asyncHttpCall` function is in charge of doing a `request_uri` (from `resty.http` library) and calling the Http Endpoint
- Pros: 
  - Able to call an Http Endpoint
  - Non-blocking call
- Cons:
  - Unable to use the result of Http Endpoint in the Response of the Upstream Service

2) **Synchronous** call of the Http Endpoint
- Use `ssl.https` for invoking synchronously the Http Endpoint
- Pros: 
  - Able to call an Http Endpoint
  - Able to use the result of Http Endpoint in the Response of the Upstream Service
- Cons:
  - Blocking call: if another request comes (and handled by the same worker process handling the synchronous call) the reponse will be delivered once the synchronous call is completed. Pay attention to KONG_NGINX_WORKER_PROCESSES: increase its value to decrease the risk of collision, but not avoid it.

## Example
The example included in this repository includes, for demonstration only, both options. Please choose one of them.