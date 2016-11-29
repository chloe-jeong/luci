--
-- Copyright 2016 Weongyo Jeong <weongyo@gmail.com>
-- Licensed to the public under the Apache License 2.0.
--

local fs  = require "nixio.fs"
local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local testfullps = luci.sys.exec("ps --help 2>&1 | grep BusyBox")
local psstring = (string.len(testfullps) > 0) and "ps w" or "ps axfw"

local m = Map("mudfish-pi", translate("Mudfish"))

-----------------------------------------------------------------------
--
-- BASIC CONFIGURATION
--
-----------------------------------------------------------------------

local s = m:section(TypedSection, "mudfish-pi", translate("Basic Configuration"),
		    translate("This shows Mudfish basic configuration and current state."))
s.extedit = luci.dispatcher.build_url(
   "admin", "services", "mudfish-pi", "basic", "%s"
)

local e = s:option(Flag, "enabled", translate("Enabled"))
e.rmempty = false
function e.cfgvalue(self, section)
   return luci.sys.init.enabled("mudfish-pi") and
      self.enabled or self.disabled
end

function e.write(self, section, value)
   if value == "1" then
      luci.sys.call("/etc/init.d/mudfish-pi enable > /dev/null")
      luci.sys.call("/etc/init.d/mudfish-pi start > /dev/null")
   else
      luci.sys.call("/etc/init.d/mudfish-pi stop > /dev/null")
      luci.sys.call("/etc/init.d/mudfish-pi disable > /dev/null")
   end
end

local active = s:option(DummyValue, "_active", translate("Started"))

function active.cfgvalue(self, section)
   local pid = sys.exec("%s | grep mudrun | grep -v grep | head -1 | awk '{print $1}'" % { psstring } )
   if pid and #pid > 0 and tonumber(pid) ~= nil then
      local ipaddr = m.uci:get("network", "lan", "ipaddr")
      self.description = [[<a target="_blank" href="]] .. "http://" .. ipaddr .. ":8282" ..
	 [[">Mudfish Launcher UI</a>]]
      return (sys.process.signal(pid, 0))
	 and translatef("Yes (%i)", pid)
	 or  translate("No")
   end
   return translate("No")
end

local updown = s:option(Button, "_updown", translate("Start/Stop"))
updown._state = false
updown.redirect = luci.dispatcher.build_url("admin", "services", "mudfish-pi")

function updown.cbid(self, section)
   local pid = sys.exec("%s | grep mudrun | grep -v grep | head -1 | awk '{ print $1 }'" % { psstring })
   self._state = pid and #pid > 0 and sys.process.signal(pid, 0)
   self.option = self._state and "stop" or "start"
   return AbstractValue.cbid(self, section)
end

function updown.cfgvalue(self, section)
   self.title = self._state and "Stop" or "Start"
   self.inputstyle = self._state and "reset" or "reload"
end

function updown.write(self, section, value)
   if self.option == "stop" then
      luci.sys.call("/etc/init.d/mudfish-pi stop")
   else
      luci.sys.call("/etc/init.d/mudfish-pi start")
   end
   luci.http.redirect(self.redirect)
end

-----------------------------------------------------------------------
--
-- SUPPORT TUNNEL
--
-----------------------------------------------------------------------

local s = m:section(TypedSection, "mudfish-pi-support", translate("Support"),
		    translate("This shows menus for technical supports."))

local opened = s:option(DummyValue, "_opened", translate("Opened"))
function opened.cfgvalue(self, section)
   local pid = sys.exec("%s | grep mudsupport | grep -v grep | head -1 | awk '{print $1}'" % { psstring } )
   if pid and #pid > 0 and tonumber(pid) ~= nil then
      if sys.process.signal(pid, 0) then
         self.description = translatef("Your secure token is <b>%i</b>.", fs.readfile("/etc/mudfish-pi/mudsupport.token"))
	 return translatef("Yes (%i)", pid)
      else
	 return translate("No")
      end
   end
   return translate("No")
end

local updown = s:option(Button, "_updown", translate("Start/Stop"))
updown._state = false
updown.redirect = luci.dispatcher.build_url("admin", "services", "mudfish-pi")

function updown.cbid(self, section)
   local pid = sys.exec("%s | grep mudsupport | grep -v grep | head -1 | awk '{ print $1 }'" % { psstring })
   self._state = pid and #pid > 0 and sys.process.signal(pid, 0)
   self.option = self._state and "stop" or "start"
   return AbstractValue.cbid(self, section)
end

function updown.cfgvalue(self, section)
   self.title = self._state and "Stop" or "Start"
   self.inputstyle = self._state and "reset" or "reload"
end

function updown.write(self, section, value)
   if self.option == "stop" then
      luci.sys.call("/usr/bin/killall -9 mudsupport")
      local ssh_pid = fs.readfile("/etc/mudfish-pi/mudsupport.ssh.pid")
      if ssh_pid ~= nil then
         luci.sys.call("/bin/kill -9 %s" % { ssh_pid })
      end
   else
      os.execute("/opt/mudfish-pi/current/bin/mudsupport")
   end
   luci.http.redirect(self.redirect)
end

return m
