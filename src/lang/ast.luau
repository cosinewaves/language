--!strict

local nodeTypes = {
	Program = "Program",
	NumericLiteral = "NumericLiteral",
	Identifier = "Identifier",
	BinaryExpr = "BinaryExpr",
	VariableDeclaration = "VariableDeclaration",
	Assignment = "Assignment",
}

export type statement = {
	kind: string, -- one of nodeTypes
}

export type expression = statement

export type program = {
	kind: "Program",
	body: { statement },
}

export type binaryExpr = {
	kind: "BinaryExpr",
	left: expression,
	right: expression,
	operator: string,
}

export type identifier = {
	kind: "Identifier",
	symbol: string,
}

export type numericLiteral = {
	kind: "NumericLiteral",
	value: number,
}

export type variableDeclaration = {
	kind: "VariableDeclaration",
	identifier: identifier,
	value: expression,
}

export type assignment = {
	kind: "Assignment",
	identifier: identifier,
	value: expression,
}

local function program(body: { statement }): program
	return {
		kind = nodeTypes.Program,
		body = body,
	} :: program
end

local function binaryExpression(left: expression, operator: string, right: expression): binaryExpr
	return {
		kind = nodeTypes.BinaryExpr,
		left = left,
		right = right,
		operator = operator,
	} :: binaryExpr
end

local function identifier(symbol: string): identifier
	return {
		kind = nodeTypes.Identifier,
		symbol = symbol,
	} :: identifier
end

local function numericLiteral(value: number): numericLiteral
	return {
		kind = nodeTypes.NumericLiteral,
		value = value,
	} :: numericLiteral
end

local function variableDeclaration(id: identifier, value: expression): variableDeclaration
	return {
		kind = nodeTypes.VariableDeclaration,
		identifier = id,
		value = value,
	} :: variableDeclaration
end

local function assignment(id: identifier, value: expression): assignment
	return {
		kind = nodeTypes.Assignment,
		identifier = id,
		value = value,
	} :: assignment
end

return {
	nodeTypes = nodeTypes,
	program = program,
	binaryExpression = binaryExpression,
	identifier = identifier,
	numericLiteral = numericLiteral,
	variableDeclaration = variableDeclaration,
	assignment = assignment,
}
