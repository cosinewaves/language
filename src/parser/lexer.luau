--!strict

local util = require("../help/util")
local tokensTbl = require("./tokens")
local keywords = require("./keywords")

export type token = { type: string, value: string }

local binaryOperators = { "+", "-", "*", "/", "^", "%" }

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

		-- identifiers / keywords / boolean literals
		elseif util.isAlpha(char) then
			local start = i
			while i <= length and util.isAlpha(source:sub(i, i)) do
				i += 1
			end

			local value = source:sub(start, i - 1)

			-- check if the value is a keyword or boolean literal
			local tokenType = keywords[value]

			if tokenType then
				-- If it's a keyword or boolean literal, use the keyword token type
				tokens[#tokens + 1] = makeToken(tokenType, value)
			else
				-- Otherwise, it's a user-defined identifier
				tokens[#tokens + 1] = makeToken(tokensTbl.IDENTIFIER, value)
			end
		elseif char == '"' or char == "'" then
			local quote = char
			i += 1
			local str = ""

			while i <= length do
				local c = source:sub(i, i)
				if c == quote then
					break
				end

				-- handle escape sequences
				if c == "\\" then
					i += 1
					local nextChar = source:sub(i, i)
					if nextChar == "n" then
						str ..= "\n"
					elseif nextChar == "t" then
						str ..= "\t"
					else
						str ..= nextChar
					end
				else
					str ..= c
				end
				i += 1
			end

			if i > length then
				error("(lexer.tokenise) unterminated string literal")
			end

			-- consume closing quote
			i += 1

			tokens[#tokens + 1] = makeToken(tokensTbl.STRING_LITERAL, str)

		-- comparison operators in your lexer loop
		elseif (char == "=" :: string) and source:sub(i + 1, i + 1) == "=" then
			tokens[#tokens + 1] = makeToken(tokensTbl.EQ, "==")
			i += 2
		elseif char == "!" and source:sub(i + 1, i + 1) == "=" then
			tokens[#tokens + 1] = makeToken(tokensTbl.NE, "!=")
			i += 2
		elseif char == "<" then
			if source:sub(i + 1, i + 1) == "=" then
				tokens[#tokens + 1] = makeToken(tokensTbl.LTE, "<=")
				i += 2
			else
				tokens[#tokens + 1] = makeToken(tokensTbl.LT, "<")
				i += 1
			end
		elseif char == ">" then
			if source:sub(i + 1, i + 1) == "=" then
				tokens[#tokens + 1] = makeToken(tokensTbl.GTE, ">=")
				i += 2
			else
				tokens[#tokens + 1] = makeToken(tokensTbl.GT, ">")
				i += 1
			end
		else -- unknown characters
			error(string.format("(lexer.tokenise) unrecognized character '%s' (%d)", char, string.byte(char)))
		end
	end

	return tokens
end

return {
	tokenise = tokenise,
	makeToken = makeToken,
}
