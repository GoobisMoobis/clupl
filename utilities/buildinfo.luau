--[[
This file is completely replaced in the building process in buildscript.luau

"format" is the format clupl is in, such as deb (.deb), rpm, (.rpm), arch (.pkg.tar.zst), or appimage (.appimage).
"lute" is what version of lute is bundled in the program.

"lute" is generated on-the-fly for appimage-based clupl versions, as it relies
on the SYSTEM version of lute that the USER has installed rather than a version
bundled into the program itself.
]]

return {
	format = "source",
	lute = "unknown",
}
