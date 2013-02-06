require 'core/expr/code/eval'

module EvalStencil
  include EvalExpr

  def eval_Color(r, g, b, factory)
    factory.Color(r.eval.round, g.eval.round, b.eval.round)
  end

  def eval_InstanceOf(base, class_name)
    a = base.eval
    a && Schema::subclass?(a.schema_class, class_name)
  end

  def eval_ETernOp(op1, op2, e1, e2, e3, dynamic)
    if !dynamic
      super
    else
      v = e1.eval
      fail "NON_DYNAMIC #{v}" if !v.is_a?(Variable)
      a = e2.eval
      b = e3.eval
      v.test(a, b)
    end
  end

  def eval_EBinOp(op, e1, e2, dynamic)
    if !dynamic
      super op, e1, e2
    else
      r1 = e1.eval
      r1 = Variable.new("gen", r1) if r1 && !r1.is_a?(Variable)
      r2 = e2.eval
      r2 = Variable.new("gen", r2) if r2 && !r2.is_a?(Variable)
      r1.send(op.to_s, r2)
    end
  end

  def eval_EUnOp(op, e, dynamic)
    if !dynamic
      super op, e
    else
      r1 = e1.eval
      r1 = Variable.new("gen", r1) if r1 && !r1.is_a?(Variable)
      r1.send(op.to_s)
    end
  end

  def eval_EField(e, fname, in_fc, dynamic)
    if in_fc or !dynamic
      super e, fname, in_fc
    else
      r = e.eval
      if r.is_a? Variable
        r = r.value.dynamic_update
      else
        r = r.dynamic_update
      end
      r.send(fname)
    end
  end

end
