--!strict
-- simple utility library for the language

local function isAlpha(char: string): boolean
	return char:upper() ~= char:lower()
end

local function isDigit(char: string): boolean
	local c = string.byte(char)
	return c >= 48 and c <= 57
end

local function isWhitespace(char: string): boolean
	return char == " " or char == "\n" or char == "\t"
end

return {
	isAlpha = isAlpha,
	isDigit = isDigit,
	isWhitespace = isWhitespace,
}
