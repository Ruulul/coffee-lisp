{ Tonic } = require '@socketsupply/tonic'
{ tokenize, parseTokens, evalTree } = lisp = require './lisp.coffee'

components = []

processEvent = (fn, dataKey = 'event') ->
  (e) ->
    element = Tonic.match e.target, "[data-#{dataKey}]"
    return unless element? 
    event = element.dataset[dataKey]
    fn.call this, event, element, e

components.push class PrettyLisp extends Tonic
  keydown: processEvent handleTabsOnTextArea = (event, textarea, e) ->
    if event == 'input'
      if e.keyCode == '\t'.charCodeAt 0
        e.preventDefault()
        start = textarea.selectionStart
        textarea.setRangeText '  '
        , start
        , start
        , 'end'
  change: processEvent (event, element) ->
    switch event
      when 'input'
        @querySelector('lisp-transpiler').transpile element.value
  click: processEvent (event) ->
    if event == 'compile'
      @querySelector('lisp-transpiler').transpile @querySelector('textarea').value
  input: processEvent (event, element) ->
    switch event
      when 'input'
        @querySelector('output[data-output=lisp]').innerText = element.value 
  render: ->
    @html"""
       <div>
           <textarea data-event=input></textarea>
           <button data-event=compile>
            Compile
          </button>
           <lisp-transpiler id=#{@id}-output>
          </lisp-transpiler>
      </div>
    """

components.push class LispTranspiler extends Tonic
  click: processEvent (event, el, e) ->
    e.preventDefault()
    switch event
      when 'eval'
        @state.eval = 
          try 
            evalTree (parseTokens tokenize @state.output), lisp.doFreshEnv() 
          catch e 
            console.log e
            String e
        @reRender()
  calculateIdentation: (line) ->
    return undefined unless line?
    count = 0
    for char in line
      if char == ' ' then count++ else break
    count
  _transpile: (lines, prevLine = '') ->
    return unless lines?.length > 0
    transpilation = []
    firstIdentation = @calculateIdentation lines[0]
    for line, index in lines
      continue unless (currIdentation = @calculateIdentation line) == firstIdentation 
      nextLine = lines[index + 1]
      nextIdentation = @calculateIdentation nextLine
      switch
        when nextIdentation and nextIdentation > currIdentation
          nextBit = lines.map @calculateIdentation
            .indexOf currIdentation, index + 1
          nextBit = undefined if nextBit is -1
          transpilation.push """
          #{' '.repeat currIdentation}(#{line.trim()}
          #{@_transpile (lines.slice index + 1, nextBit), line}
          #{' '.repeat currIdentation})
          """
        else
          transpilation.push """
          #{' '.repeat currIdentation}(#{line.trim()})
          """
    transpilation
    .join '\n'

  transpile: (input) ->
    @state.output = 'transpiling...'
    @reRender()
    @state.output = String @_transpile input.split '\n'
    @reRender()
  render: ->
    @html"""
    <pre><output data-output=lisp>#{@state.output}</output></pre>
    <button data-event=eval>Eval output</button>
    <pre><output data-output=eval>#{String @state.eval}</button></pre>
    """

Tonic.add component for component in components