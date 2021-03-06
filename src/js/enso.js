
if (typeof window === 'undefined') {
// running in node
  fs = require("fs");
  ARGV = process.argv.slice(2);
  puts = function(obj) {
    console.log("" + obj);
  }
} else {
// running in browser
  puts = function(obj) {
    document.write(("" + obj).replace(/</g, "&lt").replace(/>/g, "&gt").replace(/\n/g, "<br>") + "<br>");
  }
  root_url = window.location.href;
  var pos = root_url.indexOf("/js");
  root_url = root_url.slice(0, pos + 1);
  fs = {
    readFileSync: function(path) {
      var resource;
      if(typeof ActiveXObject == 'undefined'){
        resource = new XMLHttpRequest();
      }
      else{ // IE
        resource = new ActiveXObject("Microsoft.XMLHTTP");
      }
      resource.open('GET', root_url + path, false);
      resource.send(null);
      return resource.responseText; // JavaScript waits for response
    }
  }
}
  
  S = function() {
   return  Array.prototype.slice.call(arguments).join("");
  }
      
  EnsoHash = function(init) {
    var data = init;
    this.has_key_P = function(key) { return data.hasOwnProperty(key); };
    this._get = function(key) { 
      return data[key]; 
    };
    this.inspect = function() {
      return "<HASH " + this.size() + ">";
    }
    this.toString = this.inspect;
    this.size = function() { 
      var count = 0;
      for (k in data) {
        if (data.hasOwnProperty(k))
          count++;
      }
      return count;
    };
    this._set = function(key, value) {
      return data[key] = value;
    };
    this.each = function(fun) {
      for (k in data) {
        if (data.hasOwnProperty(k))
          fun(k, data[k]);
      }
    };
    this.each_value = function(fun) {
      for (k in data) {
        if (data.hasOwnProperty(k))
          fun(data[k]);
      }
    };
    this.keys = function() { 
      var keys = [];
      for (k in data) {
        if (data.hasOwnProperty(k))
          keys.push(k);
      }
      return keys;
    }
    this.values = function() { 
      var vals = [];
      this.each_value(function(x) {
        vals.push(x);
      })
      return vals;
    }
    this.empty_P = function() { 
      var count = 0;
      for (k in data) {
        if (data.hasOwnProperty(k))
          return false;
      }
      return true;
    };
  }
  
  TrueClass = Boolean;
  FalseClass = Boolean;
  Proc = { new: function(p) { return p; } };
  
  CompatStream = function(s) {
    this.push = function(d) {
      if (s)
        s.write(d);
      else
        document.write(("" + d).replace("<", "&lt").replace(">", "&gt").replace("\n", "<br>"));
    }
  };

  File = {
    exists_P: function(p) { 
      return fs.existsSync(p);
    },
    create_file_map: function () {
      return System.readJSON("model_index.json");
    },
    read_header: function (path) {
      var data = fs.readFileSync(path).toString();
      var pos = data.indexOf("\n");
      if (pos == -1)
        return data;
      else
        return data.substring(0, pos);
    }
  };
  
  System = {
    max: function(a, b) {
      return a > b ? a : b;
    },
    readJSON: function(path) {
      return JSON.parse(fs.readFileSync(path));
    },
    test_type: function(obj, type) {
      if (obj == null)
        return false;
      if (typeof type != "function")
        type = type.new;
      return obj.is_a_P(type); // TODO: why does this work, but "obj instanceof type" does not?
    },
    stdout: function() { return new CompatStream(typeof process == 'undefined' ? null : process.stdout); },
    stderr: function() { return new CompatStream(typeof process == 'undefined' ? null : process.stderr); },
  }
  
  Object.prototype.raise = function(msg) { puts(msg); return ERROR; }
  
  compute_rest_arguments = function(args, num) { 
    var x = new Array;
    while (num < args.length)
      x.push(args[num++]);
    return x;
  }

  Function.prototype.call_rest_args$ = function(obj, fun, args, rest) {
    var len = arguments.length;
    var newargs = [];
    var i;
    for (i = 1; i < len-2; i++) 
      newargs.push(arguments[i]);
    newargs = newargs.concat(arguments[len-1]); 
    return this.apply(a, newargs);
  }
  
  Array.prototype.values = function() { return this; }
  Array.prototype.any_P = Array.prototype.some;
  Object.prototype.has_key_P = Object.prototype.hasOwnProperty
  Array.prototype.each = function(fun) {  // Array.prototype.forEach;
    var i;
    for (i = 0; i < this.length; i++) {
      fun(this[i], i);
    }
  };
  Array.prototype.each_with_index = Array.prototype.each;
  Array.prototype.clone = function(fun) {  // Array.prototype.forEach;
    var i;
    var result = new Array;
    for (i = 0; i < this.length; i++) {
      result.push(this[i]);
    }
    return result;
  };
  Array.prototype.zip = function(other) {  // Array.prototype.forEach;
    var i;
    var result = new Array;
    for (i = 0; i < this.length; i++) {
      result.push([this[i], other[i]]);
    }
    return result;
  };
  
  String.prototype.inspect = function() {
     return "\"" + this.replace(/([\\"'])/g, "\\$1").replace(/\0/g, "\\0") + "\"";
  } 
  String.prototype.repeat = function(n) {
    result = "";
    for (var i = 0; i < n; i++)
      result = result + this;
    return result;
  }
  
  Array.prototype.size = function() { return this.length }
  Array.prototype.map = function(fun) {  // Array.prototype.forEach;
    var result = new Array;
    this.each(function (x) { 
      result.push(fun(x));
    })
    return result;
  };
 
  Object.prototype.include_P =  function(obj) {  // Array.prototype.filter;
    var i;
    for (i = 0; i < this.length; i++) {
      if (this[i] == obj)
        return true;
    }
    return false;
  };  
  Array.prototype.select =  function(fun) {  // Array.prototype.filter;
    var i;
    var result = new Array;
    for (i = 0; i < this.length; i++) {
      if (fun(this[i]))
        result.push(this[i]);
    }
    return result;
  };
  Array.prototype.flat_map = function(fun) { 
    var x = new Array; 
    this.each(function(obj) { 
      x = x.concat(fun(obj));
    }); 
    return x; 
  };
  Array.prototype.concat = function(other) {
    var x = new Array; 
    var hasA, hasB;
    this.each(function(obj) { 
      x.push(obj);
      hasA = true;
    }); 
    other.each(function(obj) { 
      x.push(obj);
      hasb = true;
    }); 
    return x; 
  };
  Array.prototype.union = function(other) {
    var x = new Array; 
    this.each(function(obj) { 
      x.push(obj);
    }); 
    other.each(function(obj) {
      // if (!x.contains(obj))
        x.push(obj);
    }); 
    return x; 
  };
  
    
  
  
  Object.prototype.each = function (cmd) {
    for (var i in this) {
      if (this.hasOwnProperty(i)) {
        var a = this[i];
        cmd.call(a, i, a)
      }
    }
  }

  _fixup_method_name = function(name) { 
    if (name.slice(-1) == "?") { 
      name = name.slice(0,-1) + "_P";
    } 
    return name; 
  }
  Object.prototype.find = function(pred) { 
    var result = null;
    this.each( function(a) {
      if (result == null && pred(a)) {
        result = a; 
      }
    });
    return result;
  }
  Object.prototype.find_first = function(pred) { 
    var result = null;
    this.each( function(a) {
      if (result == null) {
        var item = pred(a);
        if (item) 
          result = item; 
      }
    });
    return result;
  }
  
  Integer = Number;
  Numeric = Number;
  Fixnum = Number;
  
  Object.prototype.is_a_P = function(type) { return this instanceof type; }
  Object.prototype.define_singleton_value = function(name, val) { this[_fixup_method_name(name)] = function() { return val;} }
  Object.prototype.define_singleton_method = function(proc, name) { this[_fixup_method_name(name)] = proc }
  String.prototype.size = function() { return this.length }
  String.prototype.to_s = function() { return this }
  Number.prototype.to_i = function() { return this }
  Number.prototype.to_s = function() { return this.toString(); }
  Array.prototype.to_s = function() { return "<ARRAY " + this.length + ">" }
  String.prototype.casecmp = function(other) { 
     puts("COMP " + this + "=" + other + " => " + this.toUpperCase() === other.toUpperCase());
     return this.toUpperCase() === other.toUpperCase() 
   }
  Array.prototype.first = function() { return this[0]; }
  Object.prototype._get = function(k) { return this[k] }
  String.prototype._get = function(k) { if (k >= 0) { return this[k] } else { return this[this.length+k] } }
  Array.prototype._get = function(k) { if (k >= 0) { return this[k] } else { return this[this.length+k] } }
  Object.prototype._set = function(k, v) { this[k] = v; return v; }
  String.prototype._set = function(k, v) { raise("Strings are immutable"); }
  String.prototype.gsub = String.prototype.replace;
  String.prototype.index = String.prototype.indexOf;
  String.prototype.to_sym = function() { return this; }
  String.prototype.start_with_P = function(prefix) {
    return this.indexOf(prefix) === 0;
  }
  String.prototype.end_with_P = function(suffix) {
      return this.match(suffix+"$") == suffix;
  };
  String.prototype.rindex = String.prototype.lastIndexOf;
  
  string$split = String.prototype.split;
  String.prototype.split = function(sep, lim) {
    return string$split.call(this, sep, lim).filter(function(x) { return x != ""; });
  }
  string$slice = String.prototype.slice;
  String.prototype.slice = function(start, len) {
    if (len != undefined)
      len = start + len;
    return string$slice.call(this, start, len);
  }
  
  EnsoBaseClass = {
  }
  // put enso global methods here
  EnsoBaseClass._instance_spec_ = {  
    send: function(method) {
      var args = Array.prototype.slice.call(arguments, 1);
      var fun = this[method.replace("?", "_P")];
      if (!fun) raise("Undefined method " + method + " for " + this);
      var val = fun.apply(this, args);
      return val;
    },
    define_getter: function(name, prop) {
      this[name] = function() { return prop.get() }    // have to get "self" right
    },
    define_setter: function(name, prop) {
      this["set_" + name] = function(val) { 
        prop.set(val)
      }  // have to get "self" right
    },
    _get: function(k) { return this[k].call(this); },
    _set: function(k, v) { 
      return this["set_" + k].call(this, v);
    },
    method: function(m) { var self = this; 
      return function() { 
        return self[m].apply(self, arguments); 
    }},
    to_s: function() {             
       var kind = this.__classname__;
       if (this.schema_class)
         kind = this.schema_class().name();
       var info = "";
       if (typeof this.name == "function")
         info = this.name();
       else if (this._id)
         info = this._id();
       return "<[" + kind + " " + info + "]>";
    },
    respond_to_P: function(method) { return this[method.replace("?", "_P")]; },
  }

  MakeClass = function(name, base_class, includes, meta_fun, instance_fun) {
      // NewClass = MakeClass(ParentClass, function(super) { return { 
      //    _class_: { 
      //         class_var1: init-value,            // @@var
      //         class_method: function(...) {...}  // def self.class_method(...) ...
      //         // the "new" method gets added here
      //     },
      //     initialize: function(..) {             // def intialize(..) 
      //        this.$.instance_var = init-value;   //    @instance_vaf = ...
      //     },
      //     instance_method: function(a, b) {    // def instance_method(a, b, *args)
      //        var self = this;                  // default preamble
      //        args = get_rest_arguments(arguments, 2)  // autogenerated call to set up rest args
      //        self.$.var                          // @var
      //        self._class_.var                    // @@var
      //        self.super$.foo.apply(self, arguments);    // super
      //        self.super$.foo.call(self, arg1, arg2...); // super(arg1, arg2)  # in foo method
      //        o.foo(a,b,*c)                       // o.foo.call_method(a, b, c)  # where call_method is in the library
      //     }
      //  }})
      // return value: the value of _class_ is the return value (or a synthetic new _class_ is added for you)
          
      // base_class is the *class* object of the base class
      // instance_fun returns the record containing fields for this object, given super
      //    which can contain a "_class_" field to specify its class data

      // create a class structure if there isn't one (for example, when inheriting Array)
      var parent_proto;
      if (typeof base_class === "function") {
        parent_proto = base_class.prototype;
        var temp = new Object(EnsoBaseClass);
        temp.new = base_class;
        base_class = temp;
      } else {
        if (base_class == null)
          base_class = EnsoBaseClass;
        parent_proto = base_class._instance_spec_;
      }

      // get the prototype of the base constructor function      
      // if there are mixins, then a clone of the mixin's prototype is inserted between object and base
      if (includes.length > 0) {
        var eigen = Object.create({});
    		for (var i = 0, len = includes.length; i < len; i++) {
    			var methods = includes[i];
    			for (var m in methods) {
    				if (methods.hasOwnProperty(m)) {
    				  eigen[m] = methods[m] 
    			  }
    			}
  	    }
        eigen.__proto__ = parent_proto;
        parent_proto = eigen;
      }
      else {
        // connect this instance_spec bindings to inherit the parent's instance_spec 
      }

      var instance_spec = new instance_fun(parent_proto);
      instance_spec.__classname__ = name;
      instance_spec.__proto__ = parent_proto;

      // make sure there is a class object 
      instance_spec._class_ = new Object({});
      instance_spec._class_.$ = base_class.$ || new Object({});
      meta_fun.call(instance_spec._class_);
      
      // connect this object's class data to the base class data 
      instance_spec._class_.__proto__ = base_class;
      // remember the instance_spec for each class
      instance_spec._class_._instance_spec_ = instance_spec;
      // make sure there is an initializer function
      instance_spec.initialize = instance_spec.initialize || function() {
          if (parent_proto.hasOwnProperty("initialize")) {
              parent_proto.initialize.apply(this, arguments);
          }
      };

      // create the constructor function      
      var constructor = function() {
         var obj = Object.create(instance_spec);
         obj.$ = {};

          obj.inspect = EnsoBaseClass._instance_spec_.to_s;
          obj.toString = function() { 
            return this.to_s();
          };
          
         instance_spec.initialize.apply(obj, arguments);
         return obj;
      }
      // set its prototype, even thought it is not actually used view "new"
      // it is accessed above
      // fill in the "new" function of the class
      constructor.prototype = instance_spec;
      instance_spec._class_.new = constructor;
      // return the new class
      return instance_spec._class_;
  }  

  EnsoProxyObject = EnsoBaseClass;
  
  MakeMixin = function(includes, instance_fun) {
      var instance_spec = new instance_fun();
      // get all methods defined in this mixin and its parents
      	var methods = {};
      	if (includes.length > 0) {
    			for (var i = 0, len = includes.length; i < len; i++) {
    				var incld = includes[i];
            for (var attr in incld) {
              if (incld.hasOwnProperty(attr)) { 
                methods[attr] = incld[attr]
               }
            }
    			}
      	}
      	for (var attr in instance_spec) {
      		if (instance_spec.hasOwnProperty(attr)) { 
      		  methods[attr] = instance_spec[attr]
      		 }
      	}
      	return methods
   }
   Enumerable = MakeMixin([], function() {
     this.all_P= function(pred) { var x = true; this.each(function(obj) { x = x && pred(obj) }); return x; };
     this.any_P= function(pred) { var x = false; this.each(function(obj) { x = x || pred(obj) }); return x; };
     this.map = Array.prototype.map;
     this.each_with_index = function(cmd) {
       var i = 0;
       this.each(function(obj) { 
         cmd(obj, i);
         i++;
       })
     };
   });

    Range = MakeClass("Range", null, [Enumerable], 
    function() {},
    function(super$) { return {
      initialize: function(a, b) {
        this.$.a = a;
        this.$.b = b;
      },
      each: function(proc) {
        var i;
        for (i = this.$.a; i <= this.$.b; i++)
          proc(i);
      }       
    }});   

