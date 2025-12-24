--!strict

local util = require("../help/util")
local tokensTbl = require("./tokens")
local keywords = require("./keywords")

export type token = { type: string, value: string }

local binaryOperators = { "+", "-", "*", "/" }

local function makeToken(tokenType: string, value: string): token
	return {
		type = tokenType,
		value = value,
	} :: token
end

local function tokenise(source: string): { token }
	local tokens: { token } = {}
	local i: number = 1
	local length: number = #source

	while i <= length do
		local char: string = source:sub(i, i)

		-- skip whitespace first
		if util.isWhitespace(char) then
			i += 1

		-- single-character tokens
		elseif char == "(" then
			tokens[#tokens + 1] = makeToken(tokensTbl.OPEN_PARENTHESIS, char)
			i += 1
		elseif char == ")" then
			tokens[#tokens + 1] = makeToken(tokensTbl.CLOSE_PARENTHESIS, char)
			i += 1
		elseif table.find(binaryOperators, char) then
			tokens[#tokens + 1] = makeToken(tokensTbl.BINARY_OPERATOR, char)
			i += 1
		elseif char == "=" then
			tokens[#tokens + 1] = makeToken(tokensTbl.EQUALS, char)
			i += 1

		-- numbers
		elseif util.isDigit(char) then
			local start = i
			while i <= length and util.isDigit(source:sub(i, i)) do
				i += 1
			end
			local value = source:sub(start, i - 1)
			tokens[#tokens + 1] = makeToken(tokensTbl.NUMBER, value)

		-- identifiers / keywords
		elseif util.isAlpha(char) then
			local start = i
			while i <= length and util.isAlpha(source:sub(i, i)) do
				i += 1
			end
			local value = source:sub(start, i - 1)
			local keywordType = keywords[value]
			if keywordType then
				tokens[#tokens + 1] = makeToken(keywordType, value)
			else
				tokens[#tokens + 1] = makeToken(tokensTbl.IDENTIFIER, value)
			end

		-- unknown characters
		else
			error(string.format("unrecognized character '%s' (%d)", char, string.byte(char)))
		end
	end

	return tokens
end

return {
	tokenise = tokenise,
	makeToken = makeToken,
}
