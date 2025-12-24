--!strict
local fs = require("@lune/fs")

local lexer = require("@self/lang/lexer")
local parser = require("@self/lang/parser")
local evaluator = require("@self/lang/evaluator")

local source = fs.readFile("../language/test.txt")

local tokens = lexer.tokenise(source)
local ast = parser.parse(tokens)
local result = evaluator.run(ast)

print(result)
