--!strict

local ast = require("./ast")
local lexer = require("./lexer")
local tokens = require("./tokens")

type token = lexer.token
type program = ast.program
type statement = ast.statement
type expression = ast.expression
type identifier = ast.identifier

export type parser = {
	tokens: { token },
	position: number,

	at: (self: parser) -> token?,
	eof: (self: parser) -> boolean,
	consume: (self: parser) -> token,
	expect: (self: parser, tokenType: string, err: string) -> token,

	parseProgram: (self: parser) -> program,
	parseStatement: (self: parser) -> statement,
	parseVariableDeclaration: (self: parser) -> statement,
	parseExpression: (self: parser) -> expression,
	parseBinaryExpression: (self: parser, minPrecedence: number?) -> expression,
	parsePrimaryExpression: (self: parser) -> expression,
}

-- binary expressions with precedence
local PRECEDENCE = {
	["+"] = 1,
	["-"] = 1,
	["*"] = 2,
	["/"] = 2,
	["%"] = 2, -- modulo same as multiplication
	["^"] = 3, -- exponentiation higher
}

local parser = {}
parser.__index = parser

function parser.new(tokens: { token }): parser
	return setmetatable({
		tokens = tokens,
		position = 1,
	}, parser) :: parser
end

function parser.at(self: parser): token?
	return self.tokens[self.position]
end

function parser.eof(self: parser): boolean
	return self.position > #self.tokens
end

function parser.consume(self: parser): token
	local current = self:at()
	self.position += 1
	return current :: token
end

function parser.expect(self: parser, tokenType: string, err: string): token
	local t = self:at()
	if not t or t.type ~= tokenType then
		error(err)
	end
	return self:consume()
end

-- top level parser
function parser.parseProgram(self: parser): program
	local body: { statement } = {}
	while not self:eof() do
		body[#body + 1] = self:parseStatement()
	end
	return ast.program(body)
end

-- set declarations or expressions/assignments
function parser.parseStatement(self: parser): statement
	local t = self:at()
	if not t then
		error("(parser.parseStatement) unexpected end of input")
	end

	if t.type == tokens.SET then
		return self:parseVariableDeclaration()
	end

	-- parse as expression
	local expr = self:parseExpression()

	-- if expression is an assignment, it's already handled in parseExpression
	return expr
end

-- variable declaration so like set x = expr
function parser.parseVariableDeclaration(self: parser): statement
	self:consume() -- consume 'set'

	local name = self:expect(tokens.IDENTIFIER, "(parser.parseVariableDeclaration) expected identifier after 'set'")
	self:expect(tokens.EQUALS, "(parser.parseVariableDeclaration) expected '=' after identifier")

	local value = self:parseExpression()
	return ast.variableDeclaration(ast.identifier(name.value), value) :: statement
end

-- expression parser which handles assignment
function parser.parseExpression(self: parser): expression
	local expr = self:parseBinaryExpression()

	-- top-level assignment
	local t = self:at()
	if t and t.type == tokens.EQUALS and expr.kind == ast.nodeTypes.Identifier then
		self:consume()
		local value = self:parseExpression()
		return ast.assignment(expr :: identifier, value) :: expression
	end

	return expr
end

function parser.parseBinaryExpression(self: parser, minPrecedence: number?): expression
	minPrecedence = minPrecedence or 0
	local left = self:parsePrimaryExpression()

	while true do
		local t = self:at()
		if not t or t.type ~= tokens.BINARY_OPERATOR then
			break
		end

		local prec = PRECEDENCE[t.value] or 0
		if prec < minPrecedence then
			break
		end

		local op = self:consume().value
		local right = self:parseBinaryExpression(prec + 1)
		left = ast.binaryExpression(left, op, right) :: expression
	end

	return left
end

-- primary expressions numbers, identifiers, parentheses
function parser.parsePrimaryExpression(self: parser): expression
	local t = self:at()
	if not t then
		error("(parser.parsePrimaryExpression) unexpected end of input")
	end

	if t.type == tokens.NUMBER then
		self:consume()
		return ast.numericLiteral(tonumber(t.value) :: number) :: expression
	end

	if t.type == tokens.IDENTIFIER then
		self:consume()
		return ast.identifier(t.value) :: expression
	end

	if t.type == tokens.OPEN_PARENTHESIS then
		self:consume()
		local expr = self:parseExpression()
		self:expect(tokens.CLOSE_PARENTHESIS, "(parser.parsePrimaryExpression) expected closing parenthesis")
		return expr
	end

	-- string literal
	if t.type == tokens.STRING_LITERAL then
		self:consume()
		return ast.stringLiteral(t.value) :: expression
	end

	error(string.format("(parser.parsePrimaryExpression) unexpected token: %s (%s)", t.type :: string, t.value))
end

-- entry point
local function parse(tokensList: { token }): program
	local p = parser.new(tokensList)
	return p:parseProgram()
end

return {
	parse = parse,
}
