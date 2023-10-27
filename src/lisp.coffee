
prettyPrint = (x) -> console.log JSON.stringify x, undefined, 4

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
  console.log 'new env created:', env
  env

exports.tokenize = tokenize = (input) -> (
  input
  .replaceAll '(', ' ( '
  .replaceAll ')', ' ) '
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

handleString = (string, env) -> (env.find string) ? string

###
  TODOs:
    - [x] make quote not evaluate the subtree
    - [x] make aliases work
    - [x] make var definitions
    - [ ] make macro definitions
    - [ ] make lambda definitions
###
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
  if env.find(head) isnt env.find('quote')
    tree = for argument in tree
      switch
        when argument instanceof Array
          argument = evalTree argument, env 
        when typeof argument is 'string'
          argument = handleString argument, env
      argument

  switch
    when fn = env.find(head)
      console.log "calling #{head} with", tree
      fn tree, env
    else
      throw new ReferenceError " #{head} does not exist in context"

exports.addGlobals = addGlobals = (env) ->
      env['progn'] = (args, env) -> args.at -1
    # math ops
      env['+']  = (args) ->  args.reduce (acc, cur) -> acc + cur
      env['-']  = (args) ->  args.reduce (acc, cur) -> acc - cur
      env['*']  = (args) ->  args.reduce (acc, cur) -> acc * cur
      env['/']  = (args) ->  args.reduce (acc, cur) -> acc / cur
      env['%']  = (args) -> args.reduce (acc, cur) -> acc % cur
      env['mod'] = (args) -> args.reduce (acc, cur) -> acc %% cur
    # math comparsions
      env['>']  = (args) ->  args.reduce (acc, cur) -> acc > cur
      env['<']  = (args) ->  args.reduce (acc, cur) -> acc < cur
      env['>='] = (args) ->  args.reduce (acc, cur) -> acc >= cur
      env['<='] = (args) ->  args.reduce (acc, cur) -> acc <= cur
      env['='] = ([a, args...]) -> args.every (arg) -> arg == a
    # boolean logic
      env['and'] = (args) ->  args.reduce (acc, cur) -> acc and cur
      env['or']  = (args) ->  args.reduce (acc, cur) -> acc or cur
      env['not'] = ([a]) -> not a
    # list operations
      env['length'] = ([a]) -> a.length
      env['cons'] = ([a, b]) -> a.concat(b)
      env['car'] = ([a]) -> a
      env['cdr'] = ([a, args...]) -> args
      env['append'] = ([a, b]) -> a.concat(b)
      env['list'] = (args) -> args
    # checks
      env['list?'] = (args) -> args.every (a) -> a instanceof Array
      env['null'] = (args) -> args.every (a) -> a.length == 0
      env['symbol?'] = (args) -> args.every (a) -> typeof a == 'string'
    # control flow
      env['if'] = ([test, consequence, orelse]) -> if test then consequence else orelse
    # lists processing
      env["'"] = (args) -> args
      env['"'] = (args) -> "\"#{args.join ' '}\""
    # definitions (variable, function, macro)
      env['def'] = ([name, value], env) -> env.findEnv(name)[name] = value
      env['def*'] = (args, env) -> env['def'] name, value for [name, value] in args
    # aliases
      env['equal?'] = env['=']
      env['eq?'] = env['=']
      env['string'] = env['"']
      env['quote'] = env["'"]
      
      env

exports.doFreshEnv = doFreshEnv = (outer) -> addGlobals Env { params: [], args: [], outer }
global_env = doFreshEnv()