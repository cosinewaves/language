--!strict

local util = require("../help/util")
local tokensTbl = require("./tokens")
local keywords = require("./keywords")

export type token = { type: string, value: string }

-- use lookup table for O(1) operator checks
local binaryOperators = {
	["+"] = true,
	["-"] = true,
	["*"] = true,
	["/"] = true,
	["^"] = true,
	["%"] = true,
}

local singleCharTokens = {
	["("] = tokensTbl.OPEN_PARENTHESIS,
	[")"] = tokensTbl.CLOSE_PARENTHESIS,
	[","] = tokensTbl.COMMA,
}

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
		local nextChar: string? = if i < length then source:sub(i + 1, i + 1) else nil

		-- skip whitespace first
		if util.isWhitespace(char) then
			i += 1

		-- single-character tokens (parentheses, comma)
		elseif singleCharTokens[char] then
			tokens[#tokens + 1] = makeToken(singleCharTokens[char], char)
			i += 1

		-- two-character comparison operators (check before single-char '=')
		elseif char == "=" and nextChar == "=" then
			tokens[#tokens + 1] = makeToken(tokensTbl.EQ, "==")
			i += 2
		elseif char == "!" and nextChar == "=" then
			tokens[#tokens + 1] = makeToken(tokensTbl.NE, "!=")
			i += 2
		elseif char == "<" and nextChar == "=" then
			tokens[#tokens + 1] = makeToken(tokensTbl.LTE, "<=")
			i += 2
		elseif char == ">" and nextChar == "=" then
			tokens[#tokens + 1] = makeToken(tokensTbl.GTE, ">=")
			i += 2

		-- comments:
		-- single-line: --
		-- block: /* ... */
		elseif char == "-" and nextChar == "-" then
			-- consume until end of line
			i += 2
			while i <= length and source:sub(i, i) ~= "\n" do
				i += 1
			end
			-- newline left to be skipped by whitespace next loop
		elseif char == "/" and nextChar == "*" then
			-- block comment: consume until '*/'
			i += 2
			local closed = false
			while i <= length - 1 do
				if source:sub(i, i + 1) == "*/" then
					closed = true
					i += 2
					break
				end
				i += 1
			end
			if not closed then
				error("(lexer.tokenise) unterminated block comment")
			end

		-- augmented assignment operators (check after comments to avoid conflicts)
		elseif char == "+" and nextChar == "=" then
			tokens[#tokens + 1] = makeToken(tokensTbl.PLUS_EQUALS, "+=")
			i += 2
		elseif char == "-" and nextChar == "=" then
			-- note: '--' comment case handled above, so this is safe
			tokens[#tokens + 1] = makeToken(tokensTbl.MINUS_EQUALS, "-=")
			i += 2
		elseif char == "*" and nextChar == "=" then
			tokens[#tokens + 1] = makeToken(tokensTbl.MUL_EQUALS, "*=")
			i += 2
		elseif char == "/" and nextChar == "=" then
			-- block comment '/*' handled earlier, so this is safe
			tokens[#tokens + 1] = makeToken(tokensTbl.DIV_EQUALS, "/=")
			i += 2

		-- single-character '=' and single <, >
		elseif char == "=" then
			tokens[#tokens + 1] = makeToken(tokensTbl.EQUALS, char)
			i += 1
		elseif char == "<" then
			tokens[#tokens + 1] = makeToken(tokensTbl.LT, char)
			i += 1
		elseif char == ">" then
			tokens[#tokens + 1] = makeToken(tokensTbl.GT, char)
			i += 1

		-- binary operators (single-char)
		elseif binaryOperators[char] then
			tokens[#tokens + 1] = makeToken(tokensTbl.BINARY_OPERATOR, char)
			i += 1

		-- numbers (support optional fractional part)
		elseif util.isDigit(char) then
			local start = i
			-- integer part
			while i <= length and util.isDigit(source:sub(i, i)) do
				i += 1
			end

			-- fractional part: only accept if there's a '.' followed by at least one digit
			local currentChar = if i <= length then source:sub(i, i) else ""
			local followingChar = if i < length then source:sub(i + 1, i + 1) else ""
			if currentChar == "." and util.isDigit(followingChar) then
				i += 1 -- consume '.'
				while i <= length and util.isDigit(source:sub(i, i)) do
					i += 1
				end
			end

			local value = source:sub(start, i - 1)
			tokens[#tokens + 1] = makeToken(tokensTbl.NUMBER, value)

		-- identifiers / keywords / boolean literals
		elseif util.isIdentifierStart(char) then
			local start = i
			-- allow letters, digits and underscores after first char
			while i <= length and util.isIdentifierPart(source:sub(i, i)) do
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

		-- strings
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
