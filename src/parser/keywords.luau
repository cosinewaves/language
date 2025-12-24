--!strict

local tokens = require("./tokens")

return {
	set = tokens.SET,
	["true"] = "BOOLEAN_LITERAL",
	["false"] = "BOOLEAN_LITERAL",
} :: { [any]: string }
