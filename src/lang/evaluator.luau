--!strict

local ast = require("./ast")
local environment = require("./environment")

export type runtimeValue = number

type environment = environment.environment
type program = ast.program
type statement = ast.statement
type expression = ast.expression
type binaryExpr = ast.binaryExpr
type identifier = ast.identifier
type numericLiteral = ast.numericLiteral
type variableDeclaration = ast.variableDeclaration
type assignment = ast.assignment

-- recursively evaluate AST nodes
local function evaluate(node: statement | expression, env: environment): runtimeValue
	-- program node: evaluate all statements in order
	if node.kind == ast.nodeTypes.Program then
		local result: runtimeValue = 0
		for _, stmt in (node :: program).body do
			result = evaluate(stmt, env)
		end
		return result
	end

	-- variable declaration: set x = expr
	if node.kind == ast.nodeTypes.VariableDeclaration then
		local decl = node :: variableDeclaration
		local value = evaluate(decl.value, env)
		env:declare(decl.identifier.symbol, value)
		return value
	end

	-- assignment: x = expr
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

	-- identifier
	if node.kind == ast.nodeTypes.Identifier then
		return env:lookup((node :: identifier).symbol)
	end

	-- binary expression
	if node.kind == ast.nodeTypes.BinaryExpr then
		local expr = node :: binaryExpr
		local left = evaluate(expr.left, env)
		local right = evaluate(expr.right, env)

		if expr.operator == "+" then
			return left + right
		elseif expr.operator == "-" then
			return left - right
		elseif expr.operator == "*" then
			return left * right
		elseif expr.operator == "/" then
			return left / right
		else
			error("unknown operator: " .. expr.operator)
		end
	end

	error("unknown AST node: " .. tostring(node.kind))
end

local function run(programNode: program): runtimeValue
	local globalEnv = environment.new(nil)
	return evaluate(programNode :: expression, globalEnv)
end

return {
	run = run,
	evaluate = evaluate,
}
