
prettyFormat = (x) -> (JSON.stringify x, undefined, 4) + " (#{x?.constructor?.name ? typeof x})"
prettyPrint = (x) -> console.log prettyFormat x

exports.Env = Env = (obj) ->
  env = {}
  outer = obj.outer
  env[obj.params[i]] = arg for arg, i in obj.args
  env.find = (variable) ->
    if variable of env
      env[variable]
    else outer?.find variable
  env.findEnv = (variable) ->
    if variable of env
      env
    else
      if outer? then outer.findEnv(variable) else env
  env

exports.tokenize = tokenize = (input) -> (
  input
  .replaceAll '(', ' ( '
  .replaceAll ')', ' ) '
  .trim()
  .split /\s+/
  .reverse()
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

handleString = (string, env) -> 
  switch
    when string[0] is '"' and string[0] is string.at -1
      string
    when string[0] is "'"
      string.slice 1
    else
      if isNaN string then env.find string else parseFloat string

###
  TODOs:
    - [x] make quote not evaluate the subtree
    - [x] make aliases work
    - [x] make var definitions
    - [ ] make macro definitions
    - [x] make lambda definitions
###
exports.evalTree = evalTree = (tree, _env) ->
  console.log "evaluating expression #{prettyFormat tree}"
  env = _env ? global_env
  if tree not instanceof Array
    switch typeof tree
      when 'string'
        result = handleString tree, env
      else
        result = tree
    console.log "#{prettyFormat tree} evaluated to #{prettyFormat result}"
  else
    head = tree.shift()
    result = env.find(head)?(tree, env) ? throw new ReferenceError " #{prettyFormat head} does not exist in context"
    console.log "#{prettyFormat head} call on #{prettyFormat tree} evaluated to #{prettyFormat result}"
  result

binaryCompression = (fn) ->
  (args, env) -> args.reduce (a, b) -> fn (evalTree a, env), (evalTree b, env)
everyCompression = (fn) ->
  (args, env) -> args.every (a) -> fn evalTree a, env
mapCompression = (fn) ->
  (args, env) -> args.map (a) -> fn evalTree a, env
exports.addGlobals = addGlobals = (env) ->
      env['progn'] = (args, env) -> 
        result =  evalTree arg, env for arg in args
        result
      env['apply'] = ([fn, args], env) -> 
        (env.find evalTree fn, env)((evalTree args, env), env)
      env['eval'] = ([args], env) ->
        result = evalTree args, env
        return result if result not instanceof Array
        [fn, list...] = result
        env['apply'] ["'" + fn, ['quote', list...]], env
    # math ops
      env['+']  = binaryCompression (a, b) -> a + b
      env['-']  = binaryCompression (a, b) -> a - b
      env['*']  = binaryCompression (a, b) -> a * b
      env['/']  = binaryCompression (a, b) -> a / b
      env['%']  = binaryCompression (a, b) -> a % b
      env['mod'] = binaryCompression (a, b) -> a %% b
    # math comparsions
      env['>']  = binaryCompression (a, b) -> a > b
      env['<']  = binaryCompression (a, b) -> a < b
      env['>='] = binaryCompression (a, b) -> a >= b
      env['<='] = binaryCompression (a, b) -> a == b
      env['=']  = ([a, args...], env) -> do (args, env) -> everyCompression (b) -> b == evalTree a, env
    # boolean logic
      env['and'] = binaryCompression (a, b) -> a and b
      env['or']  = binaryCompression (a, b) -> a or b
      env['not'] = ([a], env) -> not (evalTree a, env)
    # list operations
      env['length'] = binaryCompression (a, b) -> a.length + b.length
      env['car'] = ([a], env) -> evalTree a, env
      env['cdr'] = ([a, args...], env) -> evalTree args, env
      env['append'] = binaryCompression (a, b) -> a.concat b
      env['list'] = mapCompression (a) -> a
    # checks
      env['list?'] = everyCompression (a) -> a instanceof Array
      env['null'] = everyCompression (a) -> a.length == 0
      env['symbol?'] = everyCompression (a) -> typeof a == 'string'
    # control flow
      env['if'] = ([test, consequence, orelse], env) -> if evalTree test, env then evalTree consequence, env else evalTree orelse, env
    # lists processing
      env['"'] = (args) -> "\"#{args.join ' '}\""
    # definitions (variable, function, macro)
      env['def'] = ([name, value], env) -> env.findEnv(name)[name] = evalTree value, env
      env['lambda'] = ([params, expr]) -> 
        (args, env) -> evalTree expr, Env { params, args, outer: env }
    # hardcoded macros
      env['defun'] = ([name, params, expr], env) ->
        env['def'] [name, ['lambda', params, expr]], env
      env['def*'] = (args) ->
        env['progn'] (args.map ([name, value]) -> ['def', name, value]), env
      env["'"] = (args, env) -> args
    # aliases
      env['#'] = env['lambda']
      env['cons'] = env['append']
      env['head'] = env['car']
      env['tail'] = env['cdr']
      env['equal?'] = env['=']
      env['eq?'] = env['=']
      env['string'] = env['"']
      env['quote'] = env["'"]
      
      env

exports.doFreshEnv = doFreshEnv = (outer) -> addGlobals Env { params: [], args: [], outer }
global_env = doFreshEnv()