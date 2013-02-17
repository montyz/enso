define([
  "core/expr/code/eval",
  "core/expr/code/lvalue",
  "core/semantics/code/interpreter"
],
function(Eval, Lvalue, Interpreter) {

  var Impl ;
  var Closure = MakeClass( {
    env: function() { return this.$.env },
    set_env: function(val) { this.$.env  = val },

    initialize: function(body, formals, env, interp) {
      var self = this; 
      var super$ = this.super$.initialize;
      self.$.body = body;
      self.$.formals = formals;
      self.$.env = env.clone();
      return self.$.interp = interp;
    },

    call: function() {
      var self = this; 
      var params = compute_rest_arguments(arguments, 0 );
      var nenv;
      var super$ = this.super$.call;
      nenv = Env.HashEnv().new();
      self.$.formals.zip(params).each(function(f, v) {
        return nenv ._set( f.name() , v );
      });
      nenv.set_parent(self.$.env);
      return self.$.interp.dynamic_bind(function() {
        return self.$.interp.eval(self.$.body);
      }, new EnsoHash ( { } ));
    },

    to_s: function() {
      var self = this; 
      var super$ = this.super$.to_s;
      return S("#<Closure(", self.$.formals.map(function(f) {
        return f.name();
      }).join(", "), ") {", self.$.body, "}>");
    }
  });

  var EvalCommand = MakeMixin({
    include: [ Eval. EvalExpr , Lvalue. LValueExpr , Interpreter. Dispatcher ],

    eval: function(obj) {
      var self = this; 
      var super$ = this.super$.eval;
      return self.dispatch("eval", obj);
    },

    eval_EWhile: function(cond, body) {
      var self = this; 
      var super$ = this.super$.eval_EWhile;
      while (self.eval(cond)) {
        self.eval(body);
      }
    },

    eval_EFor: function(var_V, list, body) {
      var self = this; 
      var nenv;
      var super$ = this.super$.eval_EFor;
      nenv = Env.HashEnv().new().set_parent(self.$.D._get("env"));
      return self.eval(list).each(function(val) {
        nenv ._set( var_V , val );
        return self.dynamic_bind(function() {
          return self.eval(body);
        }, new EnsoHash ( { } ));
      });
    },

    eval_EIf: function(cond, body, body2) {
      var self = this; 
      var super$ = this.super$.eval_EIf;
      if (self.eval(cond)) {
        return self.eval(body);
      } else if (! (body2 == null)) {
        return self.eval(body2);
      }
    },

    eval_EBlock: function(body) {
      var self = this; 
      var res;
      var super$ = this.super$.eval_EBlock;
      res = null;
      self.dynamic_bind(function() {
        return body.each(function(c) {
          return res = self.eval(c);
        });
      }, new EnsoHash ( { } ));
      return res;
    },

    eval_EFunDef: function(name, formals, body) {
      var self = this; 
      var res;
      var super$ = this.super$.eval_EFunDef;
      res = Impl.Closure().new(body, formals, self.$.D._get("env"), self);
      res.env() ._set( name , res );
      self.$.D._get("env") ._set( name , res );
      return res;
    },

    eval_ELambda: function(body, formals) {
      var self = this; 
      var super$ = this.super$.eval_ELambda;
      return Proc.new(function() {
        return Impl.Closure().new(body, formals, self.$.D._get("env"), self).call .call_rest_args$(Impl.Closure().new(body, formals, self.$.D._get("env"), self), p );
      });
    },

    eval_EFunCall: function(fun, params, lambda) {
      var self = this; 
      var p, f;
      var super$ = this.super$.eval_EFunCall;
      return self.dynamic_bind(function() {
        if (lambda == null) {
          return self.eval(fun).call .call_rest_args$(self.eval(fun), params.map(function(p) {
            return self.eval(p);
          }) );
        } else {
          p = self.eval(lambda);
          f = self.eval(fun);
          return f.call .call_rest_args$(f, params.map(function(p) {
            return self.eval(p);
          }) );
        }
      }, new EnsoHash ( { } ));
    },

    eval_EAssign: function(var_V, val) {
      var self = this; 
      var super$ = this.super$.eval_EAssign;
      return self.lvalue(var_V).value() = self.eval(val);
    }
  });

  var EvalCommandC = MakeClass( {
    include: [ EvalCommand ],

    initialize: function() {
      var self = this; 
      var super$ = this.super$.initialize;
    }
  });

  Impl = {
    Closure: Closure,
    EvalCommand: EvalCommand,
    EvalCommandC: EvalCommandC,

  };
  return Impl;
})