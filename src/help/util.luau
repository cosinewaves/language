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

-- identifier rules:
-- start: letter or underscore
-- part: letter, digit, or underscore
local function isIdentifierStart(char: string): boolean
	if char == "_" then
		return true
	end
	return isAlpha(char)
end

local function isIdentifierPart(char: string): boolean
	if char == "_" then
		return true
	end
	return isAlpha(char) or isDigit(char)
end

return {
	isAlpha = isAlpha,
	isDigit = isDigit,
	isWhitespace = isWhitespace,
	isIdentifierStart = isIdentifierStart,
	isIdentifierPart = isIdentifierPart,
}
