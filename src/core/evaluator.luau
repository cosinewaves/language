--!strict

local ast = require("./ast")
local environment = require("./environment")

export type functionValue = {
	kind: "Function",
	name: string,
	parameters: { ast.identifier },
	body: { ast.statement },
	closure: environment.environment,
}

export type returnValue = {
	kind: "ReturnValue",
	value: any,
}

export type runtimeValue = number | string | boolean | functionValue

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
type whileStatement = ast.whileStatement
type forStatement = ast.forStatement
type functionDeclaration = ast.functionDeclaration
type callExpression = ast.callExpression
type returnStatement = ast.returnStatement

local function evaluate(node: statement | expression, env: environment): any
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
			-- execute consequent in its own block scope
			local blockEnv = environment.new(env)
			local result: any = false
			for _, stmt in ifStmt.consequent do
				result = evaluate(stmt, blockEnv)
				-- propagate return values
				if type(result) == "table" and result.kind == "ReturnValue" then
					return result
				end
			local result: runtimeValue = false
			for _, stmt in ifStmt.consequent do
				result = evaluate(stmt, blockEnv)
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
				-- execute however branch in its own block scope
				local blockEnv = environment.new(env)
 				local result: any = false
				for _, stmt in branch.body do
					result = evaluate(stmt, blockEnv)
					-- propagate return values
					if type(result) == "table" and result.kind == "ReturnValue" then
						return result
					end
				local result: runtimeValue = false
				for _, stmt in branch.body do
					result = evaluate(stmt, blockEnv)
				end
				return result
			end
		end

		-- otherwise clause (else)
		if ifStmt.alternate then
			-- execute otherwise in its own block scope
			local blockEnv = environment.new(env)
			local result: any = false
			for _, stmt in ifStmt.alternate do
				result = evaluate(stmt, blockEnv)
				-- propagate return values
				if type(result) == "table" and result.kind == "ReturnValue" then
					return result
				end
			local result: runtimeValue = false
			for _, stmt in ifStmt.alternate do
				result = evaluate(stmt, blockEnv)
			end
			return result
		end

		-- no branch taken
		return false
	end

	if node.kind == ast.nodeTypes.WhileStatement then
		local whileStmt = node :: whileStatement
		local result: any = false
		local result: runtimeValue = false

		while true do
			-- evaluate condition in parent scope
			local conditionValue = evaluate(whileStmt.condition, env)
			if type(conditionValue) ~= "boolean" then
				error("(evaluator.evaluate) whilst condition must be a boolean")
			end

			if not conditionValue then
				break
			end

			-- create fresh body scope for each iteration
			local bodyEnv = environment.new(env)
			for _, stmt in whileStmt.body do
				result = evaluate(stmt, bodyEnv)
				-- propagate return values
				if type(result) == "table" and result.kind == "ReturnValue" then
					return result
				end
			end
		end

		return result
	end

	if node.kind == ast.nodeTypes.ForStatement then
		local forStmt = node :: forStatement
		local result: any = false
		local result: runtimeValue = false

		-- create loop scope for loop variable
		local loopEnv = environment.new(env)

		-- execute init (variable declaration) in loop scope
		evaluate(forStmt.init, loopEnv)

		-- loop
		while true do
			local conditionValue = evaluate(forStmt.condition, loopEnv)
			if type(conditionValue) ~= "boolean" then
				error("(evaluator.evaluate) iterate condition must be a boolean")
			end

			if not conditionValue then
				break
			end

			-- create fresh body scope for each iteration (child of loop scope)
			local bodyEnv = environment.new(loopEnv)
			for _, stmt in forStmt.body do
				result = evaluate(stmt, bodyEnv)
				-- propagate return values
				if type(result) == "table" and result.kind == "ReturnValue" then
					return result
				end
			end

			-- execute update in loop scope (so it can access loop variable)
			evaluate(forStmt.update, loopEnv)
		end

		return result
	end

	if node.kind == ast.nodeTypes.FunctionDeclaration then
		local funcDecl = node :: functionDeclaration

		-- create function value (closure)
		local funcValue: functionValue = {
			kind = "Function",
			name = funcDecl.name.symbol,
			parameters = funcDecl.parameters,
			body = funcDecl.body,
			closure = env, -- capture current environment
		}

		-- declare function in current environment
		env:declare(funcDecl.name.symbol, funcValue)

		return funcValue
	end

	if node.kind == ast.nodeTypes.CallExpression then
		local callExpr = node :: callExpression

		-- evaluate the callee to get the function
		local func = evaluate(callExpr.callee, env)

		if type(func) ~= "table" or func.kind ~= "Function" then
			error("(evaluator.evaluate) cannot call non-function")
		end

		-- evaluate arguments
		local args: { any } = {}
		for _, argExpr in callExpr.arguments do
			args[#args + 1] = evaluate(argExpr, env)
		end

		-- check parameter count
		if #args ~= #func.parameters then
			error(
				"(evaluator.evaluate) function '"
					.. func.name
					.. "' expects "
					.. #func.parameters
					.. " arguments, got "
					.. #args
			)
		end

		-- create new environment for function execution (child of closure environment)
		local funcEnv = environment.new(func.closure)

		-- bind parameters
		for i, param in func.parameters do
			funcEnv:declare(param.symbol, args[i])
		end

		-- execute function body
		local result: any = false
		for _, stmt in func.body do
			result = evaluate(stmt, funcEnv)

			-- check if it's a return value
			if type(result) == "table" and result.kind == "ReturnValue" then
				return result.value
			end
		end

		-- if no explicit return, return false
		return result
	end

	if node.kind == ast.nodeTypes.ReturnStatement then
		local retStmt = node :: returnStatement

		local value: any = false
		if retStmt.value then
			value = evaluate(retStmt.value, env)
		end

		-- return a special structure to signal return
		return { kind = "ReturnValue", value = value }
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

local function run(node: program): any
	local globalEnv = environment.new(nil)
	return evaluate(node :: expression, globalEnv)
end

return {
	run = run,
	evaluate = evaluate,
}
