
# the important thing about copy is that it does NOT use
# the traversal fields (spine) of the structure.

class Copy
  def initialize(factory, memo = {})
    @factory = factory
    @memo = memo
  end

  def register(source, target)
      @memo[source] = target
  end
  
  def copy(source, *args)
    return nil if source.nil?
    target = @memo[source]
    return target if target
    #puts "COPY #{source} #{args}"
    klass = source.schema_class
    target = @factory[klass.name]

	# copy the primitive fields first, so that our name is defined
    klass.fields.each do |field|
      if field.type.Primitive?
        target[field.name] = source[field.name]
      end
    end

    register(source, target)

    klass.fields.each do |field|
      next if field.type.Primitive? || (field.inverse && field.inverse.traversal)
      #puts "  FIELD #{field.name} #{source[field.name].class} #{source[field.name]}"
      if !field.many
        target[field.name] = copy(source[field.name], *args)
      else
        source[field.name].each do |x|
          target[field.name] << copy(x, *args)
        end
      end
    end
    return target
  end
end


def copy(obj)
  f = Factory::new(obj._graph_id.schema)
  obj = Copy.new(f).copy(obj)
  obj.finalize
end

if __FILE__ == $0 then

  require 'core/system/load/load'
  
  gs = Load::load('grammar.schema')
  sg = Load::load('schema.grammar')

  require 'core/schema/tools/print'
  
  newSchema = Copy.new(Factory::new(gs)).copy(sg)
  newSchema.finalize()
  
  Print::Print.print(newSchema)
end
