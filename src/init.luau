--!strict
local fs = require("@lune/fs")
local process = require("@lune/process")

local lexer = require("@self/parser/lexer")
local parser = require("@self/parser/parser")
local evaluator = require("@self/core/evaluator")

-- check if a file was provided
if #process.args == 0 then
	print("Error: No file provided")
	print("Usage: lune run src/init.luau <file.lang>")
	process.exit(1)
end

local filename = process.args[1]

-- check if file exists
if not fs.isFile(filename) then
	print(string.format("Error: File '%s' does not exist", filename))
	process.exit(1)
end

-- read and execute the file
local success, result = pcall(function()
	local source = fs.readFile(filename)
	local tokens = lexer.tokenise(source)
	local ast = parser.parse(tokens)
	return evaluator.run(ast)
end)

if not success then
	print("runtime error:")
	print(result)
	process.exit(1)
end

print(result)
