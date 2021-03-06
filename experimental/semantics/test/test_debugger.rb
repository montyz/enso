require 'core/system/load/load'
require 'core/semantics/interpreters/debug'

#Fibo is the fibonacci function. Source found in core/expr/test/fibo.impl
# Note that the whole program is surrounded by an implicit block (EBlock)
# with two statements: the fun def and the fun call

CacheXML.clean('fibo.impl') #need to clean cache to get origin tracking
fib = Load::load('fibo.impl')
Load::Loader.find_model('fibo.impl') {|path| $file = IO.readlines(path)}

#EvalCommandC.new is the non-debug version
# DebugMod is parameterized by the interpreter (ie EvalCommand),
interp = Interpreter(Debug.wrap(EvalCommand))

#run it!
puts interp.eval(fib, env: {'f'=>10})
