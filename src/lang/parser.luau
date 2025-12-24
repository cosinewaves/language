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

	at: (self: parser) -> token,
	eof: (self: parser) -> boolean,
	consume: (self: parser) -> token,
	expect: (self: parser, tokenType: string, err: string) -> token,

	parseProgram: (self: parser) -> program,
	parseStatement: (self: parser) -> statement,
	parseExpression: (self: parser) -> expression,
	parseBinaryExpression: (self: parser) -> expression,
	parsePrimaryExpression: (self: parser) -> expression,
	parseVariableDeclaration: (self: parser) -> statement,
}

local parser = {}
parser.__index = parser

function parser.new(tokens: { token }): parser
	return setmetatable({
		tokens = tokens,
		position = 1,
	}, parser) :: parser
end

function parser.at(self: parser): token
	return self.tokens[self.position] :: token
end

function parser.eof(self: parser): boolean
	return self.position > #self.tokens
end

function parser.consume(self: parser): token
	local current = self:at()
	self.position += 1
	return current
end

function parser.expect(self: parser, tokenType: string, err: string): token
	local t = self:at()

	if not t or t.type ~= tokenType then
		error(err)
	end

	return self:consume()
end

function parser.parseProgram(self: parser): program
	local body: { statement } = {}

	while not self:eof() do
		body[#body + 1] = self:parseStatement()
	end

	return ast.program(body)
end

function parser.parseStatement(self: parser): statement
	if self:at().type == tokens.SET then
		return self:parseVariableDeclaration()
	end

	return self:parseExpression()
end

function parser.parseVariableDeclaration(self: parser): statement
	self:consume()

	local name = self:expect(tokens.IDENTIFIER, "expected identifier after let")
	self:expect(tokens.EQUALS, "expected '=' after identifier")

	local value = self:parseExpression()

	return ast.variableDeclaration(ast.identifier(name.value), value) :: statement
end

function parser.parseExpression(self: parser): expression
	return self:parseBinaryExpression()
end

function parser.parseBinaryExpression(self: parser): expression
	local left = self:parsePrimaryExpression()

	while not self:eof() and self:at().type == tokens.BINARY_OPERATOR do
		local operator = self:consume().value
		local right = self:parsePrimaryExpression()

		left = ast.binaryExpression(left, operator, right) :: expression
	end

	return left
end

function parser.parsePrimaryExpression(self: parser): expression
	local t = self:at()

	if not t then
		error("unexpected end of input")
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
		self:expect(tokens.CLOSE_PARENTHESIS, "expected closing parenthesis")

		return expr
	end

	error(string.format("unexpected token: %s (%s)", t.type, t.value))
end

local function parse(tokenList: { token }): program
	local p = parser.new(tokenList)
	return p:parseProgram()
end

return {
	parse = parse,
}
