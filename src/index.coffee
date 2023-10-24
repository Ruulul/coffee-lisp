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
           <lisp-transpiler id=#{@id}-output></lisp-transpiler>
           <button data-event=compile>
            Compile
          </button>
      </div>
    """

components.push class LispTranspiler extends Tonic
  calculateIdentation: (line) ->
    count = 0
    for char in line
      if char == ' ' then count++ else break
    count
  _transpile: (input, prevLine = '') ->
    return unless input
    console.log "input: #{input.replaceAll '\n', '|'}"
    #debugger
    pointer = 0
    lines = input.split '\n'
    transpilation = []
    firstIdentation = @calculateIdentation lines[0]
    for line, index in lines
      pointer += line.length + 1
      prevIdentation = @calculateIdentation prevLine if prevLine?
      currIdentation = @calculateIdentation line
      nextIdentation = @calculateIdentation nextLine if (nextLine = lines[index + 1])?
      prevIdentation ?= 0
      nextIdentation ?= 0
      switch
        when nextIdentation > currIdentation
          nextBit = lines.map @calculateIdentation
            .indexOf currIdentation, 1
          transpilation.push """
          #{' '.repeat currIdentation}(#{line.trim()}
          #{@_transpile (
            lines
            .slice 1, nextBit
            .join '\n'), line}
          #{' '.repeat currIdentation})
          """
        when nextIdentation <= currIdentation
          transpilation.push """
          #{' '.repeat currIdentation}(#{line.trim()})
          """
    console.log transpilation.join '|'
    transpilation
    .filter (line) => (@calculateIdentation line) == firstIdentation 
    .join '\n'

  transpile: (input) ->
    @state.output = 'transpiling...'
    @reRender()
    @state.output = String @_transpile input
    @reRender()
  render: ->
    @html"""
    <pre><output>#{@state.output}</output></pre>
    """

Tonic.add component for component in components