--!strict

export type environment = {
	parent: environment?,
	values: { [string]: any },

	declare: (self: environment, name: string, value: any) -> (),
	assign: (self: environment, name: string, value: any) -> (),
	has: (self: environment, name: string) -> boolean,
	lookup: (self: environment, name: string) -> any,
}

local environment = {}
environment.__index = environment

-- create new environment with optional parent scope
function environment.new(parent: environment?): environment
	return setmetatable({
		parent = parent,
		values = {},
	}, environment) :: environment
end

-- declare a new variable in this scope
function environment.declare(self: environment, name: string, value: any): ()
	if self.values[name] ~= nil then
		error("variable already declared: " .. name)
	end
	self.values[name] = value
end

-- assign to an existing variable (searches parent scopes)
function environment.assign(self: environment, name: string, value: any): ()
	if self.values[name] ~= nil then
		self.values[name] = value
	elseif self.parent then
		self.parent:assign(name, value)
	else
		error("assignment to undeclared variable: " .. name)
	end
end

-- check if a variable exists in this scope or parent scopes
function environment.has(self: environment, name: string): boolean
	if self.values[name] ~= nil then
		return true
	elseif self.parent then
		return self.parent:has(name)
	end
	return false
end

-- lookup variable value (searches parent scopes)
function environment.lookup(self: environment, name: string): any
	if self.values[name] ~= nil then
		return self.values[name]
	elseif self.parent then
		return self.parent:lookup(name)
	end
	error("undefined variable: " .. name)
end

return {
	new = environment.new,
}
