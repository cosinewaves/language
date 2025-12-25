--!strict

local nodeTypes = {
	Program = "Program",
	NumericLiteral = "NumericLiteral",
	StringLiteral = "StringLiteral",
	BooleanLiteral = "BooleanLiteral",
	Identifier = "Identifier",
	BinaryExpr = "BinaryExpr",
	UnaryExpr = "UnaryExpr",
	VariableDeclaration = "VariableDeclaration",
	Assignment = "Assignment",
	IfStatement = "IfStatement",
	WhileStatement = "WhileStatement",
	ForStatement = "ForStatement",
	FunctionDeclaration = "FunctionDeclaration",
	CallExpression = "CallExpression",
	ReturnStatement = "ReturnStatement",
}

export type statement = { kind: string }
export type expression = statement

export type program = { kind: "Program", body: { statement } }

export type numericLiteral = { kind: "NumericLiteral", value: number }
export type stringLiteral = { kind: "StringLiteral", value: string }
export type booleanLiteral = { kind: "BooleanLiteral", value: boolean }
export type identifier = { kind: "Identifier", symbol: string }
export type binaryExpr = { kind: "BinaryExpr", left: expression, operator: string, right: expression }
export type unaryExpr = { kind: "UnaryExpr", operator: string, argument: expression }
export type variableDeclaration = { kind: "VariableDeclaration", identifier: identifier, value: expression }
export type assignment = { kind: "Assignment", identifier: identifier, value: expression }

-- IfStatement structure:
-- given (condition) then
--   body
-- however (condition) then
--   body
-- otherwise
--   body
-- finish
export type ifBranch = { condition: expression, body: { statement } }
export type ifStatement = {
	kind: "IfStatement",
	condition: expression,
	consequent: { statement },
	alternates: { ifBranch }, -- however clauses
	alternate: { statement }?, -- otherwise clause
}

export type whileStatement = {
	kind: "WhileStatement",
	condition: expression,
	body: { statement },
}

export type forStatement = {
	kind: "ForStatement",
	init: statement,
	condition: expression,
	update: statement,
	body: { statement },
}

export type functionDeclaration = {
	kind: "FunctionDeclaration",
	name: identifier,
	parameters: { identifier },
	body: { statement },
}

export type callExpression = {
	kind: "CallExpression",
	callee: expression,
	arguments: { expression },
}

export type returnStatement = {
	kind: "ReturnStatement",
	value: expression?,
}

local function program(body: { statement }): program
	return { kind = nodeTypes.Program, body = body }
end

local function numericLiteral(value: number): numericLiteral
	return { kind = nodeTypes.NumericLiteral, value = value }
end

local function stringLiteral(value: string): stringLiteral
	return { kind = nodeTypes.StringLiteral, value = value }
end

local function booleanLiteral(value: boolean): booleanLiteral
	return { kind = nodeTypes.BooleanLiteral, value = value }
end

local function identifier(symbol: string): identifier
	return { kind = nodeTypes.Identifier, symbol = symbol }
end

local function binaryExpression(left: expression, operator: string, right: expression): binaryExpr
	return { kind = nodeTypes.BinaryExpr, left = left, operator = operator, right = right }
end

local function unaryExpression(operator: string, argument: expression): unaryExpr
	return { kind = nodeTypes.UnaryExpr, operator = operator, argument = argument }
end

local function variableDeclaration(id: identifier, value: expression): variableDeclaration
	return { kind = nodeTypes.VariableDeclaration, identifier = id, value = value }
end

local function assignment(id: identifier, value: expression): assignment
	return { kind = nodeTypes.Assignment, identifier = id, value = value }
end

local function ifStatement(
	condition: expression,
	consequent: { statement },
	alternates: { ifBranch },
	alternate: { statement }?
): ifStatement
	return {
		kind = nodeTypes.IfStatement,
		condition = condition,
		consequent = consequent,
		alternates = alternates,
		alternate = alternate,
	}
end

local function whileStatement(condition: expression, body: { statement }): whileStatement
	return {
		kind = nodeTypes.WhileStatement,
		condition = condition,
		body = body,
	}
end

local function forStatement(
	init: statement,
	condition: expression,
	update: statement,
	body: { statement }
): forStatement
	return {
		kind = nodeTypes.ForStatement,
		init = init,
		condition = condition,
		update = update,
		body = body,
	}
end

local function functionDeclaration(
	name: identifier,
	parameters: { identifier },
	body: { statement }
): functionDeclaration
	return {
		kind = nodeTypes.FunctionDeclaration,
		name = name,
		parameters = parameters,
		body = body,
	}
end

local function callExpression(callee: expression, arguments: { expression }): callExpression
	return {
		kind = nodeTypes.CallExpression,
		callee = callee,
		arguments = arguments,
	}
end

local function returnStatement(value: expression?): returnStatement
	return {
		kind = nodeTypes.ReturnStatement,
		value = value,
	}
end

return {
	nodeTypes = nodeTypes,
	program = program,
	numericLiteral = numericLiteral,
	stringLiteral = stringLiteral,
	booleanLiteral = booleanLiteral,
	identifier = identifier,
	binaryExpression = binaryExpression,
	unaryExpression = unaryExpression,
	variableDeclaration = variableDeclaration,
	assignment = assignment,
	ifStatement = ifStatement,
	whileStatement = whileStatement,
	forStatement = forStatement,
	functionDeclaration = functionDeclaration,
	callExpression = callExpression,
	returnStatement = returnStatement,
}
