
prettyPrint = (x) -> console.log JSON.stringify x, undefined, 4

exports.Env = Env = (obj) ->
  env = {}
  outer = obj.outer ? {}
  env[obj.params[i]] = arg for arg, i in obj.args
  env.find = (variable) ->
    if variable of env
      env[variable]
    else outer?.find variable
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

###
  TODOs:
    - make quote not evaluate the subtree
    - make aliases work
    - make var definitions
    - make macro definitions
    - make lambda definitions
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
    env['+']  = (args) ->  args.reduce (acc, cur) -> acc + cur
    env['-']  = (args) ->  args.reduce (acc, cur) -> acc - cur
    env['*']  = (args) ->  args.reduce (acc, cur) -> acc * cur
    env['/']  = (args) ->  args.reduce (acc, cur) -> acc / cur
    env['%']  = (args) -> args.reduce (acc, cur) -> acc % cur
    env['mod'] = (args) -> args.reduce (acc, cur) -> acc %% cur

    env['>']  = (args) ->  args.reduce (acc, cur) -> acc > cur
    env['<']  = (args) ->  args.reduce (acc, cur) -> acc < cur
    env['>='] = (args) ->  args.reduce (acc, cur) -> acc >= cur
    env['<='] = (args) ->  args.reduce (acc, cur) -> acc <= cur
    env['='] = ([a, args...]) -> args.all((arg) -> arg == a)

    env['and'] = (args) ->  args.reduce (acc, cur) -> acc and cur
    env['or']  = (args) ->  args.reduce (acc, cur) -> acc or cur
    env['not'] = ([a]) -> not a

    env['length'] = ([a]) -> a.length
    env['cons'] = ([a, b]) -> a.concat(b)
    env['car'] = ([a]) -> a
    env['cdr'] = ([a, args...]) -> args
    env['append'] = ([a, b]) -> a.concat(b)
    env['list'] = (args) -> args
    env['list?'] = (args) -> args.all (a) -> a instanceof Array
    env['null?'] = (args) -> args.all (a) -> a.length == 0
    env['symbol?'] = (args) -> args.all (a) -> typeof a == 'string'
    env['if'] = ([test, consequence, orelse]) -> if test then consequence else orelse
    env["'"] = (args) -> args
    env['"'] = (args) -> "\"#{args.join ' '}\""
    # aliases
    env['equal?'] = env['=']
    env['eq?'] = env['=']
    env['string'] = env['"']
    env['quote'] = env["'"]
    env

global_env = addGlobals Env { params: [], args: [], outer: undefined }