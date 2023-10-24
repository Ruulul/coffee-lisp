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
        textarea.setRangeText '\t'
        , start
        , start
        , 'end'
  change: processEvent (event, element) ->
    switch event
      when 'input'
        @querySelector('output').innerText = 'transpiling...'
  input: processEvent (event, element) ->
    switch event
      when 'input'
        @querySelector('output').innerText = element.value 
  render: ->
    @html"""
       <div>
         <textarea data-event=input></textarea>
         <lisp-transpiler></lisp-transpiler>
      </div>
    """

components.push class LispTranspiler extends Tonic
  render: ->
    @html"""
    <pre><output></output></pre>
    """

Tonic.add component for component in components