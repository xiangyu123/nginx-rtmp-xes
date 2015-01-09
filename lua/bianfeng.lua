-- Copyright 2014 ChinaCache Inc. All Rights Reserved.
-- Author: yiji.liu@chinacache.com (Yiji Liu)

-- report property
--set $node 127.0.0.1;
--set $start_url http://www.zhanqi.tv/api/anchor/live_user.setlivestart;
--set $end_url http://www.zhanqi.tv/api/anchor/live_user.setlivestop;
--set $private_key dfvFb52!^$#vv@zhanqi;

local TIME_OUT = 10
local token_check = ngx.var.token_check or 0
local key_label = ngx.var.key_label or "k"
local time_label = ngx.var.time_label or "t"
local token_key = ngx.var.token_key
local node = ngx.var.node
local report_url = ngx.var.report_url
local report_port = ngx.var.report_port or 80
local start_uri = ngx.var.start_uri
local end_uri = ngx.var.end_uri
local report_uri = start_uri
local private_key = ngx.var.private_key
local retry_count = ngx.var.retry_count or 3
local time_out = ngx.var.time_out or TIME_OUT * 1000
local white_ip = ngx.var.white_ip or nil

local req_args = ngx.req.get_uri_args()
local originIP = req_args["addr"];
local tcurl = req_args["tcurl"]
local app = tcurl
local appname = req_args["app"]
local id = req_args["name"]
local time = ngx.time()
local sign =  ngx.md5(id.."_"..originIP.."_"..private_key.."_"..time)
local calltype = req_args["call"]

--local variable
local remote_request = require "common.remote_request"
local request = nil
local pos = -1
local sendheader = {}
local err = nil
local res = nil
local header = nil

if not originIP or not app or not appname or not id or not sign or not report_url or not start_uri or not end_uri or not private_key or not token_key then
	ngx.log(ngx.ERR, "Bianfeng : configure error")
	goto ERROR
end

--get host information from tcurl
pos = string.find(app, "//")
if pos ~= nil then
	app = string.sub(app, pos + 2, -1)
end

pos = string.find(app, ":")
if pos ~= nil then
	app = string.sub(app, 1, pos - 1)
else
	pos = string.find(app, "/")
	if pos ~= nil then
		app = string.sub(app, 1, pos - 1)
	end
end

--ngx.log(ngx.ERR, "Bianfeng : calltype "..calltype)
--ngx.log(ngx.ERR, "originIP:"..originIP.." appname: "..appname.." id: "..id.." time: "..time.." time: "..sign)

if calltype ~= "publish" and calltype ~= "publish_done" then
	ngx.exit(ngx.HTTP_OK)
elseif calltype == "publish" then
	report_uri = start_uri
	--do token_check
	local k = req_args[key_label]
	local t = req_args[time_label]
	
	--ngx.log(ngx.CRIT, "Bianfeng :  calltype "..calltype.."token_check "..token_check)
	
	if tonumber(token_check) == 1 then
		--Bellow code can be used when token information is in app
		--local k = nil
		--local t = nil
		--pos = string.find(tcurl, "?")
		--if pos ~= nil then
		--	local param = string.sub(tcurl, pos + 1, -1)
			
			--ngx.log(ngx.CRIT, "Bianfeng : param .."..param)
			
		--	local startpos = string.find(param, key_label.."=")
		--	local endpos = string.find(param, "&")
		--	if startpos ~= nil then
		--		if endpos ~= nil then
		--			k = string.sub(param, startpos + string.len(key_label.."="), endpos - 1)
		--		else
		--			k = string.sub(param, startpos + string.len(key_label.."="), -1)
		--		end
				
		--		startpos = string.find(param, time_label.."=")
		--	    endpos = string.find(param, "&")
				
		--		if endpos ~= nil then
		--			t = string.sub(param, startpos + string.len(time_label.."="), endpos - 1)
		--		else
		--			t = string.sub(param, startpos + string.len(time_label.."="), -1)
		--		end
		--	end
		--end
		
		--ngx.log(ngx.CRIT, "Bianfeng :  k "..k.." t "..t.." token_key "..token_key)
		pos = nil
		if white_ip then
			pos = string.find(white_ip, originIP)
		end
	
		if pos == nil then
			if not k or not t or not token_key then
				ngx.log(ngx.CRIT, "Bianfeng : token check failed for with no key or no time information")
				goto ERROR
			else
				--k = md5($key/zqlive/$streamKey$t)
				--ngx.log(ngx.INFO, "Bianfeng : "..token_key.."/"..appname.."/"..id..t)
				local md5key = ngx.md5(token_key.."/"..appname.."/"..id..t)
				if md5key ~= k then
					ngx.log(ngx.ERR, "Bianfeng : token check failed for key not equal, value: "..md5key)
					ngx.exit(ngx.HTTP_FORBIDDEN)
					goto ERROR
				end
				ngx.log(ngx.INFO, "Bianfeng : token check successfully")
			end
		end
	end
	--end token_check
else
	report_uri = end_uri
end
--?ip=推流端IP&id=流名&node=节点IP&app=推流域名&appname=发布点&time=时间戳&sign=xxx
--&app=lxhdl.cdn.zhanqi.tv&appname=zqlive&
report_uri = report_uri.."?ip="..originIP.."&id="..id.."&node="..node.."&app="..app.."&appname="..appname.."&time="..time.."&sign="..sign

--report_uri = report_uri.."?ip=115.236.48.234&id=352_tmL4d&node=117.21.182.169&app=lxhdl.cdn.zhanqi.tv&appname=zqlive".."&time="..time.."&sign="..sign
--ngx.log(ngx.INFO, "Bianfeng Report : "..report_url..report_uri)

sendheader["Host"] = report_url
request = remote_request.new()

if not request then
	goto RET_OK
end

res, err = request:remote_connect(report_url, report_port, retry_count)

if err then
	ngx.log(ngx.CRIT, "Bianfeng : Report ".."Connect to report server failed")
	goto RET_OK
end

res, err = request:remote_request(sendheader, report_uri, retry_count, nil)
if err then
	ngx.log(ngx.CRIT, "Bianfeng : Report send request failed ")
	goto RET_OK 
end

res, header = request:remote_response_header()

if not res or string.sub(res, 1, 1) ~= "2" then
	ngx.log(ngx.CRIT, "Bianfeng : Report ERROR "..res)
	request:release(0)
	goto RET_OK
end

ngx.log(ngx.INFO, "Bianfeng : Report OK "..res)
request:release(0)
ngx.exit(ngx.HTTP_OK)

::ERROR::
ngx.exit(ngx.HTTP_FORBIDDEN)

::RET_OK::
ngx.exit(ngx.HTTP_OK)
