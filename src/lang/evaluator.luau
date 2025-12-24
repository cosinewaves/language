-- TODO: type errors

local ast = require("./ast")
local enviroment = require("./environment")

export type runtimeValue = number

type environment = enviroment.environment
type program = ast.program
type statement = ast.statement
type expression = ast.expression
type binaryExpr = ast.binaryExpr
type identifier = ast.identifier
type numericLiteral = ast.numericLiteral
type variableDeclaration = ast.variableDeclaration

local function evaluate(node: program, env: environment): runtimeValue?
	-- program
	if node.kind == ast.nodeTypes.Program then
		local result: runtimeValue? = nil

		for _, statement: statement in node.body do
			result = evaluate(statement :: program, env)
		end

		return result
	end

	-- variable declaration
	if node.kind == ast.nodeTypes.VariableDeclaration then
		local decl = node :: variableDeclaration
		local value = evaluate(decl.value :: program, env)

		env:declare(decl.identifier.symbol, value)
		return value
	end

	-- Numeric literal
	if node.kind == ast.nodeTypes.NumericLiteral then
		return (node :: numericLiteral).value
	end

	-- Identifier
	if node.kind == ast.nodeTypes.Identifier then
		return env:lookup((node :: identifier).symbol)
	end

	-- Binary expression
	if node.kind == ast.nodeTypes.BinaryExpr then
		local expr = node :: binaryExpr
		local left = evaluate(expr.left, env)
		local right = evaluate(expr.right, env)

		if expr.operator == "+" then
			return (left :: number) + (right :: number)
		elseif expr.operator == "-" then
			return (left :: number) - (right :: number)
		elseif expr.operator == "*" then
			return (left :: number) * (right :: number)
		elseif expr.operator == "/" then
			return (left :: number) / (right :: number)
		end

		error("unknown operator: " .. expr.operator)
	end

	-- assignment
	if node.kind == ast.nodeTypes.Assignment then
		local assign = node :: ast.assignment
		local value = evaluate(assign.value, env)
		-- update existing variable
		if env.values[assign.identifier.symbol] ~= nil then
			env.values[assign.identifier.symbol] = value
		else
			error("assignment to undeclared variable: " .. assign.identifier.symbol)
		end
		return value
	end

	error("unknown AST node: " .. tostring(node.kind))
end

local function run(programNode: program): runtimeValue?
	local globalEnv = enviroment.new(nil)
	return evaluate(programNode, globalEnv)
end

return {
	run = run,
}
