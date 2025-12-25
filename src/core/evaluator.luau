--!strict

local ast = require("./ast")
local environment = require("./environment")

export type runtimeValue = number | string | boolean

type environment = environment.environment
type program = ast.program
type statement = ast.statement
type expression = ast.expression
type binaryExpr = ast.binaryExpr
type unaryExpr = ast.unaryExpr
type identifier = ast.identifier
type numericLiteral = ast.numericLiteral
type stringLiteral = ast.stringLiteral
type booleanLiteral = ast.booleanLiteral
type variableDeclaration = ast.variableDeclaration
type assignment = ast.assignment
type ifStatement = ast.ifStatement
type ifBranch = ast.ifBranch

local function evaluate(node: statement | expression, env: environment): runtimeValue
	if node.kind == ast.nodeTypes.Program then
		local result: runtimeValue = false
		for _, stmt in (node :: program).body do
			result = evaluate(stmt, env)
		end
		return result
	end

	if node.kind == ast.nodeTypes.VariableDeclaration then
		local decl = node :: variableDeclaration
		local value = evaluate(decl.value, env)
		env:declare(decl.identifier.symbol, value)
		return value
	end

	if node.kind == ast.nodeTypes.Assignment then
		local assign = node :: assignment
		local value = evaluate(assign.value, env)

		-- ensure variable exists
		env:assign(assign.identifier.symbol, value)
		return value
	end

	if node.kind == ast.nodeTypes.IfStatement then
		local ifStmt = node :: ifStatement

		-- evaluate main condition
		local conditionValue = evaluate(ifStmt.condition, env)
		if type(conditionValue) ~= "boolean" then
			error("(evaluator.evaluate) if condition must be a boolean")
		end

		if conditionValue then
			-- execute consequent
			local result: runtimeValue = false
			for _, stmt in ifStmt.consequent do
				result = evaluate(stmt, env)
			end
			return result
		end

		-- check however clauses (elseif)
		for _, branch in ifStmt.alternates do
			local branchCondition = evaluate(branch.condition, env)
			if type(branchCondition) ~= "boolean" then
				error("(evaluator.evaluate) however condition must be a boolean")
			end

			if branchCondition then
				local result: runtimeValue = false
				for _, stmt in branch.body do
					result = evaluate(stmt, env)
				end
				return result
			end
		end

		-- otherwise clause (else)
		if ifStmt.alternate then
			local result: runtimeValue = false
			for _, stmt in ifStmt.alternate do
				result = evaluate(stmt, env)
			end
			return result
		end

		-- no branch taken
		return false
	end

	if node.kind == ast.nodeTypes.NumericLiteral then
		return (node :: numericLiteral).value
	end

	if node.kind == ast.nodeTypes.StringLiteral then
		return (node :: stringLiteral).value
	end

	if node.kind == ast.nodeTypes.BooleanLiteral then
		return (node :: booleanLiteral).value
	end

	if node.kind == ast.nodeTypes.Identifier then
		return env:lookup((node :: identifier).symbol)
	end

	-- unary expression
	if node.kind == ast.nodeTypes.UnaryExpr then
		local expr = node :: unaryExpr
		local val = evaluate(expr.argument, env)

		if expr.operator == "not" then
			return not val
		end

		if expr.operator == "-" then
			if type(val) ~= "number" then
				error("(evaluator) unary '-' expects a number")
			end
			return -val
		end

		error("(evaluator) unknown unary operator: " .. expr.operator)
	end

	if node.kind == ast.nodeTypes.BinaryExpr then
		local expr = node :: binaryExpr
		local op = expr.operator

		if op == "and" then
			local left = evaluate(expr.left, env)
			if type(left) ~= "boolean" then
				error("(evaluator.evaluate) 'and' expects booleans")
			end
			if not left then
				return false
			end
			local right = evaluate(expr.right, env)
			if type(right) ~= "boolean" then
				error("(evaluator.evaluate) 'and' expects booleans")
			end
			return right
		end

		if op == "or" then
			local left = evaluate(expr.left, env)
			if type(left) ~= "boolean" then
				error("(evaluator.evaluate) 'or' expects booleans")
			end
			if left then
				return true
			end
			local right = evaluate(expr.right, env)
			if type(right) ~= "boolean" then
				error("(evaluator.evaluate) 'or' expects booleans")
			end
			return right
		end

		local left = evaluate(expr.left, env)
		local right = evaluate(expr.right, env)

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
			elseif op == "==" then
				return left == right
			elseif op == "!=" then
				return left ~= right
			elseif op == "<" then
				return left < right
			elseif op == ">" then
				return left > right
			elseif op == "<=" then
				return left <= right
			elseif op == ">=" then
				return left >= right
			end
		end

		if type(left) == "string" and type(right) == "string" then
			if op == "+" then
				return left .. right
			elseif op == "==" then
				return left == right
			elseif op == "!=" then
				return left ~= right
			end
		end

		if type(left) == "boolean" and type(right) == "boolean" then
			if op == "==" then
				return left == right
			elseif op == "!=" then
				return left ~= right
			end
		end

		error("(evaluator.evaluate) invalid operation: " .. type(left) .. " " .. op .. " " .. type(right))
	end

	error("(evaluator.evaluate) unknown AST node: " .. tostring(node.kind))
end

local function run(node: program): runtimeValue
	local globalEnv = environment.new(nil)
	return evaluate(node :: expression, globalEnv)
end

return {
	run = run,
	evaluate = evaluate,
}
