--!strict

local ast = require("../core/ast")
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
	parseUnaryExpression: (self: parser) -> expression,
}

-- binary precedence table
local PRECEDENCE = {
	["or"] = 0,
	["and"] = 1,
	["=="] = 2,
	["!="] = 2,
	["<"] = 2,
	[">"] = 2,
	["<="] = 2,
	[">="] = 2,
	["+"] = 3,
	["-"] = 3,
	["*"] = 4,
	["/"] = 4,
	["%"] = 4,
	["^"] = 5,
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

-- top-level program parser
function parser.parseProgram(self: parser): program
	local body: { statement } = {}
	while not self:eof() do
		body[#body + 1] = self:parseStatement()
	end
	return ast.program(body)
end

-- parse statements: variable declarations or expressions
function parser.parseStatement(self: parser): statement
	local t = self:at()
	if not t then
		error("(parser.parseStatement) unexpected end of input")
	end

	if t.type == tokens.SET then
		return self:parseVariableDeclaration()
	end

	-- parse as expression (may be assignment)
	return self:parseExpression()
end

function parser.parseVariableDeclaration(self: parser): statement
	self:consume() -- consume 'set'

	local name = self:expect(tokens.IDENTIFIER, "(parser.parseVariableDeclaration) expected identifier after 'set'")
	self:expect(tokens.EQUALS, "(parser.parseVariableDeclaration) expected '=' after identifier")

	local value = self:parseExpression()
	return ast.variableDeclaration(ast.identifier(name.value), value) :: statement
end

-- expression parser supports top-level assignments
function parser.parseExpression(self: parser): expression
	local expr = self:parseBinaryExpression()

	-- assignment
	local t = self:at()
	if t and t.type == tokens.EQUALS and expr.kind == ast.nodeTypes.Identifier then
		self:consume()
		local value = self:parseExpression()
		return ast.assignment(expr :: identifier, value) :: expression
	end

	return expr
end

-- binary expressions with precedence climbing
function parser.parseBinaryExpression(self: parser, minPrecedence: number?): expression
	minPrecedence = minPrecedence or 0
	local left = self:parseUnaryExpression()

	while true do
		local t = self:at()
		if not t then
			break
		end

		local op = t.value
		local prec = PRECEDENCE[op] or -1
		if prec < minPrecedence then
			break
		end

		if
			t.type ~= tokens.BINARY_OPERATOR
			and not (op == "and" or op == "or")
			and not (op == "==" or op == "!=" or op == "<" or op == ">" or op == "<=" or op == ">=")
		then
			break
		end

		self:consume()
		local right = self:parseBinaryExpression(prec + 1)
		left = ast.binaryExpression(left, op, right) :: expression
	end

	return left
end

-- unary expressions: only 'not' for now
function parser.parseUnaryExpression(self: parser): expression
	local t = self:at()
	if t and t.type == tokens.NOT then
		local op = self:consume().value
		local argument = self:parseUnaryExpression()
		return ast.unaryExpression(op, argument) :: expression
	end
	return self:parsePrimaryExpression()
end

-- primary expressions
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

	if t.type == tokens.BOOLEAN_LITERAL then
		self:consume()
		local value = t.value == "true"
		return ast.booleanLiteral(value) :: expression
	end

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
