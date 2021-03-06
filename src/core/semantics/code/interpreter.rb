=begin

 Some definitions for documentation below:
 - operation: an action the interpreter can take, eg eval, debug, lvalue, etc
 - type: schema type, eg BinaryOp
 - method: name of method for {o:operation X t:type} eg eval_BinaryOp()
=end

module Interpreter
  class DynamicPropertyStack
    def initialize
      @current = {}
      @stack = []
    end
    
    def [](name)
      @current[name]
    end
    
    def include?(name)
      @current.include?(name)
    end
    
    def _bind(field, value)
      old = @current[field]
      @stack << [field, old]
      @current[field] = value
    end
    
    def _pop(n = 1)
      while (n > 0) do
        parts = @stack.pop
        @current[parts[0]] = parts[1]
        n -= 1
      end
    end
    
    def to_s
      @current.to_s
    end
  end
  
  module Dispatcher
    attr_accessor :_
    
    def dynamic_bind fields, &block
      if !@D
        @D = DynamicPropertyStack.new
      end
      fields.each do |key, value|
        @D._bind(key, value)
      end
      result = block.call
      @D._pop(fields.size)
      result
    end
    
    def debug
      @debug = true
      @indent = 0 if !@indent
    end
    
    def dispatch(operation, obj)
      if @debug
        $stderr << "#{' '.repeat(@indent)}>#{operation} #{obj}\n"
        @indent = @indent + 1
      end
      type = obj.schema_class
      method = "#{operation}_#{type.name}".to_s
      if !respond_to?(method)
        method = find(operation, type)  # slow path
      end
      if !method
        method = "#{operation}_?".to_s
        if !respond_to?(method)
          raise "Missing method in interpreter for #{operation}_#{type.name}(#{obj})"
        end
        result = send(method, type, obj, @D)
      else
        params = type.fields.map {|f| obj[f.name] }
        result = send(method, *params)
      end
      if @debug
        @indent = @indent - 1
        $stderr << "#{' '.repeat(@indent)}= #{result}\n"
      end
      result
    end
  
    def dispatch_obj(operation, obj, *params)
      type = obj.schema_class
      method = "#{operation}_#{type.name}".to_s
      if !respond_to?(method)
        method = find(operation, type)  # slow path
      end
      if !method
        method = "#{operation}_?".to_s
        if !respond_to?(method)
          raise "Missing method in interpreter for #{operation}_#{type.name}(#{obj})"
        end
      end
      send(method, obj, *params)
    end
      
    def find(operation, type)
      method = "#{operation}_#{type.name}".to_s
      if respond_to?(method)
        method
      else
        type.supers.find_first do |p| 
          find(operation, p)
        end
      end
    end
  end
end
