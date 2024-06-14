-- handler.lua
local plugin = {
    PRIORITY = 1,
    VERSION = "0.1",
  }

local https   = require("ssl.https")
  
function plugin:access(plugin_conf)

  kong.service.request.set_header(plugin_conf.request_header, "this is on a request")
  
  kong.service.request.enable_buffering()
  
end
  
  
function plugin:header_filter(plugin_conf)  
  kong.response.set_header(plugin_conf.response_header, plugin.VERSION)

  -- Get the body response from the Upstream Service
  if kong.response.get_source() == "service" then
    local body = kong.service.response.get_raw_body()
    if kong.response.get_header("Content-Encoding") == "gzip" then
      local kongGzip = require("kong.tools.gzip")
      local bodyInflated, err = kongGzip.inflate_gzip(body)
      body = bodyInflated
    end
    kong.log.notice("Response from 'Upstream Service': " .. body)
  else
    kong.log.err("Error on 'Upstream Service' call")
  end

  local http  = require "resty.http"
  local httpc = http.new()

  local res, err = httpc:request_uri("https://httpbin.org/uuid", {
    method = "GET",
  })

  -- Call Asynchronously an Http Endpoint: NON blocking request
  -- BUT unable to handle the response (from the Http Endpoint) and use it in the current response (handled by this function)
  local url = "https://httpbin.org/anything"
  local ret, err = ngx.timer.at(0, plugin.asyncHttpCall, nil, url)
  if not ret then
    kong.log.err("Unable to start 'asyncHttpCall' Timer: ", err)
  end

-- Call Synchronously an Http Endpoint: BLOCKING request (avoid it)
-- able to handle the response (from the Http Endpoint) and use it in the current response (handled by this function)
  https.TIMEOUT = 1
  local url = "https://httpbin.org/uuid"
  local response_body, response_code, response_headers = https.request(url)
  if response_code == 200 and response_body then
    kong.log.notice("Sync HTTP Endpoint Call OK: " .. url .. " httpStatus: " .. response_code .. " body: " .. response_body)
  else
    kong.log.notice("Sync HTTP Endpoint Call KO: " .. url .. " httpStatus: " .. response_code)
  end
end

-- Timer function for asynchronous HTTP Endpoint call
function plugin:asyncHttpCall (premature, url)
  -- If the Nginx worker is shutting down
  if premature then
    kong.log.notice("asyncHttpCall: premature is true. Don't execute the HTTP Endpoint Call")
    -- stop the timer
    return
  end
  local http  = require "resty.http"
  local httpc = http.new()

  local res, err = httpc:request_uri(url, {
    method = "GET",
  })
  if not res then
    kong.log.err("Async HTTP Endpoint Call KO: " .. url .. " err: " .. err)
  elseif res.status ~= 200 then
    kong.log.err("Async HTTP Endpoint Call KO: " .. url .. " httpStatus: " .. res.status)
  elseif res.status == 200 then
    kong.log.notice("Async HTTP Endpoint Call OK: " .. url .. " httpStatus: " .. res.status)
  end
  
end

function plugin:body_filter(plugin_conf)  

end


return plugin