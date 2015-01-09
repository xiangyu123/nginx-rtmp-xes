-- Copyright 2014 ChinaCache Inc. All Rights Reserved.
-- Author: yiji.liu@chinacache.com (Yiji Liu)
--

--First, Define the module, and we will return the _M at the end of script;
local _M = {
    _VERSION = '1.0.1'
}

local mt = { __index = _M }

--Second, Got something Consistends
local DEFAULT_PORT = 80
local DEFAULT_RECONNECT_TIMES = 3

function _M.new(self)
    local http = require "resty.http"
    local remote_sock = http.new()
    if not remote_sock then
        return nil, "http.new() failed"
    end
    return setmetatable({remote_sock = remote_sock}, mt)
end

local function release_sock(self)
    local remote_sock = self.remote_sock
    if remote_sock then
        remote_sock:close()
        self.remote_sock = nil
    end
end

function _M.remote_connect(self, remote_addr, remote_port, retrytimes)
    local repeat_times = retrytimes or DEFAULT_RECONNECT_TIMES
    local addr = remote_addr
	local port = remote_port or DEFAULT_PORT
    local err_str = self.err_str or " "
    local remote_sock = self.remote_sock
    repeat
        local res, err = remote_sock:connect(addr, port);
        if not err then
            self.remote_sock = remote_sock
            return  remote_sock
        end
        repeat_times = repeat_times - 1  
    until repeat_times <  0
    err_str = err_str.."remote_sock can't connect remote"
    self.err_str = err_str
    release_sock(self)
    return nil, err_str
end

function _M.remote_request(self, req_headers, req_uri, retrytimes, body_data)
    local remote_sock = self.remote_sock
    local repeat_times = self.reconn_times or DEFAULT_RECONNECT_TIMES
    local remote_method = "GET"
    if  not self.remote_sock then
        return nil, "haven't create the remote_sock yet"
    end
	
    if body_data then
        remote_method = "POST"
    end
    repeat
        local remote_res, err = remote_sock:request {
            method = remote_method,
            path = req_uri,
            headers = req_headers,
            body = body_data or nil,
        }
        if not err then
            self.remote_res = remote_res
            return remote_res
        end
        repeat_times = repeat_times - 1
    until repeat_times < 0

    --close the bad socket
    release_sock(self)
    return nil, "send request to remote failed"
end


function _M.body_reader(self, size)
    local remote_res = self.remote_res
    local remote_sock = self.remote_sock
		self.body_chunk, err = self.body_reader(size) 
    return self.body_chunk, err 
end

function _M.remote_response_header(self)

	if self.remote_res == nil then
        return nil, "remote_res is nil"
	end
	
	local remote_res = self.remote_res
	local header = {}
	local status = ngx.HTTP_NOT_FOUND
	if remote_res ~= nil then
        status = remote_res.status
        for k,v in pairs(remote_res.headers) do
            header[k]=v
        end
    end
	
	self.body_reader = remote_res.body_reader
	
	return status, header
end

function _M.release(self, keepalive)
    if keepalive ~= 1 then
        release_sock(self)
    else
        self.remote_sock:set_keepalive()
    end
end

return _M
