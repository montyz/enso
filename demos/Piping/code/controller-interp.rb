
module ExecuteController
  include Lvalue::LValueExpr
  include Eval::EvalExpr
  
  operation :execute, :init, :isEVar

  def init_Controller(globals, env)
    globals.each do |g|
      if g.var.isEVar
        #Note that a new interpreter is 'needed' here because
        # suppose the outer interpreter is being debugged, you certainly don't want
        # this lambda env expresssion to show up in the debugger as well
        l = LambdaEnv.new(g.var.name) {Interpreter(EvalExpr).eval(g.val[], env: env)}
        env.set_grandparent(l)
      else
        g.eval
      end
    end
  end
  def isEVar_EVar; true; end
  def isEVar_?(type, fields, args); false; end

  def execute_Controller(states, constraints, env)
    states[env[:current_state].value].execute
    constraints.each do |c|
      c.execute
    end
  end

  def execute_Constraint(cond, action)
    if cond.eval
      action.eval
    end
  end

  def execute_State(commands, transitions, env)
    #test conditions BEFORE executing current state!!!
    moved = transitions.detect do |trans|
      trans.execute
    end
    if !moved
      commands.each do |c|
        env1 = Env::HashEnv.new.set_parent(env)  #create a new blank env page
        c.eval(env: env1)
      end
    end
  end

  def execute_Transition(guard, target, control, env)
    if guard.eval
      env[:current_state].value = target[].name
      true
    else
      false
    end
  end

  def eval_Assign(var, val)
    var.lvalue.value = val.eval
  end

  def eval_TurnSplitter(splitter, percent, env)
    env[splitter].position = [[percent, 1.0].min, 0.0].max
  end
end
