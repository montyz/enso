
require 'core/system/library/schema'
require 'core/system/utils/paths'
require 'core/schema/tools/copy'

# TODO: use the builtin paths here.

def paths(obj, path = [],  &block)
  field = Schema::class_key(obj.schema_class)

  current = path
  if field then
    key = obj[field.name]
    current = [*path, obj[field.name]]
    yield current
  end

  obj.schema_class.defined_fields.each do |f|
    next if f.computed
    next if !f.traversal
    if f.many then
      obj[f.name].each do |elt|
        paths(elt, current, &block) 
      end
    elsif f.optional then
      paths(obj[f.name], current, &block) unless obj[f.name].nil? || f.type.Primitive?
    else
      paths(obj[f.name], current, &block) unless f.type.Primitive?
    end
  end
end

def map_names!(obj, &block)
  field = Schema::class_key(obj.schema_class)

  if field then
    key = obj[field.name]
    x = yield obj[field.name]
    obj[field.name] = x if x
  end

  obj.schema_class.defined_fields.each do |f|
    next if f.computed
    next if !f.traversal
    if f.many then
      obj[f.name].each do |elt|
        map_names!(elt, &block) 
      end
    elsif f.optional then
      map_names!(obj[f.name], &block) unless obj[f.name].nil? || f.type.Primitive?
    else
      map_names!(obj[f.name], &block) unless f.type.Primitive?
    end
  end
end

def prime!(obj, prefix = '_')
  map_names!(obj) do |name|
    "#{prefix}.#{name}"
  end
end

def prime(obj, prefix = '_')
  obj = Clone(obj)
  prime!(obj, prefix)
  return obj
end



def rename!(obj, map)
  field = Schema::class_key(obj.schema_class)

  # first recompute the nested rename map since
  # nested paths depend on the old names
  map2 = {}
  if field then
    map.each do |k, v|
      name = obj[field.name]
      if k.is_a?(Hash) && k[name] then
        map2[k[name]] = v
      else
        map2[k] = v
      end
    end
  else
    map2 = map
  end

  # then update the key of the current obj if there is a key
  # if it is in the map
  if field then
    key = obj[field.name]
    obj[field.name] = map[key] if map[key]
  end
  
  rename_fields!(obj, map2)
end

def rename_fields!(obj, map)
  # then rename each non-primitive, non-nil, spine field using
  # the new map.
  obj.schema_class.defined_fields.each do |f|
    next if f.computed
    next if !f.traversal
    if f.many then
      obj[f.name].each do |elt|
        rename!(elt, map) 
      end
      obj[f.name]._recompute_hash! if Schema::is_keyed?(f.type)
    else
      rename!(obj[f.name], map) unless obj[f.name].nil? || f.type.Primitive?
    end
  end
  obj
end


def rename(obj, map)
  obj = Clone(obj)
  rename!(obj, map)
  return obj
end


if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/grammar/render/layout'
  require 'core/schema/code/factory'
  require 'core/schema/tools/print'
  require 'core/schema/tools/copy'
  ss = Load::load('schema.schema')
  sg = Load::load('schema.grammar')
  gg = Load::load('grammar.grammar')
  gs = Load::load('grammar.schema')

  ss_copy = copy(ss)


  map = {
    "Class" => "Class",
    {"Class" => "supers"} => "supertypes"
  }
  rename!(ss_copy, map)

  require 'core/grammar/tools/rename_binding'
  
  sg_copy = copy(sg)
  rename_binding!(sg_copy, map)
  
  Print::Print.print(sg_copy)

  Layout::DisplayFormat.print(gg, sg_copy)
  Layout::DisplayFormat.print(sg, ss_copy)

  prime!(sg_copy)
  
  puts "========= PRIMED ======="
  Layout::DisplayFormat.print(gg, sg_copy)

  paths(ss_copy) do |path|
    p path
  end
  
  #DisplayFormat.print(sg_copy, ss_copy)
end


# .types[str]
# .types[Schema].fields[types]
