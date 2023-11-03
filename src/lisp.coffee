
prettyFormat = (x) -> (JSON.stringify x, undefined, 4) + " (#{x?.constructor?.name ? typeof x})"
prettyPrint = (strings, expressions...) ->
  output = for string, i in strings when string isnt ''
    string + prettyFormat expressions[i] 
  console.log output.join ''

exports.Env = Env = (obj) ->
  env = {}
  outer = obj.outer
  if '&rest' in obj.params
    for param, i in obj.params
      break if param is '&rest'
      env[param] = obj.args[i]
    j = i + 1
    env[obj.params[j]] = obj.args.slice i
  else
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
      token = parseFloat token unless isNaN token
      token

handleString = (string, env) -> 
  switch
    when string[0] is '"' and string[0] is string.at -1
      string
    when string[0] is "'"
      string.slice 1
    else
      if isNaN string then env.find string else parseFloat string

treeToString = (tree) ->
  if tree instanceof Array
    "(#{
      tree.map treeToString
      .join ' '})"
  else
    tree
###
  TODOs:
    - [x] make quote not evaluate the subtree
    - [x] make aliases work
    - [x] make var definitions
    - [ ] make macro definitions
    - [x] make lambda definitions
###
exports.evalTree = evalTree = (tree, _env) ->
  prettyPrint"evaluating expression #{tree}"
  env = _env ? global_env
  prettyPrint"env is #{env}"
  if tree not instanceof Array
    switch typeof tree
      when 'string'
        result = handleString tree, env
      else
        result = tree
    prettyPrint"#{ tree} evaluated to #{result}"
  else
    head = tree.shift()
    prettyPrint"head is #{head}"
    fn = env.find(head)
    prettyPrint"fn is #{fn}"
    result = fn?(tree, env) ? throw new ReferenceError "#{prettyFormat head} does not exist in context"
    prettyPrint"#{head} call on #{tree} evaluated to #{result}"
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
        fn = evalTree fn, env
        args = evalTree args, env
        prettyPrint"apply> fn: #{fn} args: #{args}"
        (env.find fn)(args, env)
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
      env['=']  = ([a, args...], env) ->
        value = evalTree a, env
        (everyCompression (b) -> b == value)(args, env)
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
      env['if'] = ([test, consequence, orelse], env) ->
        if evalTree test, env
          evalTree consequence, env 
        else evalTree orelse, env
    # lists processing
      env['"'] = (args) -> "\"#{args.join ' '}\""
    # definitions (variable, function, macro)
      env['def'] = ([name, value], env) -> env.findEnv(name)[name] = evalTree value, env
      env['lambda'] = ([params, expr], env) -> 
        lambda = (args, env) ->
          prettyPrint"anon func args> #{args}"
          flattenedTree = for arg in args
            evalTree arg, env
          evalTree expr, Env { params, args: flattenedTree, outer: env }
        lambda.toJSON = -> "#{treeToString params} -> #{treeToString expr}"
        lambda
    # hardcoded macros
      env['defun'] = ([name, params, expr], env) ->
        env['def'] [name, ['lambda', params, expr]], env
      env['def*'] = (args) ->
        env['progn'] (args.map ([name, value]) -> ['def', name, value]), env
      env["'"] = (args, env) -> args
      env['eval'] = ([args], env) ->
        result = evalTree args, env
        return result unless result instanceof Array
        [fn, args...] = result
        env['apply'] [['quote', fn], ['list'].concat args]
        , env
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