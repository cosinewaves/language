--!strict

local tokens = require("./tokens")

return {
	set = tokens.SET,
} :: { [any]: string }
