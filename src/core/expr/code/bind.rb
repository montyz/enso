module BindExpr

  include Interpreter::Dispatcher    
    
  def bind(obj)
    dispatch(:bind, obj)
  end

 # args
  def bind_EVar(name)
    env = @D[:args][:env]
    if env.keys.include? name
      BindExpr.make_const(env[name], @D[:args][:factory])
    else
      @D[:args][:self]
    end
  end

  def bind_?(op, e1, e2)
    @D[:args][:self]
  end

  def self.make_const(val, factory)
    if val.is_a?(String)
      factory.EStrConst(val)
    elsif val.is_a?(Integer)
      factory.EIntConst(val)
    elsif val.is_a?(TrueClass) or val.is_a?(FalseClass)
      factory.EBoolConst(val)
    else
      val
    end
  end
end

class BindExprC
  include BindExpr
end