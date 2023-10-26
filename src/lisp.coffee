
prettyPrint = (x) -> console.log JSON.stringify x, undefined, 4

exports.Env = Env = (obj) ->
  env = {}
  outer = obj.outer ? {}
  env[obj.params[i]] = arg for arg, i in obj.args
  env.find = (variable) ->
    if variable of env
      env[variable]
    else outer.find? variable
  env

exports.tokenize = tokenize = (input) -> (
  input
  .replace /\(/g, ' ( '
  .replace /\)/g, ' ) '
  .trim()
  .split /\s+/
)
exports.parseTokens = parseTokens = (tokens) ->
  return new Error 'Unexpected EOF' if tokens.length == 0
  token = tokens.pop()
  switch
    when token == '('
      L = []
      until (tokens.at -1) is ')'
        L.push parseTokens tokens
      tokens.pop()
      L
    when token == ')'
      throw new SyntaxError 'Unexpected )'
    else
      if isNaN token then token else parseFloat token

handleString = (string, env) -> if string[0] is '"' and (string.at -1) is '"'
    string
  else
    env.find string
exports.evalTree = evalTree = (tree, _env) ->
  prettyPrint tree
  env = _env ? global_env
  if tree not instanceof Array
    switch typeof tree
      when 'string'
        return handleString tree, env
      else
        return tree
  head = tree.shift()
  console.log "head: #{head}"
  flattennedArguments = for argument in tree
    switch
      when argument instanceof Array
        argument = evalTree argument, env 
      when typeof argument is 'string'
        argument = handleString argument, env
    argument
  if fn = env.find(head)
    console.log "calling #{head} with #{String flattennedArguments}"
    fn flattennedArguments, env
  else
    throw new ReferenceError " #{head} does not exist in context"

exports.addGlobals = addGlobals = (env) ->
    env['+']  = (args, env) ->  args.reduce ((acc, cur) -> acc + cur), 0
    env['-']  = ([a, args], env) ->  args.reduce ((acc, cur) -> acc - cur), a
    env['*']  = (args, env) ->  args.reduce ((acc, cur) -> acc * cur), 0
    env['/']  = ([a, args], env) ->  args.reduce ((acc, cur) -> acc / cur), a
    env['>']  = ([a, b], env) ->  a > b
    env['<']  = ([a, b], env) ->  a < b
    env['>='] = ([a, b], env) -> a >= b
    env['<='] = ([a, b], env) -> a <= b
    env['='] = ([a, b], env) -> a == b
    env['%'] = ([a, b], env) -> a % b
    env['mod'] = ([a, b], env) -> a %% b
    env['equal?'] = ([a, b], env) -> a is b
    env['eq?'] = ([a, b], env) -> a is b
    env['not'] = ([a, b], env) -> not a
    env['length'] = ([a, b], env) -> a.length
    env['cons'] = ([a, b], env) -> a.concat(b)
    env['car'] = ([a], env) -> if a.length != 0 then a[0] else null
    env['cdr'] = ([a], env) -> if a.length > 1 then a.slice 1 else null
    env['append'] = ([a, b], env) -> a.concat(b)
    env['list'] = () -> Array::slice.call arguments
    env['list?'] = ([a]) -> args instanceof Array
    env['null?'] = ([a]) -> a.length == 0
    env['symbol?'] = (args) -> typeof a == 'string'
    env['if'] = ([test, consequence, orelse]) -> if test then consequence else orelse
    env["'"] = (args) -> args
    env['"'] = (args) -> "\"#{args.join ' '}\""
    env

global_env = addGlobals Env { params: [], args: [] }