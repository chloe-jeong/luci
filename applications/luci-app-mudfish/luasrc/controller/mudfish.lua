-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2008 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.mudfish", package.seeall)

function index()
	entry( {"admin", "services", "mudfish"}, cbi("mudfish"), _("Mudfish") )
	entry( {"admin", "services", "mudfish", "basic"},    cbi("mudfish-basic"),    nil ).leaf = true
	entry( {"admin", "services", "mudfish", "advanced"}, cbi("mudfish-advanced"), nil ).leaf = true
end
