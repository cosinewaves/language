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
	parseOr: (self: parser) -> expression,
	parseAnd: (self: parser) -> expression,
	parseComparison: (self: parser) -> expression,
	parseAdditive: (self: parser) -> expression,
	parseMultiplicative: (self: parser) -> expression,
	parseUnary: (self: parser) -> expression,
	parsePrimary: (self: parser) -> expression,
}

local parser = {}
parser.__index = parser

function parser.new(tokensList: { token }): parser
	return setmetatable({
		tokens = tokensList,
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
	local t = self:at()
	self.position += 1
	return t :: token
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
	local t = self:at()
	if not t then
		error("(parser.parseStatement) unexpected EOF")
	end

	if t.type == tokens.SET then
		return self:parseVariableDeclaration()
	end

	return self:parseExpression()
end

function parser.parseVariableDeclaration(self: parser): statement
	self:consume() -- set

	local name = self:expect(tokens.IDENTIFIER, "(parser.parseVariableDeclaration) expected identifier")

	self:expect(tokens.EQUALS, "(parser.parseVariableDeclaration) expected '='")

	local value = self:parseExpression()
	return ast.variableDeclaration(ast.identifier(name.value), value) :: statement
end

function parser.parseExpression(self: parser): expression
	local expr = self:parseOr()

	-- assignment
	local t = self:at()
	if t and t.type == tokens.EQUALS and expr.kind == ast.nodeTypes.Identifier then
		self:consume()
		local value = self:parseExpression()
		return ast.assignment(expr :: identifier, value) :: expression
	end

	return expr
end

-- or
function parser.parseOr(self: parser): expression
	local left = self:parseAnd()

	while self:at() and (self:at() :: token).type == tokens.OR do
		local op = self:consume().value
		local right = self:parseAnd()
		left = ast.binaryExpression(left, op, right) :: expression
	end

	return left
end

-- and
function parser.parseAnd(self: parser): expression
	local left = self:parseComparison()

	while self:at() and (self:at() :: token).type == tokens.AND do
		local op = self:consume().value
		local right = self:parseComparison()
		left = ast.binaryExpression(left, op, right) :: expression
	end

	return left
end

-- == != < > <= >=
function parser.parseComparison(self: parser): expression
	local left = self:parseAdditive()

	while self:at() do
		local v = (self:at() :: token).value
		if v == "==" or v == "!=" or v == "<" or v == ">" or v == "<=" or v == ">=" then
			local op = self:consume().value
			local right = self:parseAdditive()
			left = ast.binaryExpression(left, op, right)
		else
			break
		end
	end

	return left
end

-- + -
function parser.parseAdditive(self: parser): expression
	local left = self:parseMultiplicative()

	while self:at() do
		local v = self:at().value
		if v == "+" or v == "-" then
			local op = self:consume().value
			local right = self:parseMultiplicative()
			left = ast.binaryExpression(left, op, right)
		else
			break
		end
	end

	return left
end

-- * / %
function parser.parseMultiplicative(self: parser): expression
	local left = self:parseUnary()

	while self:at() do
		local v = (self:at() :: token).value
		if v == "*" or v == "/" or v == "%" then
			local op = self:consume().value
			local right = self:parseUnary()
			left = ast.binaryExpression(left, op, right) :: expression
		else
			break
		end
	end

	return left
end

-- unary: not
function parser.parseUnary(self: parser): expression
	local t = self:at()

	if t and t.type == tokens.NOT then
		local op = self:consume().value
		local expr = self:parseUnary()
		return ast.unaryExpression(op, expr) :: expression
	end

	return self:parsePrimary()
end

function parser.parsePrimary(self: parser): expression
	local t = self:at()
	if not t then
		error("(parser.parsePrimary) unexpected EOF")
	end

	if t.type == tokens.NUMBER then
		self:consume()
		return ast.numericLiteral(tonumber(t.value) :: number) :: expression
	end

	if t.type == tokens.STRING_LITERAL then
		self:consume()
		return ast.stringLiteral(t.value) :: expression
	end

	if t.type == tokens.BOOLEAN_LITERAL then
		self:consume()
		return ast.booleanLiteral(t.value == "true") :: expression
	end

	if t.type == tokens.IDENTIFIER then
		self:consume()
		return ast.identifier(t.value) :: expression
	end

	if t.type == tokens.OPEN_PARENTHESIS then
		self:consume()
		local expr = self:parseExpression()
		self:expect(tokens.CLOSE_PARENTHESIS, "expected ')'")
		return expr
	end

	error(string.format("(parser.parsePrimary) unexpected token: %s (%s)", t.type, t.value))
end

local function parse(tokenList: { token }): program
	return parser.new(tokenList):parseProgram()
end

return {
	parse = parse,
}
