--!strict
local _fs = require("@lune/fs")

local lexer = require("@self/parser/lexer")
local parser = require("@self/parser/parser")
local evaluator = require("@self/core/evaluator")

--local source = fs.readFile("./examples/test1.lang")
local source = [[
set a = 5
set b = 3
set c = a > 3
c
]]
local tokens = lexer.tokenise(source)
local ast = parser.parse(tokens)
local result = evaluator.run(ast)

print(result)
