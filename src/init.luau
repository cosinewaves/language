--!strict
local _fs = require("@lune/fs")

local lexer = require("@self/parser/lexer")
local parser = require("@self/parser/parser")
local evaluator = require("@self/core/evaluator")

--local source = fs.readFile("./examples/test1.lang")
local source = [[
set a = 10
set b = 5
set c = 20
set d = not (not (c > a))
]]
local tokens = lexer.tokenise(source)
local ast = parser.parse(tokens)
local result = evaluator.run(ast)

print(result)
