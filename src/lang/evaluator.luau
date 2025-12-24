--!strict

local ast = require("./ast")
local environment = require("./environment")

export type runtimeValue = number | string | boolean

type environment = environment.environment
type program = ast.program
type statement = ast.statement
type expression = ast.expression
type binaryExpr = ast.binaryExpr
type identifier = ast.identifier
type numericLiteral = ast.numericLiteral
type stringLiteral = ast.stringLiteral
type booleanLiteral = ast.booleanLiteral
type variableDeclaration = ast.variableDeclaration
type assignment = ast.assignment

local function evaluate(node: statement | expression, env: environment): runtimeValue
	-- program
	if node.kind == ast.nodeTypes.Program then
		local result: runtimeValue = 0
		for _, stmt in (node :: program).body do
			result = evaluate(stmt, env)
		end
		return result
	end

	-- variable declaration
	if node.kind == ast.nodeTypes.VariableDeclaration then
		local decl = node :: variableDeclaration
		local value = evaluate(decl.value, env)
		env:declare(decl.identifier.symbol, value)
		return value
	end

	-- assignment
	if node.kind == ast.nodeTypes.Assignment then
		local assign = node :: assignment
		local value = evaluate(assign.value, env)
		if env:has(assign.identifier.symbol) then
			env:assign(assign.identifier.symbol, value)
		else
			error("assignment to undeclared variable: " .. assign.identifier.symbol)
		end
		return value
	end

	-- numeric literal
	if node.kind == ast.nodeTypes.NumericLiteral then
		return (node :: numericLiteral).value
	end

	-- string literal
	if node.kind == ast.nodeTypes.StringLiteral then
		return (node :: stringLiteral).value
	end

	-- boolean literal
	if node.kind == ast.nodeTypes.BooleanLiteral then
		return (node :: booleanLiteral).value
	end

	-- identifier
	if node.kind == ast.nodeTypes.Identifier then
		return env:lookup((node :: identifier).symbol)
	end

	-- binary expression
	if node.kind == ast.nodeTypes.BinaryExpr then
		local expr = node :: binaryExpr
		local left = evaluate(expr.left, env)
		local right = evaluate(expr.right, env)
		local op = expr.operator

		-- arithmetic for numbers
		if type(left) == "number" and type(right) == "number" then
			if op == "+" then
				return left + right
			elseif op == "-" then
				return left - right
			elseif op == "*" then
				return left * right
			elseif op == "/" then
				return left / right
			elseif op == "%" then
				return left % right
			elseif op == "^" then
				return left ^ right
			else
				error("unknown numeric operator: " .. op)
			end
		end

		-- string concatenation
		if type(left) == "string" and type(right) == "string" then
			if op == "+" then
				return left .. right
			else
				error("invalid operator for strings: " .. op)
			end
		end

		-- todo: boolean logic

		error("invalid binary operation between " .. type(left) .. " and " .. type(right))
	end

	error("unknown AST node: " .. tostring(node.kind))
end

local function run(programNode: program & expression): runtimeValue
	local globalEnv = environment.new(nil)
	return evaluate(programNode, globalEnv)
end

return {
	run = run,
	evaluate = evaluate,
}
