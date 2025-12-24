--!strict
local fs = require("@lune/fs")
local process = require("@lune/process")

local lexer = require("@self/parser/lexer")
local parser = require("@self/parser/parser")
local evaluator = require("@self/core/evaluator")

assert(#process.args ~= 0, "no files provided")
local source = fs.readFile(process.args[1])

local tokens = lexer.tokenise(source)
local ast = parser.parse(tokens)
local result = evaluator.run(ast)

print(result)
