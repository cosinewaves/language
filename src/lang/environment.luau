--!strict

export type environment = {
	parent: environment?,
	values: { [string]: any },

	declare: (self: environment, name: string, value: any) -> (),
	lookup: (self: environment, name: string) -> any,
}

local environment = {}
environment.__index = environment

function environment.new(parent: environment?): environment
	return setmetatable({
		parent = parent,
		values = {},
	}, environment) :: environment
end

function environment.declare(self: environment, name: string, value: any): ()
	if self.values[name] ~= nil then
		error("variable already declared: " .. name)
	end

	self.values[name] = value
	return
end

function environment.lookup(self: environment, name: string): any
	if self.values[name] ~= nil then
		return self.values[name] :: any
	end

	if self.parent then
		return self.parent:lookup(name) :: any
	end

	error("undefined variable: " .. name)
end

return {
	new = environment.new,
}
