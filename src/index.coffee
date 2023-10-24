{ Tonic } = require '@socketsupply/tonic'
class PrettyLisp extends Tonic
  render: ->
    @html"""
      Pretty Lisp Transpiler
    """

Tonic.add PrettyLisp