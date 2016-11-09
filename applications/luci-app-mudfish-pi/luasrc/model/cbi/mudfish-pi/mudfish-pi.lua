-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Licensed to the public under the Apache License 2.0.

local fs  = require "nixio.fs"
local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local testfullps = luci.sys.exec("ps --help 2>&1 | grep BusyBox")
local psstring = (string.len(testfullps) > 0) and "ps w" or "ps axfw"

local m = Map("mudfish-pi", translate("Mudfish"))
local s = m:section(TypedSection, "mudfish-pi",
		    translate("Mudfish instances"),
		    translate("Below is a list of configured Mudfish instances and their current state"))
s.extedit = luci.dispatcher.build_url(
	"admin", "services", "mudfish-pi", "basic", "%s"
)

function s.parse(self, section)
end

function s.create(self, name)
end

s:option(Flag, "enabled", translate("Enabled"))

local active = s:option(DummyValue, "_active", translate("Started"))
function active.cfgvalue(self, section)
   local pid = sys.exec("%s | grep %s | grep mudfish | grep -v grep | awk '{print $1}'" % { psstring,section} )
   if pid and #pid > 0 and tonumber(pid) ~= nil then
      return (sys.process.signal(pid, 0))
	 and translatef("yes (%i)", pid)
	 or  translate("no")
   end
   return translate("no")
end

local updown = s:option(Button, "_updown", translate("Start/Stop"))
updown._state = false
updown.redirect = luci.dispatcher.build_url("admin", "services", "mudfish-pi")

function updown.cbid(self, section)
   local pid = sys.exec("%s | grep %s | grep mudfish | grep -v grep | awk '{ print $1 }'" % { psstring, section })
   self._state = pid and #pid > 0 and sys.process.signal(pid, 0)
   self.option = self._state and "stop" or "start"
   return AbstractValue.cbid(self, section)
end

function updown.cfgvalue(self, section)
   self.title = self._state and "stop" or "start"
   self.inputstyle = self._state and "reset" or "reload"
end

function updown.write(self, section, value)
   if self.option == "stop" then
      local pid = sys.exec("%s | grep %s | grep mudfish | grep -v grep | awk '{print $1}'" % { psstring, section })
      sys.process.signal(pid, 15)
   else
      luci.sys.call("/etc/init.d/mudfish-pi start %s" % section)
   end
   luci.http.redirect(self.redirect)
end

return m
