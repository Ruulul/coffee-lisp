{ Tonic } = require '@socketsupply/tonic'

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
        @querySelector('output').innerText = element.value 
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
  calculateIdentation: (line) ->
    count = 0
    for char in line
      if char == ' ' then count++ else break
    count
  _transpile: (lines, prevLine = '') ->
    return unless lines?.length > 0
    #debugger
    transpilation = []
    firstIdentation = @calculateIdentation lines[0]
    do => for line, index in lines
      continue unless (@calculateIdentation line) == firstIdentation 
      prevIdentation = @calculateIdentation prevLine if prevLine?
      currIdentation = @calculateIdentation line
      nextIdentation = @calculateIdentation nextLine if (nextLine = lines[index + 1])?
      prevIdentation ?= 0
      nextIdentation ?= 0
      switch
        when nextIdentation > currIdentation
          nextBit = lines.map @calculateIdentation
            .indexOf currIdentation, index + 1
          nextBit = undefined if nextBit is -1
          """
          #{' '.repeat currIdentation}(#{line.trim()}
          #{@_transpile (lines.slice index + 1, nextBit), line}
          #{' '.repeat currIdentation})
          """
        when nextIdentation <= currIdentation
          """
          #{' '.repeat currIdentation}(#{line.trim()})
          """
    .join '\n'

  transpile: (input) ->
    @state.output = 'transpiling...'
    @reRender()
    @state.output = String @_transpile input.split '\n'
    @reRender()
  render: ->
    @html"""
    <pre><output>#{@state.output}</output></pre>
    """

Tonic.add component for component in components